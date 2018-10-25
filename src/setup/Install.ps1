function Get-User-Only-Paths {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $all = [System.Environment]::GetEnvironmentVariable("Path", "User")
    return ($all.Split(';') | Where-Object { $_ -notin $machine.Split(';') }) -join ';'
}

function Add-To-Path {
    if ($Root -In $user_only.Split(";") ) {
        Write-Host $Root," is already in User Path."
        $Setting.Settings.Path.addedByMe = $false
        $Setting.Settings.Path.path = "{$Root}"
        return $false
    } else {
        [Environment]::SetEnvironmentVariable("Path", $Root + ";" + $user_only , "User")
        Write-Host $Root," is added to User Path."
        $Setting.Settings.Path.addedByMe = $false
        $Setting.Settings.Path.path = "{$Root}"
        return $true
    }
}

function Write-Path-To-File {
    $file = ($PSScriptRoot) + "\path.txt"
    Out-File -FilePath $file -InputObject $Root -Encoding utf8 
}
[XML]$Setting = Get-Content -Path ".\setup\setting.xml"
Write-Host $Setting.Settings.Install.Installed
Write-Host $Setting.Settings.Path.addedByMe
Write-Host $Setting.Settings.Path.path
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$user_only = $(Get-User-Only-Paths)
if ($Setting.Settings.Install.Installed){
    Write-Host "Already Installed. Use force mode?"
} else {
    Add-To-Path
    $Setting.Settings.Install.Installed = $false
}
$Setting.Save(".\setup\setting.xml")

# Write-Path-To-File
# foreach ($path in ([System.Environment]::GetEnvironmentVariable("Path", "User")).split(";")){
#     Write-Host $path
# }

# Write-Host $Setting_XML
# foreach ($path in $user_only.split(";")){
#     Write-Host $path
# }
# Pause
