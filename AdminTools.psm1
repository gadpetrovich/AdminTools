foreach($module in (ls $PSScriptRoot\Modules)) {
	import-module "$PSScriptRoot\Modules\$module\AdminTools.$module"
}

Set-Alias join		Join-Object

Export-ModuleMember -Alias * -Function * -Cmdlet *