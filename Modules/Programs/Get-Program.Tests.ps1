#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
#$sut = "AdminTools.Programs.psm1"
#import-module "$here\$sut"
remove-module AdminTools -ErrorAction SilentlyContinue; import-module AdminTools

Describe "Get-Program" {
    Context "Локальные программы и программы на компьютерах в сети" {
        Mock -ModuleName AdminTools.Programs Open-RegistryRemoteKey{ 
            #return [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine', $Computer, $Arch)
            $OutputObj = "" | Select-Object View, ComputerName
            $OutputObj.View = if ($Arch -eq [Microsoft.Win32.RegistryView]::Registry32) { "Registry32" } else { "Registry64" }
            $OutputObj.ComputerName = $Computer
            return $OutputObj
        }
        
        Mock -ModuleName AdminTools.Programs Open-RegistrySubKey { #param($HKLM, $Name)
            #return $HKLM.OpenSubKey($Name)
            $OutputObj = "" | Select-Object Name
            $OutputObj.Name = $HKLM.ComputerName + "\\" + $Name
            return $OutputObj
        }

        Mock -ModuleName AdminTools.Programs Close-RegistryKey { #param($Key)
            #$Key.Close()
        }

        Mock -ModuleName AdminTools.Programs Get-RegistryValue { #param($Key, $ValueName)
            #return $Key.GetValue($ValueName)
            
            if ($Key.Name -ieq "$($env:COMPUTERNAME)\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\app1") {
                switch ($ValueName) {
                    "DisplayName" { "app1"; Break }
                    "DisplayVersion" { "1.1.1.1"; Break }
                    "ParentKeyName" { $null;  Break }
                    "SystemComponent" { 0;  Break }
                    default { ""; Break }
                }
            } elseif ($Key.Name -ieq "$($env:COMPUTERNAME)\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\app2") {
                switch ($ValueName) {
                    "DisplayName" { "app2"; Break }
                    "DisplayVersion" { "2.2.2.2"; Break }
                    "ParentKeyName" { $null;  Break }
                    "SystemComponent" { 0;  Break }
                    default { ""; Break }
                }
            } elseif ($Key.Name -ieq "comp1\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\app3") {
                switch ($ValueName) {
                    "DisplayName" { "application 3"; Break }
                    "DisplayVersion" { "1.0.0.1"; Break }
                    "ParentKeyName" { $null;  Break }
                    "SystemComponent" { 0;  Break }
                    default { ""; Break }
                }
            } elseif ($Key.Name -ieq "comp1\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\app4") {
                switch ($ValueName) {
                    "DisplayName" { "application 4"; Break }
                    "DisplayVersion" { "2.0.0.4"; Break }
                    "ParentKeyName" { $null;  Break }
                    "SystemComponent" { 0;  Break }
                    default { ""; Break }
                }
            } elseif ($Key.Name -ieq "comp2\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\app5") {
                switch ($ValueName) {
                    "DisplayName" { "application 5"; Break }
                    "DisplayVersion" { "3.0.0.5"; Break }
                    "ParentKeyName" { $null;  Break }
                    "SystemComponent" { 0;  Break }
                    default { ""; Break }
                }
            } elseif ($Key.Name -ieq "comp2\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\app6") {
                switch ($ValueName) {
                    "DisplayName" { "application 6"; Break }
                    "DisplayVersion" { "2.0.0.6"; Break }
                    "ParentKeyName" { $null;  Break }
                    "SystemComponent" { 0;  Break }
                    default { ""; Break }
                }
            } elseif ($Key.Name -ieq "comp2\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\app7") {
                switch ($ValueName) {
                    "DisplayName" { "application 7"; Break }
                    "DisplayVersion" { "2.0.0.7"; Break }
                    "ParentKeyName" { $null;  Break }
                    "SystemComponent" { 0;  Break }
                    default { ""; Break }
                }
            } else {
                return "asdf"
            }
        }

        Mock -ModuleName AdminTools.Programs Get-RegistryValueNames { #param($Key)
            #return $Key.GetValueNames()
            return "asdf"
        }

        Mock -ModuleName AdminTools.Programs Get-RegistrySubKeyNames { #param($Key)
            #return $Key.GetSubKeyNames()
            if ($Key.Name -ieq "$($env:COMPUTERNAME)\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall") {
                return @("app1", "app2")
            } 
            elseif ($Key.Name -ieq "comp1\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall") {
                return @("app3", "app4")
            } 
            elseif ($Key.Name -ieq "comp2\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall") {
                return @("app5", "app6", "app7")
            } 
            else {
                return "asdf"
            }
        }

        Mock -ModuleName AdminTools.Programs Get-Architectures { #param($Computer)
            $archs = @([Microsoft.Win32.RegistryView]::Registry32)
	        #$arch = (get-wmiobject -Class Win32_OperatingSystem -ComputerName $Computer).OSArchitecture
	        #if ($arch -Match "64") {
		    #    $archs += [Microsoft.Win32.RegistryView]::Registry64
	        #}
            return $archs
        }

        Mock -ModuleName AdminTools.Programs Test-Connection { #param($ComputerName, $Count, $ea)
            return $ComputerName -in $env:COMPUTERNAME, "comp1" , "comp2"
        }

        Mock -ModuleName AdminTools.Programs Get-RegKeyLastWriteTime { #param($Key)
            return ([DateTime]::Parse("01.01.2017 1:00"))
        }
        
		$result = Get-Program ".*"
	
        It "Имена приложений" {
		    $result.Name | Should Be "app1", "app2"   
        }
        It "Версии" {
		    $result.Version | Should Be "1.1.1.1", "2.2.2.2"   
        }
        It "Компьютер" {
            $result.ComputerName | select -Unique | Should Be $env:COMPUTERNAME
        }

        $result = Get-Program -ComputerName comp1, comp2 .*
        It "Имена приложений для компьютеров в сети" {
		    $result.Name | Should Be "application 3", "application 4", "application 5", "application 6", "application 7"
        }

        It "Версии для приложений на компьютерах в сети" {
		    $result.Version | Should Be "1.0.0.1", "2.0.0.4", "3.0.0.5", "2.0.0.6", "2.0.0.7"
        }

        It "Имена компьютеров" {
		    $result.ComputerName | Should Be "comp1", "comp1", "comp2", "comp2", "comp2"
        }

        $result = Get-Program -ComputerName fictiveComp .* -ErrorVariable err -ErrorAction SilentlyContinue
        It "Поиск программ на несуществующем компьютере" {
            $err.Count | Should Be 1
            $err[0].ToString() | Should Be "Компьютер fictiveComp не отвечает"
            $result.Count | Should Be 0
        }

        $result = Get-Program -ComputerName comp2 "^app.*6$"
        It "Поиск программы по регулярному выражению" {
		    $result.Name | Should Be "application 6"
        }
    }

    Context "32-битная система" {
    }

    Context "64-битная система" {
    }

    Context "64-битная система, поиск программ на 32-битных системах" {
    }

    Context "32-битная система, поиск программ на 64-битных системах" {
    }

}
