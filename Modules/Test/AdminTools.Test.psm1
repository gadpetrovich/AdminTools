# требуется для работы start-removeservice и stop-removeservice
$null = [System.Reflection.Assembly]::Load("System.ServiceProcess, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")


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
			get-wmiobject -Class Win32_OperatingSystem -ComputerName $comp
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


<# 
 .Synopsis
  Запускает службы на удаленном компьютере.

 .Description
  Функция Start-RemoteService запускает службы на удаленных компьютерах с помощью утилиты sc.exe. Если служба уже запущена, выдается предупреждение и команда игнорируется. 
 
 .Parameter ComputerName
  Компьютер, на котором требуется запустить службу. Может использоваться для перадачи объектов по конвейеру.
 
 .Parameter Name
  Имя запускаемой службы. Требуется указать точное имя службы (не допускается использование отображаемых имен). Может использоваться для перадачи объектов по конвейеру.

 .Parameter InputObject
  Задает объекты ServiceController, представляющие запускаемые службы. Введите переменную, содержащую объекты, либо команду или выражение для получения объектов.
  
 .Outputs
  Возвращаемые поля:
  ComputerName - имя компьютера
  Name         - имя службы
  Status       - результат выполнения функции
  
 .Example
   PS C:\> start-remoteservice -name msiserver -computername pc-remote

   Описание
   -----------
   Эта команда запускает службу "msiserver" на компьютере "pc-remote".
   
 .Example
   PS C:\> $a = get-service servicename -ComputerName pc-remote 
   
   PS C:\> start-remoteservice -InputObject $a

   Описание
   -----------
   Приведенные команды запускают на компьютере "pc-remote" службу "servicename".
 
 .Example
   PS C:\> $a = get-service servicename -ComputerName pc-remote | start-remoteservice 

   Описание
   -----------
   Приведенные команды запускают на компьютере "pc-remote" службу "servicename".  
 
 .Link
	Get-Service
	
 .Link
	Start-Service

 .Link
	Stop-RemoteService
	
#>
function Start-RemoteService
{
	[cmdletbinding(SupportsShouldProcess=$True)]
	param (            
		[parameter(position=0,ValueFromPipelineByPropertyName=$true,Mandatory=$true,ParameterSetName="Normal")]
		[string[]]$Name,
		[parameter(position=1,ValueFromPipelineByPropertyName=$true,ParameterSetName="Normal")]
		[string[]]$ComputerName = $env:computername,
		
		[parameter(position=0,ValueFromPipeline=$true, ParameterSetName="ServiceControllers")]
		[System.ServiceProcess.ServiceController[]]$InputObject
	)          
	
	begin{}
	process{
		function func([string]$service, [string]$computer)
		{
			$status = &sc.exe \\$computer query $service
			if ($status.Length -lt 5) {
				throw "Неправильное имя сервиса: $service"
			}
			
			$result = "Cancelled"
			if ($status[3] -ilike "*running*") {
				Write-Warning "Сервис $service уже запущен"
				$result = "RUNNING"
			} else {							
				if ($pscmdlet.ShouldProcess("$service на компьютере $computer")) {
					$respond = &sc.exe \\$computer start $service
					if ($respond.Length -lt 5) {
						$result = "Error"
						Write-Error "Не удалось запустить службу"
					} elseif ($respond[3] -ilike "*START_PENDING*" -or $respond[3] -ilike "*running*") {
						$result = "START_PENDING"
					}
				}
			}
			$OutputObj = New-Object -TypeName PSobject             
			$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $computer
			$OutputObj | Add-Member -MemberType NoteProperty -Name Name -Value $service
			$OutputObj | Add-Member -MemberType NoteProperty -Name Status -Value $result
			$OutputObj
		}
		try {
			switch ($PsCmdlet.ParameterSetName) 
			{ 
				"ServiceControllers" { 
					foreach ($i in $InputObject) {
						Write-Verbose ("Компьютер " + $i.MachineName)
		              	if(!(Test-Connection -ComputerName $i.MachineName -Count 1 -ea 0)) { throw "Компьютер " + $i.MachineName + " недоступен"}
		                		                
                        func $i.ServiceName $i.MachineName
					}
				} 
				"Normal" { 
					foreach($computer in $ComputerName) {
                        Write-Verbose "Компьютер $Computer"            
		              	if(!(Test-Connection -ComputerName $Computer -Count 1 -ea 0)) { throw "Компьютер $computer недоступен"}
		                			
						foreach($service in $Name) {
                            if ($service -eq "" -or $service -eq $null) {
                				throw "Не указано имя сервиса"
                			}
							func $service $computer
						}
					}
				}
			}
			
			
		} catch {
			Write-Error $_
		}
	}
	end{}
}


<# 
 .Synopsis
  Останавливает службы на удаленном компьютере.

 .Description
  Функция Stop-RemoteService останавливает службы на удаленных компьютерах с помощью утилиты sc.exe. Если служба уже остановлена, выдается предупреждение и команда игнорируется. 
 
 .Parameter ComputerName
  Компьютер, на котором требуется остановить службу. Может использоваться для перадачи объектов по конвейеру.
 
 .Parameter Name
  Имя останавливаемой службы. Требуется указать точное имя службы (не допускается использование отображаемых имен). Может использоваться для перадачи объектов по конвейеру.

 .Parameter InputObject
  Задает объекты ServiceController, представляющие останавливаемые службы. Введите переменную, содержащую объекты, либо команду или выражение для получения объектов.
  
 .Outputs
  Возвращаемые поля:
  ComputerName - имя компьютера
  Name         - имя службы
  Status       - результат выполнения функции
  
 .Example
   PS C:\> stop-remoteservice -name msiserver -computername pc-remote

   Описание
   -----------
   Эта команда останавливает службу "msiserver" на компьютере "pc-remote".
   
 .Example
   PS C:\> $a = get-service servicename -ComputerName pc-remote 
   
   PS C:\> stop-remoteservice -InputObject $a

   Описание
   -----------
   Приведенные команды останавливают на компьютере "pc-remote" службу "servicename".
 
 .Example
   PS C:\> $a = get-service servicename -ComputerName pc-remote | start-remoteservice 

   Описание
   -----------
   Приведенные команды останавливают на компьютере "pc-remote" службу "servicename".  
  
 .Link
	Get-Service
	
 .Link
	Stop-Service

 .Link
	Start-RemoteService
#>
function Stop-RemoteService
{
	[cmdletbinding(SupportsShouldProcess=$True)]
	param (            
		[parameter(position=0,ValueFromPipelineByPropertyName=$true,Mandatory=$true,ParameterSetName="Normal")]
		[string[]]$Name,
		[parameter(position=1,ValueFromPipelineByPropertyName=$true,ParameterSetName="Normal")]
		[string[]]$ComputerName = $env:computername,
		
		[parameter(position=0,ValueFromPipeline=$true, ParameterSetName="ServiceControllers")]
		[System.ServiceProcess.ServiceController[]]$InputObject
	)          
	
	begin{}
	process{
		function func([string]$service, [string]$computer)
		{
			$status = &sc.exe \\$computer query $service
			if ($status.Length -lt 5) {
				throw "Неправильное имя сервиса: $service"
			}
			
			$result = "Cancelled"
			if ($status[3] -ilike "*stopped*") {
				Write-Warning "Сервис $service уже остановлен"
				$result = "STOPPED"
			} else {							
				if ($pscmdlet.ShouldProcess("$service на компьютере $computer")) {						
					$respond = &sc.exe \\$computer stop $service
					if ($respond.Length -lt 5) {
						$result = "Error"
						Write-Error "Не удалось остановить службу"
					} elseif ($respond[3] -ilike "*STOP_PENDING*" -or $respond[3] -ilike "*STOPPED*") {
						$result = "STOP_PENDING"
					} 
				}
			}
			$OutputObj = New-Object -TypeName PSobject             
			$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $computer
			$OutputObj | Add-Member -MemberType NoteProperty -Name Name -Value $service
			$OutputObj | Add-Member -MemberType NoteProperty -Name Status -Value $result
			$OutputObj
		}
		
		try {
			switch ($PsCmdlet.ParameterSetName) 
			{ 
				"ServiceControllers" { 
					foreach ($i in $InputObject) {
						Write-Verbose ("Компьютер " + $i.MachineName)
		              	if(!(Test-Connection -ComputerName $i.MachineName -Count 1 -ea 0)) { throw "Компьютер " + $i.MachineName + " недоступен"}
		                
                        func $i.ServiceName $i.MachineName
					}
				} 
				"Normal" { 
					foreach($computer in $ComputerName) {
                        Write-Verbose "Компьютер $Computer"            
		              	if(!(Test-Connection -ComputerName $Computer -Count 1 -ea 0)) { throw "Компьютер $computer недоступен"}
		                			
						foreach($service in $Name) {
                            if ($service -eq "" -or $service -eq $null) {
                				throw "Не указано имя сервиса"
                			}
							func $service $computer
						}
					}
				}
			}
			
		} catch {
			Write-Error $_
		}
	}
	end{}
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