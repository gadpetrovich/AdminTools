
# ������ ���������� ��������� du
# ���� ���������� ����������� ������ ������ �������
# ����� �� �������� ���������� �������� ��� ������ ������ ����� �� ����� ������������ �����
function Get-DiskUsageLinear($LiteralPath = ".", [int]$Depth = [int]::MaxValue, [switch]$ShowLevel, [switch]$ShowProgress)
{
	#������ ����������
	$dirs = New-Object System.Collections.Generic.List[System.Object];
	#������ �������� ������ � �����������
	$indexes = New-Object System.Collections.Generic.List[System.Object];
	#������ �������� �����
	$sizes = New-Object System.Collections.Generic.List[System.Object];
	
	$dir = @(Get-ChildItem -LiteralPath $LiteralPath -Force)
	
	$dirs.add($dir)
	$indexes.add(0)
	$sizes.add(0)
	
	#������� �����������
	$level = 0
	while($true)
	{
		while ($indexes[$level] -ge $dirs[$level].Length)
		{#����� �����, ��������� �� ������� ����
			if ($ShowProgress -and ($level -lt 4)) {
				Write-Progress -Id $level -activity "���������� �������" -status "������������"  -Complete
			}
			$size = $sizes[$level]
			if ($level -eq 0) { 
				# �������
				#"������ ����� $LiteralPath = $size"
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
			
			#"����� �� ����� " + $dirs[$level][ $indexes[$level] ].FullName + " ������ = " + $size
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
		
		if ($ShowProgress -and ($dirs[$level].length -gt 0) -and ($level -lt 4)) {
			Write-Progress -Id $level -activity ("���������� �������: " + ("{0:N3} MB" -f ($sizes[$level] / 1MB))) -status ("������������ " + $file.FullName) -PercentComplete (($indexes[$level] / ($dirs[$level].length))  * 100)
		}
		
		
		#"������� = " + $level + " ����� = " + $dirs[$level].Length + " ������ = " + $indexes[$level] + " ��� ����� = " +  $file.FullName
		
		if($file.PSIsContainer) {
			#�����, ��������� �� ������� ����
		
			#"����� � ����� " + $file.FullName
			$dir = @(Get-ChildItem -LiteralPath $file.FullName -Force)
			
			$level++
			$dirs.Add($dir)
			$indexes.Add(0)
			$sizes.Add(0)
		} else {
			# ������� ����
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
		if ($ShowProgress -and ($dir.length -gt 0) -and ($Level -lt 4)) {
			Write-Progress -Id $Level -activity ("���������� �������: " + ("{0:N3} MB" -f ($size / 1MB))) -status ("������������ " + $i.FullName) -PercentComplete (($j / ($dir.length))  * 100)
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
	if ($ShowProgress -and ($Level -lt 4)) {
		Write-Progress -Id $Level -activity "���������� �������" -status "������������"  -Complete
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
# ����������� ���������� ������� �����
# $ShowProgress - ���������� ��� ������������ (�� 4 �������)
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
  ��������� ������ ��������� ��������� � �� ���������� ���������.

 .Description
  ��������� ������ ������������ ���������� ��������. 
 
  
 .Parameter LiteralPath
  �������, ������ �������� ��������� ����������.

 .Parameter Depth
  ������� ����������� ���������. ��������� ��� ����������� ������������ ������ (�� ������� ������������ ����� �� ������).
 
 .Parameter ShowLevel
  ��������� ������� Level, � ��� ������ ������� ����������� ��������.
  
 .Parameter ShowProgress
  ���������� �������� ������������ ���������. ������� ������������ �� ������� �� ��������� Depth � ����� 4.
  
 .Parameter RecursiveAlgorithm
  ������������ ����������� �������� ��� ������������ ����� (� ������ ������ � ����� ������ �������� ������ ����� ���������� �������).

 .Example
   # ������� ������� � ��������� �����.
   Get-DiskUsage | select FullName, Length

 .Example
   # ������ ������� �����.
   Get-DiskUsage . -Depth 0 | select FullName, Length
 
 .Example 
   # ���������� ���������� � ���� ���������� ������������.
   Get-DiskUsage . -ShowProgress | select FullName, Length
   
 .Example
   # ������� ������� ��������� � ������� ����.
   Get-DiskUsage | Update-Length  | select FullName, Length
 
 .Example 
   # ��������� ������������ ����������.
   Get-DiskUsage 'C:\Program Files' -RecursiveAlgorithm | ft -AutoSize FullName, Length
   
 .Example
	# ������� '��� 10' ����� ������� ����� � 'C:\Program Files'.
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
  ��������� ������ ��������� � �� ���������� ���������.

 .Description
  ��������� ������ ������������ ���������� ��������, ������ �������� ������������ � ���� Length. ��������� �������� ��������������� � �������� ������.
 
 .Parameter InputObject
   ������ ������ � ����������. ����� �������������� ��� �������� �������� �� ���������.
   
 .Example
   PS C:\> ls | ? { $_.PSIsContainer } | Update-DirLength

   ��������
   -----------
   ������� ����� � ������� ����������.
   
 .Example
   PS C:\> Update-DirLength $(gi dir1; gi dir2)

   ��������
   -----------
   ������� ���������� dir1 � dir2.
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
  ����������� �������� Length � �������� ���.

 .Description
  � ���������� ���������� ������ ������� � ���� Length ����� �������� ������ � ������� "{0:N3} MB". �.�. ����� ����� ������������� � ����� �������� ���. ��������� �������� ��������������� � �������� ������.
 
 .Parameter InputObject
   ������ ������ � ����������. ����� �������������� ��� �������� �������� �� ���������.
 
 .Parameter NumericParameter
   ����������� ��������. �������� �� ��������� "Length".
 
 .Parameter NewParameter
   ����������� ��������. �������� ��������������� �������� �� NumericParameter. �� ��������� �� �� ���, ��� � � NumericParameter.

 .Example
   PS C:\> ls | Update-Length

   ��������
   -----------
   ������� ������ � ������� ����������.
   
 .Example
   PS C:\> ls -force | ? { !$_.psiscontainer  } | Update-Length -NewParameter HLength | sort length -descending | select name , hlength
   
   ��������
   -----------
   ������� ����� � ������� ������ � ��������������� ����. ����������� ����� �������� HLength � ������������ ������ ������� Update-Length.
   
#>
function Update-Length
{
	[cmdletbinding()]            
	param(            
		[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
		[PSobject]$InputObject,
		[string]$NumericParameter = "Length",
		[string]$NewParameter = $NumericParameter
	)  
	
	begin{}
	process {
		foreach($i in $InputObject) {      
			$i | Add-Member -MemberType NoteProperty -Name $NewParameter -Value ("{0:N3} MB" -f ($i.$NumericParameter / 1MB)) -force
			$i
		}
	}
	end{}
}

