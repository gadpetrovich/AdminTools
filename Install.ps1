[cmdletbinding(SupportsShouldProcess=$True)]  
param ([switch]$Force)
$srcDir = Get-Item .
$installPath = ($env:PSModulePath -split ";")[0]
$destPath = [System.IO.Path]::Combine($installPath, $srcDir.Name)
if ($pscmdlet.ShouldProcess("Расширение " + $srcDir.Name) -and
	($Force -or $pscmdlet.ShouldContinue("Установка расширения " + $srcDir.Name + " в каталог $destPath", ""))
) {
	if ($WhatIfPreference -or $srcDir.FullName -ne $destPath) {
		echo ("Выполняется установка расширения " + $srcDir.Name + " в каталог $destPath")
		if (Test-Path $destPath) {
			echo "Удаление установленного расширения"
			rm $destPath -Force -Recurse -ErrorAction SilentlyContinue
		}
		mkdir $installPath -Force | out-null
		echo "Копирование расширения"
		cp $srcDir $installPath -Force -Recurse
	} else {
		Write-Warning "Расширение уже установлено"
	}
}