@echo off
REM Windows için: create-ebu-vm.bat C:\yol\ebu-os-1.0-amd64.iso
set VB="C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
set ISO=%~1
set VM=EBU-OS
%VB% createvm --name %VM% --ostype Debian_64 --register
%VB% modifyvm %VM% --memory 4096 --cpus 2 --vram 128 --graphicscontroller vmsvga --nic1 nat --clipboard-mode bidirectional --draganddrop bidirectional --boot1 dvd --boot2 disk --ioapic on
%VB% createmedium disk --filename "%USERPROFILE%\VirtualBox VMs\%VM%\%VM%.vdi" --size 30720
%VB% storagectl %VM% --name SATA --add sata --controller IntelAhci
%VB% storageattach %VM% --storagectl SATA --port 0 --device 0 --type hdd --medium "%USERPROFILE%\VirtualBox VMs\%VM%\%VM%.vdi"
%VB% storagectl %VM% --name IDE --add ide
%VB% storageattach %VM% --storagectl IDE --port 0 --device 0 --type dvddrive --medium "%ISO%"
%VB% startvm %VM%
