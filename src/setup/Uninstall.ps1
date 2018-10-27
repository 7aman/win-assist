$RootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
function Get-User-Only-Paths {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $all = [System.Environment]::GetEnvironmentVariable("Path", "User")
    return ($all.Split(';') | Where-Object { $_ -notin $machine.Split(';') }) -join ';'
}

function Remove-From-Path {
    $path = Get-User-Only-Paths
    $path = ($path.Split(';') | Where-Object { $_ -ne $RootPath }) -join ';'
    [System.Environment]::SetEnvironmentVariable("Path", $path, 'User')
    Write-Host "'"$RootPath"' is removed from PATH" -ForegroundColor Green
}
Remove-From-Path