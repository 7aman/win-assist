if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
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
$global:Arguments = $args
# Default Values
# $global:PublicNIC = "Wi-Fi"
# $global:PrivateNIC = "Ethernet"
# $global:PrivateIP = "192.168.1.199"
# $global:PrivateGateway = "192.168.1.2"
# $global:PrivateSubnet = 0


function Write-AdapterNames {
    Write-Host "Available Net Adapters are:" -ForegroundColor Green
    $NIC_list = Get-NetAdapter | Select-Object -Property Name
    foreach ($NIC in $NIC_list) {
        Write-Host "    "$NIC.Name -ForegroundColor Cyan
    }
    Pause
    Exit
}
function Test-ActionArgument {
    $ACCEPTED = @("list", "set", "del", "add", "share")
    $action = $global:Arguments[0]
    if ($ACCEPTED -contains $action){
        return $action
    }
    else {
        Write-Host "Invalid action argument."
        Write-Host "Valid action arguments are:"
        foreach ($action in $ACCEPTED) {
            Write-Host "    "$action -ForegroundColor Cyan
        } 
        Pause
        Exit
    }
}


# Argument Validation

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
        return @($given_string, $false)
    }
    elseif ($given_string -match $ValidSubnetRegex) {
        return @($false, $given_string)
        
    }
    elseif ($given_string -match $ValidIPSubnetRegex) {
        $IPSUBNET = $ValidIPSubnetRegex.Match($given_string).groups
        return @($IPSUBNET[1].Value, $IPSUBNET[2].Value)
    } else {
        return @($false, $false)
    }
}
function  List-IP {
    $arg = $global:Arguments[1]

    if ($arg -eq "nics"){
        Write-AdapterNames
    }elseif (Test-AdapterName($arg)){
        Start-Process  netsh "interface ip show addresses",$arg -NoNewWindow -wait
    }else {
        Write-Host "    '$arg' is not a valid NIC." -ForegroundColor Red
        Write-AdapterNames
    }
}

function  Set-IP {
    # Write-Host "Argument Checking:" -ForegroundColor Yellow
    $ARGSS = $global:Arguments | Select-Object -Skip 1
    $NIC = ""
    $IPS = @()
    $SUB = ""
    foreach ($arg in $ARGSS){
        if (Test-AdapterName($arg)){
            $NIC = $arg
        }
        $IP, $eSUB = Test-IPSubnet($arg)
        if ($eSub){
            $SUB = $eSUB
        }
        if ($IP){
            $IPS += $IP
        }
    }
    Write-Host  "Command to run:" -ForegroundColor Yellow
    Write-Host  "netsh interface ip set address "$NIC"  static  "$IP" "$SUBNET $GATEWAY -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Result: "

    netsh interface ip set address $NIC  static $IP $SUBNET $GATEWAY

    if (!$LastExitCode){
        Write-Host "OK. IP is set successfully." -ForegroundColor  Green
    }
    Write-Host "Getting"$NIC" interface information..." -ForegroundColor  Yellow
    Start-Sleep 4
    Start-Process  netsh "interface ip show addresses",$NIC -NoNewWindow -wait
}
function  Test-OtherArguments {
    # Write-Host "Argument Checking:" -ForegroundColor Yellow
    $ARGSS = $global:Arguments | Select-Object -Skip 1
    $counter = 0
    foreach ($arg in $ARGSS){

        if ($arg -eq "nics"){
            Write-AdapterNames
        }

        if (Test-AdapterName($arg)){
            if ($counter -eq 0){
                $global:PrivateNIC = $arg
                Write-Host "    '$arg' will be used as private NIC."  -ForegroundColor Green
                $counter++
                continue
            } elseif ($counter -eq 1) {
                $global:PublicNIC = $arg
                Write-Host "    '$arg' will be used as public NIC." -ForegroundColor Green
                $counter++
                continue
            } else {
                Write-Host "More than two NIC is given." -ForegroundColor Red
                Pause
                Exit
            }
        }
        # check for ip or subnet
        elseif (Test-IPSubnet($arg)){
                continue
        }
        else {
            Write-Host "    '$arg' is not valid. Ignored." -ForegroundColor Red
        }
    }
}
$action = $(Test-ActionArgument)
if ($action -eq "list"){
    List-IP
} elseif ($action -eq "set"){
    Set-IP

}

Write-Host "Done!" -ForegroundColor Green
Pause
