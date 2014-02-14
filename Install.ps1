$srcDir = Get-Item .
$installPath = ($env:PSModulePath -split ";")[0]
$destPath = [System.IO.Path]::Combine($installPath, $srcDir.Name)

if ($srcDir.FullName -ne $destPath) {
	echo ("����������� ��������� ���������� " + $srcDir.Name + " � ������� $destPath")
	if (Test-Path $destPath) {
		echo "������ ������������� ����������"
		rm $destPath -Force -Recurse -ErrorAction SilentlyContinue
	}
	mkdir $installPath -Force
	echo "����������� ����������"
	cp $srcDir $installPath -Force -Recurse
} else {
	echo "���������� ��� �����������"
}
 