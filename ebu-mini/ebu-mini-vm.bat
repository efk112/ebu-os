@echo off
REM EBU Mini OS icin VirtualBox sanal makinesi kurar ve baslatir
set VB="C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
set ISO=%~dp0ebu-os-mini.iso
%VB% createvm --name EBU-Mini --ostype Other --register
%VB% modifyvm EBU-Mini --memory 64 --vram 16 --firmware bios --boot1 dvd --boot2 none --nic1 none
%VB% storagectl EBU-Mini --name IDE --add ide
%VB% storageattach EBU-Mini --storagectl IDE --port 0 --device 0 --type dvddrive --medium "%ISO%"
%VB% startvm EBU-Mini
