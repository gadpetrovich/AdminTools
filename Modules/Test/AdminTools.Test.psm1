

# $null | Skip-Null | % { ... } 
filter Skip-Null { $_|?{ $_ -ne $null } }


function Get-NetView
{
	[cmdletbinding()]
	param(
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[Alias("CN","__SERVER","Computer","CNAME","Name","ComputerName")]
		[string]$Match
	)
	begin {
		$objs = net view 
		$objs = $objs | select -skip 3 -first ($objs.length-5)
	}
	process {
		$o2 = $objs | ? { $_ -imatch $Match }
		if ($o2 -eq $null) { return }
		foreach ($i in $o2) {
			$s = $i -split "\s+", 2
			$obj = New-Object -TypeName PSObject
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $s[0].Trim("\\")
			$obj | Add-Member -MemberType NoteProperty -Name Description -Value $s[1]
			$obj
		}
	}
	end { }
}

function  Format-TableAuto { 
	begin {
		$list = @()
	}
	process { 
		$list += $_ 
	}
	end {
		$list | ft -a -Wrap
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
            iex "New-Item Function:Global:$name -Value { [$($type.FullName)]::$name.Invoke( `$args ) }"
        } else {
            $MemberDefinition
        }
    }
}


New-PInvoke user32 "void FlashWindow(IntPtr hwnd, bool bInvert)" 

function Assert-PSWindow ()
{
	FlashWindow (ps -id $pid).MainWindowHandle $true
}

#http://xaegr.wordpress.com/2007/01/24/decoder/
function ConvertTo-Encoding ([string]$From, [string]$To){  
    Begin{  
        $encFrom = [System.Text.Encoding]::GetEncoding($from)  
        $encTo = [System.Text.Encoding]::GetEncoding($to)  
    }  
    Process{  
        $bytes = $encTo.GetBytes($_)  
        $bytes = [System.Text.Encoding]::Convert($encFrom, $encTo, $bytes)  
        $encTo.GetString($bytes)  
    }  
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
		$InputObject | Select $Property | Get-Member -MemberType *Property | % {
			$obj = "" | select Name, Value
			$obj.Name = $_.Name
			$obj.Value = $InputObject.($_.Name)
			$obj 
		}
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
			sleep 1 
		}; 
		Write-Progress  -Activity $Activity -Status "Выход" -Completed
	}
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
	[Alias("CN","__SERVER","Computer","CNAME")]
	[string[]]$ComputerName=$env:ComputerName,
	[string]$Key = "HKLM",
	[string]$SubKey
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

		$KEYQUERYVALUE = 0x1
		$KEYREAD = 0x19
		$KEYALLACCESS = 0x3F
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
		$type2 = Add-Type -MemberDefinition $sig2 -Name Win32Utils `
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
		$searchKeyRemote = $type0::RegConnectRegistry($computer, $searchKey, `
		[ref]$hKey)
		$result = $type1::RegOpenKeyEx($hKey, $SubKey, 0, $KEYREAD, `
		[ref]$hKeyref)

		#initialize variables
		$time = New-Object Long

		$result = $type2::RegQueryInfoKey($hKeyref, $null, [ref]$null, 0, [ref]$null, [ref]$null, `
		    [ref]$null, [ref]$null, [ref]$null, [ref]$null, [ref]$null, [ref]$time)
		#create output object
		$o = "" | Select Key, LastWriteTime, ComputerName
		$o.ComputerName = "$computer" 
		$o.Key = "$Key\$SubKey"
		# TODO Change to use the time api
		$o.LastWriteTime = (Get-Date $time).AddYears(1600).AddHours(-4)
		$o

		$result = $type3::RegCloseKey($hKey);
		}
	}
} # End Get-RegKeyLastWriteTime function

<# 
 .Synopsis
  Объединяет два списка в один.

 .Description
  Результат выполнения Join-Object есть декартово произведение двух списков, представленных параметрами LeftObject и RightObject. Если какие-либо имена свойств у LeftObject и RightObject совпадают, то к имени свойства из списка RightObject добавляется строка "Join". Например при объединении списков, содеражих одинаковые свойства (Id, Name), получаем результирующий список со свойствами: Id, Name, JoinId, JoinName.
  В случае, когда элементы списков не наследуются от класса PSObject, параметры LeftProperty и RightProperty не используются, и имена свойств результирующего списка выбираются, как "Value" и "JoinValue".
    
 .Parameter LeftObject
  Первый список для объединения. Может использоваться для перадачи объектов по конвейеру.

 .Parameter RightObject
  Второй список для объединения. К именам свойств, совпадающим с полями из LeftObject, будет добавляться префикс "Join".
 
 .Parameter FilterScript
  Указывает блок скрипта, используемый для фильтрации объектов. Для передачи параметров в скрипт используйте param(): { param($i,$j); ... }. Переменная $i содержит объект из LeftObject, $j - из RightObject.
  
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
  
  Для передачи параметров в блок скрипта используйте param(): { param($i,$j); ... }. Переменная $i содержит объект из LeftObject, $j - из RightObject.  
  
  К именам свойств, совпадающим с уже существующими полями, будет добавляться префикс "Join".
  
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
   PS C:\> Join-Object (1..9) (1..9) { param($i, $j); $i+$j -eq 10 } 
   
   Описание
   -----------
   На экран будут выведены суммы чисел, равных 10-и.
 
 .Example
   PS C:\> $comp1 = Get-Program comp1
   PS C:\> $comp2 = Get-Program comp2
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
		$LeftObject, 
		$RightObject,
		[Alias("Where")][ScriptBlock]$FilterScript = { $true },
		[Object[]]$LeftProperty = $null,
		[Object[]]$RightProperty = $null,
		[Hashtable[]]$CustomProperty = $null
	)
	
	begin{}
	process {
		
		function getFreeJoinParameter($Obj, $PropName) 
		{
			$name = $PropName
			if ($Obj | Get-Member -Name $name) {
				$name = "Join$PropName"
			}
			
			for ($i = 2; $Obj | Get-Member -Name $name; $i++) {
				$name = "Join$PropName$i"
			}
			return $name
		}

		function fillTempObject($properties, $left, $right)
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
		function addProperty($out, $prop_list)
		{			
			foreach($ip in $prop_list | Get-Member -MemberType *Property) {		
				$ip_name = getFreeJoinParameter $out $ip.Name
				$out | Add-Member -MemberType NoteProperty -Name $ip_name -Value $prop_list.($ip.Name)
			}
		}
		function addValue($out, $source)
		{
			$ip_name = getFreeJoinParameter $out "Value"
			$out | Add-Member -MemberType NoteProperty -Name $ip_name -Value $source
		}
		
		foreach($i in $LeftObject) {
			foreach($j in $RightObject) {
				if ( !($FilterScript.Invoke($i, $j))) {continue}
				$out = New-Object -TypeName PSobject    
				
				if($LeftProperty) {
					addProperty $out ($i | select $LeftProperty)
				} else {
					addValue $out $i
				}
				
				if($RightProperty) {
					addProperty $out ($j | select $RightProperty)
				} else {
					addValue $out $j
				}
				
				if($CustomProperty) {
					addProperty $out (fillTempObject $CustomProperty $i $j)
				}
				$out
			}
		}
	}
	end{}
}