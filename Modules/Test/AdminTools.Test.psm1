# $null | Skip-Null | % { ... } 
filter Skip-Null { $_|?{ $_ -ne $null } }

# полное описание свойств и методов:
# Get-OsInfo [compname] | get-member
# 
# полный список свойств:
# Get-OsInfo [compname] | select *
#
#
# перезагрузка
# (Get-OsInfo compname).Reboot()
# или Restart-Computer compname
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
			get-wmiobject -Class Win32_OperatingSystem -ComputerName $comp
		}
	}
	end {}
}


function Get-NetObject([string]$Match)
{
    $objs = net view 
	$o2 = $objs | select -skip 3 -first ($objs.length-5) | ? { $_ -imatch $Match } # убрали лишние строки 
	foreach($i in $o2) {
		$s = $i -split "\s+", 2
		$obj = New-Object -TypeName PSObject
		$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $s[0].Trim("\\")
		$obj | Add-Member -MemberType NoteProperty -Name Description -Value $s[1]
		$obj
	}
}


<# 
 .Synopsis
  Объединяет два списка в один.

 .Description
  Результат выполнения Join-Object представляет собой декартово произведение двух списков, представленных параметрами InputObject и JoinObject. Если какие-либо имена полей у InputObject и JoinObject совпадают, то к имени поля из списка JoinObject добавляется строка "Join". Например при объединении списков, содеражих одинаковые поля (Id, Name), получаем результирующий список в полями: Id, Name, JoinId, JoinName.
  В случае, когда элементы списков не наследуются от класса PSObject, параметры InputProperty и JoinProperty неиспользуются, и имена полей результирующего списка выбираются, как "Value" и "JoinValue".
    
 .Parameter InputObject
  Первый список для объединения. Может использоваться для перадачи объектов по конвейеру.

 .Parameter JoinObject
  Второй список для объединения. К именам полей, совпадающим с полями из InputObject, будет добавляться префикс "Join".
 
 .Parameter FilterScript
  Указывает блок скрипта, используемый для фильтрации объектов. Для передачи параметров в скрипт используйте param() ( { param($i,$j); ... }). Переменная $i содержит объект из InputObject, $j - из JoinObject.
  
 .Parameter InputProperty
  Указывает список полей из InputObject для добавления в результирующий список. Подстановочные знаки разрешены.

  Значение параметра InputProperty может быть новым вычисляемым свойством. Чтобы создать вычисляемое свойство, используйте хэш-таблицу. Допустимые ключи:
  -- Name (или Label) <строка>
  -- Expression <строка> или <блок скрипта>
  
  К именам полей, совпадающим с уже существующими полями, будет добавляться префикс "Join".
 
 .Parameter JoinProperty
  Указывает список полей из JoinObject для добавления в результирующий список. Подстановочные знаки разрешены.

  Значение параметра JoinProperty может быть новым вычисляемым свойством. Чтобы создать вычисляемое свойство, используйте хэш-таблицу. Допустимые ключи:
  -- Name (или Label) <строка>
  -- Expression <строка> или <блок скрипта>
  
  К именам полей, совпадающим с уже существующими полями, будет добавляться префикс "Join".

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
   PS C:\> $a | Join-Object -JoinObject $b -where { param($i,$j); $i.name -eq $j.name } -InputProperty name, LastWriteTime -JoinProperty LastWriteTime

   Описание
   -----------
   Эта команда возвращает список файлов и директорий с совпадающими именами в c:\dir1 и c:\dir2. Используется передача параметра InputObject через конвейер.
   
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
 
#>
function Join-Object
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		$InputObject, 
		$JoinObject,
		[Alias("Where")][ScriptBlock]$FilterScript = { $true },
		[Object[]]$InputProperty = $null,
		[Object[]]$JoinProperty = $null
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

		function addJoinParameter($out, $i, $properties)
		{
			$prop_list = $i | select $properties 
			$props = $prop_list | Get-Member -MemberType *Property
			#  "$i -is [PSObject] не подходит, т.к. для параметра InputObject в виде 1,2 
			#  он будет возвращать $true. $false будет, если параметр указать в виде (1,2) или @(1,2).
			if( $i -is [PSObject] -and $props){
				
				foreach($ip in $props) {
					
					$ip_name = getFreeJoinParameter $out $ip.Name
					$out | Add-Member -MemberType NoteProperty -Name $ip_name -Value $prop_list.($ip.Name)
				}
			} else {
				$ip_name = getFreeJoinParameter $out "Value"
				$out | Add-Member -MemberType NoteProperty -Name $ip_name -Value $i
			} 
		}
		
		foreach($i in $InputObject) {
			foreach($j in $JoinObject) {
				if ( !($FilterScript.Invoke($i, $j))) {continue}
				
				$out = New-Object -TypeName PSobject             
				addJoinParameter $out $i $InputProperty
				addJoinParameter $out $j $JoinProperty
				$out
			}
		}
	}
	end{}
}