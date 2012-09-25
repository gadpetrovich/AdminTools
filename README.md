AdminTools
==========
Набор инструментов для администрирования компьютеров в локальной сети.

Установка
---------
Скопируте AdminTools в любой каталог, указанный в переменной `$env:PSModulePath`

Список модулей
--------------

### FileSystem

Get-DiskUsage - Возращает список вложенных каталогов с их суммарными размерами.

Update-DirLength - Обновляет список каталогов с их суммарными размерами.

Update-Length - Преобразует параметр Length в читаемый вид. 

### Programs

Get-Program - Возварщает список установленных программ.

Uninstall-Program - Удаляет указанную программу.

Install-Program - Устанавливает программу из указанного источника.

### Test

Get-OsInfo

Get-NetObject

Join-Object - Объединяет два списка в один.

### UserAndGroups

Add-UserToAdmin

Remove-UserFromAdmin

Алиасы
------
*   join - Join-Object
*   <del> get - Select-Object </del>