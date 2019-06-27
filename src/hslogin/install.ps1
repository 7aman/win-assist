$Name = "hslogin"
$scriptPath = $PSScriptRoot
# bin Folder
$shrtDst = Split-Path (Split-Path $scriptPath -Parent) -Parent 
$PWERSHELL = "C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe"
$WshShell = New-Object -comObject WScript.Shell

$shrt = $shrtDst + "\$Name.lnk"
$MyShortcut = $WshShell.CreateShortcut($shrt)
$MyShortcut.WindowStyle = 3
$MyShortcut.IconLocation = $scriptPath +"\$Name.ico"
$MyShortcut.TargetPath = $PWERSHELL
$MyShortcut.Arguments =  "$scriptPath\$Name.ps1"
$MyShortcut.Save()

$bytes = [System.IO.File]::ReadAllBytes($shrt)
$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
[System.IO.File]::WriteAllBytes($shrt, $bytes)
