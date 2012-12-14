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
				Write-Verbose "Working on $Computer"            
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
						$AppGUID   = $App            
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
						
						$AppDetails.Close()
					}
				}	
				$HKLM.Close()
			}            
		} catch {
			write-error ($_.tostring() + "`n" +  $_.InvocationInfo.PositionMessage) -CategoryReason $_.CategoryInfo -ErrorId $_.FullyQualifiedErrorId
		}
	}            

	end {}
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
			$appName = $app.AppName
			if ($pscmdlet.ShouldProcess("$appName на компьютере $ComputerName")) {
				if ($Force -or $pscmdlet.ShouldContinue("Удаление программы $appName на компьютере $ComputerName", "")) {
					# проверяем, запущены ли процессы установки/удаления
					$msiserver = Get-Service -ComputerName $ComputerName -Name msiserver
					if ($msiserver.Status -ne "Running") { $msiserver.Start(); sleep 2 }
					while (@(Get-Process msiexec -ComputerName $ComputerName).Count -gt 1){ 
						Write-Verbose "Ждем, когда завершатся процессы установки/удаления, запущенные ранее на этом компьютере"; Sleep 2 
					}
					# удаляем
					$before_uninstall_date = Get-Date
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
					$msiserver = Get-Service -ComputerName $ComputerName -Name msiserver
					if ($msiserver.Status -ne "Running") { $msiserver.Start(); sleep 2 }
					while (@(Get-Process msiexec -ComputerName $ComputerName).Count -gt 1){ Sleep 2 }
				}
			}
			
			Write-Verbose "Получаем список событий, связанных с удалением"
			$events = @(Get-EventLog -computername $ComputerName -LogName Application -Source MsiInstaller -After $before_uninstall_date)
			$event_message = @()
			foreach($i in $events) { $event_message += $i.message }
		} catch {
			write-error ($_.tostring() + "`n" +  $_.InvocationInfo.PositionMessage) -CategoryReason $_.CategoryInfo -ErrorId $_.FullyQualifiedErrorId
		}
		switch ($($returnvalue)){
			-1 { $txt = "Canceled" }
			0 { $txt = "Uninstallation command triggered successfully" }
			2 { $txt = "You don't have sufficient permissions to trigger the command on $Computer" }
			3 { $txt = "You don't have sufficient permissions to trigger the command on $Computer" }
			8 { $txt = "An unknown error has occurred" }
			9 { $txt = "Path Not Found" }
			21 { $txt = "Invalid Parameter"}
		}
		
		
		$OutputObj = New-Object -TypeName PSobject     
		$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
		$OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value $AppGUID
		$OutputObj | Add-Member -MemberType NoteProperty -Name AppName -Value $appName
		$OutputObj | Add-Member -MemberType NoteProperty -Name ReturnValue -Value $returnvalue
		$OutputObj | Add-Member -MemberType NoteProperty -Name Text -Value $txt
		$OutputObj | Add-Member -MemberType NoteProperty -Name EventMessage -Value $event_message
		$OutputObj
		
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
			$msiserver = Get-Service -ComputerName $ComputerName -Name msiserver
			if ($msiserver.Status -ne "Running") { $msiserver.Start(); sleep 2 }
			while (@(Get-Process msiexec -ComputerName $ComputerName).Count -gt 1){ 
				Write-Verbose "Ждем, когда завершатся процессы установки/удаления, запущенные ранее на этом компьютере"; Sleep 2 
			}
			# устанавливаем
			$file = Get-Item $ProgSource
			$params = ""
			
			$before_install_date = Get-Date
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
			Write-Verbose "Ждем, когда завершатся процессы установки"
			$msiserver = Get-Service -ComputerName $ComputerName -Name msiserver
			if ($msiserver.Status -ne "Running") { $msiserver.Start() }
			while (@(Get-Process msiexec -ComputerName $ComputerName).Count -gt 1){ Sleep 2 }
		
			Write-Verbose "Получаем список программ"
			$after_install_state = Get-Program -ComputerName $ComputerName
			$diff = @(diff $before_install_state $after_install_state -Property AppName, AppVersion, AppVendor, AppGUID | ? { $_.SideIndicator -eq "=>" } )
			
			Write-Verbose "Получаем список событий, связанных с установкой"
			$events = @(Get-EventLog -computername $ComputerName -LogName Application -Source MsiInstaller -After $before_install_date)
			$event_message = @()
			foreach($i in $events) { $event_message += $i.message }
			
		} catch {
			$exit_code = -1
			write-error ($_.tostring() + "`n" +  $_.InvocationInfo.PositionMessage) -CategoryReason $_.CategoryInfo -ErrorId $_.FullyQualifiedErrorId
		}
		
		
		if ($diff) {
			foreach( $i in $diff) {
				$OutputObj = New-Object -TypeName PSobject             
				$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
				$OutputObj | Add-Member -MemberType NoteProperty -Name ProgSource -Value $ProgSource
				$OutputObj | Add-Member -MemberType NoteProperty -Name ReturnValue -Value $exit_code
				$OutputObj | Add-Member -MemberType NoteProperty -Name EventMessage -Value $event_message
				$OutputObj | Add-Member -MemberType NoteProperty -Name OutputData -Value $output_data
				
				$OutputObj | Add-Member -MemberType NoteProperty -Name AppName -Value $i.AppName
				$OutputObj | Add-Member -MemberType NoteProperty -Name AppVersion -Value $i.AppVersion
				$OutputObj | Add-Member -MemberType NoteProperty -Name AppVendor -Value $i.AppVendor
				$OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value $i.AppGUID
				$OutputObj
			}
		} else {
			$OutputObj = New-Object -TypeName PSobject             
			$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
			$OutputObj | Add-Member -MemberType NoteProperty -Name ProgSource -Value $ProgSource
			$OutputObj | Add-Member -MemberType NoteProperty -Name ReturnValue -Value $exit_code
			$OutputObj | Add-Member -MemberType NoteProperty -Name EventMessage -Value $event_message
			$OutputObj | Add-Member -MemberType NoteProperty -Name OutputData -Value $output_data
			
			$OutputObj
		}
	}
	
	end {}
}
