<# 
 .Synopsis
  Возварщает список установленных программ.

 .Description
  Функция возвращает список всех программ, установленных на указанном компьютере.
 
  
 .Parameter ComputerName
  Компьютер, для которого требуется получить список программ, по умолчанию локальный. Может использоваться для перадачи объектов по конвейеру.
 
 .Parameter AppName
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
   PS C:\> Get-Program comp01 ^p

   Описание
   -----------
   Список программ на компьютере "comp01", название которых начинается с символа "p".
  
 .Example
   PS C:\> Get-Program comp01 "prog1", "prog2"
   
   Описание
   -----------
   Отобразит список программ на компьютере "comp01", названия которых совпадают с "prog1" и "prog2".
  
 .Link
   http://techibee.com/powershell/powershell-script-to-query-softwares-installed-on-remote-computer/1389
   
 .Link
   http://gallery.technet.microsoft.com/scriptcenter/519e1d3a-6318-4e3d-b507-692e962c6666
   
 .Link
   http://gallery.technet.microsoft.com/scriptcenter/Get-All-Installed-Software-73a07eba
 
#>
function Get-Program
{
	[cmdletbinding(DefaultParameterSetName="Match")]            
	param(            
		[parameter(position=0,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername,
		
		[parameter(position=1,Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="Name")]            
		[string[]]$AppName,
		
		[parameter(position=1,ValueFromPipelineByPropertyName=$true,ParameterSetName="Match")]
		[string]$AppMatch = ""
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
					
					$AppDisplayName  = $($AppDetails.GetValue("DisplayName"))    
					if($PSCmdlet.ParameterSetName -eq "Match" -and $AppDisplayName -notmatch $AppMatch ) { continue; }
					if($PSCmdlet.ParameterSetName -eq "Name" -and $AppName -notcontains $AppDisplayName ) { continue; }
					
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
				}            
			}            
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
  
 .Notes
  Удалить программу можно также с помощью Get-Program: (Get-Program kf-map09 7-zip).Uninstall()
  
 .Example
   PS C:\> Get-Program -AppName testprogram | Uninstall-Program 

   Описание
   -----------
   Эта команда удаляет программу "testprogram" на локальном компьютере.
   
 .Example
   PS C:\> cat computers.txt | Get-Program -AppName appname | Uninstall-Program -Confirm

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
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName = $env:computername,
		[parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string]$AppGUID,
		[switch]$Force
	)          
	
	begin {}
	process {
		try {
			$returnvalue = -1
			$app = Get-Program $ComputerName | ? { $_.AppGUID -eq $AppGUID }
			$appName = $app.AppName
			if ($pscmdlet.ShouldProcess("$appName на компьютере $ComputerName")) {
				if ($Force -or $pscmdlet.ShouldContinue("Удаление программы $appName на компьютере $ComputerName", "")) {
					$uninstall_key = $app.UninstallKey
					if( $uninstall_key -match "msiexec" -or $uninstall_key -eq $null )
					{    
						$returnval = ([WMICLASS]"\\$computerName\ROOT\CIMV2:win32_process").Create("msiexec `/x$AppGUID `/qn")
					} else {
						# сложный случай - не msi-пакет
						$returnval = ([WMICLASS]"\\$ComputerName\ROOT\CIMV2:win32_process").Create(
							"$uninstall_key /S /x /silent /uninstall /qn /quiet /norestart")
					}
					$returnvalue = $returnval.returnvalue
				}
			}
		} catch {
			write-error "Failed to trigger the uninstallation. Review the error message"
			$_
			exit
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
  Дополнительные параметры установки. Для дополнительных запросов можно использовать параметр Confirm.
 
 .Parameter UseOnlyInstallParams
  Использовать для установки только параметры из InstallParams. Для дополнительных запросов можно использовать параметр Confirm.
  
 .Outputs
  PSObject. Содержит следующие параметры
  ComputerName - имя компьютера
  ProgSource   - файл инсталлятора
  AppName      - имя программы
  AppVersion   - версия приложения
  AppGUID      - GUID приложения
  AppVendor    - вендор
  ReturnValue  - результат выполнения
  
 .Example
   PS C:\> Install-Program testprogram

   Описание
   -----------
   Эта команда устанавливает программу "testprogram" на локальном компьютере.
   
 .Example
   PS C:\> cat computers.txt | Install-Program -ProgSource appname

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
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName = $env:computername, 
		
		[parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string]$ProgSource, 
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]$InstallParams = "", 
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[switch]$UseOnlyInstallParams
	)
	begin {}
	process {
		
		$file = Get-Item $ProgSource
		$params = ""
		
		$before_install_state = Get-Program -ComputerName $ComputerName
		if( $file.Extension -ine ".msi") {
			if(!$UseOnlyInstallParams) {
				$params = "/S /silent /quiet /norestart /q /qn"
			} 
			&"$PSScriptRoot\..\..\Apps\psexec" -is \\$ComputerName $ProgSource $params $InstallParams 2>$null
		} else {
			if(!$UseOnlyInstallParams) {
				$params = "/quiet /norestart /qn"
			}
			&"$PSScriptRoot\..\..\Apps\psexec" -s \\$ComputerName msiexec /i $ProgSource $params $InstallParams 2>$null
		}
		Sleep 2
		$after_install_state = Get-Program -ComputerName $ComputerName
		$diff = @(diff $before_install_state $after_install_state -Property AppName, AppVersion, AppVendor, AppGUID)
		
		if ($diff) {
			foreach( $i in $diff) {
				$OutputObj = New-Object -TypeName PSobject             
				$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
				$OutputObj | Add-Member -MemberType NoteProperty -Name ProgSource -Value $ProgSource
				$OutputObj | Add-Member -MemberType NoteProperty -Name ReturnValue -Value $LastExitCode
			
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
			$OutputObj | Add-Member -MemberType NoteProperty -Name ReturnValue -Value $LastExitCode
			$OutputObj
		}
	}
	end {}
}
