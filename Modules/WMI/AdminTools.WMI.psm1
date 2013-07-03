# перезагрузка
# (Get-OsInfo compname).Reboot()
# или Restart-Computer compname


<# 
 .Synopsis
  Выводит информацию об операционной системе.

 .Description
  Данная функция возвращает объекты класса Win32_OperatingSystem.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

  
 .Example
   PS C:\> Get-OsInfo

   Описание
   -----------
   Эта команда возвращает информацию об операционной системе.
 
 .Example
   PS C:\> (Get-OsInfo compname).Reboot()

   Описание
   -----------
   Эта команда перезагрузит компьютер "compname".
     
#>
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
			$obj
		}
	}
	end {}
}


<# 
 .Synopsis
  Выводит информацию о компьютере.

 .Description
  Данная функция возвращает объекты класса Win32_ComputerSystem.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

  
 .Example
   PS C:\> Get-ComputerInfo

   Описание
   -----------
   Эта команда возвращает информацию о компьютере. 
 
 .Example
   PS C:\> Get-ComputerInfo -ComputerName comp1, comp2, comp3 | select ComputerName, Manufacturer, Model, SystemType | fta

   Описание
   -----------
   Эта команда возвращает список свойств компьютеров в удобном для чтения виде.
     
#>
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
			$obj
		}
	}
	end {}
}


<# 
 .Synopsis
  Выводит информацию о BIOS компьютера.

 .Description
  Данная функция возвращает объекты класса Win32_Bios.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

  
 .Example
   PS C:\> Get-BiosInfo

   Описание
   -----------
   Эта команда возвращает информацию о BIOS компьютера. 
 
 .Example
   PS C:\> Get-BiosInfo -ComputerName comp1, comp2, comp3 | fta

   Описание
   -----------
   Эта команда возвращает список свойств BIOS компьютеров в удобном для чтения виде.
     
#>
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
			$obj
		}
	}
	end {}
}


<# 
 .Synopsis
  Выводит информацию о логических дисках.

 .Description
  Данная функция возвращает объекты класса Win32_LogicalDisk.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

 .Parameter DeviceID
  Имя диска, для которого будет выведена информация.
  
 .Example
   PS C:\> Get-LogicalDiskInfo

   Описание
   -----------
   Эта команда возвращает информацию обо всех логических дисках на текущем компьютере. 
 
 .Example
   PS C:\> Get-LogicalDiskInfo -DeviceID c:

   Описание
   -----------
   Эта команда возвращает информацию о логическом диске C: на текущем компьютере. 
 
 .Example
   PS C:\> [PS] C:\Program Files\SysInternals>Get-LogicalDiskInfo -ComputerName comp1, comp2, comp3 | ? { $_.DriveType -eq 3 } | Update-Length FreeSpace, Size | select ComputerName, DeviceID, FileSystem, FreeSpace, Size, VolumeName | fta

   Описание
   -----------
   Эта команда возвращает список свойств логических дисков типа 3 (жесткие диски) в удобном для чтения виде.
     
#>
function Get-LogicalDiskInfo
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername,
		[parameter(ValueFromPipelineByPropertyName=$true)]            
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
			$obj
		}
	}
	end {}
}


<# 
 .Synopsis
  Выводит информацию о физических разделах.

 .Description
  Данная функция возвращает объекты класса Win32_DiskPartition.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

 .Parameter Filter
  Строка фильтрации. Аналогична фильтру класса Win32_DiskPartition.
  
 .Example
   PS C:\> Get-DiskPartitionInfo

   Описание
   -----------
   Эта команда возвращает информацию о физических разделах жестких дисков на текущем компьютере. 
 
 .Example
   PS C:\> Get-DiskPartitionInfo -Filter "PrimaryPartition = true"
   
   Описание
   -----------
   Эта команда возвращает информацию о первичных физических разделах на текущем компьютере.
   
 .Example
   PS C:\> Get-DiskPartitionInfo -ComputerName comp1, comp2, comp3 | Update-Length Size | fta

   Описание
   -----------
   Эта команда возвращает информацию о физических разделах жестких дисков в удобном для чтения виде.
     
#>
function Get-DiskPartitionInfo
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername,           
		[parameter(ValueFromPipelineByPropertyName=$true)]            
		[string]$Filter = ""
	)  
	begin {}
	process {
		foreach ($comp in $ComputerName)
		{
			$obj = get-wmiobject -Class Win32_DiskPartition -ComputerName $comp -Filter "$Filter"
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
			$obj
		}
	}
	end {}
}


<# 
 .Synopsis
  Выводит информацию о физических дисках.

 .Description
  Данная функция возвращает объекты класса Win32_DiskDrive.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.
  
 .Example
   PS C:\> Get-DiskDriveInfo

   Описание
   -----------
   Эта команда возвращает информацию о физических дисках на текущем компьютере. 
 
 .Example
   PS C:\> Get-DiskDriveInfo comp1, comp2, comp3 | update-length size | select ComputerName, DeviceID, Model, Size

   Описание
   -----------
   Эта команда возвращает информацию о физических дисках в удобном для чтения виде.
     
#>
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
			$obj
		}
	}
	end {}
}


<# 
 .Synopsis
  Выводит информацию о процессорах.

 .Description
  Данная функция возвращает объекты класса Win32_Processor.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.
  
 .Example
   PS C:\> Get-ProcessorInfo

   Описание
   -----------
   Эта команда возвращает информацию о процессорах на текущем компьютере. 
 
 .Example
   PS C:\> Get-ProcessorInfo comp1, comp2, comp3 | select ComputerName, Name, DataWidth, NumberOfCores, SocketDesignation | fta

   Описание
   -----------
   Эта команда возвращает информацию о процессорах в удобном для чтения виде.
     
#>
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
			$obj
		}
	}
	end {}
}


<# 
 .Synopsis
  Выводит информацию о материнской плате.

 .Description
  Данная функция возвращает объекты класса win32_baseboard.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.
  
 .Example
   PS C:\> Get-MotherboardInfo

   Описание
   -----------
   Эта команда возвращает информацию о материнской плате на текущем компьютере. 
 
 .Example
   PS C:\> Get-MotherboardInfo comp1, comp2, comp3 | select ComputerName, Description, Product, Manufacturer

   Описание
   -----------
   Эта команда возвращает информацию о материнских платах в удобном для чтения виде.
     
#>
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
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
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
			$obj
		}
	}
	end {}
}



<# 
 .Synopsis
  Выводит информацию о процессах.

 .Description
  Данная функция возвращает объекты класса Win32_Process.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

  
 .Example
   PS C:\> Get-ProcessInfo

   Описание
   -----------
   Эта команда возвращает информацию о процессах. 
 
 .Example
   PS C:\> Get-ProcessInfo -ComputerName comp1, comp2, comp3 | select Name, CommandLine, VM, WS

   Описание
   -----------
   Эта команда возвращает список свойств процессов в удобном для чтения виде.
 
 .Example
   PS C:\> Get-ProcessInfo compname "Name like 'service%'"

   Описание
   -----------
   Эта команда возвращает список свойств процессов, имена которых начинаются на service.
#>
function Get-ProcessInfo
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername,
		[parameter(ValueFromPipelineByPropertyName=$true)]            
		[string]$Filter = ""
	)  
	begin {}
	process {
		foreach ($comp in $ComputerName)
		{
			$obj = get-wmiobject -Class Win32_Process -ComputerName $comp -Filter "$Filter"
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
			$obj
		}
	}
	end {}
}



<# 
 .Synopsis
  Выводит информацию о службах.

 .Description
  Данная функция возвращает объекты класса Win32_Service.
  
 .Parameter ComputerName
  Список компьютеров. Может использоваться для перадачи объектов по конвейеру.

 .Example
   PS C:\> Get-ServiceInfo

   Описание
   -----------
   Эта команда возвращает информацию о службах. 
 
 .Example
   PS C:\> Get-ServiceInfo -ComputerName comp1, comp2, comp3 | fta

   Описание
   -----------
   Эта команда возвращает список свойств служб в удобном для чтения виде.
 
 .Example
   PS C:\> Get-ServiceInfo compname "Name like 'service%'"

   Описание
   -----------
   Эта команда возвращает список свойств служб, имена которых начинаются на service.
#>
function Get-ServiceInfo
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[string[]]$ComputerName = $env:computername,
		[parameter(ValueFromPipelineByPropertyName=$true)]            
		[string]$Filter = ""
	)  
	begin {}
	process {
		foreach ($comp in $ComputerName)
		{
			$obj = get-wmiobject -Class Win32_Service -ComputerName $comp -Filter "$Filter"
			if ($obj -ne $null) {
				$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $comp -Force
			}
			$obj
		}
	}
	end {}
}