#
# Манифест модуля для модуля "AdminTools".
#
# Создано: Pavel Sharapov
#
# Дата создания: 12.07.2012
#

@{

# Файл модуля скрипта или двоичного модуля, связанный с данным манифестом
ModuleToProcess = 'AdminTools.psm1'

# Номер версии данного модуля.
ModuleVersion = '1.0'

# Уникальный идентификатор данного модуля
GUID = '1e7c6d7f-0095-40d4-9e10-ebe716397e41'

# Автор данного модуля
Author = 'Pavel Sharapov'

# Компания, создавшая данный модуль, или его поставщик
CompanyName = 'VSEGEI'

# Заявление об авторских правах на модуль
Copyright = '(c) 2012 Pavel Sharapov. Все права защищены.'

# Описание функций данного модуля
Description = ''

# Минимальный номер версии обработчика Windows PowerShell, необходимой для работы данного модуля
PowerShellVersion = '5.0'

# Имя узла Windows PowerShell, необходимого для работы данного модуля
PowerShellHostName = ''

# Минимальный номер версии узла Windows PowerShell, необходимой для работы данного модуля
PowerShellHostVersion = '5.0'

# Минимальный номер версии компонента .NET Framework, необходимой для данного модуля
DotNetFrameworkVersion = ''

# Минимальный номер версии среды CLR (общеязыковой среды выполнения), необходимой для работы данного модуля
CLRVersion = ''

# Архитектура процессора (нет, X86, AMD64, IA64), необходимая для работы модуля
ProcessorArchitecture = ''

# Модули, которые необходимо импортировать в глобальную среду перед импортированием данного модуля
RequiredModules = @()

# Сборки, которые должны быть загружены перед импортированием данного модуля
RequiredAssemblies = @()

# Файлы скрипта (.ps1), которые запускаются в среде вызывающей стороны перед импортированием данного модуля
ScriptsToProcess = @()

# Файлы типа (.ps1xml), которые загружаются при импорте данного модуля
TypesToProcess = @()

# Файлы формата (PS1XML-файлы), которые загружаются при импорте данного модуля
FormatsToProcess = @()

# Модули для импортирования в модуль, указанный в параметре ModuleToProcess, в качестве вложенных модулей
NestedModules = @()

# Функции для экспорта из данного модуля
FunctionsToExport = 
	"Get-Program", "Wait-InstallProgram", "Wait-WMIRestartComputer", "Get-RemoteCmd", "Uninstall-Program", "Install-Program",
	"Skip-Null", "Get-NetView", "Get-NetBrowserStat", "Format-TableAuto", "New-PInvoke", "Assert-PSWindow", "ConvertTo-Encoding", "Get-Property", "ConvertTo-HashTable", "Start-ProgressSleep", "Select-Choice", "Get-RegKeyLastWriteTime", "Convert-PSObjectAuto", "Join-Object", "Join-Objects", "Invoke-Parallel", "Invoke-Progress", "Set-ActualBufferSize",
	"ConvertTo-HumanReadable", "Get-DiskUsage", "Get-DiskUsageLinear", "Get-DiskUsageRecursive", "Update-DirLength", "Update-Length",
	"Start-RemoteService", "Stop-RemoteService",
	"Add-UserToAdmin", "Get-AdminUsers", "Remove-UserFromAdmin",
	"Get-BiosInfo", "Get-ComputerInfo", "Get-DiskAssociation", "Get-DiskDriveInfo", "Get-DiskPartitionInfo", "Get-LogicalDiskInfo", "Get-MotherboardInfo", "Get-NetworkAdapterConfigurationInfo", "Get-NetworkAdapterInfo", "Get-OnBoardDeviceInfo", "Get-OsInfo", "Get-PhysicalMemoryInfo", "Get-ProcessInfo", "Get-ProcessorInfo", "Get-ServiceInfo", "Get-SoundDeviceInfo", "Get-VideoControllerInfo"

# Командлеты для экспорта из данного модуля
CmdletsToExport = '*'

# Переменные для экспорта из данного модуля
VariablesToExport = '*'

# Псевдонимы для экспорта из данного модуля
AliasesToExport = '*'

# Список всех модулей, входящих в пакет данного модуля
#ModuleList = @()
ModuleList = 'Experimental', 'FileSystem', 'Programs', 'UsersAndGroups', 'Services', 'WMI'

# Список всех файлов, входящих в пакет данного модуля
FileList = 'AdminTools.psd1', 'AdminTools.psm1'

# Личные данные, передаваемые в модуль, указанный в параметре ModuleToProcess
PrivateData = ''

}

