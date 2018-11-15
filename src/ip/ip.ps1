if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}
# Default Values
$global:PublicNIC = "Wi-Fi"
$global:PrivateNIC = "Ethernet"
$global:PrivateGateway = "192.168.1.2"
$global:PrivateSubnet = 0

function Test-ActionArgument {
    $action = $args[0]
    if ($arg -eq "--list-NICs"){
        Write-AdapterNames
    }
    switch ($action) {
        "list", "set", "del", "add"
        { return$action}
        Default {}
    }
}


$SUBNETS = @(
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
# Irgument Validation

function Test-AdapterName($given_string){
    if( $(Get-NetAdapter -Name $given_string -ErrorAction SilentlyContinue -InformationAction SilentlyContinue)){
        return $true
    }
    return $false
}
function Test-IPSubnet($given_string){
    $ValidIpAddressRegex = [regex] "^((?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))$"
    $ValidSubnetRegex = [regex]"^([1-9]|[1-2][0-9]?|3[0-2])$"
    $ValidIPSubnetRegex = [regex] "^((?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))/([1-9]|[1-2][0-9]?|3[0-2])$"

    if ($given_string -match $ValidIpAddressRegex){
        $global:PrivateGateway = $given_string
        Write-Host "    '$global:PrivateGateway' is an IP." -ForegroundColor Green
        return $true
    }
    elseif ($given_string -match $ValidSubnetRegex) {
        $global:PrivateSubnet = $given_string
        Write-Host "    '$global:PrivateSubnet' is a Subnet." -ForegroundColor Green
        return $true
        
    }
    elseif ($given_string -match $ValidIPSubnetRegex) {
        $IPSUBNET = $ValidIPSubnetRegex.Match($given_string).groups
        $global:PrivateGateway = $IPSUBNET[1].Value
        $global:PrivateSubnet = $IPSUBNET[2].Value
        Write-Host "    '$given_string' is an IP/Subnet." -ForegroundColor Green
        return $true
    } else {
        return $false
    }
}

function Write-AdapterNames {
    Write-Host "Available Net Adapters are:" -ForegroundColor Green
    $NIC_list = Get-NetAdapter | Select-Object -Property Name
    foreach ($NIC in $NIC_list) {
        Write-Host "    "$NIC.Name -ForegroundColor Cyan
    }
    Pause
    Exit
}

# Argument Validation and Assignment
Write-Host "Argument Checking:" -ForegroundColor Yellow
$counter = 0
foreach ($arg in $args){
    if (Test-AdapterName($arg)){
        if ($counter -eq 0){
            $global:PublicNIC = $arg
            Write-Host "    '$arg' will be used as public NIC." -ForegroundColor Green
            $counter++
            continue
        } elseif ($counter -eq 1) {
            $global:PrivateNIC = $arg
            Write-Host "    '$arg' will be used as private NIC."  -ForegroundColor Green
            $counter++
            continue
        } else {
            Write-Host "More than two NIC is given." -ForegroundColor Red
            Pause
            Exit
        }
        Write-Information
    }
    # check for ip or subnet
    elseif (Test-IPSubnet($arg)){
            continue
    }
    else {
        Write-Host "    '$arg' is not valid. Ignored." -ForegroundColor Red
    }
}












Write-Host "Done!" -ForegroundColor Green
Pause
