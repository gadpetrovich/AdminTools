# ��������� ��� ������ start-removeservice � stop-removeservice
$null = [System.Reflection.Assembly]::LoadWithPartialName("System.ServiceProcess")


<# 
 .Synopsis
  ��������� ������ �� ��������� ����������.

 .Description
  ������� Start-RemoteService ��������� ������ �� ��������� ����������� � ������� ������� sc.exe. ���� ������ ��� ��������, �������� �������������� � ������� ������������. 
 
 .Parameter ComputerName
  ���������, �� ������� ��������� ��������� ������. ����� �������������� ��� �������� �������� �� ���������.
 
 .Parameter Name
  ��� ����������� ������. ��������� ������� ������ ��� ������ (�� ����������� ������������� ������������ ����). ����� �������������� ��� �������� �������� �� ���������.

 .Parameter InputObject
  ������ ������� ServiceController, �������������� ����������� ������. ������� ����������, ���������� �������, ���� ������� ��� ��������� ��� ��������� ��������.
  
 .Outputs
  ������������ ����:
  ComputerName - ��� ����������
  Name         - ��� ������
  Status       - ��������� ���������� �������
  
 .Example
   PS C:\> start-remoteservice -name msiserver -computername pc-remote

   ��������
   -----------
   ��� ������� ��������� ������ "msiserver" �� ���������� "pc-remote".
   
 .Example
   PS C:\> $a = get-service servicename -ComputerName pc-remote 
   
   PS C:\> start-remoteservice -InputObject $a

   ��������
   -----------
   ����������� ������� ��������� �� ���������� "pc-remote" ������ "servicename".
 
 .Example
   PS C:\> $a = get-service servicename -ComputerName pc-remote | start-remoteservice 

   ��������
   -----------
   ����������� ������� ��������� �� ���������� "pc-remote" ������ "servicename".  
 
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
			$status = &sc.exe \\$computer query $service
			if ($status.Length -lt 5) {
				throw "������������ ��� �������: $service"
			}
			
			$result = "Cancelled"
			if ($status[3] -ilike "*running*") {
				Write-Warning "������ $service ��� �������"
				$result = "RUNNING"
			} else {							
				if ($pscmdlet.ShouldProcess("$service �� ���������� $computer")) {
					$respond = &sc.exe \\$computer start $service
					if ($respond.Length -lt 5) {
						$result = "Error"
						Write-Error "�� ������� ��������� ������"
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
						Write-Verbose ("��������� " + $i.MachineName)
		              	if(!(Test-Connection -ComputerName $i.MachineName -Count 1 -ea 0)) { throw "��������� " + $i.MachineName + " ����������"}
		                		                
                        func $i.ServiceName $i.MachineName
					}
				} 
				"Normal" { 
					foreach($computer in $ComputerName) {
                        Write-Verbose "��������� $Computer"            
		              	if(!(Test-Connection -ComputerName $Computer -Count 1 -ea 0)) { throw "��������� $computer ����������"}
		                			
						foreach($service in $Name) {
                            if ($service -eq "" -or $service -eq $null) {
                				throw "�� ������� ��� �������"
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
  ������������� ������ �� ��������� ����������.

 .Description
  ������� Stop-RemoteService ������������� ������ �� ��������� ����������� � ������� ������� sc.exe. ���� ������ ��� �����������, �������� �������������� � ������� ������������. 
 
 .Parameter ComputerName
  ���������, �� ������� ��������� ���������� ������. ����� �������������� ��� �������� �������� �� ���������.
 
 .Parameter Name
  ��� ��������������� ������. ��������� ������� ������ ��� ������ (�� ����������� ������������� ������������ ����). ����� �������������� ��� �������� �������� �� ���������.

 .Parameter InputObject
  ������ ������� ServiceController, �������������� ��������������� ������. ������� ����������, ���������� �������, ���� ������� ��� ��������� ��� ��������� ��������.
  
 .Outputs
  ������������ ����:
  ComputerName - ��� ����������
  Name         - ��� ������
  Status       - ��������� ���������� �������
  
 .Example
   PS C:\> stop-remoteservice -name msiserver -computername pc-remote

   ��������
   -----------
   ��� ������� ������������� ������ "msiserver" �� ���������� "pc-remote".
   
 .Example
   PS C:\> $a = get-service servicename -ComputerName pc-remote 
   
   PS C:\> stop-remoteservice -InputObject $a

   ��������
   -----------
   ����������� ������� ������������� �� ���������� "pc-remote" ������ "servicename".
 
 .Example
   PS C:\> $a = get-service servicename -ComputerName pc-remote | start-remoteservice 

   ��������
   -----------
   ����������� ������� ������������� �� ���������� "pc-remote" ������ "servicename".  
  
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
			$status = &sc.exe \\$computer query $service
			if ($status.Length -lt 5) {
				throw "������������ ��� �������: $service"
			}
			
			$result = "Cancelled"
			if ($status[3] -ilike "*stopped*") {
				Write-Warning "������ $service ��� ����������"
				$result = "STOPPED"
			} else {							
				if ($pscmdlet.ShouldProcess("$service �� ���������� $computer")) {						
					$respond = &sc.exe \\$computer stop $service
					if ($respond.Length -lt 5) {
						$result = "Error"
						Write-Error "�� ������� ���������� ������"
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
						Write-Verbose ("��������� " + $i.MachineName)
		              	if(!(Test-Connection -ComputerName $i.MachineName -Count 1 -ea 0)) { throw "��������� " + $i.MachineName + " ����������"}
		                
                        func $i.ServiceName $i.MachineName
					}
				} 
				"Normal" { 
					foreach($computer in $ComputerName) {
                        Write-Verbose "��������� $Computer"            
		              	if(!(Test-Connection -ComputerName $Computer -Count 1 -ea 0)) { throw "��������� $computer ����������"}
		                			
						foreach($service in $Name) {
                            if ($service -eq "" -or $service -eq $null) {
                				throw "�� ������� ��� �������"
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
