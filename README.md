﻿AdminTools
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

### Services

Start-RemoteService - Запускает службы на удаленном компьютере.

Stop-RemoteService - Останавливает службы на удаленном компьютере.

### Test

Skip-Null

Get-OsInfo

Get-ComputerInfo

Get-BiosInfo

Get-LogicalDiskInfo

Get-DiskPartitionInfo

Get-DiskDriveInfo

Get-ProcessorInfo

Get-NetObject

Format-TableAuto

Join-Object - Объединяет два списка в один.

### UserAndGroups

Add-UserToAdmin

Remove-UserFromAdmin

Алиасы
------
*   join - Join-Object
*   get - Select-Object
*   Add-Program - Install-Program
*   Remove-Program - Uninstall-Program
*   fta - Format-TableAuto
