#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
#$sut = "AdminTools.Experimental.psm1"
#import-module "$here\$sut"
remove-module AdminTools -ErrorAction SilentlyContinue; import-module AdminTools

Describe "Join-Object" {
	
	mkdir TestDrive:\1 -Force | Out-Null
	mkdir TestDrive:\2 -Force | Out-Null
	
	mkdir TestDrive:\1\a | Out-Null
	mkdir TestDrive:\1\b | Out-Null
	mkdir TestDrive:\1\ab | Out-Null
	
	mkdir TestDrive:\2\c | Out-Null
	mkdir TestDrive:\2\d | Out-Null
	mkdir TestDrive:\2\ab | Out-Null
	
	$a = ls TestDrive:\1
	$b = ls TestDrive:\2
	
    It "объединение по одинаковым значениям" {
		$res = Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime LastWriteTime
		$res.Name | Should Be "ab"
		$res.LastWriteTime | Should Be $a.LastWriteTime
		$res.JoinLastWriteTime | Should Be $b.LastWriteTime
    }
	
	It "вычисляемое свойство для правого параметра" {
		$res = Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime @{Name = "Dir2_LastWriteTime"; Expression = {$_.LastWriteTime}}
		$res.Name | Should Be "ab"
		$res.LastWriteTime | Should Be $a.LastWriteTime
		$res.Dir2_LastWriteTime | Should Be $b.LastWriteTime
    }
	
	It "вычисляемое свойство для обоих параметров" {
		$res = Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime LastWriteTime @{Name = "diff"; Expression={param($i,$j);  [int]($i.LastWriteTime - $j.LastWriteTime).TotalSeconds }}
		$res.Name | Should Be "ab"
		$res.LastWriteTime | Should Be $a.LastWriteTime
		$res.JoinLastWriteTime | Should Be $b.LastWriteTime
		[Math]::Abs($res.diff) | Should BeLessThan 3
    }
	
	It "передача левого параметра через конвейер" {
		$res = $a | Join-Object -RightObject $b -where { param($i,$j); $i.name -eq $j.name } -LeftProperty name, LastWriteTime -RightProperty LastWriteTime
		$res.Name | Should Be "ab"
		$res.LastWriteTime | Should Be $a.LastWriteTime
		$res.JoinLastWriteTime | Should Be $b.LastWriteTime
    }
	
	It "объединение по одинаковым значениям и добавление всех левых строк" {
		$res = Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, LastWriteTime LastWriteTime -Type AllInLeft
		$res.Name | Should Be "ab", "a", "b"
		$res.LastWriteTime | Should Be $a.LastWriteTime
		$res.JoinLastWriteTime | Should Be $b[0].LastWriteTime, $null, $null
    }
	
	It "фильтрация чисел" {
		$res = Join-Object (1..9) (1..9) { param($i, $j); $i+$j -eq 10 } 
		$res.Value | Should Be $(1..9)
		$res.JoinValue | Should Be $(9..1)
    }
	
	It "передача левого параметра через конвейер и добавление всех правых строк" {
		$res = $a | Join-Object -RightObject $b -where { param($i,$j); $i.name -eq $j.name } -LeftProperty name, @{Name="LastWriteTime2"; Expression={$_.LastWriteTime}} -RightProperty LastWriteTime -Type AllInRight
		$res.Name | Should Be "ab", $null, $null
		$res.LastWriteTime | Should Be $b.LastWriteTime
		$res.LastWriteTime2 | Should Be $a[1].LastWriteTime, $null, $null #$a[1] = "ab", т.к. "a", "ab", "b"
    }
	
	It "передача левого параметра через конвейер и добавление всех левых строк" {
		$res = $a | Join-Object -RightObject $b -where { param($i,$j); $i.name -eq $j.name } -LeftProperty name, LastWriteTime -RightProperty LastWriteTime -Type AllInLeft
		$res.Name | Should Be "ab", "a", "b"
		$res.LastWriteTime | Should Be $a.LastWriteTime
		$res.JoinLastWriteTime | Should Be $b[0].LastWriteTime, $null, $null
    }
	
	It "передача левого параметра через конвейер и добавление всех строк" {
		$res = $a | Join-Object -RightObject $b -where { param($i,$j); $i.name -eq $j.name } -LeftProperty name, LastWriteTime -RightProperty Name, LastWriteTime -Type AllInBoth
		$res.Name | Should Be "ab", "a", "b", $null, $null
		$res.JoinName | Should Be "ab", "c", "d", $null, $null
		$res.LastWriteTime | Should Be ($a.LastWriteTime + ($null, $null))
		$res.JoinLastWriteTime | Should Be ($b.LastWriteTime + ($null, $null))
    }
	
	
	It "извлечение свойств по шаблонам" {
		$res = Join-Object $a $b { param($i,$j); $i.name -eq $j.name } name, *Time *Time
		$res.Name | Should Be "ab"
		$res.LastWriteTime | Should Be $a[1].LastWriteTime
		$res.LastAccessTime | Should Be $a[1].LastAccessTime
		$res.CreationTime | Should Be $a[1].CreationTime
		$res.JoinLastWriteTime | Should Be $b[0].LastWriteTime
		$res.JoinLastAccessTime | Should Be $b[0].LastAccessTime
		$res.JoinCreationTime | Should Be $b[0].CreationTime
    }
}
