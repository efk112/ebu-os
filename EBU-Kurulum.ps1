# EBU OS Kurulum Yardımcısı (Windows) - sanal makineyi ve EBU ISO'yu otomatik kurar
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$IsoUrl = ""   # <-- GitHub Releases'teki ebu-os-1.0-amd64.iso linkini buraya yaz (boşsa "Gözat" ile ISO seçilir)
$VmName = "EBU-OS"

$f = New-Object Windows.Forms.Form -Property @{Text="EBU OS Kurulum Yardımcısı";Size="560,520";StartPosition="CenterScreen";FormBorderStyle="FixedDialog";MaximizeBox=$false;Font="Segoe UI,10"}
function L($t,$x,$y,$w=500,$h=24,$b=$false){$l=New-Object Windows.Forms.Label -Property @{Text=$t;Location="$x,$y";Size="$w,$h"};if($b){$l.Font="Segoe UI,16,style=Bold"};$f.Controls.Add($l);$l}
L "EBU OS" 20 12 300 36 $true | Out-Null
L "Windows'ta sanal makine olarak EBU'yu kurar." 20 50 | Out-Null
L "ISO dosyası:" 20 85 | Out-Null
$iso = New-Object Windows.Forms.TextBox -Property @{Location="20,110";Size="400,26"}; $f.Controls.Add($iso)
$br = New-Object Windows.Forms.Button -Property @{Text="Gözat";Location="430,108";Size="90,28"}; $f.Controls.Add($br)
L "RAM (MB):" 20 150 90 | Out-Null
$ram = New-Object Windows.Forms.NumericUpDown -Property @{Location="110,148";Size="80,26";Minimum=2048;Maximum=32768;Increment=512;Value=4096}; $f.Controls.Add($ram)
L "İşlemci:" 210 150 70 | Out-Null
$cpu = New-Object Windows.Forms.NumericUpDown -Property @{Location="280,148";Size="50,26";Minimum=1;Maximum=16;Value=2}; $f.Controls.Add($cpu)
L "Disk (GB):" 350 150 80 | Out-Null
$dsk = New-Object Windows.Forms.NumericUpDown -Property @{Location="430,148";Size="70,26";Minimum=15;Maximum=500;Value=30}; $f.Controls.Add($dsk)
$bar = New-Object Windows.Forms.ProgressBar -Property @{Location="20,190";Size="500,22"}; $f.Controls.Add($bar)
$log = New-Object Windows.Forms.TextBox -Property @{Location="20,222";Size="500,190";Multiline=$true;ReadOnly=$true;ScrollBars="Vertical"}; $f.Controls.Add($log)
$go = New-Object Windows.Forms.Button -Property @{Text="Kur ve Başlat";Location="20,425";Size="500,40";Font="Segoe UI,11,style=Bold"}; $f.Controls.Add($go)
function Log($m){$log.AppendText("$m`r`n");[Windows.Forms.Application]::DoEvents()}

$br.Add_Click({$d=New-Object Windows.Forms.OpenFileDialog -Property @{Filter="ISO|*.iso"};if($d.ShowDialog() -eq "OK"){$iso.Text=$d.FileName}})

$go.Add_Click({
  $go.Enabled=$false
  try{
    # 1) VirtualBox
    $vb="$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
    if(-not (Test-Path $vb)){
      Log "VirtualBox bulunamadı, kuruluyor (winget)..."
      if(Get-Command winget -ErrorAction SilentlyContinue){
        winget install -e --id Oracle.VirtualBox --accept-package-agreements --accept-source-agreements | Out-Null
      }
      if(-not (Test-Path $vb)){Start-Process "https://www.virtualbox.org/wiki/Downloads";throw "VirtualBox'ı elle kur (sayfa açıldı), sonra bu programı tekrar çalıştır."}
    }
    Log "VirtualBox hazır."
    # 2) ISO
    if(-not $iso.Text){
      if(-not $IsoUrl){throw "ISO seçilmedi. 'Gözat' ile ISO'yu seç."}
      $dest="$env:USERPROFILE\Downloads\ebu-os-1.0-amd64.iso"; Log "ISO indiriliyor (yarıda kalırsa tekrar çalıştır)..."
      $j=Start-BitsTransfer -Source $IsoUrl -Destination $dest -Asynchronous
      while($j.JobState -in 'Connecting','Transferring'){ if($j.BytesTotal -gt 0){$bar.Value=[int](100*$j.BytesTransferred/$j.BytesTotal)};[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 300}
      if($j.JobState -ne 'Transferred'){throw "İndirme başarısız: $($j.JobState)"}
      Complete-BitsTransfer $j; $iso.Text=$dest; $bar.Value=100
    }
    if(-not (Test-Path $iso.Text)){throw "ISO bulunamadı: $($iso.Text)"}
    # 3) Sanal makine
    $name=$VmName; if((& $vb list vms) -match "`"$name`""){$name="$VmName-"+(Get-Date -Format "MMddHHmm")}
    Log "Sanal makine oluşturuluyor: $name"
    $dir="$env:USERPROFILE\VirtualBox VMs\$name"; $vdi="$dir\$name.vdi"
    & $vb createvm --name $name --ostype Debian_64 --register | Out-Null
    & $vb modifyvm $name --memory $ram.Value --cpus $cpu.Value --vram 128 --graphicscontroller vmsvga --nic1 nat --clipboard-mode bidirectional --draganddrop bidirectional --boot1 dvd --boot2 disk --ioapic on
    & $vb modifyvm $name --audio-driver default --audio-controller hda --audio-enabled on 2>$null
    & $vb createmedium disk --filename $vdi --size ($dsk.Value*1024) | Out-Null
    & $vb storagectl $name --name SATA --add sata --controller IntelAhci
    & $vb storageattach $name --storagectl SATA --port 0 --device 0 --type hdd --medium $vdi
    & $vb storagectl $name --name IDE --add ide
    & $vb storageattach $name --storagectl IDE --port 0 --device 0 --type dvddrive --medium $iso.Text
    Log "Başlatılıyor..."; & $vb startvm $name | Out-Null
    Log "TAMAM! EBU açılıyor. Diske kurmak için masaüstündeki 'Install' simgesini kullan."
    Log "Canlı oturum: kullanıcı ogrenci / parola live"
  }catch{ Log "HATA: $($_.Exception.Message)"; [Windows.Forms.MessageBox]::Show($_.Exception.Message,"EBU Kurulum") | Out-Null }
  $go.Enabled=$true
})
[void]$f.ShowDialog()
