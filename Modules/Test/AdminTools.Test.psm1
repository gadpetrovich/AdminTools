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
  ������ ����� �� InputObject ��� ���������� � �������������� ������.
  
 .Parameter JoinProperty
  ������ ����� �� JoinObject ��� ���������� � �������������� ������. � ������ �����, ����������� � ������ �� InputObject, ����� ����������� ������� "Join".

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
   PS C:\> $comp1 = Get-InstalledSoftware comp1
   PS C:\> $comp2 = Get-InstalledSoftware comp2
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
		[String[]]$InputProperty = "*",
		[String[]]$JoinProperty = "*"
	)
	
	begin{}
	process {
		
		foreach($i in $InputObject) {
			foreach($j in $JoinObject) {
				if ( !($FilterScript.Invoke($i, $j))) {continue}
				
				$out = New-Object -TypeName PSobject             
				
				# ��������� �������� �� ������� ������
				#write-host $i $i.Gettype().fullname
				if( $i -is [PSObject] ){
					#write-host $i " is psobject"
					$props = $i | Get-Member -MemberType *Property -Name $InputProperty
					foreach($ip in $props) {
						$out | Add-Member -MemberType NoteProperty -Name $ip.Name -Value $i.($ip.Name)
					}
				} else {
					#write-host $i " not is psobject"
					$out | Add-Member -MemberType NoteProperty -Name Value -Value $i
				} 
				# ��������� �������� �� ������� ������
				if( $j -is [PSObject] ){
					$props = $j | Get-Member -MemberType *Property -Name $JoinProperty
					foreach($jp in $props) {
						$jp_name = $jp.Name
						if (($out | Get-Member -Name $jp_name) -ne $null) {
							$jp_name = "Join" + $jp_name
						}
						$out | Add-Member -MemberType NoteProperty -Name $jp_name -Value $j.($jp.Name)
					}
				} else {
					$out | Add-Member -MemberType NoteProperty -Name JoinValue -Value $j
				}
				$out
			}
		}
	}
	end{}
}