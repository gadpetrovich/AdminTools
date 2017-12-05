#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
#$sut = "AdminTools.Experimental.psm1"
#import-module "$here\$sut"
remove-module AdminTools -ErrorAction SilentlyContinue; import-module AdminTools

Describe "Invoke-Parallel" {
    It "количество передаваемых данных для заданий" {
		1..11 | Foreach-Parallel { $_.count } -ObjPerJob 5 | Should Be (,1 * 11)
		"a", "b", "c" | Foreach-Parallel { $_ + "1" } -ObjPerJob 2 | sort | Should Be "a1", "b1", "c1"
		
		$test = [pscustomobject]@{a=1;b=2}, [pscustomobject]@{a=2;b=3}, [pscustomobject]@{a=3;b=4}
		$source = [pscustomobject]@{a=1;b=2}, [pscustomobject]@{a=2;b=3}, [pscustomobject]@{a=3;b=4}
		$result = $source | Foreach-Parallel { $_ } -ObjPerJob 2 | sort a 
		$result.a | Should Be ($test.a)
		$result.b | Should Be ($test.b)
    }
	
	It "корректное получение и отправка PSCustomObject" {
		$test =   [pscustomobject]@{a=2;b=1}, [pscustomobject]@{a=3;b=2}
		$source = [pscustomobject]@{a=1;b=2}, [pscustomobject]@{a=2;b=3}
		$result = $source | Foreach-Parallel { $_.a += 1; $_.b -= 1; $_ } | sort a 
		$result.a | Should Be ($test.a)
		$result.b | Should Be ($test.b)
    }
	
	It "запуск заданий без ожидания завершения" {
		$jobs = @()
		$result1 = 1..5 | Foreach-Parallel { $_ } -Jobs ([ref]$jobs) -Throttle 2
		$jobs.count | Should Be 5
		($jobs | ? State -eq "Completed").count | Should BeGreaterThan 1
		$result1.count | Should BeGreaterThan 1
		$result2 = Foreach-Parallel -Jobs ([ref]$jobs) -Wait
		($jobs | ? State -eq "Completed").count | Should Be 5
		$result2.count | Should BeLessThan 4
		$result1 + $result2 | sort | Should Be (1..5)
	}
	
	It "проверка Begin и End" {
		$result = 1..10 | Foreach-Parallel -Begin { $script:a = 0 } -process { $script:a += $_ } -end { $a } -ObjPerJob 4
		$result | Should Be (1 + 2 + 3 + 4), (5 + 6 + 7 + 8), (9 + 10)
	}
	
	It "передача одного аргумента" {
		$test = 1..5 | % { $_ * 3 }
		$result = 1..5 | Foreach-Parallel {param($i); $_ * $i } -Args 3
		$result | Should Be $test
	}
	
	It "передача двух аргументов" {
		$test = 4, 6, 12, 12, 20
		$result = 1..5 | Foreach-Parallel {$_ * $args[$_ % 2] } -Args 3, 4
		$result | Should Be $test
	}
}
