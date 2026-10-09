#!/usr/bin/env bash
# VirtualBox'ta EBU OS sanal makinesini otomatik oluşturur ve başlatır.
# Kullanım: bash create-ebu-vm.sh /yol/ebu-os-1.0-amd64.iso
set -euo pipefail
ISO="${1:?ISO yolunu ver}"; VM="EBU-OS"
command -v VBoxManage >/dev/null || { echo "VirtualBox kurulu değil: https://www.virtualbox.org"; exit 1; }
VBoxManage createvm --name "$VM" --ostype Debian_64 --register
VBoxManage modifyvm "$VM" --memory 4096 --cpus 2 --vram 128 --graphicscontroller vmsvga \
  --nic1 nat --clipboard-mode bidirectional --draganddrop bidirectional --boot1 dvd --boot2 disk --ioapic on
VBoxManage modifyvm "$VM" --audio-driver default --audio-controller hda --audio-enabled on 2>/dev/null || true
VDI="$HOME/VirtualBox VMs/$VM/$VM.vdi"
VBoxManage createmedium disk --filename "$VDI" --size 30720
VBoxManage storagectl "$VM" --name SATA --add sata --controller IntelAhci
VBoxManage storageattach "$VM" --storagectl SATA --port 0 --device 0 --type hdd --medium "$VDI"
VBoxManage storagectl "$VM" --name IDE --add ide
VBoxManage storageattach "$VM" --storagectl IDE --port 0 --device 0 --type dvddrive --medium "$ISO"
VBoxManage startvm "$VM"
echo "Sanal makine açıldı. Canlı oturum için bekle; diske kurmak için masaüstündeki 'Install' simgesini kullan."
