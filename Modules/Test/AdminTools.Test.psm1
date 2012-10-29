

# $null | Skip-Null | % { ... } 
filter Skip-Null { $_|?{ $_ -ne $null } }

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
			$obj = get-wmiobject -Class Win32_OperatingSystem -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}

function Get-ComputerInfo
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
			$obj = get-wmiobject -Class Win32_ComputerSystem -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}

function Get-BiosInfo
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
			$obj = get-wmiobject -Class Win32_Bios -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}


function Get-LogicalDiskInfo
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername,
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string]$DeviceID = ""
	)  
	begin {}
	process {
		foreach ($comp in $ComputerName)
		{
			if (![String]::IsNullOrEmpty($DeviceID)) {
				$obj = get-wmiobject -Class Win32_LogicalDisk -ComputerName $comp -Filter "DeviceID = '$DeviceID'"
			} else {
				$obj = get-wmiobject -Class Win32_LogicalDisk -ComputerName $comp
			}
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}


function Get-DiskPartitionInfo
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername,           
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string]$Filter = ""
	)  
	begin {}
	process {
		foreach ($comp in $ComputerName)
		{
			$obj = get-wmiobject -Class Win32_DiskPartition -ComputerName $comp -Filter "$Filter"
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}


function Get-DiskDriveInfo
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
			$obj = get-wmiobject -Class Win32_DiskDrive -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}


function Get-ProcessorInfo
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
			$obj = get-wmiobject -Class Win32_Processor -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}


function Get-MotherboardInfo
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
			$obj = get-wmiobject -Class win32_baseboard -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}

<# 
 .Synopsis
  Выводит список устройств, встроенных в материнскую плату.

 .Description
  Данная функция возвращает объекты класса Win32_OnBoardDevice.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

  
 .Example
   PS C:\> Get-OnBoardDeviceInfo

   Описание
   -----------
   Эта команда возвращает список встроенных устройств на текущем компьютере. 
 
 .Example
   PS C:\> Get-OnBoardDeviceInfo computer1, computer2 | select ComputerName, Description | ft -a

   Описание
   -----------
   Эта команда возвращает список встроенных устройств материнских плат компьютеров computer1 и computer2.
     
#>
function Get-OnBoardDeviceInfo
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
			$obj = get-wmiobject -Class Win32_OnBoardDevice -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}


<# 
 .Synopsis
  Выводит список модулей памяти, расположенных на материнской плате.

 .Description
  Данная функция возвращает объекты класса Win32_PhysicalMemory.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

  
 .Example
   PS C:\> Get-PhysicalMemoryInfo

   Описание
   -----------
   Эта команда возвращает список модулей памяти. 
 
 .Example
   PS C:\> Get-PhysicalMemoryInfo | Update-Length -NumericParameter Capacity | select BankLabel, Capacity,  DeviceLocator, Tag, Speed, Manufacturer, PartNumber, SerialNumber | fta

   Описание
   -----------
   Эта команда возвращает список модулей памяти в удобном для чтения виде.
     
#>
function Get-PhysicalMemoryInfo
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
			$obj = get-wmiobject -Class Win32_PhysicalMemory -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}



<# 
 .Synopsis
  Выводит список звуковых карт.

 .Description
  Данная функция возвращает объекты класса Win32_SoundDevice.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

  
 .Example
   PS C:\> Get-SoundDeviceInfo

   Описание
   -----------
   Эта команда возвращает список звуковых карт. 
 
 .Example
   PS C:\> Get-SoundDeviceInfo | select Caption, Manufacturer

   Описание
   -----------
   Эта команда возвращает список звуковых карт в удобном для чтения виде.
     
#>
function Get-SoundDeviceInfo
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
			$obj = get-wmiobject -Class Win32_SoundDevice -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}

<# 
 .Synopsis
  Выводит список видеокарт.

 .Description
  Данная функция возвращает объекты класса Win32_VideoController.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

  
 .Example
   PS C:\> Get-VideoControllerInfo

   Описание
   -----------
   Эта команда возвращает список видеокарт. 
 
 .Example
   PS C:\> Get-VideoControllerInfo | select Caption, AdapterRAM, DeviceID, DriverVersion, VideoModeDescription

   Описание
   -----------
   Эта команда возвращает список видеокарт в удобном для чтения виде.
     
#>
function Get-VideoControllerInfo
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
			$obj = get-wmiobject -Class Win32_VideoController -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}


<# 
 .Synopsis
  Выводит список сетевых карт.

 .Description
  Данная функция возвращает объекты класса Win32_NetworkAdapter.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

  
 .Example
   PS C:\> Get-NetworkAdapterInfo

   Описание
   -----------
   Эта команда возвращает список сетевых карт. 
 
 .Example
   PS C:\> Get-NetworkAdapterInfo | ? { $_.PhysicalAdapter -eq $true }

   Описание
   -----------
   Эта команда возвращает список физических адаптеров.
     
#>
function Get-NetworkAdapterInfo
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
			$obj = get-wmiobject -Class Win32_NetworkAdapter -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}


<# 
 .Synopsis
  Выводит список настроек сетевых карт.

 .Description
  Данная функция возвращает объекты класса Win32_NetworkAdapterConfiguration.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

  
 .Example
   PS C:\> Get-NetworkAdapterConfigurationInfo

   Описание
   -----------
   Эта команда возвращает список сетевых адаптеров. 
 
 .Example
   PS C:\> Get-NetworkAdapterConfigurationInfo | ? { $_.IPEnabled } | select Description, IPAddress, DNSServerSearchOrder, DefaultIPGateway, IPSubnet, MACAddress

   Описание
   -----------
   Эта команда возвращает список настроек сетевых адаптеров в удобном для чтения виде.
     
#>
function Get-NetworkAdapterConfigurationInfo
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
			$obj = get-wmiobject -Class Win32_NetworkAdapterConfiguration -ComputerName $comp
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp
			$obj
		}
	}
	end {}
}

function Get-NetObject([string]$Match)
{
    $objs = net view 
	$o2 = $objs | select -skip 3 -first ($objs.length-5) | ? { $_ -imatch $Match } # убрали лишние строки 
	foreach($i in $o2) {
		$s = $i -split "\s+", 2
		$obj = New-Object -TypeName PSObject
		$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $s[0].Trim("\\")
		$obj | Add-Member -MemberType NoteProperty -Name Description -Value $s[1]
		$obj
	}
}

function  Format-TableAuto { 
	begin {
		$list = @()
	}
	process { 
		$list += $_ 
	}
	end {
		$list | ft -a -Wrap
	}
}

<# 
 .Synopsis
  Объединяет два списка в один.

 .Description
  Результат выполнения Join-Object есть декартово произведение двух списков, представленных параметрами LeftObject и RightObject. Если какие-либо имена свойств у LeftObject и RightObject совпадают, то к имени свойства из списка RightObject добавляется строка "Join". Например при объединении списков, содеражих одинаковые свойства (Id, Name), получаем результирующий список со свойствами: Id, Name, JoinId, JoinName.
  В случае, когда элементы списков не наследуются от класса PSObject, параметры LeftProperty и RightProperty не используются, и имена свойств результирующего списка выбираются, как "Value" и "JoinValue".
    
 .Parameter LeftObject
  Первый список для объединения. Может использоваться для перадачи объектов по конвейеру.

 .Parameter RightObject
  Второй список для объединения. К именам свойств, совпадающим с полями из LeftObject, будет добавляться префикс "Join".
 
 .Parameter FilterScript
  Указывает блок скрипта, используемый для фильтрации объектов. Для передачи параметров в скрипт используйте param(): { param($i,$j); ... }. Переменная $i содержит объект из LeftObject, $j - из RightObject.
  
 .Parameter LeftProperty
  Указывает список свойств из LeftObject для добавления в результирующий список. Подстановочные знаки разрешены. Если этот параметр не указан, то LeftObject будет добавлен, как значение (под именем "Value").

  Значение параметра LeftProperty может быть новым вычисляемым свойством. Чтобы создать вычисляемое свойство, используйте хэш-таблицу. Допустимые ключи:
  -- Name (или Label) <строка>
  -- Expression <строка> или <блок скрипта>
  
  К именам свойств, совпадающим с уже существующими полями, будет добавляться префикс "Join".
 
 .Parameter RightProperty
  Указывает список свойств из RightObject для добавления в результирующий список. Подстановочные знаки разрешены. Если этот параметр не указан, то RightObject будет добавлен, как значение (под именем "Value").

  Значение параметра RightProperty может быть новым вычисляемым свойством. Чтобы создать вычисляемое свойство, используйте хэш-таблицу. Допустимые ключи:
  -- Name (или Label) <строка>
  -- Expression <строка> или <блок скрипта>
  
  К именам свойств, совпадающим с уже существующими полями, будет добавляться префикс "Join".

 .Parameter CustomProperty
  Добавляет свойства, которые вычисляются из значений в обоих объектах.
  
  Значение параметра CustomProperty должно быть новым вычисляемым свойством. Чтобы создать вычисляемое свойство, используйте хэш-таблицу. Допустимые ключи:
  -- Name (или Label) <строка>
  -- Expression <блок скрипта>
  
  Для передачи параметров в блок скрипта используйте param(): { param($i,$j); ... }. Переменная $i содержит объект из LeftObject, $j - из RightObject.  
  
  К именам свойств, совпадающим с уже существующими полями, будет добавляться префикс "Join".
  
 .Example
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime LastWriteTime

   Описание
   -----------
   Эта команда возвращает список файлов и директорий с совпадающими именами в c:\dir1 и c:\dir2. 
 
 .Example
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime @{Name = "Dir2_LastWriteTime"; Expression = {$_.LastWriteTime}}

   Описание
   -----------
   Эта команда возвращает список файлов и директорий с совпадающими именами в c:\dir1 и c:\dir2. Параметр LasWriteTime во втором списке переименовывается в Dir2_LastWriteTime.
     
 .Example
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime LastWriteTime  @{Name = "diff"; Expression={param($i,$j);  [int]($i.LastWriteTime - $j.LastWriteTime).TotalDays }}

   Описание
   -----------
   Эта команда возвращает список файлов и директорий с совпадающими именами в c:\dir1 и c:\dir2 и разницу в днях для свойств LastWriteTime. 
   
 .Example
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> $a | Join-Object -RightObject $b -where { param($i,$j); $i.name -eq $j.name } -LeftProperty name, LastWriteTime -RightProperty LastWriteTime

   Описание
   -----------
   Эта команда возвращает список файлов и директорий с совпадающими именами в c:\dir1 и c:\dir2. Используется передача параметра LeftObject через конвейер.
   
 .Example
   PS C:\> Join-Object (1..9) (1..9) { param($i, $j); $i+$j -eq 10 } 
   
   Описание
   -----------
   На экран будут выведены суммы чисел, равных 10-и.
 
 .Example
   PS C:\> $comp1 = Get-Program comp1
   PS C:\> $comp2 = Get-Program comp2
   PS C:\> Join-Object $comp1 $comp2 { param($i, $j); $i.AppName -eq $j.AppName } AppName, InstalledDate InstalledDate
 
   Описание
   -----------
   Вывод дат установки одноименных программ на разных компьютерах.
 
 .Link
   http://blogs.msdn.com/b/powershell/archive/2012/07/13/join-object.aspx
#>
function Join-Object
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		$LeftObject, 
		$RightObject,
		[Alias("Where")][ScriptBlock]$FilterScript = { $true },
		[Object[]]$LeftProperty = $null,
		[Object[]]$RightProperty = $null,
		[Hashtable[]]$CustomProperty = $null
	)
	
	begin{}
	process {
		
		function getFreeJoinParameter($Obj, $PropName) 
		{
			$name = $PropName
			if ($Obj | Get-Member -Name $name) {
				$name = "Join$PropName"
			}
			
			for ($i = 2; $Obj | Get-Member -Name $name; $i++) {
				$name = "Join$PropName$i"
			}
			return $name
		}

		function fillTempObject($properties, $left, $right)
		{
			$prop_list = New-Object -Type PSObject
			# заполняем промежуточный объект $prop_list
			foreach($p in $properties) {
				if( $p -is [Hashtable] ) {
					# вычисляемое поле
					# блок проверки
					if( ! ($p.ContainsKey("Name") -or $p.ContainsKey("Label")) ) {
						throw "Параметр не имеет имени"
					}
					if ( ! ($p.ContainsKey("Expression") -and $p.Expression -is [ScriptBlock]) ) {
						throw "Параметр не имеет выполняемого блока"
					}
					# имя
					if ($p.ContainsKey("Name")) { 
						$name = $p.Name 
					} else { 
						$name = $p.Label
					}
					# выражение					
					$expression = $p.Expression.Invoke($left, $right)
					if( $expression.Count -eq 0) {
						$expression = $null
					} elseif( $expression.Count -eq 1) {
						$expression = $expression[0]
					}
					
					$prop_list | Add-Member -MemberType NoteProperty -Name $name -Value $expression
				} else {
					throw "Параметр должен быть типа Hashtable"
				}
			}
			return $prop_list
		}
		function addProperty($out, $prop_list)
		{			
			foreach($ip in $prop_list | Get-Member -MemberType *Property) {		
				$ip_name = getFreeJoinParameter $out $ip.Name
				$out | Add-Member -MemberType NoteProperty -Name $ip_name -Value $prop_list.($ip.Name)
			}
		}
		function addValue($out, $source)
		{
			$ip_name = getFreeJoinParameter $out "Value"
			$out | Add-Member -MemberType NoteProperty -Name $ip_name -Value $source
		}
		
		foreach($i in $LeftObject) {
			foreach($j in $RightObject) {
				if ( !($FilterScript.Invoke($i, $j))) {continue}
				$out = New-Object -TypeName PSobject    
				
				if($LeftProperty) {
					addProperty $out ($i | select $LeftProperty)
				} else {
					addValue $out $i
				}
				
				if($RightProperty) {
					addProperty $out ($j | select $RightProperty)
				} else {
					addValue $out $j
				}
				
				if($CustomProperty) {
					addProperty $out (fillTempObject $CustomProperty $i $j)
				}
				$out
			}
		}
	}
	end{}
}