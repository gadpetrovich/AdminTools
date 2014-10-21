<# 
 .Synopsis
  Возвращает список установленных программ.

 .Description
  Функция возвращает список всех программ, установленных на указанных компьютерах.
 
  
 .Parameter ComputerName
  Компьютер, для которого требуется получить список программ, по умолчанию локальный. Может использоваться для перадачи объектов по конвейеру.
 
 .Parameter AppMatch
  Регулярное выражение для поиска программы по ее названию. Может использоваться для перадачи объектов по конвейеру.
  
 .Parameter ShowUpdates
  Если установлен данный переключатель, то будут выводиться обновления.
  
 .Parameter ShowSystemComponents
  Если установлен данный переключатель, то будут выводиться системные компоненты.
  
 .Outputs
  PSObject. Содержит следующие параметры
  [string]Name
  [string]Version
  [string]Vendor
  [DateTime]InstalledDate
  [string]InstallLocation
  [string]UninstallKey
  [string]QuietUninstallKey
  [string]GUID
  
 .Example
   PS C:\> Get-Program

   Описание
   -----------
   Отобразит все программы на локальном компьютере.
   
 .Example
   PS C:\> Get-Program -ComputerName comp01 ^p

   Описание
   -----------
   Список программ на компьютере "comp01", название которых начинается с символа "p".
  
 .Link
   http://techibee.com/powershell/powershell-script-to-query-softwares-installed-on-remote-computer/1389
   
 .Link
   http://gallery.technet.microsoft.com/scriptcenter/519e1d3a-6318-4e3d-b507-692e962c6666
   
 .Link
   http://gallery.technet.microsoft.com/scriptcenter/Get-All-Installed-Software-73a07eba
 
#>
function Get-Program
{
	param(
		[parameter(position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[string]$AppMatch = "",
		[parameter(position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[Alias("CN","__SERVER","Computer","CNAME")]
		[string[]]$ComputerName = $env:computername,
		[switch]$ShowUpdates,
		[switch]$ShowSystemComponents
	)            

	begin {}            

	process {    
		
		function get_installed_date($AppDetails, $Computer) {
			
			$AppInstalledDate = $AppDetails.GetValue("InstallDate")
			if (![String]::IsNullOrEmpty($AppInstalledDate) -and `
					$AppInstalledDate.Length -eq 8) {
				$Year = $AppInstalledDate.Substring(0,4)
				$Month = $AppInstalledDate.Substring(4,2)
				$Day = $AppInstalledDate.Substring(6,2)
				return New-Object DateTime($Year, $Month, $Day)	
			}
			
			$regdata = Get-RegKeyLastWriteTime -ComputerName $computer -Key HKLM `
				-SubKey $AppDetails.name.Substring($AppDetails.Name.IndexOf("\")+1) -NoEnumKey
			
			return $regdata.LastWriteTime
		}
		
		function get_application($Computer, $AppRegistry, $App)
		{
			$AppDetails = $HKLM.OpenSubKey($AppRegistry + "\\" + $App)
			$OutputObj = "" | select ComputerName, Name, Version, Vendor, InstalledDate, `
				InstallLocation, UninstallKey, QuietUninstallKey, GUID
			$OutputObj.ComputerName = $Computer.ToUpper()
			$OutputObj.Name = $AppDetails.GetValue("DisplayName")
			$OutputObj.UninstallKey = $AppDetails.GetValue("UninstallString")
			$ReleaseType = $AppDetails.GetValue("ReleaseType")
			$ParentKeyName = $AppDetails.GetValue("ParentKeyName")
			$SystemComponent = $AppDetails.GetValue("SystemComponent")
			
			if (
				!$OutputObj.Name -or
				$OutputObj.Name -notmatch $AppMatch -or
				!$OutputObj.UninstallKey -or
				(!$ShowUpdates -and ($ReleaseType -imatch "(Update|Hotfix)" -or $ParentKeyName)) -or
				(!$ShowSystemComponents -and $SystemComponent -gt 0)
			) { $AppDetails.Close(); return }
			
			$OutputObj.Version = $AppDetails.GetValue("DisplayVersion")
			$OutputObj.Vendor = $AppDetails.GetValue("Publisher")
			$OutputObj.InstalledDate = get_installed_date $AppDetails $Computer 
			$OutputObj.InstallLocation = $AppDetails.GetValue("InstallLocation")
			$OutputObj.QuietUninstallKey = $AppDetails.GetValue("QuietUninstallString")
			$OutputObj.GUID = $App
			$OutputObj
			
			$AppDetails.Close()
		}
		
		function get_applications($Computer, $UninstallRegKey) {
			$UninstallRef  = $HKLM.OpenSubKey($UninstallRegKey)
			if ($UninstallRef -eq $null) { return }
			$Applications = $UninstallRef.GetSubKeyNames()
			$UninstallRef.Close()
			foreach ($App in $Applications) {
				get_application $Computer $UninstallRegKey $App
			}
		}
		
		foreach($Computer in $ComputerName) {  
			try {          
				Write-Verbose "Берем список программ из $Computer по шаблону `"$AppMatch`""            
				if (!(Test-Connection -ComputerName $Computer -Count 2 -ea 0)) { 
					Write-Error "Компьютер $Computer не отвечает"
					Continue
				}
				$key = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
				
				$archs = @([Microsoft.Win32.RegistryView]::Registry32)
				$arch = (get-wmiobject -Class Win32_OperatingSystem -ComputerName $Computer).OSArchitecture
				if ($arch -Match "64") {
					$archs += [Microsoft.Win32.RegistryView]::Registry64
				}
				
				foreach ($arch in $archs) {
					$HKLM = [microsoft.win32.registrykey]::OpenRemoteBaseKey(
						'LocalMachine', $computer, $arch)
					get_applications $computer $key
					$HKLM.Close()  
				}
			} catch {
				Write-Error $_
			}
		}
	}            

	end {}
}

function Wait-InstallProgram 
{
	param(
		[parameter(position=0,ValueFromPipelineByPropertyName=$true)]
		[Alias("CN","__SERVER","Computer","CNAME")]
		[string]$ComputerName = $env:computername, 
		[parameter(position=1,ValueFromPipelineByPropertyName=$true)]
		[int]$WaitSecPeriod = 7,
		[parameter(position=2,ValueFromPipelineByPropertyName=$true)]
		[int]$SecTimeout = 6000
	)
	try {
		$before = Get-Date
		Write-Verbose "Запуск ожидания установки/удаления программы, время: $before"
		$msiserver = Get-Service -ComputerName $ComputerName -Name msiserver
		if ($msiserver.Status -ne "Running") { $msiserver.Start(); sleep 2 }
		while ( $true )
		{ 
			Sleep $WaitSecPeriod
			if (-not (
				@(Get-ProcessInfo $ComputerName | ? { $_.Name -imatch "msiexec" }).Count -gt 1 -or 
				(Get-ProcessInfo $ComputerName | ? { $_.Name -imatch "(nsis|uninst|wusa|setup)" }) 
			)) {
				break
			}
			if ( ((Get-Date)-$before).TotalSeconds -gt $SecTimeout ) {
				throw "Истекло время ожидания установки/удаления программы"
			}
		}
		Write-Verbose "Завершение ожидания установки/удаления программы, время: $(Get-Date)"
	} catch {
		Write-Error $_
	}
}

function Wait-WMIRestartComputer
{
	param(
		[parameter(position=0,ValueFromPipelineByPropertyName=$true)]
		[Alias("CN","__SERVER","Computer","CNAME")]
		[string]$ComputerName,
		[parameter(position=1,ValueFromPipelineByPropertyName=$true)]
		[int]$WaitSecPeriod = 10, 
		[parameter(position=2,ValueFromPipelineByPropertyName=$true)]
		[int]$SecTimeout = 300,
		[parameter(position=3)]
		[switch]$DontWaitShutdown
	)
	try {
		if (!$DontWaitShutdown) {
			$before = Get-Date
			# ждем, когда wmi вырубится
			Write-Verbose "Запуск ожидания отключения WMI, время: $before"
			while($true) {
				try {
					if (-not (Get-WmiObject -class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction silentlycontinue)) {
						break
					}
				} catch { }
				if ( ((Get-Date)-$before).TotalSeconds -gt $SecTimeout ) {
					throw "Истекло время ожидания на остановку WMI"
				}
				Sleep $WaitSecPeriod
			}
		}
		$before = Get-Date
		# ждем, когда wmi заработает
		Write-Verbose "Запуск ожидания включения WMI, время: $before"
		while($true) {
			try {
				if (Get-WmiObject -class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction silentlycontinue) {
					break
				}
			} catch { }
			if ( ((Get-Date)-$before).TotalSeconds -gt $SecTimeout ) {
				throw "Истекло время ожидания на запуск WMI"
			}
			Sleep $WaitSecPeriod
		}
		Write-Verbose "Перезагрузка завершена: $(Get-Date)"
	} catch {
		Write-Error $_
	}
}

function Get-RemoteCmd([string]$ComputerName, [string] $cmd) 
{
	return "`"$PSScriptRoot\..\..\Apps\psexec`" \\$ComputerName -s $cmd"
}

<# 
 .Synopsis
  Удаляет указанную программу.

 .Description
  Удаляет программу, указанную в параметре GUID. Деинсталляция производится с тихом режиме, для этого используются ключи "/S /x /silent /uninstall /qn /quiet /norestart" для нестандартных установщиков и "/qn" для msi-пакетов.
 
  
 .Parameter ComputerName
  Компьютер, на котором требуется удалить программу. Может использоваться для перадачи объектов по конвейеру.
 
 .Parameter GUID
  Guid деинсталлируемой программы. Может использоваться для перадачи объектов по конвейеру.

 .Parameter NoDefaultParams
  Убирает стандартные параметры удаления nsis и msiexec. Не влияет на программы, у которых есть параметр QuietUninstallKey.
  
 .Parameter Interactive
  Выводит окно деинсталлятора на рабочий стол удаленного компьютера.
 
 .Parameter Force
  Подавляет запрос на удаление программы. Для дополнительных запросов можно использовать параметр Confirm.
 
 .Parameter PassThru
  Возвращает объекты, описывающие удаленные программы. По умолчанию эта функция не формирует никаких выходных данных.
 
 .Outputs
  PSObject. Содержит следующие параметры
  [string]ComputerName - имя компьютера
  [string]Name      - имя программы
  [string]GUID      - GUID приложения
  [int]ReturnValue  - результат выполнения
  [string[]]Text         - результат выполнения в текстовом виде
  [Object[]]EventMessage - сообщения от MsiInstaller'а
  [DateTime]StartTime - начало удаления
  [DateTime]EndTime   - окончание удаления
  
 .Notes
  
 .Example
   PS C:\> Get-Program testprogram | Uninstall-Program 

   Описание
   -----------
   Эта команда удаляет программу "testprogram" на локальном компьютере.
   
 .Example
   PS C:\> cat computers.txt | Get-Program Name | Uninstall-Program -Confirm

   Описание
   -----------
   Эта команда удаляет программу "Name" на компьютерах, указанных в файле "computers.txt".
 
 .Example
   PS C:\> "ComputerName, Name
   >> comp1, prog1
   >> comp2, prog2 " | echo >remove_apps.csv
   >>
   PS C:\> Import-Csv remove_apps.csv | Get-Program | Uninstall-Program

   Описание
   -----------
   Эта команда удаляет программы, указанные в файле "remove_apps.csv".
     
 .Link
   http://techibee.com/powershell/powershell-uninstall-software-on-remote-computer/1400
   
 .Link
   параметры NSIS http://nsis.sourceforge.net/Docs/Chapter3.html#3.2.1
   
#>
function Uninstall-Program
{
	[cmdletbinding(SupportsShouldProcess=$True)]            
	param (            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string]$GUID,
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[Alias("CN","__SERVER","Computer","CNAME")]
		[string]$ComputerName = $env:computername,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Alias("EmptyDefaultParams")]
		[switch]$NoDefaultParams,
		[switch][Alias("Visible")]$Interactive,
		[switch]$Force,
		[switch]$PassThru
	)          
	
	begin {}
	process {
		function get_cmd() {
			$_cmd = ""
			if ($Interactive) { $_cmd += "-i " }
			
			if ($app.QuietUninstallKey -ne $null) {
				$_cmd += $app.QuietUninstallKey
			} elseif ($uninstall_key -match "msiexec" -or $uninstall_key -eq $null) {
				$uninstall_guid = [regex]::match($uninstall_key, "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}").Value
				$params = "/x {$uninstall_guid} "
				if (!$NoDefaultParams) {
					$params += "/qn"
				}
				
				$_cmd += "msiexec $params"
			} else {
				if (!$NoDefaultParams) {
					$params = "/S /x /silent /uninstall /qn /quiet /norestart"
				} 
				if ($uninstall_key.IndexOf('"') -eq -1 -and $uninstall_key.Split().Count -gt 1) {
					$match = [regex]::Match($uninstall_key, ".*\.\w*")
					$uninstall_key = $uninstall_key.Insert(0, '"')
					$uninstall_key = $uninstall_key.Insert($match.Length, '"')
				}
				$_cmd += "$uninstall_key $params"
			}
			return $_cmd
		}
		
		function remove_app() {
			$uninstall_key = $app.UninstallKey
			
			$_cmd = Get-RemoteCmd $ComputerName (get_cmd)
			Write-Verbose $_cmd
			try {
				$output_data = &cmd /c "`"$_cmd`" 2>&1" | % {
					if ([int]$_[1] -lt 32) { 
						$_ | ConvertTo-Encoding -From utf-16 -To cp866
					} else {
						$_ | ConvertTo-Encoding -From windows-1251 -To cp866
					}
				}
			} catch {}
			$return_value = $LastExitCode
		}
		
		$app_name = ""
		$output_data = @("")
		
		try {
			$current_principal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
			if ($ComputerName -eq $env:computername -and
				!$current_principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) { 
				throw "Для удаления приложения требуются права администратора"
			}
			
			$return_value = -1
			if(!(Test-Connection -ComputerName $ComputerName -Count 2 -ea 0)) { 
				throw "Компьютер $ComputerName не отвечает"
			}
			
			$app = Get-Program -ComputerName $ComputerName | ? { $_.GUID -eq $GUID }
			if ($app -eq $null) {
				throw "Приложения с GUID = $GUID нет в системе"
			}
			
			$app_name = $app.Name
			$before_uninstall_date = Get-Date
			if (
				$pscmdlet.ShouldProcess("$app_name на компьютере $ComputerName") -and
				($Force -or $pscmdlet.ShouldContinue("Удаление программы $app_name с компьютера $ComputerName", ""))
			) {
				Wait-InstallProgram $ComputerName
				Write-Verbose "Время запуска удаления: $before_uninstall_date"
				. remove_app
				Wait-InstallProgram $ComputerName
				Write-Verbose "Время завершения удаления: $(Get-Date)"
			} else {
				$return_value = 0
			}
			
			Write-Verbose "Получаем список событий, связанных с удалением"
			if ($PassThru) {
				$events = @(Get-EventLog -computername $ComputerName -LogName Application -Source MsiInstaller -After $before_uninstall_date)
				$event_message = @()
				foreach($i in $events) { $event_message += $i.message }
			}
			if ($return_value -ne 0) {
				throw "Не удалось удалить приложение $app_name." + ([String]::Join("`n", $output_data)) 
			}
		} catch {
			if ($exit_code -eq 0) {	$exit_code = -1 }
			Write-Error $_
		} finally {
			if ($PassThru) {
				$OutputObj = "" | Select ComputerName, GUID, Name, ReturnValue, Text, EventMessage, StartTime, EndTime
				$OutputObj.ComputerName = $ComputerName
				$OutputObj.GUID = $GUID
				$OutputObj.Name = $app_name
				$OutputObj.ReturnValue = $return_value
				if ($output_data -ne $null -and $output_data.Count -gt 0) { 
					$OutputObj.Text = $output_data[$output_data.Count-1]
				}
				$OutputObj.EventMessage = $event_message
				$OutputObj.StartTime = $before_uninstall_date.ToString()
				$OutputObj.EndTime = (Get-Date).ToString()
				
				$OutputObj
			}
		}
	}
	end {}
}


<# 
 .Synopsis
  Устанавливает программу из указанного источника.

 .Description
  Устанавливает программу из указанного источника. Инсталляция производится с тихом режиме, для этого используются ключи "/quiet /norestart /qn" для нестандартных установщиков и "/S /silent /quiet /norestart /q /qn" для msi-пакетов. Для инсталляторов, не поддерживающих выше указанные ключи, нужно установить параметры NoDefaultParams:$true и InstallParams с требуемыми ключами.
 
 .Parameter ComputerName
  Компьютер, на который требуется установить программу. Может использоваться для перадачи объектов по конвейеру.
 
 .Parameter ProgSource
  Путь к установщику программы. Может использоваться для перадачи объектов по конвейеру.

 .Parameter InstallParams
  Дополнительные параметры установки.
 
 .Parameter NoDefaultParams
  Использовать для установки только параметры из InstallParams.
  
 .Parameter Interactive
  Выводит окно установщика на рабочий стол удаленного компьютера.
  
 .Parameter Force
  Подавляет запрос на установку программы. Для дополнительных запросов можно использовать параметр Confirm.
 
 .Parameter PassThru
  Возвращает объекты, описывающие удаленные программы. По умолчанию эта функция не формирует никаких выходных данных.
 
 .Outputs
  PSObject. Содержит следующие параметры
  [string]ComputerName - имя компьютера
  [string]ProgSource   - файл инсталлятора
  [string]Name      - имя программы
  [string]Version   - версия приложения
  [string]GUID      - GUID приложения
  [string]Vendor    - вендор
  [int]ReturnValue  - результат выполнения
  [object[]]EventMessage - сообщения от MsiInstaller'а
  [string[]]OutputData   - текст, выводимый установщиком в стандартный поток вывода 
  [DateTime]StartTime - начало установки
  [DateTime]EndTime   - окончание установки
  
 .Example
   PS C:\> Install-Program testprogram

   Описание
   -----------
   Эта команда устанавливает программу "testprogram" на локальном компьютере.
   
 .Example
   PS C:\> cat computers.txt | Install-Program Name

   Описание
   -----------
   Эта команда устанавливает программу "Name" на компьютерах, указанных в файле "computers.txt".
 
 .Example
   PS C:\> "ComputerName, ProgSource
   >> comp1, prog1
   >> comp2, prog2 " | echo >install_apps.csv
   >>
   PS C:\> Import-Csv install_apps.csv | Install-Program

   Описание
   -----------
   Эта команда устанавливает программы, указанные в файле "install_apps.csv".
     
 .Link
   http://techibee.com/powershell/powershell-uninstall-software-on-remote-computer/1400
   
 .Link
   параметры NSIS http://nsis.sourceforge.net/Docs/Chapter3.html#3.2.1
   
#>
function Install-Program() 
{
	[cmdletbinding(SupportsShouldProcess=$True)]
	param(
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string]$ProgSource, 
		
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[Alias("CN","__SERVER","Computer","CNAME")]
		[string]$ComputerName = $env:computername, 
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$InstallParams = "", 
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Alias("UseOnlyInstallParams")]
		[switch]$NoDefaultParams,
		[switch][Alias("Visible")]$Interactive,
		[switch]$Force,
		[switch]$PassThru
	)
	begin {}
	process {	
		function get_cmd() {
			$_cmd = ""
			if ($Interactive) { $_cmd += "-i " }
			
			if ($file.Extension -ieq ".msi" -or $file.Extension -ieq ".msp") {
				if (!$NoDefaultParams) {
					$params = "/quiet /norestart /qn"
				}
				if ($file.Extension -ieq ".msi") {
					$install_type = "/i"
				} else {
					$install_type = "/update"
				}
				
				$_cmd += "msiexec $install_type `"$ProgSource`" $params $InstallParams"
			} elseif ($file.Extension -ieq ".msu") {
				if (!$NoDefaultParams) {
					$params = "/quiet /norestart"
				}
				
				$_cmd += "wusa `"$ProgSource`" $params $InstallParams"
				#ошибка 3010 сигнализирует о необходимости перезагрузки компьютера
			} else {
				if (!$NoDefaultParams) {
					$params = "/S /silent /quiet /norestart /q /qn /install"
				} 
				
				$_cmd += "`"$ProgSource`" $params $InstallParams"
			}
			return $_cmd
		}
		
		function add_program() {
			$_cmd = Get-RemoteCmd $ComputerName (get_cmd)
			Write-Verbose $_cmd
			try {
				$output_data = &cmd /c "`"$_cmd`" 2>&1" | % {
					if ([int]$_[1] -lt 32) { 
						$_ | ConvertTo-Encoding -From utf-16 -To cp866
					} else {
						$_ | ConvertTo-Encoding -From windows-1251 -To cp866
					}
				}
			} catch {}
			$exit_code = $LastExitCode
		}
		
		$exit_code = 0
		$output_data = @("")
		$before_install_date = Get-Date
		try {
			$current_principal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
			if ($ComputerName -eq $env:computername -and
				!$current_principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) { 
				throw "Для установки приложения требуются права администратора"
			}
			
			if(!(Test-Connection -ComputerName $ComputerName -Count 2 -ea 0)) { 
				throw "Компьютер $ComputerName не отвечает"
			}
			
			# устанавливаем
			$file = Get-Item $ProgSource
			$params = ""
			
			
			$before_install_state = Get-Program -ComputerName $ComputerName
			
			if (
				$pscmdlet.ShouldProcess("$ProgSource на компьютере $ComputerName") -and
				($Force -or $pscmdlet.ShouldContinue("Установка программы $ProgSource на компьютер $ComputerName", ""))
			) {	
				Wait-InstallProgram $ComputerName
				Write-Verbose "Время запуска установки: $before_install_date"
				. add_program
				Wait-InstallProgram $ComputerName
				Write-Verbose "Время завершения установки: $(Get-Date)"
			}
			if ($PassThru) {
				Write-Verbose "Получаем список программ"
				$after_install_state = Get-Program -ComputerName $ComputerName
				if ($before_install_state -eq $null) {
					$diff = @($after_install_state)
				} else {
					$diff = @(diff $before_install_state $after_install_state -Property Name, Version, Vendor, GUID | ? { $_.SideIndicator -eq "=>" } )
				}
				Write-Verbose "Получаем список событий, связанных с установкой"
				$events = @(Get-EventLog -computername $ComputerName -LogName Application -Source MsiInstaller -After $before_install_date -ErrorAction SilentlyContinue)
				$event_message = @()
				foreach($i in $events) { $event_message += $i.message }
			}
			if ($exit_code -ne 0 -and $exit_code -ne 3010) { throw "Произошла ошибка во время установки приложения $ProgSource." + ([String]::Join("`n", $output_data)) }
		} catch {
			if ($exit_code -eq 0) {	$exit_code = -1 }
			Write-Error $_
		} finally {
			if ($PassThru) {
				if ($diff) {
					foreach( $i in $diff) {
						$OutputObj = "" | select ComputerName, ProgSource, ReturnValue, EventMessage, OutputData, Name, Version, Vendor, GUID, StartTime, EndTime
						$OutputObj.ComputerName = $ComputerName
						$OutputObj.ProgSource = $ProgSource
						$OutputObj.ReturnValue = $exit_code
						$OutputObj.EventMessage = $event_message
						if ($output_data -ne $null -and $output_data.Count -gt 0) { 
							$OutputObj.OutputData = $output_data[$output_data.Count-1]
						}
						$OutputObj.Name = $i.Name
						$OutputObj.Version = $i.Version
						$OutputObj.Vendor = $i.Vendor
						$OutputObj.GUID = $i.GUID
						$OutputObj.StartTime = $before_install_date.ToString()
						$OutputObj.EndTime = (Get-Date).ToString()
						$OutputObj
					}
				} else {
					$OutputObj = "" | select ComputerName, ProgSource, ReturnValue, EventMessage, OutputData, StartTime, EndTime
					$OutputObj.ComputerName = $ComputerName
					$OutputObj.ProgSource = $ProgSource
					$OutputObj.ReturnValue = $exit_code
					$OutputObj.EventMessage = $event_message
					if ($output_data -ne $null -and $output_data.Count -gt 0) { 
						$OutputObj.OutputData = $output_data[$output_data.Count-1]
					}
					$OutputObj.StartTime = $before_install_date.ToString()
					$OutputObj.EndTime = (Get-Date).ToString()
				
					$OutputObj

				}
			}
		}
	}
	
	end {}
}
