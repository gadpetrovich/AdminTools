# $null | Skip-Null | % { ... } 
filter Skip-Null { $_|?{ $_ -ne $null } }

# ������ �������� ������� � �������:
# Get-OsInfo [compname] | get-member
# 
# ������ ������ �������:
# Get-OsInfo [compname] | select *
#
#
# ������������
# (Get-OsInfo compname).Reboot()
# ��� Restart-Computer compname
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
	$o2 = $objs | select -skip 3 -first ($objs.length-5) | ? { $_ -imatch $Match } # ������ ������ ������ 
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
  ���������� ��� ������ � ����.

 .Description
  ��������� ���������� Join-Object ������������ ����� ��������� ������������ ���� �������, �������������� ����������� LeftObject � RightObject. ���� �����-���� ����� ������� � LeftObject � RightObject ���������, �� � ����� �������� �� ������ RightObject ����������� ������ "Join". �������� ��� ����������� �������, ��������� ���������� �������� (Id, Name), �������� �������������� ������ �� ����������: Id, Name, JoinId, JoinName.
  � ������, ����� �������� ������� �� ����������� �� ������ PSObject, ��������� LeftProperty � RightProperty ��������������, � ����� ������� ��������������� ������ ����������, ��� "Value" � "JoinValue".
    
 .Parameter LeftObject
  ������ ������ ��� �����������. ����� �������������� ��� �������� �������� �� ���������.

 .Parameter RightObject
  ������ ������ ��� �����������. � ������ �������, ����������� � ������ �� LeftObject, ����� ����������� ������� "Join".
 
 .Parameter FilterScript
  ��������� ���� �������, ������������ ��� ���������� ��������. ��� �������� ���������� � ������ ����������� param(): { param($i,$j); ... }. ���������� $i �������� ������ �� LeftObject, $j - �� RightObject.
  
 .Parameter LeftProperty
  ��������� ������ ������� �� LeftObject ��� ���������� � �������������� ������. �������������� ����� ���������.

  �������� ��������� LeftProperty ����� ���� ����� ����������� ���������. ����� ������� ����������� ��������, ����������� ���-�������. ���������� �����:
  -- Name (��� Label) <������>
  -- Expression <������> ��� <���� �������>
  
  � ������ �������, ����������� � ��� ������������� ������, ����� ����������� ������� "Join".
 
 .Parameter RightProperty
  ��������� ������ ������� �� RightObject ��� ���������� � �������������� ������. �������������� ����� ���������.

  �������� ��������� RightProperty ����� ���� ����� ����������� ���������. ����� ������� ����������� ��������, ����������� ���-�������. ���������� �����:
  -- Name (��� Label) <������>
  -- Expression <������> ��� <���� �������>
  
  � ������ �������, ����������� � ��� ������������� ������, ����� ����������� ������� "Join".

 .Parameter CustomProperty
  ��������� ��������, ������� ����������� �� �������� � ����� ��������.
  
  �������� ��������� CustomProperty ������ ���� ����� ����������� ���������. ����� ������� ����������� ��������, ����������� ���-�������. ���������� �����:
  -- Name (��� Label) <������>
  -- Expression <���� �������>
  
  ��� �������� ���������� � ���� ������� ����������� param(): { param($i,$j); ... }. ���������� $i �������� ������ �� LeftObject, $j - �� RightObject.  
  
  � ������ �������, ����������� � ��� ������������� ������, ����� ����������� ������� "Join".
  
 .Example
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime LastWriteTime

   ��������
   -----------
   ��� ������� ���������� ������ ������ � ���������� � ������������ ������� � c:\dir1 � c:\dir2. 
 
 .Example
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime @{Name = "Dir2_LastWriteTime"; Expression = {$_.LastWriteTime}}

   ��������
   -----------
   ��� ������� ���������� ������ ������ � ���������� � ������������ ������� � c:\dir1 � c:\dir2. �������� LasWriteTime �� ������ ������ ����������������� � Dir2_LastWriteTime.
     
 .Example
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime LastWriteTime  @{Name = "diff"; Expression={param($i,$j);  [int]($i.LastWriteTime - $j.LastWriteTime).TotalDays }}

   ��������
   -----------
   ��� ������� ���������� ������ ������ � ���������� � ������������ ������� � c:\dir1 � c:\dir2 � ������� � ���� ��� ������� LastWriteTime. 
   
 .Example
   PS C:\> $a = get-childitem c:\dir1
   PS C:\> $b = get-childitem c:\dir2
   PS C:\> $a | Join-Object -RightObject $b -where { param($i,$j); $i.name -eq $j.name } -LeftProperty name, LastWriteTime -RightProperty LastWriteTime

   ��������
   -----------
   ��� ������� ���������� ������ ������ � ���������� � ������������ ������� � c:\dir1 � c:\dir2. ������������ �������� ��������� LeftObject ����� ��������.
   
 .Example
   PS C:\> Join-Object (1..9) (1..9) { param($i, $j); $i+$j -eq 10 } 
   
   ��������
   -----------
   �� ����� ����� �������� ����� �����, ������ 10-�.
 
 .Example
   PS C:\> $comp1 = Get-Program comp1
   PS C:\> $comp2 = Get-Program comp2
   PS C:\> Join-Object $comp1 $comp2 { param($i, $j); $i.AppName -eq $j.AppName } AppName, InstalledDate InstalledDate
 
   ��������
   -----------
   ����� ��� ��������� ����������� �������� �� ������ �����������.
 
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
			# ��������� ������������� ������ $prop_list
			foreach($p in $properties) {
				if( $p -is [Hashtable] ) {
					# ����������� ����
					# ���� ��������
					if( ! ($p.ContainsKey("Name") -or $p.ContainsKey("Label")) ) {
						throw "�������� �� ����� �����"
					}
					if ( ! ($p.ContainsKey("Expression") -and $p.Expression -is [ScriptBlock]) ) {
						throw "�������� �� ����� ������������ �����"
					}
					# ���
					if ($p.ContainsKey("Name")) { 
						$name = $p.Name 
					} else { 
						$name = $p.Label
					}
					# ���������					
					$expression = $p.Expression.Invoke($left, $right)
					if( $expression.Count -eq 0) {
						$expression = $null
					} elseif( $expression.Count -eq 1) {
						$expression = $expression[0]
					}
					
					$prop_list | Add-Member -MemberType NoteProperty -Name $name -Value $expression
				} else {
					throw "�������� ������ ���� ���� Hashtable"
				}
			}
			return $prop_list
		}
		function addJoinParameter($out, $source, $prop_list)
		{
			#$prop_list = $source | select $properties 
			
			# $props �������� �������� ��������� �������
			$props = $prop_list | Get-Member -MemberType *Property
			#  "$source -is [PSObject] �� ��������, �.�. ��� ��������� LeftObject � ���� 1,2 
			#  �� ����� ���������� $true. $false �����, ���� �������� ������� � ���� (1,2) ��� @(1,2).
			if( $source -is [PSObject] -and $props){
				foreach($ip in $props) {		
					$ip_name = getFreeJoinParameter $out $ip.Name
					$out | Add-Member -MemberType NoteProperty -Name $ip_name -Value $prop_list.($ip.Name)
				}
			} else {
				$ip_name = getFreeJoinParameter $out "Value"
				$out | Add-Member -MemberType NoteProperty -Name $ip_name -Value $source
			} 
		}
		
		foreach($i in $LeftObject) {
			foreach($j in $RightObject) {
				if ( !($FilterScript.Invoke($i, $j))) {continue}
				$out = New-Object -TypeName PSobject             
				addJoinParameter $out $i ($i | select $LeftProperty)
				addJoinParameter $out $j ($j | select $RightProperty)
				if($CustomProperty) {
					$custom = fillTempObject $CustomProperty $i $j
					addJoinParameter $out $custom $custom
				}
				$out
			}
		}
	}
	end{}
}