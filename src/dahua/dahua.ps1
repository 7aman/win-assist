if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

Push-Location -Path "$PSScriptRoot\tftp\"
Write-host "Directory is changed tp '$PSScriptRoot\tftp\' successfully" -ForegroundColor Yellow


$global:Arguments = $args

$global:NIC = "Ethernet"
$global:exePath = "$PSScriptRoot\tftp\bin\upgrade_info.exe"
$global:txtPath = "$PSScriptRoot\tftp\commands.txt"
$global:outPath = "$PSScriptRoot\tftp\root\upgrade_info_7db780a713a4.txt"
$global:consolePath = "$PSScriptRoot\tftp\console.bat"
$global:tftpPath = "$PSScriptRoot\tftp\tftp.bat"


function Test-Argument {
    $ACCEPTED = @("tftp", "reset", "again")
    $action = $global:Arguments[0]
    if ($ACCEPTED -contains $action) { return $action }
    else {
        Write-Host "Invalid action argument."
        Write-Host "Valid action arguments are:"
        foreach ($action in $ACCEPTED) { Write-Host "    "$action -ForegroundColor Cyan } 
        Pause
        Exit
    }
}


function Set-IP {
    Write-host "Change Network Configuration:" -ForegroundColor Yellow
    Start-Process netsh "interface ip set address $global:NIC static 192.168.1.1 255.255.0.0"  -NoNewWindow | Wait-Job | out-null
    Start-Process netsh "interface ip add address $global:NIC 192.168.254.254 255.255.0.0" -NoNewWindow | Wait-Job | out-null
    Write-host "    IP is set successfully" -ForegroundColor Yellow
    Set-MpPreference -DisableRealtimeMonitoring $true | Wait-Job
    Write-host "    'Real-time Protection' for Michrosoft Windows Defender Anti-Virus is disabled successfully" -ForegroundColor Yellow
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False | Wait-Job
    Write-host "    'Firewall' is disabled successfully" -ForegroundColor Yellow
    Write-Host
}

function Get-UserCommands {
    Remove-Item  $global:txtPath  -ErrorAction Ignore 
    $i = 0
	while ($True){
		$i++
		Write-host "command $i :"  -ForegroundColor Green -NoNewLine
		$usercommand = $(Read-Host)

		if ($usercommand) {
			if ($i -ne 1) {
				$newline = "`n"
				Out-File -FilePath $global:txtPath -InputObject $newline -Encoding ASCII -Append -NoNewLine
			}
			Out-File -FilePath $global:txtPath -InputObject $usercommand -Encoding ASCII -Append -NoNewLine
		} else {
			if ($i -eq 1) {
				$usercommand = "help"
                Out-File -FilePath $global:txtPath -InputObject $usercommand -Encoding ASCII -Append -NoNewLine
			}
			break
		}
    }

}


function Write-ResetCommands {
    $usercommand = 'cfgRestore'
    Out-File -FilePath $global:txtPath -InputObject $usercommand -Encoding ASCII -Append -NoNewLine
    Write-host "'upgrade_info_7db780a713a4.txt' is created successfully" -ForegroundColor Yellow
	Write-host
}


function Write-UpgradeInfo {
    if (!(Test-Path $(Split-Path $global:outPath -Parent) -PathType Container)) {
        Write-Host "    Creating 'root' directory for tftp..."
        New-Item -ItemType Directory -Force -Path $(Split-Path $global:outPath -Parent) | Out-Null
    }
    Start-Process -FilePath $global:exePath -Args "$global:txtPath $global:outPath" -wait -NoNewWindow
    Write-host "'upgrade_info_7db780a713a4.txt' is created successfully" -ForegroundColor Yellow
	Write-host
}

function Invoke-TFTP {
	Write-host "Running tftp server" -ForegroundColor Yellow
	Write-host
	Start-Process -FilePath $global:tftpPath -WindowStyle Maximized
}


function Invoke-Console {
	Write-host "Running console" -ForegroundColor Yellow
	Write-host
	Start-Process -FilePath  $global:consolePath -WindowStyle Maximized
}


function Stop-OldProcess {
    Get-Process | Where-Object {$_.mainWindowTitle -match "tftp server output"} | Stop-Process
    Get-Process | Where-Object {$_.mainWindowTitle -match "console output"} | Stop-Process
}

function Start-TFTP {
    Set-IP
    Get-UserCommands
    Write-UpgradeInfo
    if ($global:Arguments[1] -eq "open") {
        Invoke-Item $(Split-Path $global:outPath -Parent)
    }
}

function Reset-Configs {
    Set-IP
    # Start-Sleep 3
    Write-ResetCommands
}

$action = $(Test-Argument)
if ($action -eq "tftp") {Start-TFTP }
elseif ($action -eq "reset") { Reset-Configs }
elseif ($action -eq "again") { Set-IP }

Stop-OldProcess
Invoke-Console
Invoke-TFTP
Write-host "Power on your device!" -ForegroundColor Red
Write-host
Timeout /T 5
Exit