

<# 
 .Synopsis
  ���������� ������ ������������� ��������.

 .Description
  ������� ���������� ������ ��������, ������������� � ������� msi.
 
  
 .Parameter ComputerName
  ���������, ��� �������� ��������� �������� ������ ��������, �� ��������� ���������.

 .Parameter ProgMatch
  ���������� ��������� ��� ������ ����������� ���������.

 .Outputs
  System.Management.ManagementObject#root\cimv2\Win32_Product. 
  ��������� �� ������������ �����:
  IdentifyingNumber
  Vendor
  Version
  Caption
 
 .Example
   # ���������� ��� ��������� �� ��������� ����������.
   Get-Program

 .Example
   # ������ �������� �� ���������� "comp01", �������� ������� ���������� � ������� "p".
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
   PS C:\> Get-InstalledSoftware

   ��������
   -----------
   ���������� ��� ��������� �� ��������� ����������.
   
 .Example
   PS C:\> Get-InstalledSoftware -ComputerName comp01 -AppName "^p" 

   ��������
   -----------
   ������ �������� �� ���������� "comp01", �������� ������� ���������� � ������� "p".
   
 .Link
   http://techibee.com/powershell/powershell-script-to-query-softwares-installed-on-remote-computer/1389
   
 .Link
   http://gallery.technet.microsoft.com/scriptcenter/519e1d3a-6318-4e3d-b507-692e962c6666
   
 .Link
   http://gallery.technet.microsoft.com/scriptcenter/Get-All-Installed-Software-73a07eba
 
#>
function Get-InstalledSoftware
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername,
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string]$AppName = ""
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
					if($AppDisplayName -notmatch $AppName ) { continue; }
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
  ������� ���������, ��������� � ��������� AppGUID. ������������� ������������ � ����� ������, ��� ����� ������������ ����� "/S /x /silent /uninstall /qn /quiet" ��� ������������� ������������ � "/qn" ��� msi-�������.
 
  
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
   PS C:\> Get-InstalledSoftware -AppName testprogram | Uninstall-Program 

   ��������
   -----------
   ��� ������� ������� ��������� "testprogram" �� ��������� ����������.
   
 .Example
   PS C:\> cat computers.txt | Get-InstalledSoftware -AppName appname | Uninstall-Program -Confirm

   ��������
   -----------
   ��� ������� ������� ��������� "appname" �� �����������, ��������� � ����� "computers.txt".
 
 .Example
   PS C:\> "ComputerName, AppName
   >> comp1, prog1
   >> comp2, prog2 " | echo >remove_apps.csv
   >>
   PS C:\> Import-Csv remove_apps.csv | Get-InstalledSoftware | Uninstall-Program

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
			$app = Get-InstalledSoftware $ComputerName | ? { $_.AppGUID -eq $AppGUID }
			$appName = $app.AppName
			if ($pscmdlet.ShouldProcess("$appName �� ���������� $ComputerName")) {
				if ($Force -or $pscmdlet.ShouldContinue("�������� ��������� $appName �� ���������� $ComputerName", "")) {
					$uninstall_key = $app.UninstallKey
					if( $uninstall_key -match "msiexec" -or $uninstall_key -eq $null )
					{    
						## psexe ��������� ��� ������ � �������� �������
						#psexec \\$ComputerName msiexec /x $AppGUID /qn
						$returnval = ([WMICLASS]"\\$computerName\ROOT\CIMV2:win32_process").Create("msiexec `/x$AppGUID `/qn")
					} else {
						# ������� ������ - �� msi-�����
						$returnval = ([WMICLASS]"\\$ComputerName\ROOT\CIMV2:win32_process").Create(
							"$uninstall_key /S /x /silent /uninstall /qn /quiet")
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
	if( $file.Extension -ine ".msi")
	{
		if(!$UseOnlyInstallParams) {
			$params = "/S /silent /quiet /norestart /q /qn"
		} else {
			$params = ""
		}
		psexec -is \\$ComputerName $ProgSource $params $InstallParams
	} else {
		if(!$UseOnlyInstallParams) {
			$params = "/quiet /norestart /qn"
		} else {
			$params = ""
		}
		psexec -s \\$ComputerName msiexec /i $ProgSource $params $InstallParams
	}
}
