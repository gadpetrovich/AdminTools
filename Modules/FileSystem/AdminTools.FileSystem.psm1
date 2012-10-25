
# аналог юникосовой программы du
# ниже расположен рекурсивный аналог данной функции
# здесь же пришлось развернуть рекурсию для вывода данных прямо во время сканирования папки
function Get-DiskUsageLinear($LiteralPath = ".", [int]$Depth = [int]::MaxValue, [switch]$ShowLevel, [switch]$ShowProgress)
{
	#список директорий
	$dirs = New-Object System.Collections.Generic.List[System.Object];
	#список индексов файлов в директориях
	$indexes = New-Object System.Collections.Generic.List[System.Object];
	#список размеров папок
	$sizes = New-Object System.Collections.Generic.List[System.Object];
	
	$dir = @(Get-ChildItem -LiteralPath $LiteralPath -Force)
	
	$dirs.add($dir)
	$indexes.add(0)
	$sizes.add(0)
	
	#уровень вложенности
	$level = 0
	while($true)
	{
		while ($indexes[$level] -ge $dirs[$level].Length)
		{#конец папки, переходим на уровень ниже
			if ($ShowProgress -and ($level -lt 2)) {
				Write-Progress -Id $level -activity "Вычисление размера" -status "Сканирование"  -Complete
			}
			$size = $sizes[$level]
			if ($level -eq 0) { 
				# выходим
				#"Размер папки $LiteralPath = $size"
				#$obj = New-Object -TypeName PSobject             
				#$obj | Add-Member -MemberType NoteProperty -Name FullName -Value (get-item -LiteralPath $LiteralPath -force).FullName
				$obj = Get-Item -Force -LiteralPath $LiteralPath
				$obj | Add-Member -MemberType NoteProperty -Name Length -Value $size
				if($ShowLevel) { $obj | Add-Member -MemberType NoteProperty -Name Level -Value $level }
				return $obj 
			}
			
			$sizes[$level-1] += $size
			
			$indexes.RemoveAt($level)
			$dirs.RemoveAt($level)
			$sizes.RemoveAt($level)
			$level--
			
			#"вышли из папки " + $dirs[$level][ $indexes[$level] ].FullName + " размер = " + $size
			if($level -lt $Depth) {
				#$obj = New-Object -TypeName PSobject             
				#$obj | Add-Member -MemberType NoteProperty -Name FullName -Value $dirs[$level][ $indexes[$level] ].FullName
				$obj = Get-Item -Force -LiteralPath $dirs[$level][ $indexes[$level] ].FullName
				$obj | Add-Member -MemberType NoteProperty -Name Length -Value $size
				if($ShowLevel) { $obj | Add-Member -MemberType NoteProperty -Name Level -Value ($level+1) }
				$obj 
			}
			$indexes[$level]++
		}
		
		$file = $dirs[$level][ $indexes[$level] ]
		
		if ($ShowProgress -and ($dirs[$level].length -gt 0) -and ($level -lt 2)) {
			Write-Progress -Id $level -activity ("Вычисление размера: " + ("{0:N3} MB" -f ($sizes[$level] / 1MB))) -status ("Сканирование " + $file.FullName) -PercentComplete (($indexes[$level] / ($dirs[$level].length))  * 100)
		}
		
		
		#"уровень = " + $level + " длина = " + $dirs[$level].Length + " индекс = " + $indexes[$level] + " имя файла = " +  $file.FullName
		
		if($file.PSIsContainer) {
			#папка, переходим на уровень выше
		
			#"вошли в папку " + $file.FullName
			$dir = @(Get-ChildItem -LiteralPath $file.FullName -Force)
			
			$level++
			$dirs.Add($dir)
			$indexes.Add(0)
			$sizes.Add(0)
		} else {
			# обычный файл
			$sizes[$level] += $file.Length
			$indexes[$level]++			
		}
	}
}

function recursive_disk_usage([string]$LiteralPath, [int]$Depth, [int]$Level, [switch]$ShowLevel, [switch]$ShowProgress)
{
	$size = 0
	#$list = New-Object System.Collections.Generic.List[System.Object];
	$list = @()
	$dir = Get-ChildItem -LiteralPath $LiteralPath -Force
	$j = 0
	foreach ($i in $dir)
	{	
		if ($ShowProgress -and ($dir.length -gt 0) -and ($Level -lt 2)) {
			Write-Progress -Id $Level -activity ("Вычисление размера: " + ("{0:N3} MB" -f ($size / 1MB))) -status ("Сканирование " + $i.FullName) -PercentComplete (($j / ($dir.length))  * 100)
		}
		if ( $i.PSIsContainer ) {
			$objs = @(recursive_disk_usage -LiteralPath $i.FullName -Depth $Depth -Level ($Level+1) -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress)
			
			$size += $objs[-1].Length
			if ( $Level -lt $Depth ) { $list += $objs }
			
		} else {	
			$size += $i.Length
		}
		$j++
	}
	if ($ShowProgress -and ($Level -lt 2)) {
		Write-Progress -Id $Level -activity "Вычисление размера" -status "Сканирование"  -Complete
	}
	#$obj = New-Object -TypeName PSobject             
	#$obj | Add-Member -MemberType NoteProperty -Name FullName -Value $LiteralPath
	$obj = Get-Item -Force -LiteralPath $LiteralPath
	$obj | Add-Member -MemberType NoteProperty -Name Length -Value $size
	
	if($ShowLevel) { $obj | Add-Member -MemberType NoteProperty -Name Level -Value $Level }
	$list += $obj

	#$obj.Length.ToString() + "`t" + $obj.FullName | write-host 
	return $list
}
# рекурсивное вычисление размера папки
# $ShowProgress - отображать ход сканирования (до 2 уровней)
# 
function Get-DiskUsageRecursive(
	[string]$LiteralPath = ".", 
	[int]$Depth = [int]::MaxValue, 
	[switch]$ShowLevel, 
	[switch]$ShowProgress
)
{
	recursive_disk_usage -LiteralPath $LiteralPath -Depth $Depth -_Level 0 -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress
}

<# 
 .Synopsis
  Возращает список вложенных каталогов с их суммарными размерами.

 .Description
  Выполняет полное сканирование указанного каталога. 
 
  
 .Parameter LiteralPath
  Каталог, размер которого требуется подсчитать.

 .Parameter Depth
  Глубина вложенности каталогов. Требуется для ограничения отображаемых данных (на процесс сканирования никак не влияет).
 
 .Parameter ShowLevel
  Добавляет столбец Level, в нем указан уровень вложенности каталога.
  
 .Parameter ShowProgress
  Отображает прогресс сканирования каталогов. Уровень сканирования не зависит от параметра Depth и равен 2.
  
 .Parameter RecursiveAlgorithm
  Используется рекурсивный алгоритм для сканирования папок (в данном случае в вывод данные отдаются только после выполнения фукнции).

 .Example
   # Размеры текущей и вложенных папок.
   Get-DiskUsage | select FullName, Length

 .Example
   # Размер текущей папки.
   Get-DiskUsage . -Depth 0 | select FullName, Length
 
 .Example 
   # Отобразить информацию о ходе выполнения сканирования.
   Get-DiskUsage . -ShowProgress | select FullName, Length
   
 .Example
   # Вывести размеры каталогов в удобном виде.
   Get-DiskUsage | Update-Length  | select FullName, Length
 
 .Example 
   # Выполнить сканирование рекурсивно.
   Get-DiskUsage 'C:\Program Files' -RecursiveAlgorithm | ft -AutoSize FullName, Length
   
 .Example
	# Вывести 'топ 10' самых толстых папок в 'C:\Program Files'.
   Get-DiskUsage 'C:\Program Files' -ShowProgress -ShowLevel | ? {$_.Level -eq 1} | sort Length -Descending | select FullName, Length -First 10 | Update-Length | ft -AutoSize
#>
function Get-DiskUsage(
	[string]$LiteralPath = ".", 
	[int]$Depth = [int]::MaxValue, 
	[switch]$ShowLevel, 
	[switch]$ShowProgress,
	[switch]$RecursiveAlgorithm
)
{
	if($RecursiveAlgorithm) {
		Get-DiskUsageRecursive -LiteralPath $LiteralPath -Depth $Depth -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress
	} else {
		Get-DiskUsageLinear -LiteralPath $LiteralPath -Depth $Depth -ShowLevel:$ShowLevel -ShowProgress:$ShowProgress
	}
	
}

<# 
 .Synopsis
  Обновляет список каталогов с их суммарными размерами.

 .Description
  Выполняет полное сканирование указанного каталога, Размер каталога записывается в поле Length. Изменения вносятся непосредственно в исходный список.
 
 .Parameter InputObject
   Список файлов и директорий. Может использоваться для передачи объектов по конвейеру.
   
 .Example
   PS C:\> ls | ? { $_.PSIsContainer } | Update-DirLength

   Описание
   -----------
   Размеры папок в текущей директории.
   
 .Example
   PS C:\> Update-DirLength $(gi dir1; gi dir2)

   Описание
   -----------
   Размеры директорий dir1 и dir2.
#>
function Update-DirLength
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[PSobject]$InputObject
	)  
	
	begin{}
	process {
		foreach($file in $InputObject) {      
			if ($file -is [System.IO.DirectoryInfo]) {
				$dir_usage = Get-DiskUsage $file.FullName -Depth 0
				$file | Add-Member -MemberType NoteProperty -Name Length -Value ($dir_usage.Length)
			}
			$file
		}
	}
	end{}
}

<# 
 .Synopsis
  Преобразует параметр Length в читаемый вид.

 .Description
  В результате выполнения данной функции в поле Length будет записана строка в формате "{0:N3} MB". Т.е. число будет преобразовано в более читаемый вид. Изменения вносятся непосредственно в исходный список.
 
 .Parameter InputObject
   Список файлов и директорий. Может использоваться для передачи объектов по конвейеру.
 
 .Parameter NumericParameter
   Считываемый параметр. Значение по умолчанию "Length".
 
 .Parameter NewParameter
   Добавляемый параметр. Содержит преобразованное значение из NumericParameter. По умолчанию то же имя, что и у NumericParameter.

 .Example
   PS C:\> ls | Update-Length

   Описание
   -----------
   Размеры файлов в текущей директории.
   
 .Example
   PS C:\> ls -force | ? { !$_.psiscontainer  } | Update-Length -NewParameter HLength | sort length -descending | select name , hlength
   
   Описание
   -----------
   Выводит имена и размеры файлов в отсортированном виде. Добавляется новый параметр HLength с результатами работы функции Update-Length.
   
#>
function Update-Length
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[PSobject]$InputObject,
		[parameter(position=0)]
		[string[]]$NumericParameter = "Length",
		[parameter(position=1)]
		[string[]]$NewParameter = $NumericParameter
	)  
	
	begin{}
	process {
		if ($NewParameter.Length -ne $NumericParameter.Length) {
			throw "Несоответствие количества параметров NumericParameter и NewParameter"
		}
		foreach($i in $InputObject) {      
			for([int]$j = 0; $j -lt $NumericParameter.Length; $j++) {
				$i | Add-Member -MemberType NoteProperty -Name ($NewParameter[$j]) -Value ("{0:N3} MB" -f ($i.($NumericParameter[$j]) / 1MB)) -force
			}
			$i
		}
	}
	end{}
}

