if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}
$global:SUBNETS = @(
    "255.255.255.0",
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

$global:Arguments = $args

function Write-AdapterNames {
    Write-Host "Available Net Adapters are:" -ForegroundColor Green
    $NIC_list = Get-NetAdapter | Select-Object -Property Name
    foreach ($NIC in $NIC_list) { Write-Host "    "$NIC.Name -ForegroundColor Cyan }
    Pause
    Exit
}
function Test-ActionArgument {
    $ACCEPTED = @("list", "set", "del", "add", "share")
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


function Test-AdapterName($given_string){
    if( $(Get-NetAdapter -Name $given_string -ErrorAction SilentlyContinue -InformationAction SilentlyContinue)) { return $true }
    else { return $false }
}
function Test-IPSubnet($given_string){
    $ValidIpAddressRegex = [regex] "^((?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))$"
    $ValidSubnetRegex = [regex]"^([1-9]|[1-2][0-9]?|3[0-2])$"
    $ValidIPSubnetRegex = [regex] "^((?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))/([1-9]|[1-2][0-9]?|3[0-2])$"
    if ($given_string -match $ValidIpAddressRegex) { return @($given_string, $false) }
    elseif ($given_string -match $ValidSubnetRegex) { return @($false, $given_string) }
    elseif ($given_string -match $ValidIPSubnetRegex) {
        $IPSUBNET = $ValidIPSubnetRegex.Match($given_string).groups
        return @($IPSUBNET[1].Value, $IPSUBNET[2].Value)
    }
    else { return @($false, $false) }
}
function  Show-IPList {
    $NIC = ""
    if ($global:Arguments[1]) {
        $arg = $global:Arguments[1]
        if ($arg -eq "nics") { Write-AdapterNames }
        elseif (Test-AdapterName($arg)) { $NIC = $arg }
        else {
            Write-Host "    given argument($arg) is not a valid NIC." -ForegroundColor Red
            Write-Host "    using 'Ethernet' as default NIC." -ForegroundColor Red
            Write-Host "    you can see list of available NICs by 'ip list nics'." -ForegroundColor Red
            $NIC = "Ethernet"
        }
    }
    else {
        Write-Host "    no arguments is presented." -ForegroundColor Yellow
        Write-Host "    using 'Ethernet' as default NIC." -ForegroundColor Yellow
        Write-Host "    you can see list of available NICs by 'ip list nics'." -ForegroundColor Yellow
        $NIC = "Ethernet"
    }
    Start-Process  netsh "interface ip show config",$NIC -NoNewWindow -wait
}

function  Set-IP {
    $ARGSS = $global:Arguments | Select-Object -Skip 1
    $NIC = ""
    $IPS = @()
    $SUB = ""
    foreach ($arg in $ARGSS){
        if (Test-AdapterName($arg)) { if (!$NIC) { $NIC = $arg } }
        $IP, $eSUB = Test-IPSubnet($arg)
        if ($eSub) { if (!$SUB) { $SUB = $eSUB } }
        if ($IP) { $IPS += $IP }
    }
    if (!$SUB) { $SUB = 24 }
    if (!$NIC) { $NIC = "Ethernet" }
    if (!$IPS) {
        $IPS += "192.168.1.199"
        $IPS += " "
    }
    if (!$IPS[1]) { $IPS += " " }
    Write-Host "Setting IP Address using this command:" -ForegroundColor Green
    Write-Host "    netsh interface ip set address $NIC static" $IPS[0], $global:SUBNETS[$SUB], $IPS[1]
    Start-Process netsh "interface ip set address $NIC static", $IPS[0], $global:SUBNETS[$SUB], $IPS[1] -NoNewWindow -wait
    Write-Host "OK. IP is set successfully." -ForegroundColor  Green

    if ($IPS[2]) {
        Write-Host "Setting Primary DNS using this command:" -ForegroundColor Green
        Write-Host "    netsh interface ip set dnsservers $NIC static", $IPS[2]
        Start-Process netsh "interface ip set dnsserver $NIC static", $IPS[2] -NoNewWindow -wait
        Write-Host "OK. Primary DNS is set successfully." -ForegroundColor  Green
        if ($IPS[3]) {
            Write-Host "Setting Alternative DNS using this command:" -ForegroundColor Green
            Write-Host "    netsh interface ip add dnsservers $NIC", $IPS[3],"index=2"
            Start-Process netsh "interface ip add dnsserver $NIC", $IPS[3],"index=2" -NoNewWindow -wait
            Write-Host "OK. Alternative DNS is set successfully." -ForegroundColor  Green
        }
    } else {
        # delete previous configured dns
        Start-Process netsh "interface ip delete dns $NIC all" -NoNewWindow -wait -RedirectStandardOutput "NUL"
    }  

}

function Add-IP {
    $ARGSS = $global:Arguments | Select-Object -Skip 1
    $NIC = ""
    $IPS = @()
    $SUB = ""
    foreach ($arg in $ARGSS){
        if (Test-AdapterName($arg)) { if (!$NIC) { $NIC = $arg } }
        $IP, $eSUB = Test-IPSubnet($arg)
        if ($eSub) { if (!$SUB) { $SUB = $eSUB } }
        if ($IP) { $IPS += $IP }
    }
    if (!$SUB) { $SUB = 24 }
    if (!$NIC) { $NIC = "Ethernet" }
    if (!$IPS) {
        $IPS += "192.168.1.199"
        $IPS += " "
    }
    if (!$IPS[1]) { $IPS += " " }

    Write-Host "Add IP Address using this command:" -ForegroundColor Green
    Write-Host "    netsh interface ip add address", $NIC, $IPS[0], $global:SUBNETS[$SUB], $IPS[1]
    Start-Process netsh "interface ip add address", $NIC, $IPS[0], $global:SUBNETS[$SUB], $IPS[1] -NoNewWindow -wait
    Write-Host "OK. IP is added successfully." -ForegroundColor  Green
}

function Remove-IP {
    $ARGSS = $global:Arguments | Select-Object -Skip 1
    $NIC = ""
    $IP = ""
    foreach ($arg in $ARGSS){
        if (Test-AdapterName($arg)) { if (!$NIC) { $NIC = $arg } }
        $eIP, $eSUB = Test-IPSubnet($arg)
        if (!$IP) { $IP = $eIP }
    }
    if (!$NIC) { $NIC = "Ethernet" }
    if (!$IP) { $IP = "192.168.1.199" }

    Write-Host "Delete IP Address using this command:" -ForegroundColor Green
    Write-Host "    netsh interface ip delete address", $NIC, $IP
    Start-Process netsh "interface ip delete address", $NIC, $IP -NoNewWindow -wait
    Write-Host "OK. IP is deleted successfully." -ForegroundColor  Green
}

function  Connect-Internet {
    $PublicNIC = ""
    $PrivateNIC = ""
    $PrivateGateway = ""
    $PrivateSubnet = ""
    $ARGSS = $global:Arguments | Select-Object -Skip 1
    foreach ($arg in $ARGSS){
        if (Test-AdapterName($arg)) {
            if (!$PublicNIC) { $PublicNIC = $arg }
            elseif (!$PrivateNIC) { $PrivateNIC = $arg}
        }
        $IP, $SUB = Test-IPSubnet($arg)
        if ($Sub) { if (!$PrivateSubnet) { $PrivateSubnet = $SUB } }
        if ($IP)  { if (!$PrivateGateway) { $PrivateGateway = $IP } }
    }
    
    if (!$PublicNIC) { $PublicNIC = "Wi-Fi" }
    if (!$PrivateNIC) { $PrivateNIC = "Ethernet" }
    if (!$PrivateSubnet) { $PrivateSubnet = 24 }
    if (!$PrivateGateway) { $PrivateGateway = "192.168.1.199" }

    # Constants
    $public = 0 
    $private = 1 

    Write-Host
    Write-Host "Creating netshare object..." -ForegroundColor Yellow
    $netshare = New-Object -ComObject HNetCfg.HNetShare

    Write-Host
    Write-Host "Getting private adapter..." -ForegroundColor Yellow
    $privateadapter = $netshare.EnumEveryConnection | Where-Object {$netshare.NetConnectionProps($_).Name -eq $PrivateNIC }

    Write-Host "Getting public adapter..." -ForegroundColor Yellow
    $publicadapter = $netshare.EnumEveryConnection | Where-Object {$netshare.NetConnectionProps($_).Name -eq $PublicNIC}

    $netshare.INetSharingConfigurationForINetConnection($privateadapter).DisableSharing()

    Write-Host
    Write-host "Modify public adapter..." -ForegroundColor Yellow 
    $netshare.INetSharingConfigurationForINetConnection($publicadapter).DisableSharing()
    $netshare.INetSharingConfigurationForINetConnection($publicadapter).EnableSharing($public)

    Write-Host "Modify private adapter..."  -ForegroundColor Yellow
    $netshare.INetSharingConfigurationForINetConnection($privateadapter).DisableSharing()
    $netshare.INetSharingConfigurationForINetConnection($privateadapter).EnableSharing($private)


    # Default IP of private NIC is '192.168.137.1', not very common range. I like to change it to '192.168.1.199'
    Write-host "Setting IP Address of '$PrivateNIC' to '$PrivateGateway' / '$PrivateSubnet'" -ForegroundColor Yellow 
    $Subnet = $global:SUBNETS[$PrivateSubnet]
    Start-Process netsh "interface ip set address",$PrivateNIC,"static",$PrivateGateway,$Subnet -NoNewWindow -wait
    Start-Process netsh "interface ip delete dns $PrivateNIC all" -NoNewWindow -wait -RedirectStandardOutput "NUL"

    Write-host "Checking Internet Connectivity:" -ForegroundColor Yellow 
    Start-Process ping "8.8.8.8" -NoNewWindow -wait
}

$action = $(Test-ActionArgument)
if ($action -eq "list") { Show-IPList }
elseif ($action -eq "set") { Set-IP }
elseif ($action -eq "add") { Add-IP }
elseif ($action -eq "del") { Remove-IP }
elseif ($action -eq "share") { Connect-Internet}

Write-Host
Write-Host "Done!" -ForegroundColor Green
Pause
