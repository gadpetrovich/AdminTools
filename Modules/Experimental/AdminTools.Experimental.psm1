

# $null | Skip-Null | % { ... } 
filter Skip-Null { $_ | Where-Object { $_ -ne $null } }


function Get-NetView
{
	[cmdletbinding()]
	param(
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[Alias("CN","__SERVER","Computer","CNAME","Name","ComputerName","Address", "HostName")]
		[string]$Match
	)
	begin {
		$strs = net view 
		$strs = $strs | select-object -skip 3 -first ($strs.length-5)
		$objs = foreach ($i in $strs) {
			$s = $i -split "\s+", 2
			$obj = New-Object -TypeName PSObject
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $s[0].Trim("\\")
			$obj | Add-Member -MemberType NoteProperty -Name Description -Value $s[1].Trim()
			$obj
		}
	}
	process {
		$objs | Where-Object { $_.ComputerName -imatch $Match -or $_.Description -imatch $Match }
	}
	end { }
}

function Get-NetBrowserStat
{
	[cmdletbinding()]
	param(
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[Alias("CN","__SERVER","Computer","CNAME","Name","Address", "HostName")]
		[string]$ComputerName = $env:computername
	)
	begin { }
	process {
		$nbtstat = nbtstat -a $ComputerName | Select-String "<01>"
		$obj = New-Object -TypeName PSObject
		$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName
		$obj | Add-Member -MemberType NoteProperty -Name MasterBrowser -Value ($null -ne $nbtstat)
		$obj
	}
	end { }
}

function Format-TableAuto ([Object[]]$Property = $Null, [Object]$GroupBy) {
	begin {
		$list = @()
	}
	process { 
		$list += $_ 
	}
	end {
		$list | Format-Table -Property $Property -a -Wrap -GroupBy $GroupBy
	}
}

function New-PInvoke
{
    <#
    .Synopsis
        Generate a powershell function alias to a Win32|C api function
    .Description
        Creates C# code to access a C function, and exposes it via a powershell function
    .Example
        New-PInvoke user32 "void FlashWindow(IntPtr hwnd, bool bInvert)"
        
Generates a function for FlashWindow which ignores the boolean return value, and allows you to make a window flash to get the user's attention. Once you've created this function, you could use this line to make a PowerShell window flash at the end of a long-running script:

        C:\PS>FlashWindow (ps -id $pid).MainWindowHandle $true
    .Parameter Library
        A C Library containing code to invoke
    .Parameter Signature
        The C# signature of the external method
    .Parameter OutputText
        If Set, retuns the source code for the pinvoke method.
        If not, compiles the type. 
    .Link
        http://poshcode.org/1409
	#>
	param(
	[Parameter(Mandatory=$true, 
		HelpMessage="The C Library Containing the Function, i.e. User32")]
	[String]
	$Library,

	[Parameter(Mandatory=$true,
		HelpMessage="The Signature of the Method, i.e.: int GetSystemMetrics(uint Metric)")]
	[String]
	$Signature,

	[Switch]
	$OutputText
	)

	process {
		if ($Library -notlike "*.dll*") {
			$Library+=".dll"
		}
		if ($signature -notlike "*;") {
			$Signature+=";"
		}
		if ($signature -notlike "public static extern*") {
			$signature = "public static extern $signature"
		}
		
		$name = $($signature -replace "^.*?\s(\w+)\(.*$",'$1')
		
		$MemberDefinition = "[DllImport(`"$Library`")]`n$Signature"
		
		if (-not $OutputText) {
			$type = Add-Type -PassThru -Name "PInvoke$(Get-Random)" -MemberDefinition $MemberDefinition
			Invoke-Expression "New-Item Function:Global:$name -Value { [$($type.FullName)]::$name.Invoke( `$args ) }"
		} else {
			$MemberDefinition
		}
	}
}


New-PInvoke user32 "void FlashWindow(IntPtr hwnd, bool bInvert)" 

function Assert-PSWindow ()
{
	FlashWindow (Get-Process -id $pid).MainWindowHandle $true
}

#http://xaegr.wordpress.com/2007/01/24/decoder/
function ConvertTo-Encoding() {
	[cmdletbinding()]
	param (
		[parameter(ValueFromPipeline=$true)]
		[string]$String,
		[string]$From, 
		[string]$To
	)
	begin {} 
	process { 	
		$encFrom = [System.Text.Encoding]::GetEncoding($from)
		$encTo = [System.Text.Encoding]::GetEncoding($to)
		$bytes = $encTo.GetBytes($String)
		$bytes = [System.Text.Encoding]::Convert($encFrom, $encTo, $bytes)
		$encTo.GetString($bytes)
	}
	end {}
}

function Get-Property ()
{
	[cmdletbinding()]
	param(
		[Object[]]$Property = "*",
		[parameter(ValueFromPipeline=$true)]
		$InputObject
	)
	Process {
		$InputObject | Select-Object $Property | Get-Member -MemberType *Property | ForEach-Object {
			$obj = "" | Select-Object Name, Value
			$obj.Name = $_.Name
			$obj.Value = $InputObject.($_.Name)
			$obj 
		}
	}
}

function ConvertTo-HashTable
{
	[cmdletbinding()]
	param(
		[parameter(ValueFromPipeline=$true)]
		[PSObject]$InputObject
	)
	Process {
		$InputObject.psobject.properties | foreach-Object -begin {$h=@{}} -process {$h."$($_.Name)" = $_.Value} -end {$h}
	}
}

function Start-ProgressSleep
{
	[cmdletbinding()]
	param(
		[parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[int]$Seconds,
		[parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[string]$Activity
	)
	Process {
		$j = 0;
		for ($i = $Seconds; $i -ge 0; $i--) { 
			Write-Progress -Activity $Activity -Status "Осталось секунд: $i" -PercentComplete `
				(($Seconds - $i) / ($Seconds) * 100);
			start-sleep 1 
		}; 
		Write-Progress  -Activity $Activity -Status "Выход" -Completed
	}
}

function Select-Choice {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Caption,
		[string]$Message,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string[]]$Choices,
		[string[]]$ChoiceDescriptions = $null,
		[int]$DefaultChoice = 0
	)
	$list = @()
	for ($i = 0; $i -lt $Choices.Length; $i++) {
		if ($null -eq $ChoiceDescriptions -or $ChoiceDescriptions.Length -ne $Choices.Length) {
			$list += New-Object System.Management.Automation.Host.ChoiceDescription $Choices[$i]
		} else {
			$list += New-Object System.Management.Automation.Host.ChoiceDescription $Choices[$i], $ChoiceDescriptions[$i]
		}
	}
	$choicesList = [System.Management.Automation.Host.ChoiceDescription[]]$list
	$host.ui.PromptForChoice($Caption, $Message, $choicesList, $DefaultChoice)
}
function Get-RegKeyLastWriteTime {
	<#
	.SYNOPSIS
	Retrieves the last write time of the supplied registry key

	.DESCRIPTION
	The Registry data that a hive stores in containers are called cells. A cell 
	can hold a key, a value, a security descriptor, a list of subkeys, or a 
	list of key values.

	Get-RegKeyLastWriteTime retrieves the LastWriteTime through a pointer to the
	FILETIME structure that receives the time at which the enumerated subkey was
	last written. Values do not contain a LastWriteTime	property, but changes to
	child values update the parent keys lpftLastWriteTime.
	
	The LastWriteTime is updated when a key is created, modified, accessed, or
	deleted.

	.PARAMETER ComputerName
	Computer name to query

	.PARAMETER Key
	Root Key to query

	HKCR - Symbolic link to HKEY_LOCAL_MACHINE \SOFTWARE \Classes.
	HKCU - Symbolic link to a key under HKEY_USERS representing a user's profile
	hive.
	HKLM - Placeholder with no corresponding physical hive. This key contains
	other keys that are hives.
	HKU  - Placeholder that contains the user-profile hives of logged-on
	accounts.
	HKCC - Symbolic link to the key of the current hardware profile

	.PARAMETER SubKey
	Registry Key to query

	.EXAMPLE
	Get-RegKeyLastWriteTime -ComputerName testwks -Key HKLM -SubKey Software

	.EXAMPLE
	Get-RegKeyLastWriteTime -SubKey Software\Microsoft

	.EXAMPLE
	"testwks1","testwks2" | Get-RegKeyLastWriteTime -SubKey Software\Microsoft `
	\Windows\CurrentVersion

	.NOTES
	NAME: Get-RegKeyLastWriteTime
	AUTHOR: Shaun Hess
	VERSION: 1.0
	LASTEDIT: 01JUL2011
	LICENSE: Creative Commons Attribution 3.0 Unported License
	(http://creativecommons.org/licenses/by/3.0/)

	.LINK
	http://www.shaunhess.com
	
	.LINK
	http://www.shaunhess.com/journal/2011/7/4/reading-the-lastwritetime-of-a-registry-key-using-powershell.html
	#>

	[CmdletBinding()]

	param(
	[parameter(
	ValueFromPipeline=$true,
	ValueFromPipelineByPropertyName=$true)]
	[Alias("CN","__SERVER","Computer","CNAME", "HostName")]
	[string[]]$ComputerName=$env:ComputerName,
	[string]$Key = "HKLM",
	[string]$SubKey,
	[switch]$NoEnumKey
	)

	BEGIN {
		switch ($Key) {
			"HKCR" { $searchKey = 0x80000000} #HK Classes Root
			"HKCU" { $searchKey = 0x80000001} #HK Current User
			"HKLM" { $searchKey = 0x80000002} #HK Local Machine
			"HKU"  { $searchKey = 0x80000003} #HK Users
			"HKCC" { $searchKey = 0x80000005} #HK Current Config
			default {
			"Invalid Key. Use one of the following options:
			HKCR, HKCU, HKLM, HKU, HKCC"}
		}

		$KEYREAD = 0x19
	}
	PROCESS {
		foreach($computer in $ComputerName) {
		
$sig0 = @'
[DllImport("advapi32.dll", SetLastError = true)]
public static extern int RegConnectRegistry(
	string lpMachineName,
	int hkey,
	ref int phkResult);
'@
		$type0 = Add-Type -MemberDefinition $sig0 -Name Win32Utils `
			-Namespace RegConnectRegistry -Using System.Text -PassThru

$sig1 = @'
[DllImport("advapi32.dll", CharSet = CharSet.Auto)]
public static extern int RegOpenKeyEx(
	int hKey,
	string subKey,
	int ulOptions,
	int samDesired,
	out int hkResult);
'@
		$type1 = Add-Type -MemberDefinition $sig1 -Name Win32Utils `
			-Namespace RegOpenKeyEx -Using System.Text -PassThru

$sig2 = @'
[DllImport("advapi32.dll", EntryPoint = "RegEnumKeyEx")]
extern public static int RegEnumKeyEx(
    int hkey,
    int index,
    StringBuilder lpName,
    ref int lpcbName,
    int reserved,
    int lpClass,
    int lpcbClass,
    out long lpftLastWriteTime);
'@
		$type2 = Add-Type -MemberDefinition $sig2 -Name Win32Utils `
		    -Namespace RegEnumKeyEx -Using System.Text -PassThru

$sig4 = @'
[DllImport("advapi32.dll")]
public static extern int RegQueryInfoKey(
	int hkey,
	StringBuilder lpClass,
	ref int lpcbClass,
	int lpReserved,
	out int lpcSubKeys,
	out int lpcbMaxSubKeyLen,
	out int lpcbMaxClassLen,
	out int lpcValues,
	out int lpcbMaxValueNameLen,
	out int lpcbMaxValueLen,
	out int lpcbSecurityDescriptor,
	out long lpftLastWriteTime);
'@
		$type4 = Add-Type -MemberDefinition $sig4 -Name Win32Utils `
			-Namespace RegQueryInfoKey -Using System.Text -PassThru

$sig3 = @'
[DllImport("advapi32.dll", SetLastError=true)]
public static extern int RegCloseKey(
	int hKey);
'@
		$type3 = Add-Type -MemberDefinition $sig3 -Name Win32Utils `
			-Namespace RegCloseKey -Using System.Text -PassThru


		$hKey = new-object int
		$hKeyref = new-object int
		$result = $type1::RegOpenKeyEx($hKey, $SubKey, 0, $KEYREAD, `
		[ref]$hKeyref)

		if ($NoEnumKey) {
			#initialize variables
			$time = New-Object Long
			$result = $type4::RegQueryInfoKey($hKeyref, $null, [ref]$null, 0, [ref]$null, [ref]$null, `
				[ref]$null, [ref]$null, [ref]$null, [ref]$null, [ref]$null, [ref]$time)
			#create output object
			$o = "" | Select-Object Key, LastWriteTime, ComputerName
			$o.ComputerName = "$computer" 
			$o.Key = "$Key\$SubKey"
			# TODO Change to use the time api
			$o.LastWriteTime = (Get-Date $time).AddYears(1600).AddHours(-4)
			$o
		} else {
			#initialize variables
			$builder = New-Object System.Text.StringBuilder 1024
			$index = 0
			$length = [int] 1024
			$time = New-Object Long

			#234 means more info, 0 means success. Either way, keep reading
			while ( 0,234 -contains $type2::RegEnumKeyEx($hKeyref, $index++, `
				$builder, [ref] $length, $null, $null, $null, [ref] $time) )
			{
				#create output object
				$o = "" | Select-Object Key, LastWriteTime, ComputerName
				$o.ComputerName = "$computer" 
				$o.Key = $builder.ToString()
				# TODO Change to use the time api
				$o.LastWriteTime = (Get-Date $time).AddYears(1600).AddHours(-4)
				$o

				#reinitialize for next time through the loop  
				$length = [int] 1024
				$builder = New-Object System.Text.StringBuilder 1024
			}
		}
		$result = $type3::RegCloseKey($hKey);
		}
	}
} # End Get-RegKeyLastWriteTime function


function Convert-PSObjectAuto
{
	[cmdletbinding()]            
	 param(            
		 [parameter(Mandatory=$true, ValueFromPipeline=$true)]            
		 [PSObject]
		 $Object
	 )
	process {
		foreach($prop in $Object | Get-Member -MemberType *Property) {
			$prop_name = $prop.Name
			$result = $null
			
			if ([bool]::TryParse($Object.$prop_name, [ref]$result)) {}
			elseif ([int32]::TryParse($Object.$prop_name, [ref]$result)) {}
			elseif ([int64]::TryParse($Object.$prop_name, [ref]$result)) {}
			elseif ([Double]::TryParse($Object.$prop_name, [ref]$result)) {}
			else { continue }
			
			$Object.$prop_name = $result
		}
		$Object
	}
}


<# 
 .Synopsis
  Объединяет два списка в один.

 .Description
  Результат выполнения Join-Object есть декартово произведение двух списков, представленных параметрами LeftObject и RightObject. Если какие-либо имена свойств у LeftObject и RightObject совпадают, то к имени свойства из списка RightObject добавляется строка "Join". Например при объединении списков, содеражих одинаковые свойства (Id, Name), получаем результирующий список со свойствами: Id, Name, JoinId, JoinName.
    
 .Parameter LeftObject
  Первый список для объединения. Может использоваться для перадачи объектов по конвейеру.

 .Parameter RightObject
  Второй список для объединения. К именам свойств, совпадающим с полями из LeftObject, будет добавляться префикс "Join".
 
 .Parameter FilterScript
  Указывает блок скрипта, используемый для фильтрации объектов. Для передачи параметров в скрипт используйте param(): { param($i,$j); ... }. Переменная $i содержит объект из LeftObject, $j - из RightObject. Также можно использовать массив $Args. Переменная $Args[0] содержит объект из LeftObject, $Args[1] - из RightObject. 
  
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
  
  Для передачи параметров в блок скрипта используйте param(): { param($i,$j); ... }. Переменная $i содержит объект из LeftObject, $j - из RightObject. Также можно использовать массив $Args. Переменная $Args[0] содержит объект из LeftObject, $Args[1] - из RightObject. 
  
  К именам свойств, совпадающим с уже существующими полями, будет добавляться префикс "Join".
  
 .Parameter Type
  Тип объединения списков.
  
  AllInLeft берет все записи из LeftObject и только те записи из RightObject, которые удовлетворяют условию FilterScript.
  AllInRight берет все записи из RightObject и только те записи из LeftObject, которые удовлетворяют условию FilterScript.
  OnlyIfInBoth берет только те записи, которые удовлетворяют условию FilterScript.
  AllInBoth берет все записи.
  
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
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> Join-Object -LeftObject $a -RightObject $b -where { param($i,$j); $i.name -eq $j.name } -LeftProperty name, LastWriteTime -RightProperty LastWriteTime -Type AllInLeft

   Описание
   -----------
   На экран будут выведен список файлов и директорий с совпадающими именами в c:\dir1 и c:\dir2, а также все остальные файлы и папки в директории c:\dir1.
   
 .Example
   PS C:\> Join-Object (1..9) (1..9) { param($i, $j); $i+$j -eq 10 } 
   
   Описание
   -----------
   На экран будут выведены суммы чисел, равных 10-и.
 
 .Example
   PS C:\> $comp1 = Get-Program -ComputerName comp1
   PS C:\> $comp2 = Get-Program -ComputerName comp2
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
		[ValidateNotNull()][Alias("Left", "LO")][Object[]]$LeftObject, 
		[ValidateNotNull()][Alias("Right", "RO")][Object[]]$RightObject,
		[Alias("Where")][ScriptBlock]$FilterScript = { $true },
		[Alias("LeftProperties", "LP")][Object[]]$LeftProperty = $null,
		[Alias("RightProperties", "RP")][Object[]]$RightProperty = $null,
		[Hashtable[]]$CustomProperty = $null,
		[ValidateSet("AllInLeft","OnlyIfInBoth","AllInBoth", "AllInRight")]
		[String]$Type="OnlyIfInBoth"
	)
	
	begin{
		$left_properties = @{}
		$right_properties = @{}
		$custom_properties = @{}
		$left_rows = @()
		$left_matches_count = new-object "int[]" 0
		$right_matches_count = new-object "int[]" $RightObject.Count
		$is_begin = $true
	}
	process {
		
		function fill_temp_object($properties, $left, $right)
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
		
		function add($out, $source, $properties, $prop_hash)
		{			
			if($properties -or $null -eq $source) {
				add_properties $out ($source | select-object $properties -ErrorAction SilentlyContinue) $prop_hash
			} else {
				add_value $out $source $prop_hash
			}		
		}
		function add_properties($out, $prop_list, $prop_hash)
		{
			foreach($key in $prop_hash.Keys) {                
				if ($prop_list) {
					$out | Add-Member -MemberType NoteProperty -Name $prop_hash[$key] -Value $prop_list.($key) -Force
				} else {
					$out | Add-Member -MemberType NoteProperty -Name $prop_hash[$key] -Value $null
				}
    		}
		}
		function add_value($out, $source, $prop_hash)
		{
			$out | Add-Member -MemberType NoteProperty -Name $prop_hash["Value"] -Value $source
		}
		
		function get_new_name($name, $hash_list) 
		{
:name_index	
			for ($i = 0; $true; $i++) {
				switch ($i) {
					0 { $new_name = $Name }
					1 { $new_name = "Join$Name" }
					default { $new_name = "Join$Name$i" }
				}
				foreach ($hash in $hash_list) {
					if ($hash.Values -Contains $new_name) { continue name_index }
				}
				return $new_name
			}
		}

		function init_hashtables() {
			if ($LeftProperty) {
				foreach($ip in ($LeftObject[0] | select-object $LeftProperty -ErrorAction SilentlyContinue) | Get-Member -MemberType *Property) {
					$left_properties[$ip.Name] = $ip.Name
				}
			} else {
				$left_properties["Value"] = "Value"
			}
			if ($RightProperty) {
				foreach($ip in ($RightObject[0] | select-object $RightProperty -ErrorAction SilentlyContinue) | Get-Member -MemberType *Property) {
					$right_properties[$ip.Name] = get_new_name $ip.Name @($left_properties, $right_properties)
				}
			} else {
				$right_properties["Value"] = get_new_name "Value" @($left_properties)
			}
			if ($CustomProperty) {
				foreach($ip in (fill_temp_object $CustomProperty $LeftObject[0] $RightObject[0]) | Get-Member -MemberType *Property) {
					$custom_properties[$ip.Name] = get_new_name $ip.Name @($left_properties, $right_properties, $custom_properties)
				}
			}
		}
		
		if ($is_begin) {
			init_hashtables 
			$is_begin = $false
		}
        
		for($i = 0; $i -lt $LeftObject.Count; $i++) {
			$left_rows += $LeftObject[$i]
			$left_matches_count += 0
			for($j = 0; $j -lt $RightObject.Count; $j++) {
				$left_item = $LeftObject[$i]
				$right_item = $RightObject[$j]
				
				if ( !($FilterScript.Invoke($left_item, $right_item))) {continue}
				
				$left_matches_count[$left_matches_count.Count-1]++
				$right_matches_count[$j]++
				
				$out = New-Object -TypeName PSobject
				add $out $left_item $($LeftProperty) $left_properties
				add $out $right_item $($RightProperty) $right_properties
				if($CustomProperty) {
					add_properties $out (fill_temp_object $CustomProperty $left_item $right_item) $custom_properties
				}
				$out
			}
		}
	}
	end {
		if ($Type -eq "AllInBoth" -or $Type -eq "AllInLeft") {
			for ($i = 0; $i -lt $left_rows.Count; $i++) {
				if ($left_matches_count[$i] -eq 0) {
					$out = New-Object -TypeName PSobject
					add $out $left_rows[$i] $($LeftProperty) $left_properties
					add $out $null $null $right_properties
					add $out $null $null $custom_properties
					$out
				}
			}
		}
		if ($Type -eq "AllInBoth" -or $Type -eq "AllInRight") {
			for ($i = 0; $i -lt $RightObject.Count; $i++) {
				if ($right_matches_count[$i] -eq 0) {
					$out = New-Object -TypeName PSobject    
					add $out $null $null $left_properties
					add $out $RightObject[$i] $($RightProperty) $right_properties
					add $out $null $null $custom_properties
					$out
				}
			}
		}
	}
}

function Join-Objects
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[ValidateNotNull()]$Objects, 
		[parameter(Mandatory = $true)]
		[Alias("JP")][String[]]$JoinProperties,
		[parameter(Mandatory = $true)]
		[Object[]]$Properties,
		[ValidateSet("AllInLeft","OnlyIfInBoth","AllInBoth", "AllInRight")]
		[String]$Type="OnlyIfInBoth"
	)
	begin {
        if ($Objects.Count -ne $Properties.Count) {
			throw "Кол-во списков и выбранных свойств не совпадает"
		}
        $script = { 
			$res = $true
			foreach ($prop in $JoinProperties) {
				$res = $res -and ($Args[0].$prop -ieq $Args[1].$prop)
			}
			$res
		}
        $PropertiesWithJoins = foreach ($property in $Properties) {
            ,@($JoinProperties + $property | select -Unique)
        }
    }
	process {
		$res = Join-Object -LeftObject $objects[0] -RightObject $objects[1] -FilterScript $script -LeftProperty $PropertiesWithJoins[0] -RightProperty $PropertiesWithJoins[1] -Type $Type
		for ($i = 2; $i -lt $Objects.Count; $i++) {
			$res = $res | join-object -RO $objects[$i] -F $script -LP * -RP $PropertiesWithJoins[$i] -Type $Type
			
		}
        foreach ($row in $res) {
            foreach ($prop in $JoinProperties) {
                for ($i = 1; $i -lt $Objects.Count; $i++) {
                    $JoinPropertyName = "Join$prop$(if ($i -eq 1) {''} else {$i} )"
                    if ($row.$prop -eq $null) {
				        $row.$prop = $row.$JoinPropertyName
			        }
                    $row.PSObject.Properties.Remove($JoinPropertyName)
                }
            }
		}
		$res
	}
}

function Invoke-Parallel { 
<# 
 .SYNOPSIS 
  Скрипт Invoke-Parallel выполняет обработку входных объектов в фоновых заданиях Windows PowerShell. 
  
  Фоновые задания выполняются взаимодействуя с текущим сеансом. Выполнение скрипта Invoke-Parallel завершается после обработки всех заданий, если не указан параметр Jobs. Предел одновременно запущенных заданий задается через параметр Throttle.

 .PARAMETER Process 
  Указывает блок скрипта, используемый для параллельной обработки объектов. Переменная $_ содержит объект из InputObject: { echo $_ }. 

 .PARAMETER InputObject 
  Указывает входной объект. Invoke-Parallel запускает блок скрипта для набора входных объектов в отдельном фоновом задании. Кол-во входных объектов, обрабатываемых одним заданием, задается параметром ObjPerJob.

 .PARAMETER Begin
  Указывает блок скрипта, запускаемый перед выполнением Process. 
  
 .PARAMETER End
  Указывает блок скрипта, запускаемый после выполнения Process. 
  
 .PARAMETER Throttle 
  Указывает максимальное количество одновременно запущенных фоновых заданий.

 .PARAMETER ObjPerJob 
  Указывает кол-во объектов, передаваемых в одно задание.
  
 .PARAMETER ArgumentList
  Список параметров для скриптов Begin, End и Process. Для передачи параметров используйте param(): { param($arg1, $arg2,...); ... }. Также можно использовать массив $Args.
  
 .PARAMETER Jobs 
  Ссылочная переменная для обмена данными о фоновых заданиях. Тип переменной должен быть System.Array. Если данный параметр не указан, то скрипт Invoke-Parallel завершится только после обработки всех входных объектов.

 .PARAMETER Wait
  Используется для завершения оставшихся фоновых заданий. Список заданий передается через параметр Jobs.
  
 .EXAMPLE 
   PS C:\> 1..5 | Foreach-Parallel { sleep (Get-Random 10); $_ }

   Описание
   -----------
   На экран будут выведен список чисел от 1 до 5, порядок вывода зависит от времени завершения фоновых заданий.

 .EXAMPLE 
   PS C:\> $jobs = @(); 1..5 | Foreach-Parallel { sleep (get-random 10); $_ } -Jobs ([ref]$jobs) -Throttle 2
   PS C:\> Foreach-Parallel -Jobs ([ref]$jobs) -Wait
   
   Описание
   -----------
   Первая команда вернет неполный список из чисел в случайном порядке. Оставшиеся числа будут возвращены второй командой.
   
 .EXAMPLE 
   PS C:\> 1..5 | Foreach-Parallel {param($i); $_ * $i } -Args 3

   Описание
   -----------
   На экран будут выведен список чисел от 1 до 5 умноженных на 3, порядок вывода зависит от времени завершения фоновых заданий.
   
 .FUNCTIONALITY  

 .NOTES 
#> 
	[cmdletbinding(DefaultParameterSetName="Auto")]
	param( 
        [Parameter(Position=0, Mandatory=$true, ParameterSetName="Auto")] 
		[Alias("ScriptBlock")]
        [System.Management.Automation.ScriptBlock]$Process,
        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Auto")] 
		[AllowNull()]
        [PSObject]$InputObject,
		[Parameter(Position=2, Mandatory=$false, ParameterSetName="Auto")] 
		[AllowNull()]
        [System.Management.Automation.ScriptBlock]$Begin = $null,
		[Parameter(Position=3, Mandatory=$false, ParameterSetName="Auto")] 
		[AllowNull()]
        [System.Management.Automation.ScriptBlock]$End = $null,
		[Parameter(Position=4, Mandatory=$false, ParameterSetName="Auto")]
		[ValidateRange(1,255)]
		[int]$Throttle = 5,
		[Parameter(Position=5, Mandatory=$false, ParameterSetName="Auto")]
		[ValidateRange(1,16384)]
		[int]$ObjPerJob = 1,
		[Parameter(Position=6, Mandatory=$false, ParameterSetName="Auto")]
		[Alias("Args")]
		[AllowNull()]
		[Object[]]$ArgumentList = $null,
		[Parameter(Mandatory=$false)]
		[ValidateScript({ $_.value -is [System.Array]})]
		[ref]$Jobs,
		[Parameter(Mandatory=$True,ParameterSetName="Wait")]
		[switch]$Wait
	) 
	BEGIN { 
		write-debug "begin"
		if ($Jobs) { 
			$script:jobList = $Jobs.value 
		} else { 
			$script:jobList = @() 
		}
		$script:objList = @()
		function pushObjListToJobList() {
			if ($script:objList.count -eq 0) { return }
			$script:jobList += Start-Job -Args $Process, $Begin, $End, $script:objList, $pwd, $ArgumentList -ScriptBlock { 
				Param($p, $b, $e, $param, $pwd, [Object[]]$al)
				$ProcessBase = [ScriptBlock]::Create($p)
				$BeginBase = [ScriptBlock]::Create($b)
				$EndBase = [ScriptBlock]::Create($e)
				$Process = {. $ProcessBase @al}
				$Begin = {. $BeginBase @al}
				$End = {. $EndBase @al}
				Set-Location $pwd
				$param | ForEach-Object -Process $Process -Begin $Begin -End $End
				#todo: сохранить информацию о скрытии параметров (get-process после %% выдает все параметры)
			}
			write-debug "jobs = $($script:jobList | % { $_.state })"
			$script:objList = @()
		}
		
		function convertResult {
			[cmdletbinding()] 
			param ([
				Parameter(Mandatory=$true, ValueFromPipeline=$true)]
				[AllowNull()]
				[PSObject]$InputObject
			) 
			Process {
				if ($InputObject -eq $null) { return $null }
				$InputObject.psobject.Properties.Remove("RunspaceId")
				$InputObject.psobject.Properties.Remove("PSSourceJobInstanceId")
				$InputObject.psobject.Properties.Remove("PSComputerName")
				$InputObject.psobject.Properties.Remove("PSShowComputerName")
				return $InputObject
			}
		}
	}
 
	PROCESS {
		if ($PsCmdlet.ParameterSetName -ieq "Wait") { return }
		write-debug "process"
		write-debug "InputObject = $InputObject"
		write-debug "Uncompleted jobs = $(($script:jobList | Where-Object State -ne "Completed").Count)"
		$script:jobList | Receive-Job | convertResult
		while (($script:jobList | Where-Object State -ne "Completed").Count -ge $Throttle) {
			$script:jobList | Receive-Job | convertResult
			Start-Sleep -Milliseconds 100
		}
		
		Write-debug "Process = $($Process)"
		Write-debug "Object = $($InputObject)"
		$script:objList += ,$InputObject
		Write-debug "objList = $script:objList"
		Write-debug "objList count = $($script:objList.Count)"
		if ($script:objList.Count -ge $ObjPerJob) {
			pushObjListToJobList
		}
	} 
	END { 
		write-debug "end"
		pushObjListToJobList
		if ($PsCmdlet.ParameterSetName -ieq "Wait" -or !$Jobs) {
			$script:jobList | Receive-Job -Wait | convertResult
			write-debug "jobs = $script:jobList"
			Remove-Job $script:jobList
		} else {
			$Jobs.value = $script:jobList 
		} 
		
		
    } 
}

function Invoke-Progress {
	<# 
.SYNOPSIS 

.PARAMETER Activity 

.PARAMETER Status 

.PARAMETER Id
 
.PARAMETER CurrentOperation

.PARAMETER ParentId

.PARAMETER SecondsRemaining

.PARAMETER SourceId

.PARAMETER InputObject

.EXAMPLE 
   PS C:\> 1..10 | Invoke-Progress "проверка" | % { sleep 1 }
   
   Описание
   -----------
   Посекундный вывод индикатора процесса.
      
.EXAMPLE 
   PS C:\> ls | Invoke-Progress "проверка" -CurrentOperation 'Сейчас будет выведен $($_.Name)' | % { sleep 2; $_ }
   
   Описание
   -----------
   Вывод списка файлов в текущей директории с интервалом в две секунды. в индикаторе процесса отображается номер и имя выводимого файла.
   
.FUNCTIONALITY  

.NOTES 
#> 
	[cmdletbinding()] 
	param(
        [Parameter(Mandatory=$true)] 
        [String]$Activity,
        [Parameter(Mandatory=$false)] 
		[String]$Status = $null,
		[Parameter(Mandatory=$false)] 
		[Int32]$Id,
		[Parameter(Mandatory=$false)] 
		[String]$CurrentOperation = '',
		[Parameter(Mandatory=$false)] 
		[Int32]$ParentId = -1,
		[Parameter(Mandatory=$false)] 
		[Int32]$SecondsRemaining = -1,
		[Parameter(Mandatory=$false)] 
		[Int32]$SourceId,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
		[AllowNull()]
        [PSObject]$InputObject
	) 
	$alldata = @($Input)
	if ([string]::IsNullOrEmpty($Status)) { $Status = 'Обработано $Index из $($alldata.count)' }

	$index = 0
	$StatusBlock = [scriptblock]::Create("""" + $Status + """")
	$CurrentBlock = [scriptblock]::Create("""" + $CurrentOperation + """")
	$alldata | % {
		$index++
		$Status = $StatusBlock.Invoke()
		$CurrentOperation = $CurrentBlock.Invoke()
		Write-Progress -Activity $Activity -Status $Status -Id $Id -CurrentOperation $CurrentOperation -ParentId $ParentId -SourceId $SourceId -SecondsRemaining $SecondsRemaining -PercentComplete ($index * 100 / $alldata.Count)
		
		$_
	} 
	
	Write-Progress -Activity $Activity -Id $Id -ParentId $ParentId -SourceId $SourceId -Completed
}

function Set-ActualBufferSize() 
{
	$newsize = $host.ui.rawui.BufferSize
	$newsize.Width = $host.ui.rawui.WindowSize.Width
	$host.ui.rawui.BufferSize = $newsize
}