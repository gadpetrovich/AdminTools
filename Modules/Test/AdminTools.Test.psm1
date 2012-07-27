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
  ��������� ���������� Join-Object ������������ ����� ��������� ������������ ���� �������, �������������� ����������� InputObject � JoinObject. ���� �����-���� ����� ����� � InputObject � JoinObject ���������, �� � ����� ���� �� ������ JoinObject ����������� ������ "Join". �������� ��� ����������� �������, ��������� ���������� ���� (Id, Name), �������� �������������� ������ � ������: Id, Name, JoinId, JoinName.
  � ������, ����� �������� ������� �� ����������� �� ������ PSObject, ��������� InputProperty � JoinProperty ��������������, � ����� ����� ��������������� ������ ����������, ��� "Value" � "JoinValue".
    
 .Parameter InputObject
  ������ ������ ��� �����������. ����� �������������� ��� �������� �������� �� ���������.

 .Parameter JoinObject
  ������ ������ ��� �����������. � ������ �����, ����������� � ������ �� InputObject, ����� ����������� ������� "Join".
 
 .Parameter FilterScript
  ��������� ���� �������, ������������ ��� ���������� ��������. ��� �������� ���������� � ������ ����������� param() ( { param($i,$j); ... }). ���������� $i �������� ������ �� InputObject, $j - �� JoinObject.
  
 .Parameter InputProperty
  ��������� ������ ����� �� InputObject ��� ���������� � �������������� ������. �������������� ����� ���������.

  �������� ��������� InputProperty ����� ���� ����� ����������� ���������. ����� ������� ����������� ��������, ����������� ���-�������. ���������� �����:
  -- Name (��� Label) <������>
  -- Expression <������> ��� <���� �������>
  
  � ������ �����, ����������� � ��� ������������� ������, ����� ����������� ������� "Join".
 
 .Parameter JoinProperty
  ��������� ������ ����� �� JoinObject ��� ���������� � �������������� ������. �������������� ����� ���������.

  �������� ��������� JoinProperty ����� ���� ����� ����������� ���������. ����� ������� ����������� ��������, ����������� ���-�������. ���������� �����:
  -- Name (��� Label) <������>
  -- Expression <������> ��� <���� �������>
  
  � ������ �����, ����������� � ��� ������������� ������, ����� ����������� ������� "Join".

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
   PS C:\> $a | Join-Object -JoinObject $b -where { param($i,$j); $i.name -eq $j.name } -InputProperty name, LastWriteTime -JoinProperty LastWriteTime

   ��������
   -----------
   ��� ������� ���������� ������ ������ � ���������� � ������������ ������� � c:\dir1 � c:\dir2. ������������ �������� ��������� InputObject ����� ��������.
   
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
			#  "$i -is [PSObject] �� ��������, �.�. ��� ��������� InputObject � ���� 1,2 
			#  �� ����� ���������� $true. $false �����, ���� �������� ������� � ���� (1,2) ��� @(1,2).
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