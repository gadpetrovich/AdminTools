[cmdletbinding(SupportsShouldProcess=$True)]  
param ([switch]$Force)
$srcDir = Get-Item .
$installPath = ($env:PSModulePath -split ";")[0]
$destPath = [System.IO.Path]::Combine($installPath, $srcDir.Name)
if ($pscmdlet.ShouldProcess("���������� " + $srcDir.Name) -and
	($Force -or $pscmdlet.ShouldContinue("��������� ���������� " + $srcDir.Name + " � ������� $destPath", ""))
) {
	if ($WhatIfPreference -or $srcDir.FullName -ne $destPath) {
		echo ("����������� ��������� ���������� " + $srcDir.Name + " � ������� $destPath")
		if (Test-Path $destPath) {
			echo "�������� �������������� ����������"
			rm $destPath -Force -Recurse -ErrorAction SilentlyContinue
		}
		mkdir $installPath -Force | out-null
		echo "����������� ����������"
		cp $srcDir $installPath -Force -Recurse
	} else {
		Write-Warning "���������� ��� �����������"
	}
}