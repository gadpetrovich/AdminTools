
foreach($module in (ls $PSScriptRoot\Modules)) {
	import-module "$PSScriptRoot\Modules\$module\AdminTools.$module.psm1"
}

Set-Alias join				Join-Object
Set-Alias get				Select-Object
Set-Alias Add-Program		Install-Program
Set-Alias Remove-Program	Uninstall-Program
Set-Alias fta				Format-TableAuto 
Set-Alias ul				Update-Length
Set-Alias Get-NetObject		Get-NetView
Set-Alias %%				Invoke-Parallel
Set-Alias Foreach-Parallel	Invoke-Parallel
Set-Alias Foreach-Progress	Invoke-Progress

Export-ModuleMember -Alias * -Function [a-z]* -Cmdlet *