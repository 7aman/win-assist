# open with default program


# settings
$extension = ".pdf"


# main 
Get-ChildItem $PSScriptRoot -Filter $extension |
Foreach-Object {
    Invoke-Item `"$_`"
}
