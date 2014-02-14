$srcDir = Get-Item .
$installPath = ($env:PSModulePath -split ";")[0]
$destPath = [System.IO.Path]::Combine($installPath, $srcDir.Name)

if ($srcDir.FullName -ne $destPath) {
	echo ("Выполняется установка расширения " + $srcDir.Name + " в каталог $destPath")
	if (Test-Path $destPath) {
		echo "Удаляю установленное расширение"
		rm $destPath -Force -Recurse -ErrorAction SilentlyContinue
	}
	mkdir $installPath -Force
	echo "Копирование расширения"
	cp $srcDir $installPath -Force -Recurse
} else {
	echo "Расширение уже установлено"
}
 