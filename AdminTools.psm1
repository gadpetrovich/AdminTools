foreach($module in (ls $PSScriptRoot\Modules)) {
	import-module "$PSScriptRoot\Modules\$module\AdminTools.$module.psm1"
}

Set-Alias join		Join-Object
Set-Alias get		Select-Object
Set-Alias Add-Program Install-Program
Set-Alias Remove-Program Uninstall-Program

Export-ModuleMember -Alias * -Function * -Cmdlet *