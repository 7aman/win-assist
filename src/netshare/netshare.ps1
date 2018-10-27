
param(
    $PublicNIC = "Wi-Fi", # refers to interface with Internet connectivity
    $PrivateNIC = "Ethernet", # refers to interface in private network
	$PrivateGateway = "192.168.1.2", # IP of PrivateNIC interface after sharing is completed.
	$PrivateSubnet = "24" # Netmask of PrivateNIC interface after sharing is completed.
)

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

$SUBNETS = @(
    "0.0.0.0",
    "128.0.0.0",
    "192.0.0.0",
    "224.0.0.0",
    "240.0.0.0",
    "248.0.0.0",
    "252.0.0.0",
    "254.0.0.0",
    "255.0.0.0",
    "255.128.0.0",
    "255.192.0.0",
    "255.224.0.0",
    "255.240.0.0",
    "255.248.0.0",
    "255.252.0.0",
    "255.254.0.0",
    "255.255.0.0",
    "255.255.128.0",
    "255.255.192.0",
    "255.255.224.0",
    "255.255.240.0",
    "255.255.248.0",
    "255.255.252.0",
    "255.255.254.0",
    "255.255.255.0",
    "255.255.255.128",
    "255.255.255.192",
    "255.255.255.224",
    "255.255.255.240",
    "255.255.255.248",
    "255.255.255.252",
    "255.255.255.254",
    "255.255.255.255"
)
# Irgument Validation
# Get-NetAdapter
$ValidIpAddressRegex = [regex] "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
$ValidSubnetRegex = [regex]"^([0-9]|[1-2][0-9]?|3[0-2])$"
$ValidIPSubnetRegex = [regex] "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/([0-9]|[1-2][0-9]?|3[0-2])$"

foreach ($arg in $args){
    if ($arg -match $ValidIpAddressRegex){
        Write-Host $arg, " is ip"
    }
    if ($arg -match $ValidSubnetRegex) {
        Write-Host $arg, " is subnet"
    }
    if ($arg -match $ValidIPSubnetRegex) {
        Write-Host $arg, " is ip/subnet"
    }
}

function Test-AdapterName($name){
    if( $(Get-NetAdapter -Name $name -ErrorAction SilentlyContinue -InformationAction SilentlyContinue)){
        write-host $name" is found" -ForegroundColor Green
    } else {
        write-host $name" is not found" -ForegroundColor Red
        Write-Host "Available Options:"
        Get-NetAdapter | Format-Table -Property "Name"
        Pause
        Exit
    }
}
Test-AdapterName($PublicNIC)
Test-AdapterName($PrivateNIC)

$PrivateSubnet = $SUBNETS[$PrivateSubnet]
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