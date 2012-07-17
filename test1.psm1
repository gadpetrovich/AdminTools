
# $null | Skip-Null | % { ... } 
filter Skip-Null { $_|?{ $_ -ne $null } }


<# 
 .Synopsis
  Возварщает список установленных программ.

 .Description
  Функция возвращает список программ, установленных с помощью msi.
 
  
 .Parameter ComputerName
  Компьютер, для которого требуется получить список программ, по умолчанию локальный.

 .Parameter ProgMatch
  Регулярное выражения для поиска определнной программы.

 .Outputs
  System.Management.ManagementObject#root\cimv2\Win32_Product. 
  Некоторые из возвращаемых полей:
  IdentifyingNumber
  Vendor
  Version
  Caption
 
 .Example
   # Отобразить все программы на локальном компьютере.
   Get-Program

 .Example
   # Список программ на компьютере "comp01", название которых начинается с символа "p".
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

# http://techibee.com/powershell/powershell-script-to-query-softwares-installed-on-remote-computer/1389
# http://gallery.technet.microsoft.com/scriptcenter/519e1d3a-6318-4e3d-b507-692e962c6666
# http://gallery.technet.microsoft.com/scriptcenter/Get-All-Installed-Software-73a07eba
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
# параметры NSIS http://nsis.sourceforge.net/Docs/Chapter3.html#3.2.1
#
# AppGUID - IndentifyingNumber из функции Get-Program, либо AppGUID из Get-InstalledSoftware
# Удалить программу можно также с помощью Get-Program: (Get-Program kf-map09 7-zip).Uninstall()
# Третий вариант: Get-InstalledSoftware computername | ? { $_.appname -match "programname" } | Uninstall-Program
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
			## psexe необходим для работы с сетевыми дисками
			#psexec \\$ComputerName msiexec /x $AppGUID /qn
			$returnval = ([WMICLASS]"\\$computerName\ROOT\CIMV2:win32_process").Create("msiexec `/x$AppGUID `/qn")
		} else {
			# сложный случай - не msi-пакет
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

function Install-Program([string]$ComputerName = $env:computername, [string]$ProgSource, [string]$InstallParams = "")
{
	$file = Get-Item $ProgSource
	if( $file.Extension -ine ".msi")
	{
		psexec -si \\$ComputerName $ProgSource /S /silent /quiet /norestart /q /qn $InstallParams
	} else {
		psexec -s \\$ComputerName msiexec /i $ProgSource /quiet /norestart /qn $InstallParams
	}
}

# полное описание свойств и методов:
# Get-OsInfo [compname] | get-member
# 
# полный список свойств:
# Get-OsInfo [compname] | select *
#
#
# перезагрузка
# (Get-OsInfo compname).Reboot()
# или Restart-Computer compname
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
# добавляем пользователя в группу локальных администраторов
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
        throw "Пользователь $UserName уже добавлен в список локальных администраторов"
    }
}

# удаляем пользователя из группы локальных администраторов
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
        throw "Пользователь $UserName отсутствует в списке локальных администраторов"
    }
    
}

function Find-DomainObject([string]$Match)
{
    net view | ? { $_ -imatch $Match } 
}

# аналог юникосовой программы du
# ниже расположен рекурсивный аналог данной функции
# здесь же пришлось развернуть рекурсию для вывода данных прямо во время сканирования папки
function Get-DiskUsageLinear([string]$Path = ".", [int]$Depth = [int]::MaxValue, [switch]$ShowLevel, [switch]$ShowProgress)
{
	#список директорий
	$dirs = New-Object System.Collections.Generic.List[System.Object];
	#список индексов файлов в директориях
	$indexes = New-Object System.Collections.Generic.List[System.Object];
	#список размеров папок
	$sizes = New-Object System.Collections.Generic.List[System.Object];
	
	$dir = @(Get-ChildItem -LiteralPath $Path -Force)
	
	$dirs.add($dir)
	$indexes.add(0)
	$sizes.add(0)
	
	#уровень вложенности
	$level = 0
	while($true)
	{
		while ($indexes[$level] -ge $dirs[$level].Length)
		{#конец папки, переходим на уровень ниже
			if ($ShowProgress -and ($level -lt 4)) {
				Write-Progress -Id $level -activity "Вычисление размера" -status "Сканирование"  -Complete
			}
			$size = $sizes[$level]
			if ($level -eq 0) { 
				# выходим
				#"Размер папки $Path = $size"
				$obj = New-Object -TypeName PSobject             
				$obj | Add-Member -MemberType NoteProperty -Name FullName -Value (get-item -LiteralPath $Path -force).FullName
				$obj | Add-Member -MemberType NoteProperty -Name Length -Value $size
				if($ShowLevel) { $obj | Add-Member -MemberType NoteProperty -Name Level -Value $level }
				$obj 
				
				return 
			}
			
			$sizes[$level-1] += $size
			
			$indexes.RemoveAt($level)
			$dirs.RemoveAt($level)
			$sizes.RemoveAt($level)
			$level--
			
			#"вышли из папки " + $dirs[$level][ $indexes[$level] ].FullName + " размер = " + $size
			if($level -lt $Depth) {
				$obj = New-Object -TypeName PSobject             
				$obj | Add-Member -MemberType NoteProperty -Name FullName -Value $dirs[$level][ $indexes[$level] ].FullName
				$obj | Add-Member -MemberType NoteProperty -Name Length -Value $size
				if($ShowLevel) { $obj | Add-Member -MemberType NoteProperty -Name Level -Value ($level+1) }
				$obj 
			}
			$indexes[$level]++
		}
		
		$file = $dirs[$level][ $indexes[$level] ]
		
		if ($ShowProgress -and ($dirs[$level].length -gt 0) -and ($level -lt 4)) {
			Write-Progress -Id $level -activity ("Вычисление размера: " + ("{0:N3} MB" -f ($sizes[$level] / 1MB))) -status ("Сканирование " + $file.FullName) -PercentComplete (($indexes[$level] / ($dirs[$level].length))  * 100)
		}
		
		
		#"уровень = " + $level + " длина = " + $dirs[$level].Length + " индекс = " + $indexes[$level] + " имя файла = " +  $file.FullName
		
		if($file.PSIsContainer) {
			#папка, переходим на уровень выше
		
			#"вошли в папку " + $file.FullName
			$dir = @(Get-ChildItem -LiteralPath $file.FullName -Force)
			
			$level++
			$dirs.Add($dir)
			$indexes.Add(0)
			$sizes.Add(0)
		} else {
			# обычный файл
			$sizes[$level] += $file.Length
			$indexes[$level]++			
		}
	}
}

function recursive_disk_usage([string]$Path, [int]$Depth, [int]$Level, [switch]$ShowLevel, [switch]$ShowProgress)
{
	$size = 0
	$list = New-Object System.Collections.Generic.List[System.Object];
	$dir = Get-ChildItem -LiteralPath $Path -Force
	$j = 0
	foreach ($i in $dir)
	{	
		if ($ShowProgress -and ($dir.length -gt 0) -and ($Level -lt 4)) {
			Write-Progress -Id $Level -activity ("Вычисление размера: " + ("{0:N3} MB" -f ($size / 1MB))) -status ("Сканирование " + $i.FullName) -PercentComplete (($j / ($dir.length))  * 100)
		}
		if ( $i.PSIsContainer ) {
			$objs = recursive_disk_usage -Path $i.FullName -Depth $Depth -Level ($Level+1) -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress
			if ($objs -is "PSCustomObject") {
				$size += $objs.Length
				if ( $Level -lt $Depth ) { $list.Add($objs) }
			} else {
				$size += $objs[$objs.Count-1].Length
				if ( $Level -lt $Depth ) { $list.AddRange($objs) }
			}
			
		} else {	
			$size += $i.Length
		}
		$j++
		
	}
	if ($ShowProgress -and ($Level -lt 4)) {
		Write-Progress -Id $Level -activity "Вычисление размера" -status "Сканирование"  -Complete
	}
	$obj = New-Object -TypeName PSobject             
	$obj | Add-Member -MemberType NoteProperty -Name FullName -Value $Path
	$obj | Add-Member -MemberType NoteProperty -Name Length -Value $size
	if($ShowLevel) { $obj | Add-Member -MemberType NoteProperty -Name Level -Value $Level }
	$list.add($obj)

	#$obj.Length.ToString() + "`t" + $obj.FullName | write-host 
	return $list
}
# рекурсивное вычисление размера папки
# $ShowProgress - отображать ход сканирования (до 4 уровней)
# 
function Get-DiskUsageRecursive(
	[string]$Path = ".", 
	[int]$Depth = [int]::MaxValue, 
	[switch]$ShowLevel, 
	[switch]$ShowProgress
)
{
	recursive_disk_usage -Path $Path -Depth $Depth -_Level 0 -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress
}

<# 
 .Synopsis
  Возращает список вложенных каталогов с их суммарными размерами.

 .Description
  Выполняет полное сканирование указанного каталога. 
 
  
 .Parameter Path
  Каталог, размер которого требуется подсчитать.

 .Parameter Depth
  Глубина вложенности каталогов. Требуется для ограничения отображаемых данных (на процесс сканирования никак не влияет).
 
 .Parameter ShowLevel
  Добавляет столбец Level, в нем указан уровень вложенности каталога.
  
 .Parameter ShowProgress
  Отображает прогресс сканирования каталогов. Уровень сканирования не зависит от параметра Depth и равен 4.
  
 .Parameter RecursiveAlgorithm
  Используется рекурсивный алгоритм для сканирования папок (в данном случае в вывод данные отдаются только после выполнения фукнции).

 .Example
   # Размеры текущей и вложенных папок.
   Get-DiskUsage

 .Example
   # Размер текущей папки.
   Get-DiskUsage . -Depth 0
 
 .Example 
   # Отобразить информацию о ходе выполнения сканирования.
   Get-DiskUsage . -ShowProgress
   
 .Example
   # Вывести размеры каталогов в удобном виде.
   Get-DiskUsage | Update-Length
 
 .Example 
   # Выполнить сканирование рекурсивно.
   Get-DiskUsage 'C:\Program Files' -RecursiveAlgorithm
   
 .Example
	# Вывести 'топ 10' самых толстых папок в 'C:\Program Files'.
   Get-DiskUsage 'C:\Program Files' -ShowProgress -ShowLevel | ? {$_.Level -eq 1} | sort Length -Descending | select FullName, Length -First 10 | Update-Length | ft -AutoSize
#>
function Get-DiskUsage(
	[string]$Path = ".", 
	[int]$Depth = [int]::MaxValue, 
	[switch]$ShowLevel, 
	[switch]$ShowProgress,
	[switch]$RecursiveAlgorithm
)
{
	if($RecursiveAlgorithm) {
		Get-DiskUsageRecursive -Path $Path -Depth $Depth -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress
	} else {
		Get-DiskUsageLinear -Path $Path -Depth $Depth -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress
	}
	
}

# пример использования:
# ls 'c:\program files\' | add_dirlength
<# 
 .Synopsis
  Возращает список вложенных каталогов с их суммарными размерами.

 .Description
  Выполняет полное сканирование указанного каталога. 
 
  
 .Parameter Path
  Каталог, размер которого требуется подсчитать.

 .Parameter Depth
  Глубина вложенности каталогов. Требуется для ограничения отображаемых данных (на процесс сканирования никак не влияет).
 
 .Parameter ShowLevel
  Добавляет столбец Level, в нем указан уровень вложенности каталога.
  
 .Parameter ShowProgress
  Отображает прогресс сканирования каталогов.
  
 .Parameter RecursiveAlgorithm
  Использовать рекурсивный алгоритм для сканирования папок (в данном случае в вывод данные отдаются только по окончанию выполнения фукнции).

 .Example
   # Размеры текущей и вложенных папок.
   Get-DiskUsage

 .Example
   # Размер текущей папки.
   Get-DiskUsage . -Depth 0
 
 .Example 
   # Отобразить информацию о ходе выполнения сканирования.
   Get-DiskUsage . -ShowProgress
   
 .Example
   # Вывести размеры каталогов в удобном виде.
   Get-DiskUsage | Update-Length
 
 .Example 
   # Выполнить сканирование рекурсивно.
   Get-DiskUsage 'C:\Program Files' -RecursiveAlgorithm
   
 .Example
	# Вывести 'топ 10' самых толстых папок в 'C:\Program Files'.
   Get-DiskUsage 'C:\Program Files' -ShowProgress -ShowLevel | ? {$_.Level -eq 1} | sort Length -Descending | select FullName, Length -First 10 | Update-Length | ft -AutoSize
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

function Update-Length
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[PSobject]$InputObject,
		[string]$Parameter = "Length"
	)  
	
	begin{}
	process {
		foreach($i in $InputObject) {      
			$i | Add-Member -MemberType NoteProperty -Name Length -Value ("{0:N3} MB" -f ($i.Length / 1MB)) -force
			$i
		}
	}
	end{}
}

function Join-Object
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[PSObject]$InputObject,
		[PSObject]$JoinObject,
		[ScriptBlock]$Where,
		[String[]]$InputProperty = "*",
		[String[]]$JoinProperty = "*"
	)
	
	begin{}
	process {
		
		foreach($i in $InputObject) {
			foreach($j in $JoinObject) {
				if ( ($Where.Invoke($i, $j)) -eq "True")
				{
					$out = New-Object -TypeName PSobject             
					
					# извлекаем свойства из первого списка
					$props = @(); 
					$i | Get-Member -MemberType *Property -Name $InputProperty | % { $props += $_.Name }
					foreach($ip in $props) {
						$out | Add-Member -MemberType NoteProperty -Name $ip -Value $i.$ip
					}
					
					# извлекаем свойства из второго списка
					$props = @(); 
					$j | Get-Member -MemberType *Property -Name $JoinProperty | % { $props += $_.Name }
					foreach($jp in $props) {
						$out | Add-Member -MemberType NoteProperty -Name $jp -Value $j.$jp
					}
					
					$out
				}
			}
		}
	}
	end{}
}