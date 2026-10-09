#!/usr/bin/env bash
# EBU OS 1.0 - ISO üretici (Debian 12 "bookworm" + KDE Plasma + Wine + Calamares kurulum sihirbazı)
# Gereken: Debian veya Ubuntu (gerçek makine ya da sanal makine), ~15 GB boş disk, internet
# Çalıştır:  sudo bash build-ebu-iso.sh      Sonuç: ebu/ebu-os-1.0-amd64.iso
set -euo pipefail
[ "$EUID" -eq 0 ] || { echo "Lütfen sudo ile çalıştır."; exit 1; }
apt-get update
apt-get install -y live-build debootstrap debian-archive-keyring squashfs-tools xorriso mtools dosfstools
mkdir -p ebu && cd ebu
lb clean --purge 2>/dev/null || true

lb config \
  --distribution bookworm --architectures amd64 --mode debian \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer none \
  --bootloaders "grub-efi,syslinux" --binary-images iso-hybrid \
  --bootappend-live "boot=live components quiet splash locales=tr_TR.UTF-8 keyboard-layouts=tr timezone=Europe/Istanbul hostname=ebu username=ogrenci" \
  --iso-application "EBU OS" --iso-volume "EBU_OS_1" --iso-publisher "EBU Project" \
  --apt-recommends false --security true --updates true \
  --chroot-squashfs-compression-type xz

mkdir -p config/package-lists config/hooks/live config/includes.chroot/etc/calamares/branding/ebu

cat > config/package-lists/ebu.list.chroot <<'EOF'
live-task-localisation live-task-localisation-desktop
kde-plasma-desktop sddm plasma-nm plasma-pa dolphin konsole kate okular gwenview ark spectacle
task-turkish task-turkish-desktop firefox-esr firmware-linux firmware-iwlwifi firmware-realtek
calamares calamares-settings-debian
wine wine64 winetricks
libreoffice libreoffice-l10n-tr libreoffice-kf5 gimp inkscape audacity vlc
gcompris-qt kturtle kalzium kstars marble stellarium kolourpaint
thonny idle3 geany git python3-pip build-essential
veyon-service veyon-configurator epoptes-client
virtualbox-guest-x11 virtualbox-guest-utils open-vm-tools-desktop qemu-guest-agent spice-vdagent
ufw timeshift htop neofetch cups system-config-printer bluez pipewire-audio
EOF


# --- LITE profil: PROFILE=lite sudo -E bash build-ebu-iso.sh  (hedef ~1-1.5 GB, ölçülmedi) ---
if [ "${PROFILE:-full}" = "lite" ]; then
cat > config/package-lists/ebu.list.chroot <<'EOF'
live-task-localisation
xfce4 xfce4-whiskermenu-plugin xfce4-taskmanager lightdm thunar mousepad ristretto
task-turkish firefox-esr firmware-linux network-manager-gnome pavucontrol
calamares calamares-settings-debian
wine wine64
thonny geany gcompris-qt kturtle
veyon-service epoptes-client
virtualbox-guest-x11 virtualbox-guest-utils open-vm-tools-desktop qemu-guest-agent spice-vdagent
ufw htop neofetch
EOF
fi

cat > config/hooks/live/010-ebu.hook.chroot <<'EOF'
#!/bin/bash
set -e
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="EBU OS 1.0"/; s/^NAME=.*/NAME="EBU OS"/' /etc/os-release || true
echo "EBU OS 1.0 \n \l" > /etc/issue
sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf || true
dpkg --add-architecture i386 || true
echo "ebu" > /etc/hostname
EOF
chmod +x config/hooks/live/010-ebu.hook.chroot

# Calamares markası (kurulum sihirbazında EBU yazar)
cat > config/includes.chroot/etc/calamares/branding/ebu/branding.desc <<'EOF'
---
componentName: ebu
strings:
  productName: "EBU OS"
  shortProductName: "EBU"
  version: "1.0"
  shortVersion: "1.0"
  versionedName: "EBU OS 1.0"
  shortVersionedName: "EBU 1.0"
  bootloaderEntryName: "EBU OS"
  productUrl: "https://example.edu.tr"
  supportUrl: "https://example.edu.tr"
  releaseNotesUrl: "https://example.edu.tr"
images:
  productLogo: "logo.png"
  productIcon: "logo.png"
slideshow: "show.qml"
style:
  sidebarBackground: "#1b212d"
  sidebarText: "#ffffff"
  sidebarTextSelect: "#4f8cff"
EOF

lb build 2>&1 | tee build.log
ISO=$(ls *.iso | head -1); mv "$ISO" ebu-os-1.0-amd64.iso
echo "BİTTİ: $(pwd)/ebu-os-1.0-amd64.iso"
