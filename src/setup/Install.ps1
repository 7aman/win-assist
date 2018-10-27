function Get-User-Only-Paths {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $all = [System.Environment]::GetEnvironmentVariable("Path", "User")
    return ($all.Split(';') | Where-Object { $_ -notin $machine.Split(';') }) -join ';'
}

function Add-To-Path {
    if ($Root -In $user_only.Split(";") ) {
        Write-Host "'"$Root"' is already in User Path." -ForegroundColor Green
    } else {
        [Environment]::SetEnvironmentVariable("Path", $Root + ";" + $user_only , "User")
        Write-Host "'"$Root"' is added to User Path." -ForegroundColor Green
    }
}

$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$user_only = $(Get-User-Only-Paths)
Add-To-Path