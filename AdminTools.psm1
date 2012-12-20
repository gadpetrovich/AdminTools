foreach($module in (ls $PSScriptRoot\Modules)) {
	import-module "$PSScriptRoot\Modules\$module\AdminTools.$module.psm1"
}

New-PInvoke user32 "void FlashWindow(IntPtr hwnd, bool bInvert)" 

Set-Alias join		Join-Object
Set-Alias get		Select-Object
Set-Alias Add-Program Install-Program
Set-Alias Remove-Program Uninstall-Program
Set-Alias fta		Format-TableAuto 

Export-ModuleMember -Alias * -Function * -Cmdlet *