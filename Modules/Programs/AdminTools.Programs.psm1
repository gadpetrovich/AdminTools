<# 
 .Synopsis
  ���������� ������ ������������� ��������.

 .Description
  ������� ���������� ������ ���� ��������, ������������� �� ��������� ����������.
 
  
 .Parameter ComputerName
  ���������, ��� �������� ��������� �������� ������ ��������, �� ��������� ���������. ����� �������������� ��� �������� �������� �� ���������.
 
 .Parameter AppName
  ���������� ��������� ��� ������ ��������� �� �� ��������. ����� �������������� ��� �������� �������� �� ���������.

 .Outputs
  ������������ ����:
  AppName
  AppVersion
  AppVendor
  InstalledDate
  UninstallKey
  AppGUID
  
 .Example
   PS C:\> Get-Program

   ��������
   -----------
   ��������� ��� ��������� �� ��������� ����������.
   
 .Example
   PS C:\> Get-Program comp01 ^p

   ��������
   -----------
   ������ �������� �� ���������� "comp01", �������� ������� ���������� � ������� "p".
  
 .Example
   PS C:\> Get-Program comp01 "prog1", "prog2"
   
   ��������
   -----------
   ��������� ������ �������� �� ���������� "comp01", �������� ������� ��������� � "prog1" � "prog2".
  
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
		[parameter(position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername,
		
		[parameter(position=1,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="Name")]            
		[string[]]$AppName,
		
		[parameter(position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="Match")]
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
  ������� ��������� ���������.

 .Description
  ������� ���������, ��������� � ��������� AppGUID. ������������� ������������ � ����� ������, ��� ����� ������������ ����� "/S /x /silent /uninstall /qn /quiet /norestart" ��� ������������� ������������ � "/qn" ��� msi-�������.
 
  
 .Parameter ComputerName
  ���������, �� ������� ��������� ������� ���������. ����� �������������� ��� �������� �������� �� ���������.
 
 .Parameter AppGUID
  Guid ���������������� ���������. ����� �������������� ��� �������� �������� �� ���������.

 .Parameter Force
  ��������� ������ �� �������� ���������. ��� �������������� �������� ����� ������������ �������� Confirm.
 
 .Outputs
  PSObject. �������� ��������� ���������
  ComputerName - ��� ����������
  AppName      - ��� ���������
  AppGUID      - GUID ����������
  ReturnValue  - ��������� ����������
  Text         - ��������� ���������� � ��������� ����
  
 .Notes
  ������� ��������� ����� ����� � ������� Get-Program: (Get-Program kf-map09 7-zip).Uninstall()
  
 .Example
   PS C:\> Get-Program -AppName testprogram | Uninstall-Program 

   ��������
   -----------
   ��� ������� ������� ��������� "testprogram" �� ��������� ����������.
   
 .Example
   PS C:\> cat computers.txt | Get-Program -AppName appname | Uninstall-Program -Confirm

   ��������
   -----------
   ��� ������� ������� ��������� "appname" �� �����������, ��������� � ����� "computers.txt".
 
 .Example
   PS C:\> "ComputerName, AppName
   >> comp1, prog1
   >> comp2, prog2 " | echo >remove_apps.csv
   >>
   PS C:\> Import-Csv remove_apps.csv | Get-Program | Uninstall-Program

   ��������
   -----------
   ��� ������� ������� ���������, ��������� � ����� "remove_apps.csv".
     
 .Link
   http://techibee.com/powershell/powershell-uninstall-software-on-remote-computer/1400
   
 .Link
   ��������� NSIS http://nsis.sourceforge.net/Docs/Chapter3.html#3.2.1
   
#>
function Uninstall-Program
{
	[cmdletbinding(SupportsShouldProcess=$True)]            
	param (            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[string]$ComputerName = $env:computername,
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
		[string]$AppGUID,
		[switch]$Force
	)          
	
	begin {}
	process {
		try {
			$returnvalue = -1
			$app = Get-Program $ComputerName | ? { $_.AppGUID -eq $AppGUID }
			$appName = $app.AppName
			if ($pscmdlet.ShouldProcess("$appName �� ���������� $ComputerName")) {
				if ($Force -or $pscmdlet.ShouldContinue("�������� ��������� $appName �� ���������� $ComputerName", "")) {
					$uninstall_key = $app.UninstallKey
					if( $uninstall_key -match "msiexec" -or $uninstall_key -eq $null )
					{    
						$returnval = ([WMICLASS]"\\$computerName\ROOT\CIMV2:win32_process").Create("msiexec `/x$AppGUID `/qn")
					} else {
						# ������� ������ - �� msi-�����
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
