
# $null | Skip-Null | % { ... } 
filter Skip-Null { $_|?{ $_ -ne $null } }


<# 
 .Synopsis
  ���������� ������ ������������� ��������.

 .Description
  ������� ���������� ������ ��������, ������������� � ������� msi.
 
  
 .Parameter ComputerName
  ���������, ��� �������� ��������� �������� ������ ��������, �� ��������� ���������.

 .Parameter ProgMatch
  ���������� ��������� ��� ������ ����������� ���������.

 .Outputs
  System.Management.ManagementObject#root\cimv2\Win32_Product. 
  ��������� �� ������������ �����:
  IdentifyingNumber
  Vendor
  Version
  Caption
 
 .Example
   # ���������� ��� ��������� �� ��������� ����������.
   Get-Program

 .Example
   # ������ �������� �� ���������� "comp01", �������� ������� ���������� � ������� "p".
   Get-Program -ComputerName comp01 -ProgMatch "^p"
  
 .Link
   http://blog.wadmin.ru/2011/09/powershell-lessons-manage-computer/
   
 .Link
   http://technet.microsoft.com/ru-ru/scriptcenter/dd742419.aspx
   
 .Link
   http://technet.microsoft.com/en-US/scriptcenter/ee861518.aspx
 
 .Link
   http://blogs.msdn.com/b/powershell/
#>
function Get-Program([string]$ComputerName = ".", [string]$ProgMatch="")
{
    return Get-WmiObject -Class Win32_Product -ComputerName $ComputerName | where { $_.Name -imatch $ProgMatch }
}





<# 
 .Synopsis
  ���������� ������ ������������� ��������.

 .Description
  ������� ���������� ������ ���� ��������, ������������� �� ��������� ����������.
 
  
 .Parameter ComputerName
  ���������, ��� �������� ��������� �������� ������ ��������, �� ��������� ���������. ����� �������������� ��� �������� �������� �� ���������.

 .Outputs
  ������������ ����:
  AppName
  AppVersion
  AppVendor
  InstalledDate
  UninstallKey
  AppGUID
  
 .Example
   # ���������� ��� ��������� �� ��������� ����������.
   Get-InstalledSoftware

 .Example
   # ������ �������� �� ���������� "comp01", �������� ������� ���������� � ������� "p".
   Get-InstalledSoftware -ComputerName comp01 | ? { $_.AppName -match "^p" }
  
 .Link
   http://techibee.com/powershell/powershell-script-to-query-softwares-installed-on-remote-computer/1389
   
 .Link
   http://gallery.technet.microsoft.com/scriptcenter/519e1d3a-6318-4e3d-b507-692e962c6666
   
 .Link
   http://gallery.technet.microsoft.com/scriptcenter/Get-All-Installed-Software-73a07eba
 
#>
function Get-InstalledSoftware
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername            
	)            

	begin {            
		$UninstallRegKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"             
	}            

	process {            
		foreach($Computer in $ComputerName) {            
			Write-Verbose "Working on $Computer"            
			if(Test-Connection -ComputerName $Computer -Count 1 -ea 0) {            
				$HKLM   = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computer)            
				$UninstallRef  = $HKLM.OpenSubKey($UninstallRegKey)            
				$Applications = $UninstallRef.GetSubKeyNames()            

				foreach ($App in $Applications) {            
					$AppRegistryKey  = $UninstallRegKey + "\\" + $App            
					$AppDetails   = $HKLM.OpenSubKey($AppRegistryKey)            
					$AppGUID   = $App            
					$AppDisplayName  = $($AppDetails.GetValue("DisplayName"))            
					$AppVersion   = $($AppDetails.GetValue("DisplayVersion"))            
					$AppPublisher  = $($AppDetails.GetValue("Publisher"))            
					$AppInstalledDate = $($AppDetails.GetValue("InstallDate"))            
					$AppUninstall  = $($AppDetails.GetValue("UninstallString"))            
					if(!$AppDisplayName) { continue }            
					$OutputObj = New-Object -TypeName PSobject             
					$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()            
					$OutputObj | Add-Member -MemberType NoteProperty -Name AppName -Value $AppDisplayName            
					$OutputObj | Add-Member -MemberType NoteProperty -Name AppVersion -Value $AppVersion            
					$OutputObj | Add-Member -MemberType NoteProperty -Name AppVendor -Value $AppPublisher            
					$OutputObj | Add-Member -MemberType NoteProperty -Name InstalledDate -Value $AppInstalledDate            
					$OutputObj | Add-Member -MemberType NoteProperty -Name UninstallKey -Value $AppUninstall            
					$OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value $AppGUID            
					$OutputObj# | Select ComputerName, DriveName            
				}            
			}            
		}            
	}            

	end {}
}

# http://techibee.com/powershell/powershell-uninstall-software-on-remote-computer/1400
# ��������� NSIS http://nsis.sourceforge.net/Docs/Chapter3.html#3.2.1
#
# AppGUID - IndentifyingNumber �� ������� Get-Program, ���� AppGUID �� Get-InstalledSoftware
# ������� ��������� ����� ����� � ������� Get-Program: (Get-Program kf-map09 7-zip).Uninstall()
# ������ �������: Get-InstalledSoftware computername | ? { $_.appname -match "programname" } | Uninstall-Program
function Uninstall-Program
{
	#([string]$AppGUID, [string]$ComputerName = ".")
	[cmdletbinding()]            
	param (            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName = $env:computername,
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string]$AppGUID
	)          
	
	try {
		if($AppGUID[0] -eq "{")
		{    
			## psexe ��������� ��� ������ � �������� �������
			#psexec \\$ComputerName msiexec /x $AppGUID /qn
			$returnval = ([WMICLASS]"\\$computerName\ROOT\CIMV2:win32_process").Create("msiexec `/x$AppGUID `/qn")
		} else {
			# ������� ������ - �� msi-�����
			$uninstall_key = (Get-InstalledSoftware $ComputerName | ? { $_.AppGUID -eq $AppGUID }).UninstallKey
			$returnval = ([WMICLASS]"\\$ComputerName\ROOT\CIMV2:win32_process").Create(
				"$uninstall_key /S /x /silent /uninstall /qn /quiet")
		}
	} catch {
		write-error "Failed to trigger the uninstallation. Review the error message"
		$_
		exit
	}
	switch ($($returnval.returnvalue)){
		0 { "Uninstallation command triggered successfully" }
		2 { "You don't have sufficient permissions to trigger the command on $Computer" }
		3 { "You don't have sufficient permissions to trigger the command on $Computer" }
		8 { "An unknown error has occurred" }
		9 { "Path Not Found" }
		21 { "Invalid Parameter"}
	}
}

function Install-Program() 
{
	[cmdletbinding()]
	param(
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName = $env:computername, 
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string]$ProgSource, 
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[string]$InstallParams = "", 
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[switch]$UseOnlyInstallParams
	)
	
	$file = Get-Item $ProgSource
	if( $file.Extension -ine ".msi")
	{
		if(!$UseOnlyInstallParams) {
			$params = "/S /silent /quiet /norestart /q /qn"
		} else {
			$params = ""
		}
		psexec -s \\$ComputerName $ProgSource $params $InstallParams
	} else {
		if(!$UseOnlyInstallParams) {
			$params = "/quiet /norestart /qn"
		} else {
			$params = ""
		}
		psexec -s \\$ComputerName msiexec /i $ProgSource $params $InstallParams
	}
}

# ������ �������� ������� � �������:
# Get-OsInfo [compname] | get-member
# 
# ������ ������ �������:
# Get-OsInfo [compname] | select *
#
#
# ������������
# (Get-OsInfo compname).Reboot()
# ��� Restart-Computer compname
function Get-OsInfo
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername            
	)  
	begin {}
	process {
		foreach ($comp in $ComputerName)
		{
			get-wmiobject -Class Win32_OperatingSystem -ComputerName $comp
		}
	}
	end {}
}

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
# ��������� ������������ � ������ ��������� ���������������
function Add-UserToAdmin([string]$ComputerName = ".", [string]$UserName)
{

    $col_groups = Get-WmiObject -ComputerName $ComputerName -Query "Select * from Win32_Group Where LocalAccount=True AND SID='S-1-5-32-544'"
    # local admin group
    $admgrp_name = $col_groups.Name
    $domain_name = (gwmi Win32_computersystem).domain
    $group = [ADSI]("WinNT://$ComputerName/$admgrp_name")
        
    if(-not (check_user_into_admin_group $UserName $group))
    {
        $group.Add("WinNT://$domain_name/$UserName")
    }
    else
    {
        throw "������������ $UserName ��� �������� � ������ ��������� ���������������"
    }
}

# ������� ������������ �� ������ ��������� ���������������
function Remove-UserFromAdmin([string]$ComputerName = ".", [string]$UserName)
{
    $col_groups = Get-WmiObject -ComputerName $ComputerName -Query "Select * from Win32_Group Where LocalAccount=True AND SID='S-1-5-32-544'"
    # local admin group
    $admgrp_name = $col_groups.Name
    $domain_name = (gwmi Win32_computersystem).domain
    $group = [ADSI]("WinNT://$ComputerName/$admgrp_name")
    
    if(check_user_into_admin_group $UserName $group)
    {
        $group.Remove("WinNT://$domain_name/$UserName")
    }
    else
    {
        throw "������������ $UserName ����������� � ������ ��������� ���������������"
    }
    
}

function Find-DomainObject([string]$Match)
{
    net view | ? { $_ -imatch $Match } 
}

# ������ ���������� ��������� du
# ���� ���������� ����������� ������ ������ �������
# ����� �� �������� ���������� �������� ��� ������ ������ ����� �� ����� ������������ �����
function Get-DiskUsageLinear($LiteralPath = ".", [int]$Depth = [int]::MaxValue, [switch]$ShowLevel, [switch]$ShowProgress)
{
	#������ ����������
	$dirs = New-Object System.Collections.Generic.List[System.Object];
	#������ �������� ������ � �����������
	$indexes = New-Object System.Collections.Generic.List[System.Object];
	#������ �������� �����
	$sizes = New-Object System.Collections.Generic.List[System.Object];
	
	$dir = @(Get-ChildItem -LiteralPath $LiteralPath -Force)
	
	$dirs.add($dir)
	$indexes.add(0)
	$sizes.add(0)
	
	#������� �����������
	$level = 0
	while($true)
	{
		while ($indexes[$level] -ge $dirs[$level].Length)
		{#����� �����, ��������� �� ������� ����
			if ($ShowProgress -and ($level -lt 4)) {
				Write-Progress -Id $level -activity "���������� �������" -status "������������"  -Complete
			}
			$size = $sizes[$level]
			if ($level -eq 0) { 
				# �������
				#"������ ����� $LiteralPath = $size"
				#$obj = New-Object -TypeName PSobject             
				#$obj | Add-Member -MemberType NoteProperty -Name FullName -Value (get-item -LiteralPath $LiteralPath -force).FullName
				$obj = Get-Item -Force -LiteralPath $LiteralPath
				$obj | Add-Member -MemberType NoteProperty -Name Length -Value $size
				if($ShowLevel) { $obj | Add-Member -MemberType NoteProperty -Name Level -Value $level }
				return $obj 
			}
			
			$sizes[$level-1] += $size
			
			$indexes.RemoveAt($level)
			$dirs.RemoveAt($level)
			$sizes.RemoveAt($level)
			$level--
			
			#"����� �� ����� " + $dirs[$level][ $indexes[$level] ].FullName + " ������ = " + $size
			if($level -lt $Depth) {
				#$obj = New-Object -TypeName PSobject             
				#$obj | Add-Member -MemberType NoteProperty -Name FullName -Value $dirs[$level][ $indexes[$level] ].FullName
				$obj = Get-Item -Force -LiteralPath $dirs[$level][ $indexes[$level] ].FullName
				$obj | Add-Member -MemberType NoteProperty -Name Length -Value $size
				if($ShowLevel) { $obj | Add-Member -MemberType NoteProperty -Name Level -Value ($level+1) }
				$obj 
			}
			$indexes[$level]++
		}
		
		$file = $dirs[$level][ $indexes[$level] ]
		
		if ($ShowProgress -and ($dirs[$level].length -gt 0) -and ($level -lt 4)) {
			Write-Progress -Id $level -activity ("���������� �������: " + ("{0:N3} MB" -f ($sizes[$level] / 1MB))) -status ("������������ " + $file.FullName) -PercentComplete (($indexes[$level] / ($dirs[$level].length))  * 100)
		}
		
		
		#"������� = " + $level + " ����� = " + $dirs[$level].Length + " ������ = " + $indexes[$level] + " ��� ����� = " +  $file.FullName
		
		if($file.PSIsContainer) {
			#�����, ��������� �� ������� ����
		
			#"����� � ����� " + $file.FullName
			$dir = @(Get-ChildItem -LiteralPath $file.FullName -Force)
			
			$level++
			$dirs.Add($dir)
			$indexes.Add(0)
			$sizes.Add(0)
		} else {
			# ������� ����
			$sizes[$level] += $file.Length
			$indexes[$level]++			
		}
	}
}

function recursive_disk_usage([string]$LiteralPath, [int]$Depth, [int]$Level, [switch]$ShowLevel, [switch]$ShowProgress)
{
	$size = 0
	#$list = New-Object System.Collections.Generic.List[System.Object];
	$list = @()
	$dir = Get-ChildItem -LiteralPath $LiteralPath -Force
	$j = 0
	foreach ($i in $dir)
	{	
		if ($ShowProgress -and ($dir.length -gt 0) -and ($Level -lt 4)) {
			Write-Progress -Id $Level -activity ("���������� �������: " + ("{0:N3} MB" -f ($size / 1MB))) -status ("������������ " + $i.FullName) -PercentComplete (($j / ($dir.length))  * 100)
		}
		if ( $i.PSIsContainer ) {
			$objs = @(recursive_disk_usage -LiteralPath $i.FullName -Depth $Depth -Level ($Level+1) -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress)
			
			$size += $objs[-1].Length
			if ( $Level -lt $Depth ) { $list += $objs }
			
		} else {	
			$size += $i.Length
		}
		$j++
	}
	if ($ShowProgress -and ($Level -lt 4)) {
		Write-Progress -Id $Level -activity "���������� �������" -status "������������"  -Complete
	}
	#$obj = New-Object -TypeName PSobject             
	#$obj | Add-Member -MemberType NoteProperty -Name FullName -Value $LiteralPath
	$obj = Get-Item -Force -LiteralPath $LiteralPath
	$obj | Add-Member -MemberType NoteProperty -Name Length -Value $size
	
	if($ShowLevel) { $obj | Add-Member -MemberType NoteProperty -Name Level -Value $Level }
	$list += $obj

	#$obj.Length.ToString() + "`t" + $obj.FullName | write-host 
	return $list
}
# ����������� ���������� ������� �����
# $ShowProgress - ���������� ��� ������������ (�� 4 �������)
# 
function Get-DiskUsageRecursive(
	[string]$LiteralPath = ".", 
	[int]$Depth = [int]::MaxValue, 
	[switch]$ShowLevel, 
	[switch]$ShowProgress
)
{
	recursive_disk_usage -LiteralPath $LiteralPath -Depth $Depth -_Level 0 -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress
}

<# 
 .Synopsis
  ��������� ������ ��������� ��������� � �� ���������� ���������.

 .Description
  ��������� ������ ������������ ���������� ��������. 
 
  
 .Parameter LiteralPath
  �������, ������ �������� ��������� ����������.

 .Parameter Depth
  ������� ����������� ���������. ��������� ��� ����������� ������������ ������ (�� ������� ������������ ����� �� ������).
 
 .Parameter ShowLevel
  ��������� ������� Level, � ��� ������ ������� ����������� ��������.
  
 .Parameter ShowProgress
  ���������� �������� ������������ ���������. ������� ������������ �� ������� �� ��������� Depth � ����� 4.
  
 .Parameter RecursiveAlgorithm
  ������������ ����������� �������� ��� ������������ ����� (� ������ ������ � ����� ������ �������� ������ ����� ���������� �������).

 .Example
   # ������� ������� � ��������� �����.
   Get-DiskUsage | select FullName, Length

 .Example
   # ������ ������� �����.
   Get-DiskUsage . -Depth 0 | select FullName, Length
 
 .Example 
   # ���������� ���������� � ���� ���������� ������������.
   Get-DiskUsage . -ShowProgress | select FullName, Length
   
 .Example
   # ������� ������� ��������� � ������� ����.
   Get-DiskUsage | Update-Length  | select FullName, Length
 
 .Example 
   # ��������� ������������ ����������.
   Get-DiskUsage 'C:\Program Files' -RecursiveAlgorithm | ft -AutoSize FullName, Length
   
 .Example
	# ������� '��� 10' ����� ������� ����� � 'C:\Program Files'.
   Get-DiskUsage 'C:\Program Files' -ShowProgress -ShowLevel | ? {$_.Level -eq 1} | sort Length -Descending | select FullName, Length -First 10 | Update-Length | ft -AutoSize
#>
function Get-DiskUsage(
	[string]$LiteralPath = ".", 
	[int]$Depth = [int]::MaxValue, 
	[switch]$ShowLevel, 
	[switch]$ShowProgress,
	[switch]$RecursiveAlgorithm
)
{
	if($RecursiveAlgorithm) {
		Get-DiskUsageRecursive -LiteralPath $LiteralPath -Depth $Depth -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress
	} else {
		Get-DiskUsageLinear -LiteralPath $LiteralPath -Depth $Depth -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress
	}
	
}

<# 
 .Synopsis
  ��������� ������ ��������� ��������� � �� ���������� ���������.

 .Description
  ��������� ������ ������������ ���������� ��������, ������ �������� ������������ � ���� Length. ��������� �������� ��������������� � �������� ������.
 
 .Parameter InputObject
   ������ ������ � ����������. ����� �������������� ��� �������� �������� �� ���������.
   
 .Example
   PS C:\> ls | ? { $_.PSIsContainer } | Update-DirLength

   ��������
   -----------
   ������� ����� � ������� ����������.
   

#>
function Update-DirLength
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[PSobject]$InputObject
	)  
	
	begin{}
	process {
		foreach($file in $InputObject) {      
			if ($file -is [System.IO.DirectoryInfo]) {
				$dir_usage = Get-DiskUsage $file.FullName -Depth 0
				$file | Add-Member -MemberType NoteProperty -Name Length -Value ($dir_usage.Length)
			}
			$file
		}
	}
	end{}
}

<# 
 .Synopsis
  ����������� �������� Length � �������� ���.

 .Description
  � ���������� ���������� ������ ������� � ���� Length ����� �������� ������ � ������� "{0:N3} MB". �.�. ����� ����� ������������� � ����� �������� ���. ��������� �������� ��������������� � �������� ������.
 
 .Parameter InputObject
   ������ ������ � ����������. ����� �������������� ��� �������� �������� �� ���������.
 
 .Parameter NumericParameter
   ����������� ��������. �������� �� ��������� "Length".
 
 .Parameter NewParameter
   ����������� ��������. �������� ��������������� �������� �� NumericParameter. �� ��������� �� �� ���, ��� � � NumericParameter.

 .Example
   PS C:\> ls | Update-Length

   ��������
   -----------
   ������� ������ � ������� ����������.
   
 .Example
   PS C:\> ls -force | ? { !$_.psiscontainer  } | Update-Length -NewParameter HLength | sort length -descending | select name , hlength
   
   ��������
   -----------
   ������� ����� � ������� ������ � ��������������� ����. ����������� ����� �������� HLength � ������������ ������ ������� Update-Length.
   
#>
function Update-Length
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[PSobject]$InputObject,
		[string]$NumericParameter = "Length",
		[string]$NewParameter = $NumericParameter
	)  
	
	begin{}
	process {
		foreach($i in $InputObject) {      
			$i | Add-Member -MemberType NoteProperty -Name $NewParameter -Value ("{0:N3} MB" -f ($i.$NumericParameter / 1MB)) -force
			$i
		}
	}
	end{}
}


<# 
 .Synopsis
  ���������� ��� ������ � ����.

 .Description
  ��������� ���������� Join-Object ������������ ����� ��������� ������������ ���� �������, �������������� ����������� InputObject � JoinObject. ���� �����-���� ����� ����� � InputObject � JoinObject ���������, �� � ����� ���� �� ������ JoinObject ����������� ������ "Join". �������� ��� ����������� �������, ��������� ���������� ���� (Id, Name), �������� �������������� ������ � ������: Id, Name, JoinId, JoinName.
  � ������, ����� �������� ������� �� ����������� �� ������ PSObject, ��������� InputProperty � JoinProperty ��������������, � ����� ����� ��������������� ������ ����������, ��� "Value" � "JoinValue".
    
 .Parameter InputObject
  ������ ������ ��� �����������. ����� �������������� ��� �������� �������� �� ���������.

 .Parameter JoinObject
  ������ ������ ��� �����������. � ������ �����, ����������� � ������ �� InputObject, ����� ����������� ������� "Join".
 
 .Parameter FilterScript
  ��������� ���� �������, ������������ ��� ���������� ��������. ��� �������� ���������� � ������ ����������� param() ( { param($i,$j); ... }). ���������� $i �������� ������ �� InputObject, $j - �� JoinObject.
  
 .Parameter InputProperty
  ������ ����� �� InputObject ��� ���������� � �������������� ������.
  
 .Parameter JoinProperty
  ������ ����� �� JoinObject ��� ���������� � �������������� ������. � ������ �����, ����������� � ������ �� InputObject, ����� ����������� ������� "Join".

 .Example
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime LastWriteTime

   ��������
   -----------
   ��� ������� ���������� ������ ������ � ���������� � ������������ ������� � c:\dir1 � c:\dir2. 
   
 .Example
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> $a | Join-Object -JoinObject $b -where { param($i,$j); $i.name -eq $j.name } -InputProperty name, LastWriteTime -JoinProperty LastWriteTime

   ��������
   -----------
   ��� ������� ���������� ������ ������ � ���������� � ������������ ������� � c:\dir1 � c:\dir2. ������������ �������� ��������� InputObject ����� ��������.
   
 .Example
   PS C:\> $b = 1..9
   PS C:\> $b = 1..9
   PS C:\> Join-Object $a $b { param($i, $j); $i+$j -eq 16 }
   
   ��������
   -----------
   �� ����� ����� �������� �������� ������� $a � $b, ����� ������� ����� 16-�.
#>
function Join-Object
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		$InputObject,
		$JoinObject,
		[Alias("Where")][ScriptBlock]$FilterScript = { $true },
		[String[]]$InputProperty = "*",
		[String[]]$JoinProperty = "*"
	)
	
	begin{}
	process {
		
		foreach($i in $InputObject) {
			foreach($j in $JoinObject) {
				if ( !($FilterScript.Invoke($i, $j))) {continue}
				
				$out = New-Object -TypeName PSobject             
					
				# ��������� �������� �� ������� ������
				if( $i -is [PSObject] ){
					$props = @(); 
					$i | Get-Member -MemberType *Property -Name $InputProperty | % { $props += $_.Name }
					foreach($ip in $props) {
						$out | Add-Member -MemberType NoteProperty -Name $ip -Value $i.$ip
					}
				} else {
					$out | Add-Member -MemberType NoteProperty -Name Value -Value $i
				}
				# ��������� �������� �� ������� ������
				if( $j -is [PSObject] ){
					$props = @(); 
					$j | Get-Member -MemberType *Property -Name $JoinProperty | % { $props += $_.Name }
					foreach($jp in $props) {
						$jp_name = $jp
						if (($out | Get-Member -Name $jp) -ne $null) {
							$jp_name = "Join" + $jp
						}
						$out | Add-Member -MemberType NoteProperty -Name $jp_name -Value $j.$jp
					}
				} else {
					$out | Add-Member -MemberType NoteProperty -Name JoinValue -Value $j
				}
				$out
			}
		}
	}
	end{}
}