if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}
function print_help {
    Write-Host  "Usage:"  -ForegroundColor Green
    Write-Host  "   firew on"  -ForegroundColor Green
    Write-Host  "               : to enable firewalls"  -ForegroundColor Green
    Write-Host  "   firew off"  -ForegroundColor Green
    Write-Host  "               : to disable firewalls"  -ForegroundColor Green
    Write-Host "*****************************************"
}
Switch ($args[0]) {
    "on" {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True | Wait-Job
        Write-Host  "Enabling Firewall..."  -ForegroundColor Yellow
    }
    "off" {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False | Wait-Job
        Write-Host  "Disabling Firewals...     "  -ForegroundColor Yellow
    }
    default{
        print_help
    }
}
Write-Host "Done!" -ForegroundColor Red
Pause