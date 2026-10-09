EBU OS 1.0 - Kurulum Rehberi
=============================
1) ISO ÜRET (üç yoldan biri)
   a) Debian/Ubuntu makine:  sudo bash build-ebu-iso.sh   (tam)  veya  sudo PROFILE=lite bash build-ebu-iso.sh  (küçük)
   b) Windows kullanıyorsan: VirtualBox'a Ubuntu kur, orada a) yi çalıştır
   c) Bulutta: bu klasörü GitHub'a yükle, Actions > Build EBU ISO > Run workflow
2) VIRTUALBOX'TA DENE
   Linux/Mac: bash create-ebu-vm.sh ebu-os-1.0-amd64.iso
   Windows:   create-ebu-vm.bat C:\yol\ebu-os-1.0-amd64.iso
   Giriş: kullanıcı "ogrenci", parola "live" (ilk kurulumda değiştir!)
3) GERÇEK BİLGİSAYARA KUR
   ISO'yu Rufus/Balena Etcher ile USB'ye yaz, USB'den aç, masaüstündeki Install ile Calamares'i çalıştır.
4) WINDOWS PROGRAMI: .exe dosyasına çift tıkla (Wine). Uyum program programa değişir.

5) KURULUM YARDIMCISI (Windows): EBU-Kurulum.bat dosyasina cift tikla. ISO yolunu sec, "Kur ve Baslat".
   .exe istersen: PowerShell > Install-Module ps2exe -Scope CurrentUser; Invoke-ps2exe .\EBU-Kurulum.ps1 .\EBU-Kurulum.exe -noConsole
