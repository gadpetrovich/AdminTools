# требуется для работы start-removeservice и stop-removeservice
$null = [System.Reflection.Assembly]::LoadWithPartialName("System.ServiceProcess")


<# 
 .Synopsis
  Запускает службы на удаленном компьютере.

 .Description
  Функция Start-RemoteService запускает службы на удаленных компьютерах с помощью утилиты sc.exe. Если служба уже запущена, выдается предупреждение и команда игнорируется. 
 
 .Parameter ComputerName
  Компьютер, на котором требуется запустить службу. Может использоваться для перадачи объектов по конвейеру.
 
 .Parameter Name
  Имя запускаемой службы. Требуется указать имя службы (не допускается использование отображаемых имен). Может использоваться для перадачи объектов по конвейеру.

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
	Start-Service
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
			$status = @(Get-Service -ComputerName $computer -Name $service)
			if ($status.Length -lt 1) {
				throw "Неправильное имя сервиса: $service"
			}
			foreach($s in $status)
			{
				$result = "Cancelled"
				if ($s.Status -eq "Running") {
					Write-Warning ("Сервис " + $s.Name + " уже запущен")
					$result = "Running"
				} else {							
					if ($pscmdlet.ShouldProcess(($s.Name + " на компьютере $computer"))) {
						try {
							$s.Start()
							$respond = Get-Service -ComputerName $computer -Name $s.Name
							$result = $respond.Status
						} catch {
							Write-Error ("Не удалось запустить службу: " + $_)
						}
					}
				}
				$OutputObj = New-Object -TypeName PSobject             
				$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $computer
				$OutputObj | Add-Member -MemberType NoteProperty -Name Name -Value $s.Name
				$OutputObj | Add-Member -MemberType NoteProperty -Name Status -Value $result
				$OutputObj
			}
		}
		try {
			$ErrorActionPreference = "Stop"
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
			$er = New-Object System.Management.Automation.ErrorRecord($_.Exception, $_.FullyQualifiedErrorId, $_.CategoryInfo.Category, $_.TargetObject)
			$er.ErrorDetails = New-Object System.Management.Automation.ErrorDetails($_.tostring() + "`n" +  $_.InvocationInfo.PositionMessage)
			$pscmdlet.WriteError($er)
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
  Имя останавливаемой службы. Требуется указать имя службы (не допускается использование отображаемых имен). Может использоваться для перадачи объектов по конвейеру.

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
	Stop-Service
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
			$status = @(Get-Service -ComputerName $computer -Name $service)
			if ($status.Length -lt 1) {
				throw "Неправильное имя сервиса: $service"
			}
			foreach($s in $status)
			{
				$result = "Cancelled"
				if ($s.Status -eq "Stopped") {
					Write-Warning ("Сервис " + $s.Name + " уже остановлен")
					$result = "Stopped"
				} else {							
					if ($pscmdlet.ShouldProcess(($s.Name + " на компьютере $computer"))) {	
						try { 
							$a.Stop() 
							$respond = Get-Service -ComputerName $computer -Name $s.Name
							$result = $respond.Status
						} catch {
							Write-Error ("Не удалось остановить службу: " + $_)
						}
					}
				}
				$OutputObj = New-Object -TypeName PSobject             
				$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $computer
				$OutputObj | Add-Member -MemberType NoteProperty -Name Name -Value $s.Name
				$OutputObj | Add-Member -MemberType NoteProperty -Name Status -Value $result
				$OutputObj
			}
		}
		
		try {
			$ErrorActionPreference = "Stop"
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
			$er = New-Object System.Management.Automation.ErrorRecord($_.Exception, $_.FullyQualifiedErrorId, $_.CategoryInfo.Category, $_.TargetObject)
			$er.ErrorDetails = New-Object System.Management.Automation.ErrorDetails($_.tostring() + "`n" +  $_.InvocationInfo.PositionMessage)
			$pscmdlet.WriteError($er)
			
		}
	}
	end{}
}
