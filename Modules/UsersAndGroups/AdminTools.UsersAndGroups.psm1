﻿
function check_user_into_admin_group([string]$UserName, [ADSI]$group)
{
	$group_members = @($group.psbase.Invoke("Members"))
	foreach ($member in $group_members) {
		$m = ([ADSI]$member).InvokeGet("Name")
		if ($UserName -ieq $m) { return $true }
	}
	return $false
}

# http://social.technet.microsoft.com/Forums/ru-RU/scrlangru/thread/c44049a6-7c8b-462e-9bb9-61ce1e16f4ab/
# добавляем пользователя в группу локальных администраторов
function Add-UserToAdmin
{
	[cmdletbinding(SupportsShouldProcess=$True)]
	param(
		[parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[Alias("User","LogonName")]
		[string]$UserName,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Alias("CN","__SERVER","Computer","CNAME", "HostName")]
		[string]$ComputerName = $env:computername
	)

	try {
		$current_principal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
		if ($ComputerName -eq $env:computername -and
			!$current_principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) { 
			throw "Для добавления пользователя в администраторы требуются права администратора"
		}
		
		if ($pscmdlet.ShouldProcess(("$UserName на компьютере $ComputerName"))) {	
			$col_groups = Get-WmiObject -ComputerName $ComputerName -Query "Select * from Win32_Group Where LocalAccount=True AND SID='S-1-5-32-544'"
			# local admin group
			$admgrp_name = $col_groups.Name
			$domain_name = (Get-WmiObject Win32_computersystem -ComputerName $ComputerName).domain
			$group = [ADSI]("WinNT://$ComputerName/$admgrp_name")
			
			if(-not (check_user_into_admin_group $UserName $group)) {
				$group.Add("WinNT://$domain_name/$UserName") | Out-Null
			} else {
				Write-Warning "Пользователь $UserName уже добавлен в список локальных администраторов"
			}
		}
	} catch {
		Write-Error $_
	}
}

# удаляем пользователя из группы локальных администраторов
function Remove-UserFromAdmin
{
	[cmdletbinding(SupportsShouldProcess=$True)]
	param(
		[parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[Alias("User","LogonName")]
		[string]$UserName,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Alias("CN","__SERVER","Computer","CNAME", "HostName")]
		[string]$ComputerName = $env:computername
	)
	
	try {
		$current_principal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
		if ($ComputerName -eq $env:computername -and
			!$current_principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) { 
			throw "Для удаления пользователя из администраторов требуются права администратора"
		}
		
		if ($pscmdlet.ShouldProcess(("$UserName на компьютере $ComputerName"))) {	
			$col_groups = Get-WmiObject -ComputerName $ComputerName -Query "Select * from Win32_Group Where LocalAccount=True AND SID='S-1-5-32-544'"
			# local admin group
			$admgrp_name = $col_groups.Name
			$domain_name = (Get-WmiObject Win32_computersystem -ComputerName $ComputerName).domain
			$group = [ADSI]("WinNT://$ComputerName/$admgrp_name")
			
			if(check_user_into_admin_group $UserName $group) {
				$group.Remove("WinNT://$domain_name/$UserName") | Out-Null
			} else {
				Write-Warning "Пользователь $UserName отсутствует в списке локальных администраторов"
			}
		}
    } catch {
		Write-Error $_
	}
}

function Get-AdminUsers
{
	[cmdletbinding()]
	param(
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Alias("CN","__SERVER","Computer","CNAME", "HostName")]
		[string]$ComputerName = $env:ComputerName
	)

	try {
		$col_groups = Get-WmiObject -ComputerName $ComputerName -Query "Select * from Win32_Group Where LocalAccount=True AND SID='S-1-5-32-544'"
		# local admin group
		$admgrp_name = $col_groups.Name
		$domain_name = (Get-WmiObject Win32_computersystem -ComputerName $ComputerName).domain
		$group = [ADSI]("WinNT://$ComputerName/$admgrp_name")
		$group_members = @($group.psbase.Invoke("Members"))
		
		foreach ($member in $group_members) {
			$m = ([ADSI]$member).InvokeGet("Name")
			$d = ([ADSI]$member).InvokeGet("Parent")
		
			$output = "" | Select-Object ComputerName, Domain, UserName
			$output.ComputerName = $ComputerName
			if ($d -ne "WinNT:") { $output.Domain = ($d -split "/") | Select-Object -last 1 }
			$output.UserName = $m
			$output
		}
	} catch {
		Write-Error $_
	}
}