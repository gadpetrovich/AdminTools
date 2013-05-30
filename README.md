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

Wait-InstallProgram

Wait-WMIRestartComputer

Uninstall-Program - Удаляет указанную программу.

Install-Program - Устанавливает программу из указанного источника.

### Services

Start-RemoteService - Запускает службы на удаленном компьютере.

Stop-RemoteService - Останавливает службы на удаленном компьютере.

### Test

Skip-Null

Get-NetView

Format-TableAuto

New-PInvoke

ConvertTo-Encoding

Get-Property

Start-ProgressSleep

Join-Object - Объединяет два списка в один.

### UserAndGroups

Add-UserToAdmin

Remove-UserFromAdmin

Get-AdminUsers

### WMI

Get-OsInfo

Get-ComputerInfo

Get-BiosInfo

Get-LogicalDiskInfo

Get-DiskPartitionInfo

Get-DiskDriveInfo

Get-ProcessorInfo

Get-MotherboardInfo

Get-OnBoardDeviceInfo - Список устройств, встроенных в материнскую плату.

Get-PhysicalMemoryInfo - Список модулей памяти, расположенных на материнской плате.

Get-SoundDeviceInfo - Список звуковых карт.

Get-VideoControllerInfo - Список видеокарт.

Get-NetworkAdapterInfo - Список сетевых карт.

Get-NetworkAdapterConfigurationInfo - Список настроек сетевых карт.

Алиасы
------
*   join - Join-Object
*   get - Select-Object
*   Add-Program - Install-Program
*   Remove-Program - Uninstall-Program
*   fta - Format-TableAuto
*	Get-NetObject - Get-NetView
*	ul - Update-Length