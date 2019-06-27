param(
	$port = "COM3",
	$baud_rate = 115200,
	$data_bits = 8,
	$stop_bits = 1,
	$parity = 'n',
	$flow_control = 'X'
)
<#
    Any single digit from 5 to 9 sets the number of data bits.
    ‘1’, ‘1.5’ or ‘2’ sets the number of stop bits.
    Any other numeric string is interpreted as a baud rate.
    A single lower-case letter specifies the parity: ‘n’ for none, ‘o’ for odd, ‘e’ for even, ‘m’ for mark and ‘s’ for space.
    A single upper-case letter specifies the flow control: ‘N’ for none, ‘X’ for XON/XOFF, ‘R’ for RTS/CTS and ‘D’ for DSR/DTR.
For example, ‘-sercfg 19200,8,n,1,N’ denotes a baud rate of 19200, 8 data bits, no parity, 1 stop bit and no flow control. 
#>

Write-Host "Closing existing PUTTY sessions"
$old_putty = Get-Process -Name "PUTTY" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($old_putty){
	 Stop-Process  $old_putty
}
$putty_args = "-serial $port -sercfg $baud_rate,$data_bits,$parity,$stop_bits,$flow_control"
start-process .\putty\putty.exe $putty_args