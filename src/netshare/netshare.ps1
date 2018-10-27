
param(
    $PublicNIC = "Wi-Fi", # refers to interface with Internet connectivity
    $PrivateNIC = "Ethernet", # refers to interface in private network
	$PrivateGateway = "192.168.1.2", # IP of PrivateNIC interface after sharing is completed.
	$PrivateSubnet = "255.255.255.0" # Netmask of PrivateNIC interface after sharing is completed.
)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

Write-Host "Running with these Values: " -ForegroundColor Green
Write-Host "netshare.ps1 -PublicNIC '"$PublicNIC"' -PrivateNIC  '"$PrivateNIC"' -PrivateGateway '"$PrivateGateway"' -PrivateSubnet '"$PrivateSubnet"'" -ForegroundColor Green

# Constants
$public = 0 
$private = 1 

Write-Host "Creating netshare object..." -ForegroundColor Yellow
$netshare = New-Object -ComObject HNetCfg.HNetShare

Write-Host "Getting public adapter..." -ForegroundColor Yellow
$publicadapter = $netshare.EnumEveryConnection | Where-Object {$netshare.NetConnectionProps($_).Name -eq $PublicNIC}

Write-Host "Getting private adapter..." -ForegroundColor Yellow
$privateadapter = $netshare.EnumEveryConnection | Where-Object {$netshare.NetConnectionProps($_).Name -eq $PrivateNIC }


$netshare.INetSharingConfigurationForINetConnection($privateadapter).DisableSharing()

Write-Host "Modify public adapter..." -ForegroundColor Yellow
$netshare.INetSharingConfigurationForINetConnection($publicadapter).DisableSharing()
$netshare.INetSharingConfigurationForINetConnection($publicadapter).EnableSharing($public)


Write-Host "Modify private adapter..." -ForegroundColor Yellow
$netshare.INetSharingConfigurationForINetConnection($privateadapter).DisableSharing()
$netshare.INetSharingConfigurationForINetConnection($privateadapter).EnableSharing($private)


# Default IP of private NIC is '192.168.137.1', not very common range. I like to change it to '192.168.1.2'
Write-host "Setting The IP Address of "$PrivateNIC"  to "$PrivateGateway" / "$PrivateSubnet -ForegroundColor Yellow
netsh interface ip set address $PrivateNIC static $PrivateGateway $PrivateSubnet

Write-Host "Done!" -ForegroundColor Green
# Clean up
Remove-Variable netshare
Pause