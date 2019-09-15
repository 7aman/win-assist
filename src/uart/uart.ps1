param(
    $app = "putty",
    $port = "COM3",
    $baud_rate = 115200,
    $data_bits = 8,
    $stop_bits = 1,
    $parity = 'n',
    $flow_control = 'X'
)
<#
    Any single digit from 5 to 9 sets the number of data bits.
    '1', '1.5' or '2' sets the number of stop bits.
    Any other numeric string is interpreted as a baud rate.
    A single lower-case letter specifies the parity: 'n' for none, 'o' for odd, 'e' for even, 'm' for mark and 's' for space.
    A single upper-case letter specifies the flow control: 'N' for none, 'X' for XON/XOFF, 'R' for RTS/CTS and 'D' for DSR/DTR.
For example, '-sercfg 19200,8,n,1,N' denotes a baud rate of 19200, 8 data bits, no parity, 1 stop bit and no flow control. 
#>

function Write-Help {
	Write-Host "TODO"
}
function Stop-OldProcess {
	$procs = @("PUTTY", "plink")
	foreach ($proc in $procs) {
		$old_process = Get-Process -Name $proc -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		if ($old_process) {
			Write-Host "Closing existing $proc sessions"
			Stop-Process  $old_process
		}
	}
}

function Start-Putty ($arguments) {
	Start-Process .\putty\putty.exe $arguments
}

function Start-PLink ($arguments) {
	$logfile = ".\logs\uart-" + $(get-date -f yyyyMMdd-HHmmss) + ".log"
	New-Item -ItemType Directory -Force -Path $(Split-Path $logfile -Parent) | Out-Null
	Start-Process "powershell.exe" -ArgumentList ".\plink\plink.exe",$arguments," | Tee-Object $logfile"
	Invoke-Item -Path $(Split-Path $logfile -Parent)
}

Push-Location -Path "$PSScriptRoot"
Stop-OldProcess
$arguments = "-v -serial $port -sercfg $baud_rate,$data_bits,$parity,$stop_bits,$flow_control"

if ($app -eq "putty") { 
	Start-Putty $arguments
}
elseif ($app -eq "plink") {
	Start-PLink $arguments
}
else {
	Write-Help
}

Exit
