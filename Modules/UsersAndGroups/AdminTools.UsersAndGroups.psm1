
function check_user_into_admin_group([string]$UserName, [ADSI]$group)
{
    $group_members = @($group.psbase.Invoke("Members"))
    foreach ($member in $group_members)
    {
        $m = $member.GetType().InvokeMember("Name", "GetProperty", $null, $member, $null)
        if ($UserName -ieq $m) { return $true }
    }
    return $false
}

# http://social.technet.microsoft.com/Forums/ru-RU/scrlangru/thread/c44049a6-7c8b-462e-9bb9-61ce1e16f4ab/
# добавляем пользователя в группу локальных администраторов
function Add-UserToAdmin
{
	[cmdletbinding()]
	param(
		[parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string]$UserName,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName = $env:computername
	)

	try {
		$ErrorActionPreference = "Stop"
		$col_groups = Get-WmiObject -ComputerName $ComputerName -Query "Select * from Win32_Group Where LocalAccount=True AND SID='S-1-5-32-544'"
		# local admin group
		$admgrp_name = $col_groups.Name
		$domain_name = (gwmi Win32_computersystem -ComputerName $ComputerName).domain
		$group = [ADSI]("WinNT://$ComputerName/$admgrp_name")
			
		if(-not (check_user_into_admin_group $UserName $group))
		{
			$group.Add("WinNT://$domain_name/$UserName")
		}
		else
		{
			throw "Пользователь $UserName уже добавлен в список локальных администраторов"
		}
	} catch {
		$er = New-Object System.Management.Automation.ErrorRecord($_.Exception, $null, $_.CategoryInfo.Category, $_.TargetObject)
		$er.ErrorDetails = New-Object System.Management.Automation.ErrorDetails($_.tostring() + "`n" +  $_.InvocationInfo.PositionMessage)
		$pscmdlet.WriteError($er)
	}
}

# удаляем пользователя из группы локальных администраторов
function Remove-UserFromAdmin
{
	[cmdletbinding()]
	param(
		[parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string]$UserName,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName = $env:computername
	)
	
	try {
		$ErrorActionPreference = "Stop"
		$col_groups = Get-WmiObject -ComputerName $ComputerName -Query "Select * from Win32_Group Where LocalAccount=True AND SID='S-1-5-32-544'"
		# local admin group
		$admgrp_name = $col_groups.Name
		$domain_name = (gwmi Win32_computersystem -ComputerName $ComputerName).domain
		$group = [ADSI]("WinNT://$ComputerName/$admgrp_name")
		
		if(check_user_into_admin_group $UserName $group)
		{
			$group.Remove("WinNT://$domain_name/$UserName")
		}
		else
		{
			throw "Пользователь $UserName отсутствует в списке локальных администраторов"
		}
    } catch {
		$er = New-Object System.Management.Automation.ErrorRecord($_.Exception, $null, $_.CategoryInfo.Category, $_.TargetObject)
		$er.ErrorDetails = New-Object System.Management.Automation.ErrorDetails($_.tostring() + "`n" +  $_.InvocationInfo.PositionMessage)
		$pscmdlet.WriteError($er)
	}
}

function Get-AdminUsers
{
	[cmdletbinding()]
	param(
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName = $env:ComputerName
	)

	try {
		$ErrorActionPreference = "Stop"
		$col_groups = Get-WmiObject -ComputerName $ComputerName -Query "Select * from Win32_Group Where LocalAccount=True AND SID='S-1-5-32-544'"
		# local admin group
		$admgrp_name = $col_groups.Name
		$domain_name = (gwmi Win32_computersystem -ComputerName $ComputerName).domain
		$group = [ADSI]("WinNT://$ComputerName/$admgrp_name")
		$group_members = @($group.psbase.Invoke("Members"))
		
		foreach ($member in $group_members)
		{
			$m = $member.GetType().InvokeMember("Name", "GetProperty", $null, $member, $null)
			$d = $member.gettype().InvokeMember("Parent", "GetProperty", $null, $member, $null)
			
			$output = "" | Select ComputerName, Domain, UserName
			$output.ComputerName = $ComputerName
			if ($d -ne "WinNT:") { $output.Domain = ($d -split "/") | select -last 1 }
			$output.UserName = $m
			$output
		}
	} catch {
		$er = New-Object System.Management.Automation.ErrorRecord($_.Exception, $null, $_.CategoryInfo.Category, $_.TargetObject)
		$er.ErrorDetails = New-Object System.Management.Automation.ErrorDetails($_.tostring() + "`n" +  $_.InvocationInfo.PositionMessage)
		$pscmdlet.WriteError($er)
	}
}