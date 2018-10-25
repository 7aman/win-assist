$file_path = $PSScriptRoot + ".\path.txt"
$Insatall_Path = (Get-Content $file_path ).ToString()
$Current_Root_Path = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if ($Current_Root_Path -ne $Insatall_Path) {
    Write-Host "Installation Folder was moved from ", $Insatall_Path " to ", $Current_Root_Path -ForegroundColor Yellow
    Write-Host "Move it back to ",$Insatall_Path, " then run unisntall again." -ForegroundColor Yellow
    Exit-PSSession
}
function Remove-From-Path {
    $path = [System.Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    # Remove unwanted elements
    $path = ($path.Split(';') | Where-Object { $_ -ne $RootPath }) -join ';'
    # Set it
    [System.Environment]::SetEnvironmentVariable("Path", $path, [EnvironmentVariableTarget]::User)
}
Write-Host "Removing from Path" -ForegroundColor Yellow
Remove-From-Path
Pause