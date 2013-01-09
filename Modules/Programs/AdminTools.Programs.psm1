<# 
 .Synopsis
  Возварщает список установленных программ.

 .Description
  Функция возвращает список всех программ, установленных на указанном компьютере.
 
  
 .Parameter ComputerName
  Компьютер, для которого требуется получить список программ, по умолчанию локальный. Может использоваться для перадачи объектов по конвейеру.
 
 .Parameter AppMatch
  Регулярное выражения для поиска программы по ее названию. Может использоваться для перадачи объектов по конвейеру.

 .Outputs
  Возвращаемые поля:
  AppName
  AppVersion
  AppVendor
  InstalledDate
  UninstallKey
  AppGUID
  
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
		[parameter(position=1,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername,
		
		[parameter(position=0,ValueFromPipelineByPropertyName=$true)]
		[string]$AppMatch = ""
	)            

	begin {}            

	process {            
		try
		{
			foreach($Computer in $ComputerName) {            
				Write-Verbose "Берем список программ из $Computer"            
				if(!(Test-Connection -ComputerName $Computer -Count 1 -ea 0)) { continue }
				
				$HKLM   = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computer)
				$UninstallRegKeys=@("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
				if ($HKLM.OpenSubKey("SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall") -ne $null) {
					$UninstallRegKeys += "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
				}
				foreach ($UninstallRegKey in $UninstallRegKeys)
				{
					$UninstallRef  = $HKLM.OpenSubKey($UninstallRegKey)            
					$Applications = $UninstallRef.GetSubKeyNames()            

					foreach ($App in $Applications) {            
						$AppRegistryKey  = $UninstallRegKey + "\\" + $App            
						$AppDetails   = $HKLM.OpenSubKey($AppRegistryKey)            
						
						$AppDisplayName  = $($AppDetails.GetValue("DisplayName"))    
						if($AppDisplayName -notmatch $AppMatch ) { continue; }
						
						$AppVersion   = $($AppDetails.GetValue("DisplayVersion"))            
						$AppPublisher  = $($AppDetails.GetValue("Publisher"))            
						$AppInstalledDate = $($AppDetails.GetValue("InstallDate"))            
						$AppUninstall  = $($AppDetails.GetValue("UninstallString"))            
						$AppGUID = $App            
						if(!$AppDisplayName) { continue }            
						$OutputObj = "" | select ComputerName, AppName, AppVersion, AppVendor, InstalledDate, UninstallKey, AppGUID
						$OutputObj.ComputerName = $Computer.ToUpper()            
						$OutputObj.AppName = $AppDisplayName            
						$OutputObj.AppVersion = $AppVersion            
						$OutputObj.AppVendor = $AppPublisher            
						$OutputObj.InstalledDate = $AppInstalledDate            
						$OutputObj.UninstallKey = $AppUninstall            
						$OutputObj.AppGUID = $AppGUID            
						$OutputObj# | Select ComputerName, DriveName            
						
						$AppDetails.Close()
					}
				}	
				$HKLM.Close()
			}            
		} catch {
			
			write-error ($_.tostring() + "`nВозможно у вас нет права доступа к удаленному реестру:  http://support.microsoft.com/kb/892192/ru`n" +  $_.InvocationInfo.PositionMessage) -CategoryReason $_.CategoryInfo -ErrorId $_.FullyQualifiedErrorId
		}
	}            

	end {}
}

function Wait-InstallProgram ([string]$ComputerName = $env:computername)
{
	$msiserver = Get-Service -ComputerName $ComputerName -Name msiserver
	if ($msiserver.Status -ne "Running") { $msiserver.Start(); sleep 2 }
	while (
		@(Get-Process msiexec -ComputerName $ComputerName -ErrorAction:SilentlyContinue).Count -gt 1 -or 
		(get-process *nsis* -ComputerName $ComputerName -ErrorAction:SilentlyContinue)
	){ Sleep 2 }
}

function Wait-WMIRestartComputer
{
	param(
		[parameter(position=0,ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName,
		[parameter(position=1,ValueFromPipelineByPropertyName=$true)]
		[int]$WaitSecPeriod = 10, 
		[parameter(position=2,ValueFromPipelineByPropertyName=$true)]
		[int]$SecTimeout = 300
	)

	$before = Get-Date
	# ждем, когда wmi вырубится
	Write-Verbose "Запуск ожидания отключения WMI, время: $before"
	while(Get-WmiObject -class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction silentlycontinue) {
		if ( ((Get-Date)-$before).TotalSeconds -gt $SecTimeout ) {
			Write-Error "Истекло время ожидания на остановку WMI."
		}
		Sleep $WaitSecPeriod
	}
	$before = Get-Date
	# ждем, когда wmi заработает
	Write-Verbose "Запуск ожидания включения WMI, время: $before"
	while(-not (Get-WmiObject -class Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction silentlycontinue)) {
		if ( ((Get-Date)-$before).TotalSeconds -gt $SecTimeout ) {
			Write-Error "Истекло время ожидания на остановку WMI."
		}
		Sleep $WaitSecPeriod
	}
	Write-Verbose "Перезагрузка завершена: $(Get-Date)"
}


<# 
 .Synopsis
  Удаляет указанную программу.

 .Description
  Удаляет программу, указанную в параметре AppGUID. Деинсталляция производится с тихом режиме, для этого используются ключи "/S /x /silent /uninstall /qn /quiet /norestart" для нестандартных установщиков и "/qn" для msi-пакетов.
 
  
 .Parameter ComputerName
  Компьютер, на котором требуется удалить программу. Может использоваться для перадачи объектов по конвейеру.
 
 .Parameter AppGUID
  Guid деинсталлируемой программы. Может использоваться для перадачи объектов по конвейеру.

 .Parameter Force
  Подавляет запрос на удаление программы. Для дополнительных запросов можно использовать параметр Confirm.
 
 .Outputs
  PSObject. Содержит следующие параметры
  ComputerName - имя компьютера
  AppName      - имя программы
  AppGUID      - GUID приложения
  ReturnValue  - результат выполнения
  Text         - результат выполнения в текстовом виде
  EventMessage - сообщение от MsiInstaller'а
  StartTime - начало удаления
  EndTime   - окончание удаления
  
 .Notes
  Удалить программу можно также с помощью Get-Program: (Get-Program 7-zip computername).Uninstall()
  
 .Example
   PS C:\> Get-Program testprogram | Uninstall-Program 

   Описание
   -----------
   Эта команда удаляет программу "testprogram" на локальном компьютере.
   
 .Example
   PS C:\> cat computers.txt | Get-Program appname | Uninstall-Program -Confirm

   Описание
   -----------
   Эта команда удаляет программу "appname" на компьютерах, указанных в файле "computers.txt".
 
 .Example
   PS C:\> "ComputerName, AppName
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
		[string]$AppGUID,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName = $env:computername,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[switch]$EmptyDefaultParams,
		[switch]$Force
	)          
	
	begin {}
	process {
		try {
			$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
			if (!$currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) 
			{ 
				throw "Для удаления приложения требуются права администратора"
			}

			$returnvalue = -1
			$app = Get-Program -ComputerName $ComputerName | ? { $_.AppGUID -eq $AppGUID }
			if ($app -eq $null) {
				throw "Приложения с GUID = $AppGUID нет в системе"
			}
			
			$appName = $app.AppName
			if ($pscmdlet.ShouldProcess("$appName на компьютере $ComputerName")) {
				if ($Force -or $pscmdlet.ShouldContinue("Удаление программы $appName на компьютере $ComputerName", "")) {
					# проверяем, запущены ли процессы установки/удаления
					Write-Verbose "Ждем, когда завершатся процессы установки/удаления, запущенные ранее на этом компьютере"; 
					Wait-InstallProgram $ComputerName
					# удаляем
					$before_uninstall_date = Get-Date
					Write-Verbose "Время запуска удаления: $before_uninstall_date"
					$uninstall_key = $app.UninstallKey
					if ($uninstall_key -match "msiexec" -or $uninstall_key -eq $null) 
					{
						$params = "/x `"$AppGUID`" "
						if (!$EmptyDefaultParams) {
							$params += "/qn"
						}
						
						$_cmd = "`"$PSScriptRoot\..\..\Apps\psexec`" -s \\$ComputerName msiexec $params"
					} else {
						if (!$EmptyDefaultParams) {
							$params = "/S /x /silent /uninstall /qn /quiet /norestart"
						} 
						
						$_cmd = "`"$PSScriptRoot\..\..\Apps\psexec`" -is \\$ComputerName `"$uninstall_key`" $params"
					}
					Write-Verbose $_cmd
					$output_date = &cmd /c "`"$_cmd`"" 2>$null
					$returnvalue = $LastExitCode
					
					# ждем завершения
					Write-Verbose "Ждем, когда завершатся процессы удаления"
					Wait-InstallProgram $ComputerName
					Write-Verbose "Время завершения удаления: $(Get-Date)"
				}
			}
			
			Write-Verbose "Получаем список событий, связанных с удалением"
			$events = @(Get-EventLog -computername $ComputerName -LogName Application -Source MsiInstaller -After $before_uninstall_date)
			$event_message = @()
			foreach($i in $events) { $event_message += $i.message }
			
			if ($returnvalue -ne 0) {
				throw "Не удалось удалить приложение $appName"
			}
		} catch {
			write-error ($_.tostring() + "`n" +  $_.InvocationInfo.PositionMessage) -CategoryReason $_.CategoryInfo -ErrorId $_.FullyQualifiedErrorId
			
		} finally {
			switch ($($returnvalue)){
				-1 { $txt = "Canceled" }
				0 { $txt = "Uninstallation command triggered successfully" }
				2 { $txt = "You don't have sufficient permissions to trigger the command on $Computer" }
				3 { $txt = "You don't have sufficient permissions to trigger the command on $Computer" }
				8 { $txt = "An unknown error has occurred" }
				9 { $txt = "Path Not Found" }
				21 { $txt = "Invalid Parameter"}
			}
			
			
			$OutputObj = "" | Select ComputerName, AppGUID, AppName, ReturnValue, Text, EventMessage, StartTime, EndTime
			$OutputObj.ComputerName = $ComputerName
			$OutputObj.AppGUID = $AppGUID
			$OutputObj.AppName = $appName
			$OutputObj.ReturnValue = $returnvalue
			$OutputObj.Text = $txt
			$OutputObj.EventMessage = $event_message
			$OutputObj.StartTime = $before_uninstall_date.ToString()
			$OutputObj.EndTime = (Get-Date).ToString()
			
			$OutputObj
		}
	}
	end {}
}


<# 
 .Synopsis
  Устанавливает программу из указанного источника.

 .Description
  Устанавливает программу из указанного источника. Инсталляция производится с тихом режиме, для этого используются ключи "/quiet /norestart /qn" для нестандартных установщиков и "/S /silent /quiet /norestart /q /qn" для msi-пакетов. Для инсталляторов, не поддерживающих выше указанные ключи, нужно установить параметры UseOnlyInstallParams:$true и InstallParams с требуемыми ключами.
 
 .Parameter ComputerName
  Компьютер, на который требуется установить программу. Может использоваться для перадачи объектов по конвейеру.
 
 .Parameter ProgSource
  Путь к установщику программы. Может использоваться для перадачи объектов по конвейеру.

 .Parameter InstallParams
  Дополнительные параметры установки.
 
 .Parameter UseOnlyInstallParams
  Использовать для установки только параметры из InstallParams.
  
 .Outputs
  PSObject. Содержит следующие параметры
  ComputerName - имя компьютера
  ProgSource   - файл инсталлятора
  AppName      - имя программы
  AppVersion   - версия приложения
  AppGUID      - GUID приложения
  AppVendor    - вендор
  ReturnValue  - результат выполнения
  EventMessage - сообщение от MsiInstaller'а
  OutputData   - текст, выводимый установщиком в стандартный поток вывода 
  StartTime - начало установки
  EndTime   - окончание установки
  
 .Example
   PS C:\> Install-Program testprogram

   Описание
   -----------
   Эта команда устанавливает программу "testprogram" на локальном компьютере.
   
 .Example
   PS C:\> cat computers.txt | Install-Program appname

   Описание
   -----------
   Эта команда устанавливает программу "appname" на компьютерах, указанных в файле "computers.txt".
 
 .Example
   PS C:\> "ComputerName, ProgSource
   >> comp1, prog1
   >> comp2, prog2 " | echo >install_apps.csv
   >>
   PS C:\> Import-Csv install_apps.csv | Install-Program

   Описание
   -----------
   Эта команда устанавливает программы, указанные в файле "remove_apps.csv".
     
 .Link
   http://techibee.com/powershell/powershell-uninstall-software-on-remote-computer/1400
   
 .Link
   параметры NSIS http://nsis.sourceforge.net/Docs/Chapter3.html#3.2.1
   
#>
function Install-Program() 
{
	[cmdletbinding()]
	param(
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string]$ProgSource, 
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName = $env:computername, 
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$InstallParams = "", 
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[switch]$UseOnlyInstallParams
	)
	begin {}
	process {
		try {
			
			$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
			if (!$currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) 
			{ 
				throw "Для установки приложения требуются права администратора"
			}
			# проверяем, запущены ли процессы установки/удаления
			Write-Verbose "Ждем, когда завершатся процессы установки/удаления, запущенные ранее на этом компьютере";
			Wait-InstallProgram $ComputerName
			# устанавливаем
			$file = Get-Item $ProgSource
			$params = ""
			
			$before_install_date = Get-Date
			Write-Verbose "Время запуска установки: $before_install_date"
			$before_install_state = Get-Program -ComputerName $ComputerName
			if ($file.Extension -ieq ".msi" -or $file.Extension -ieq ".msp") 
			{
				if (!$UseOnlyInstallParams) {
					$params = "/quiet /norestart /qn"
				}
				if ($file.Extension -ieq ".msi") {
					$install_type = "/i"
				} else {
					$install_type = "/update"
				}
				
				$_cmd = "`"$PSScriptRoot\..\..\Apps\psexec`" -s \\$ComputerName msiexec $install_type `"$ProgSource`" $params $InstallParams"
			} else {
				if (!$UseOnlyInstallParams) {
					$params = "/S /silent /quiet /norestart /q /qn"
				} 
				
				$_cmd = "`"$PSScriptRoot\..\..\Apps\psexec`" -is \\$ComputerName `"$ProgSource`" $params $InstallParams"
			}
			Write-Verbose $_cmd
			$output_date = &cmd /c "`"$_cmd`"" 2>$null
			$exit_code = $LastExitCode
			
			#ждем завершения
			Wait-InstallProgram $ComputerName
			Write-Verbose "Время завершения установки: $(Get-Date)"
		
			Write-Verbose "Получаем список программ"
			$after_install_state = Get-Program -ComputerName $ComputerName
			$diff = @(diff $before_install_state $after_install_state -Property AppName, AppVersion, AppVendor, AppGUID | ? { $_.SideIndicator -eq "=>" } )
			
			Write-Verbose "Получаем список событий, связанных с установкой"
			$events = @(Get-EventLog -computername $ComputerName -LogName Application -Source MsiInstaller -After $before_install_date)
			$event_message = @()
			foreach($i in $events) { $event_message += $i.message }
			
			if ($exit_code -ne 0) { throw "Произошла ошибка во время установки приложения $ProgSource" }
		} catch {
			if ($exit_code -ne 0) {	$exit_code = -1 }
			write-error ($_.tostring() + "`n" +  $_.InvocationInfo.PositionMessage) -CategoryReason $_.CategoryInfo -ErrorId $_.FullyQualifiedErrorId
			
		} finally {
		
			if ($diff) {
				foreach( $i in $diff) {
					$OutputObj = "" | select ComputerName, ProgSource, ReturnValue, EventMessage, OutputData, AppName, AppVersion, AppVendor, AppGUID, StartTime, EndTime
					$OutputObj.ComputerName = $ComputerName
					$OutputObj.ProgSource = $ProgSource
					$OutputObj.ReturnValue = $exit_code
					$OutputObj.EventMessage = $event_message
					$OutputObj.OutputData = $output_data
					
					$OutputObj.AppName = $i.AppName
					$OutputObj.AppVersion = $i.AppVersion
					$OutputObj.AppVendor = $i.AppVendor
					$OutputObj.AppGUID = $i.AppGUID
					$OutputObj.StartTime = $before_install_date.ToString()
					$OutputObj.EndTime = (Get-Date).ToString()
					$OutputObj
				}
			} else {
				$OutputObj = "" | select ComputerName, ProgSource, ProgSource, ReturnValue, EventMessage, OutputData, StartTime, EndTime
				$OutputObj.ComputerName = $ComputerName
				$OutputObj.ProgSource = $ProgSource
				$OutputObj.ReturnValue = $exit_code
				$OutputObj.EventMessage = $event_message
				$OutputObj.OutputData = $output_data
				$OutputObj.StartTime = $before_install_date.ToString()
				$OutputObj.EndTime = (Get-Date).ToString()
			
				$OutputObj

			}
		}
	}
	
	end {}
}
