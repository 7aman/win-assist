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
    $ACCEPTED = @("list", "set", "del", "add", "ping", "open", "share", "port")
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

function  Show-IP {
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
        $IPS += "192.168.1.1"
        $IPS += " "
    }
    if (!$IPS[1]) { $IPS += " " }
    Write-Host "Setting IP Address using this command:" -ForegroundColor Green
    Write-Host "    netsh interface ip set address $NIC static" $IPS[0], $global:SUBNETS[$SUB], $IPS[1]
    Start-Process netsh "interface ip set address $NIC static", $IPS[0], $global:SUBNETS[$SUB], $IPS[1] -NoNewWindow -wait

    if ($IPS[2]) {
        Write-Host "Setting Primary DNS using this command:" -ForegroundColor Green
        Write-Host "    netsh interface ip set dnsservers $NIC static", $IPS[2]
        Start-Process netsh "interface ip set dnsserver $NIC static", $IPS[2] -NoNewWindow -wait
        if ($IPS[3]) {
            Write-Host "Setting Alternative DNS using this command:" -ForegroundColor Green
            Write-Host "    netsh interface ip add dnsservers $NIC", $IPS[3],"index=2"
            Start-Process netsh "interface ip add dnsserver $NIC", $IPS[3],"index=2" -NoNewWindow -wait
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
        $IPS += "192.168.1.1"
        $IPS += " "
    }
    if (!$IPS[1]) { $IPS += " " }

    Write-Host "Add IP Address using this command:" -ForegroundColor Green
    Write-Host "    netsh interface ip add address", $NIC, $IPS[0], $global:SUBNETS[$SUB], $IPS[1]
    Start-Process netsh "interface ip add address", $NIC, $IPS[0], $global:SUBNETS[$SUB], $IPS[1] -NoNewWindow -wait
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
    if (!$IP) { $IP = "192.168.1.1" }

    Write-Host "Delete IP Address using this command:" -ForegroundColor Green
    Write-Host "    netsh interface ip delete address", $NIC, $IP
    Start-Process netsh "interface ip delete address", $NIC, $IP -NoNewWindow -wait
}

function Ping-IP {
    $arg = $global:Arguments[1]
    function Test-IP($given_string){
        $ValidIpAddressRegex = [regex] "^((?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))$"
        $ValidPartialRegex = [regex]"^(25[0-4]|2[0-4][0-9]|[01]?[0-9]?[0-9])$"
        if ($given_string -match $ValidIpAddressRegex) { return @($given_string, $false) }
        elseif ($given_string -match $ValidPartialRegex) { return @($false, $given_string) }
    }
    
    if ($null -eq $arg) { $Destination = "8.8.8.8" }
    else {
        $FullIP, $PartialIP = Test-IP($arg)
        if ($FullIP) { $Destination = $FullIP }
        elseif ($PartialIP) { $Destination = "192.168.1." + $PartialIP }
        else { 
            Write-Host "Invalid IP" -ForegroundColor Red
            Pause
            Exit
        }
    }
    Start-Process ping "-t $Destination" -NoNewWindow -Wait
}

function Open-IP {
    $arg = $global:Arguments[1]
    function Test-IP($given_string){
        $ValidIpAddressRegex = [regex] "^((?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))$"
        $ValidPartialRegex = [regex]"^(25[0-4]|2[0-4][0-9]|[01]?[0-9]?[0-9])$"
        if ($given_string -match $ValidIpAddressRegex) { return @($given_string, $false) }
        elseif ($given_string -match $ValidPartialRegex) { return @($false, $given_string) }
    }
    
    if ($null -eq $arg) { $Destination = "192.168.1.108" }
    else {
        $FullIP, $PartialIP = Test-IP($arg)
        if ($FullIP) {$Destination = $FullIP }
        elseif ($PartialIP) { $Destination = "192.168.1." + $PartialIP }
        else { 
            Write-Host "Invalid IP" -ForegroundColor Red
            $Destination = "about:blank"
        }
    }

    $browser = $null
    if (Get-Process iexplore -ea silentlycontinue | Where-Object {$_.MainWindowTitle -ne ""}) {
        Write-Host "IE is running"
        $browser = (New-Object -COM "Shell.Application").Windows() | Where-Object  { $_.Name -eq "Internet Explorer" } | Select-Object -Last 1
        Start-Sleep -milliseconds 50
        $browser.Navigate2($Destination);
    } else {
        Write-Host "Launching IE"
        $browser  = New-Object -COM "InternetExplorer.Application"
        Start-Sleep -milliseconds 50
        $browser.visible=$true
        $browser.Navigate2($Destination);
    }
    Exit
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
    if (!$PrivateGateway) { $PrivateGateway = "192.168.1.1" }

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


    # Default IP of private NIC is '192.168.137.1', not very common range. I like to change it to '192.168.1.1'
    Write-host "Setting IP Address of '$PrivateNIC' to '$PrivateGateway' / '$PrivateSubnet'" -ForegroundColor Yellow 
    $Subnet = $global:SUBNETS[$PrivateSubnet]
    Start-Process netsh "interface ip set address",$PrivateNIC,"static",$PrivateGateway,$Subnet -NoNewWindow -wait
    Start-Process netsh "interface ip delete dns $PrivateNIC all" -NoNewWindow -wait -RedirectStandardOutput "NUL"

    Write-host "Checking Internet Connectivity:" -ForegroundColor Yellow 
    Start-Process ping "8.8.8.8" -NoNewWindow -wait
}

function Test-Port {
    Write-host "-> Which Port are you searching for?"  -ForegroundColor Yellow 
    do {
        Write-host "port:"  -ForegroundColor Green -NoNewLine
        try { [int16]$port = $(Read-Host) }
        catch { Write-Host "Not valid (must be between 1-65535). Try again ..." }
    } while ($port -notin 1..65535)

    Write-host 
    Write-host "Result:"  -ForegroundColor Yellow
    netstat -abno | Select-String -pattern "Proto {1,}Local",":$port "

    while ($True){
        Write-host 
        Write-host "-> Give a  ProcessID  to kill it or Hit <Enter> to skip"  -ForegroundColor Red
        Write-host "PID:"  -ForegroundColor Green -NoNewLine
        $processid = $(Read-Host)
        if ($processid) {
            Write-host "You selected this process to kill:"  -ForegroundColor Red
            try{
                Get-Process -ID $processid -ErrorAction Stop | Format-list -Property ID,ProcessName,Path
                Write-host "Hit <Enter> to Kill or type 'c' to cancel:"  -ForegroundColor Green -NoNewLine
                $answer = $( Read-Host)
                if (!$answer ) { Taskkill -PID $processid -F }
            }
            catch { Write-host "No such Process" -ForegroundColor Red }
        }
        else { break }
    } 
}


$action = $(Test-ActionArgument)
if ($action -eq "list") { Show-IP }
elseif ($action -eq "set") { Set-IP }
elseif ($action -eq "add") { Add-IP }
elseif ($action -eq "del") { Remove-IP }
elseif ($action -eq "ping") { Ping-IP }
elseif ($action -eq "open") { Open-IP }
elseif ($action -eq "share") { Connect-Internet}
elseif ($action -eq "port") { Test-port}

Write-Host
Write-Host "Done!" -ForegroundColor Green
Timeout /T 5
# Pause
Exit
