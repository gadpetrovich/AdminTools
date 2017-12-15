#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
#$sut = "AdminTools.Experimental.psm1"
#import-module "$here\$sut"
remove-module AdminTools -ErrorAction SilentlyContinue; import-module AdminTools

Describe "Join-Objects" {
    
	mkdir TestDrive:\1 -Force | Out-Null
	mkdir TestDrive:\2 -Force | Out-Null
	
	mkdir TestDrive:\1\a | Out-Null
	mkdir TestDrive:\1\b | Out-Null
	
	mkdir TestDrive:\2\a | Out-Null
	mkdir TestDrive:\2\c | Out-Null
	
	$a = ls TestDrive:\1
	$b = ls TestDrive:\2
	
    It "объединение по типу AllInBoth" {
		$res = Join-Objects $a, $b name ("LastWriteTime"), ("LastWriteTime") AllInBoth
		$res.Name | Should Be "a", "b", "c"
        ($res | gm -MemberType NoteProperty).Name | Should Be "JoinLastWriteTime", "LastWriteTime", "Name"
		$res[0].LastWriteTime | Should Be $a[0].LastWriteTime
        $res[1].LastWriteTime | Should Be $a[1].LastWriteTime
        $res[2].LastWriteTime | Should Be $null
		$res[0].JoinLastWriteTime | Should Be $b[0].LastWriteTime
        $res[1].JoinLastWriteTime | Should Be $null
        $res[2].JoinLastWriteTime | Should Be $b[1].LastWriteTime
    }
	
    It "объединение по типу AllInBoth с добавлением имени параметра объединения для втрого списка" {
		$res = Join-Objects $a, $b name ("LastWriteTime"), ("Name", "LastWriteTime") AllInBoth
		$res.Name | Should Be "a", "b", "c"
        ($res | gm -MemberType NoteProperty).Name | Should Be "JoinLastWriteTime", "LastWriteTime", "Name"
    }
}
