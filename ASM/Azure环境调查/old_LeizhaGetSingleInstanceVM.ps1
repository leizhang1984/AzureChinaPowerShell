#import azure supoort on general powershell
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1'

#Set Execution Policy
Set-ExecutionPolicy Unrestricted

Add-AzureAccount -Environment AzureChinaCloud

$SubscriptionNames = Get-AzureSubscription | select -ExpandProperty SubscriptionName 


$result=@()
foreach ($sub in $SubscriptionNames)
{ 

	Select-AzureSubscription -SubscriptionName $sub -Current

	$vms=Get-AzureVM

	#$result=@()
	foreach($vm in $vms)
	{
    		$deploymentId = (Get-AzureDeployment -ServiceName $vm.ServiceName).DeploymentId
    		$endpoints = Get-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name|Get-AzureEndpoint
    		$vip=($endpoints|Select Vip|Sort-Object -Property Vip -Unique)
		
		$vmObject = New-Object PSObject
		$vmObject | Add-Member -MemberType NoteProperty -Name "SubscriptioName" -Value $sub
		$vmObject | Add-Member -MemberType NoteProperty -Name "ServiceName" -Value $vm.ServiceName
		$vmObject | Add-Member -MemberType NoteProperty -Name "DeploymentId" -Value $deploymentId
		$vmObject | Add-Member -MemberType NoteProperty -Name "AvailabilitySetName" -Value $vm.AvailabilitySetName
		$vmObject | Add-Member -MemberType NoteProperty -Name "Status" -Value $vm.Status


		$vmObject | Add-Member -MemberType NoteProperty -Name "InstanceName" -Value $vm.InstanceName
		$vmObject | Add-Member -MemberType NoteProperty -Name "PublicIPName" -Value $vm.PublicIPName
		$vmObject | Add-Member -MemberType NoteProperty -Name "PublicIP" -Value $vm.PublicIPAddress
		$vmObject | Add-Member -MemberType NoteProperty -Name "VIP" -Value $vip

		$result+= $vmObject


    		#$obj=New-Object PSObject

		#$obj|Add-Member NoteProperty SubscriptioName($sub)
    		#$obj|Add-Member NoteProperty ServiceName($vm.ServiceName)
    		#$obj|Add-Member NoteProperty DeploymentId($deploymentId)
    		#$obj|Add-Member NoteProperty AvailabilitySetName($vm.AvailabilitySetName)
		#$obj|Add-Member NoteProperty Status($vm.Status)

		#$obj|Add-Member NoteProperty InstanceName($vm.InstanceName)
    		#$obj|Add-Member NoteProperty PublicIPName($vm.PublicIPName)    
    		#$obj|Add-Member NoteProperty PublicIP($vm.PublicIPAddress)
    		#$obj|Add-Member NoteProperty VIP($vip)
    		#$result+=$obj
	}

	#$result|Select SubscriptioName,ServiceName,DeploymentId,AvailabilitySetName,Status,InstanceName,PublicIPName,PublicIP,VIP|Export-Csv -Path 'C:\export.csv'
	
}
$result | Export-Csv C:\vmlist.csv -NoTypeInformation
'导出虚拟机信息完成'