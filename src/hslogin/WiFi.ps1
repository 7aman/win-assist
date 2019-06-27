if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

$wifi =  $args[0] 
$profile_name = $args[1]
$reconnect = $args[2]

$q = (Get-NetAdapter -Name $wifi).Status
while ($q -eq "Disabled"){
    Write-Host ""
    Write-Host "Wi-Fi is Disabled. Enabling ..." -ForegroundColor Yellow
    Enable-NetAdapter -Name $wifi
    Write-Host $wifi" is enabled" -ForegroundColor Green
    Write-Host ""
    Start-Sleep 3
    $q = (Get-NetAdapter -Name $wifi).Status
}

if ($reconnect -eq $true) {
    netsh wlan disconnect
    Start-Sleep 3
    $q = (Get-NetAdapter -Name $wifi).Status
}

if ($q -eq "Disconnected"){
    $maximum_try = 3
    $i = 1
    Write-Host ""
    Write-Host "Connect to"$wifi" with this profile: "$profile_name
    While ($q -eq "Disconnected" -and $i -lt $maximum_try){
        Write-Host "Try"$i":"
        netsh wlan connect name=$profile_name
        Start-Sleep 3
        $q = (Get-NetAdapter -Name $wifi).Status
        $i = $i +1
    }
}

if ($q -eq "Disconnected" -and $i -eq $maximum_try){
    Write-Host ""
    Write-Host "Something is wrong with '$wifi' Adaptor. Exiting...."
} elseif ($q -eq "Up") {
    Write-Host ""
    Write-Host "Connected to Wi-fi successfully" -ForegroundColor Green
}
