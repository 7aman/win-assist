if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}function print_help {
    Write-Host  "Usage:"  -ForegroundColor Green
    Write-Host  "   firew on"  -ForegroundColor Green
    Write-Host  "               : to enable firewalls"  -ForegroundColor Green
    Write-Host  "   firew off"  -ForegroundColor Green
    Write-Host  "               : to disable firewalls"  -ForegroundColor Green
    Write-Host "*****************************************"
}
Switch ($args[0]) {
    "on" {
        Write-Host  "Enabling Firewall..."  -ForegroundColor Yellow
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True | Wait-Job
        Write-Host "Done!" -ForegroundColor Green
    }
    "off" {
        Write-Host  "Disabling Firewall...     "  -ForegroundColor Yellow
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False | Wait-Job
        Write-Host "Done!" -ForegroundColor Red
    }
    default{
        print_help
    }
}
Pause