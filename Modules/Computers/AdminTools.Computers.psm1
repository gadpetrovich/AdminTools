function Add-ComputerToAD(
	$OldComputerName,
	$NewComputerName = $OldComputerName,
	$Domain = $env:USERDNSDOMAIN,
	$AccountOU)
{
	#wmic.exe /interactive:off ComputerSystem Where "name = '%computername%'" call JoinDomainOrWorkgroup AccountOU="%AccOU%" FJoinOptions=3 Name="%NameDomain%" Password="%NewPass%" UserName="%NewAdmin%" >>rejoin.log
	
	# использование паролей:
	#http://bsonposh.com/archives/338
	
	# добавление в домен с переименовыванием компьютера
	#http://blogs.technet.com/b/heyscriptingguy/archive/2012/02/29/use-powershell-to-replace-netdom-commands-to-join-the-domain.aspx
	#(Get-WmiObject win32_computersystem).rename("newname")
	#Add-Computer -Credential iammred\administrator -DomainName iammred.net
	
	
	#http://social.technet.microsoft.com/Forums/en/w7itprogeneral/thread/22315110-cf36-440b-9590-ba1d78b4331d
	#http://letitknow.wordpress.com/2011/02/12/domain-join-using-powershell-v2-0-part-i/
	
}