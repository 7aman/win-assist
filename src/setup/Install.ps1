$RootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
function Add-To-Path {
    [Environment]::SetEnvironmentVariable("Path", $RootPath + ";" + $Env:Path , [EnvironmentVariableTarget]::User)
}
function Write-Path-To-File {
    $file = ($PSScriptRoot) + "\path.txt"
    echo $file
    Out-File -FilePath $file -InputObject $RootPath -Encoding utf8 
}
# echo $Env:path


Add-To-Path
Write-Path-To-File
Write-Host ([System.Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)).split(";")
Pause
