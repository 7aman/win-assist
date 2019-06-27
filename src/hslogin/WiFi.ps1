if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){ 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

$wifi =  $args[0] 
$profile_name = $args[1]
$maximum_try = 3
$q = (Get-NetAdapter -Name $wifi).Status

if ($q -eq "Disabled"){
    Write-Host "Wi-Fi is Disabled. Enabling ..."
    Enable-NetAdapter -Name $wifi -Wait
    Write-Host $wifi" is enabled"
    Start-Sleep 5
}

$q = (Get-NetAdapter -Name $wifi).Status
if ($q -eq "Disconnected"){
    $i = 1
    While ($q -eq "Disconnected" -and $i -lt $maximum_try){
        Write-Host $i": Try to connect "$wifi" with this profile: "$profile_name
        $i = $i +1
        netsh wlan connect name=$profile_name
        Start-Sleep 3
        $q = (Get-NetAdapter -Name $wifi).Status
    }
    if ($i -eq $maximum_try){
        Write-Host "Something is wrong with \""$wifi"\" Adaptor. Exiting...."

    } else {
        Write-Host "Now Wi-fi is up and Running"
    }
} elseif ($q -eq "Up") {
    Write-Host "Wi-fi is up and Running"
}
