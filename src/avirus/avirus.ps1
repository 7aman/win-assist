if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}
function print_help {
    Write-Host  "Usage:"  -ForegroundColor Green
    Write-Host  "   avirus on"  -ForegroundColor Green
    Write-Host  "               : to enable antivirus"  -ForegroundColor Green
    Write-Host  "   avirus off"  -ForegroundColor Green
    Write-Host  "               : to disable antivirus "  -ForegroundColor Green
    Write-Host "*********************************************************************************"
}

Switch ($args[0]) {
    "on" {
        Write-Host  "Enabling 'Real-time Protection' for Microsoft Windows Defender Anti-Virus..."  -ForegroundColor Yellow
        Set-MpPreference -DisableRealtimeMonitoring $false | Wait-Job
        Write-Host  "Done!"  -ForegroundColor Green
    }
    "off"   {
        Write-Host  "Disabling 'Real-time Protection' for Microsoft Windows Defender Anti-Virus..."  -ForegroundColor Yellow
        Set-MpPreference -DisableRealtimeMonitoring $true | Wait-Job
        Write-Host  "Done!"  -ForegroundColor Red
     }
    default {
        print_help
    }
}
Timeout /T 5

