foreach($module in (ls $PSScriptRoot\Modules)) {
	import-module "$PSScriptRoot\Modules\$module\AdminTools.$module.psm1"
}

Set-Alias join		Join-Object
Set-Alias get		Select-Object
Set-Alias Add-Program Install-Program
Set-Alias Remove-Program Uninstall-Program
Set-Alias fta		Format-TableAuto 
Set-Alias ul		Update-Length

Export-ModuleMember -Alias * -Function * -Cmdlet *