#!/bin/bash

# Check for root user
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi

# Get system information
if [[ ! -e "./sysinfo.sh" ]]; then
    echo "Error: Could not find ./sysinfo.sh script."
    exit 1
fi
. ./sysinfo.sh

################################################################################
# Basic packages
################################################################################

# Basic packages
PKG_BASIC+="wget base base-devel sudo bash-completion lsb-release htop "
PKG_BASIC+="gnome-keyring unrar cfv bind-tools "

# Install lts kernel + headers for x64 and dkms
if [[ $CPU_X64 -eq 1 ]]; then
    PKG_BASIC+="linux-lts linux-lts-headers linux-headers "
fi

################################################################################
# XORG
################################################################################

# Install X-server
PKG_XORG+="xorg-server mesa "

# Install desktop utils + video drivers for vm
if [[ CPU_VM -eq 1 ]]; then
    echo "Installing Virtualbox drivers"
    PKG_XORG+="linux-headers linux-lts-headers "
    PKG_XORG+="virtualbox-guest-utils virtualbox-guest-dkms "
# Install video drivers for x64 PC
elif [[ $CPU_X64 -eq 1 ]]; then
    INTEL_CARD=`lspci | grep -e VGA -e 3D | grep -i Intel | wc -l`
    NVIDIA_CARD=`lspci | grep -e VGA -e 3D | grep -i Nvidia | wc -l`
    AMD_CARD=`lspci | grep -e VGA -e 3D | grep -i Amd | wc -l`
    ATI_CARD=`lspci | grep -e VGA -e 3D | grep -i Ati | wc -l`
    if [[ $INTEL_CARD -eq 1 ]]; then
        echo "Installing Intel drivers"
        PKG_XORG+="xf86-video-intel "
    elif [[ $NVIDIA_CARD -eq 1 ]]; then
        echo "Installing Nvidia drivers"
        PKG_XORG+="xf86-video-nouveau "
    elif [[ $ATI_CARD -eq 1 ]]; then
        echo "Installing ATI drivers"
        PKG_XORG+="xf86-video-ati "
    elif [[ $AMD_CARD -eq 1 ]]; then
        echo "Installing AMD drivers"
        PKG_XORG+="xf86-video-amdgpu "
    else
        echo "Warning: No graphic card found. Installing fbdev and vesa."
        echo "You might want to search your graphic card with:"
        echo "lspci | grep -e VGA -e 3D"
        echo "pacman -Ss xf86-video"
        PKG_XORG+="xf86-video-fbdev xf86-video-vesa "
    fi
# Install raspi video drivers
elif [[ $CPU_RPI -eq 1 ]]; then
    PKG_XORG+="xf86-video-fbturbo-git "
    #PKG_XORG+="xf86-video-fbdev"
fi
# TODO? xorg-utils xorg-server-utils

################################################################################
# Desktop environment
################################################################################

# lightdm
PKG_DESKTOP+="lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings "
PKG_DESKTOP+="accountsservice light-locker "

# xfce
PKG_DESKTOP+="exo garcon gtk-xfce-engine tumbler xfce4-mixer xfce4-panel "
PKG_DESKTOP+="xfce4-power-manager xfce4-session xfce4-settings xfconf xfdesktop "
PKG_DESKTOP+="xfwm4 xfce4-terminal thunar-volman thunar"

# TODO arc theme + icons
# TODO git ad dep here?
PKG_DESKTOP+="gnome-themes-standard gtk-engine-murrine elementary-icon-theme "

# Install other DE related tools/plugins (also see xfce4-goodies)
PKG_DESKTOP+="dconf-editor alsa-utils xdg-user-dirs network-manager-applet "
PKG_DESKTOP+="networkmanager xfce4-notifyd nm-connection-editor file-roller "
PKG_DESKTOP+="thunar-archive-plugin xfce4-xkb-plugin xfce4-cpugraph-plugin "
PKG_DESKTOP+="thunar-media-tags-plugin plank "
PKG_DESKTOP+="xfce4-cpugraph-plugin xfce4-genmon-plugin xfce4-mpc-plugin "
PKG_DESKTOP+="xfce4-sensors-plugin xfce4-xkb-plugin xfce4-whiskermenu-plugin "
PKG_DESKTOP+="xfce4-mixer gstreamer0.10-good-plugins ffmpegthumbnailer "
PKG_DESKTOP+="freetype2 libgsf libopenraw poppler-glib xfce4-screenshooter "

# x64 only tools
if [[ $CPU_X64 -eq 1 ]]; then
    PKG_DESKTOP+="xfce4-battery-plugin "
fi

# Optional DE packages
PKG_DESKTOP_OPT+="alacarte numix-themes "


################################################################################
# Applications
################################################################################

# Applications
PKG_APP+="firefox qtox deja-dup rhythmbox gst-libav vlc thunderbird "
PKG_APP+="libreoffice-fresh gnome-disk-utility evince gnome-calculator pinta "
PKG_APP+="irssi pidgin gparted gedit meld mousepad xfburn xfce4-screenshooter "
PKG_APP+="gpicview gnome-system-monitor uget "

# x64 only
if [[ $CPU_X64 -eq 1 ]]; then
    PKG_APP+="kodi handbrake dolphin-emu "
fi

# Non ARM6 only (ARM7, x64)
if [[ $CPU_ARM6 -eq 0 ]]; then
    PKG_APP+="chromium "
fi

# Raspberry Pi only
if [[ $CPU_RPI -eq 1 ]]; then
    PKG_APP+="kodi-rbp kodi-rbp-eventclients rng-tools wiringpi "
fi

# Application alternatives
PKG_APP_ALT+="brasero gedit gnome-screenshot ristretto xfce4-taskmanager "


################################################################################
# Other
################################################################################

# Development
PKG_DEV+="git avr-gcc avrdude libusb hidapi jdk8-openjdk jre8-openjdk vim "

# Optional
PKG_OPT+="filezilla wine keepass bless puddletag openssh "

# Pentration testing
PKG_HCK+="ettercap-gtk wireshark-gtk aircrack-ng reaver nmap pygtk "

# TODO
#alsa tools pavucontrol notes/todo vnc avahi nss-mdns virtualbox virtualbox-guest-dkms linux-headers linux-lts-headers


################################################################################
# Installation
################################################################################

# Check for system updates before Configuring new packages to not break anything
echo "Checking for updates..."
checkupdates
if [[ $? -ne 0 ]];then
    pacman -Syyu
    if [[ $? -ne 0 ]]; then
        echo "Error: Installation failed."
        exit 1
    fi
else
    echo "Already up to date."
fi

PKG_ALL+="$PKG_BASIC"
PKG_ALL+="$PKG_XORG"
PKG_ALL+="$PKG_DESKTOP"
PKG_ALL+="$PKG_APP"
PKG_ALL+="$PKG_DEV"
PKG_ALL+="$PKG_OPT"
PKG_ALL+="$PKG_HCK"

echo "Installing selected packages..."
pacman -S --needed $PKG_ALL
