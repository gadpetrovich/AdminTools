#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
#$sut = "AdminTools.Programs.psm1"
#import-module "$here\$sut"
remove-module AdminTools -ErrorAction SilentlyContinue; import-module AdminTools

Describe "Get-Program" {
    Context "Список из двух программ" {
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
            $OutputObj.Name = $Name
            return $OutputObj
        }

        Mock -ModuleName AdminTools.Programs Close-RegistryKey { #param($Key)
            #$Key.Close()
        }

        Mock -ModuleName AdminTools.Programs Get-RegistryValue { #param($Key, $ValueName)
            #return $Key.GetValue($ValueName)
            
            if ($Key.Name -ieq "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\app1") {
                switch ($ValueName) {
                    "DisplayName" { "app1"; Break }
                    "DisplayVersion" { "1.1.1.1"; Break }
                    "ParentKeyName" { $null;  Break }
                    "SystemComponent" { 0;  Break }
                    default { ""; Break }
                }
            } elseif ($Key.Name -ieq "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\app2") {
                switch ($ValueName) {
                    "DisplayName" { "app2"; Break }
                    "DisplayVersion" { "2.2.2.2"; Break }
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
            if ($Key.Name -ieq "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall") {
                return @("app1", "app2")
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
            return $true
        }

        Mock -ModuleName AdminTools.Programs Get-RegKeyLastWriteTime { #param($ComputerName, $Key, $SubKey, [switch]$NoEnumKey)
            $OutputObj = "" | Select-Object LastWriteTime
            $OutputObj.LastWriteTime = 123
            $OutputObj
        }
        
		$result = Get-Program ".*"
	
        It "Имена приложений" {
		    $result.Name | Should Be "app1", "app2"   
        }
        It "Версии" {
		    $result.Version | Should Be "1.1.1.1", "2.2.2.2"   
        }
    }
}
