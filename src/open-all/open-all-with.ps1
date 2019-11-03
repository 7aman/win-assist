# open with a preferred executable

# settings
$executable = "path\to\an\executable"
$extension = ".pdf"

# main
Get-ChildItem $PSScriptRoot -recurse |
Where-Object {$_.extension -eq $extension} |
ForEach-Object {
    Start-Process -FilePath $executable -ArgumentList `"$_`"
}
