Add-AzureAccount -Environment AzureChinaCloud

$SubscriptionNames = Get-AzureSubscription | select -ExpandProperty SubscriptionName 

$result=@()
foreach ($sub in $SubscriptionNames)
{ 
	Select-AzureSubscription -SubscriptionName $sub -Current

	#Get All Cloud Service Name
	$AllServiceNames = (Get-AzureService).servicename

	foreach ($ServiceName in $AllServiceNames)
	{
		
		$deploymentId = (Get-AzureDeployment -ServiceName $ServiceName).DeploymentId	

		$deployments = Get-AzureDeployment -ServiceName $ServiceName -Slot Production
		foreach ($InstanceList in $deployments.RoleInstanceList)
		{
			
			if($InstanceList.InstanceName -like '*_IN_*')
			{
				$VMType="Cloud Service";

		        	$vmObject = New-Object PSObject
		        	$vmObject | Add-Member -MemberType NoteProperty -Name "SubscriptioName" -Value $sub
	
		        	$vmObject | Add-Member -MemberType NoteProperty -Name "ServiceName" -Value $ServiceName
		        	$vmObject | Add-Member -MemberType NoteProperty -Name "Type" -Value $VMType
		        	$vmObject | Add-Member -MemberType NoteProperty -Name "DeploymentId" -Value $deploymentId 
		        	$vmObject | Add-Member -MemberType NoteProperty -Name "InstanceName" -Value $InstanceList.InstanceName

		        	$vmObject | Add-Member -MemberType NoteProperty -Name "Status" -Value $InstanceList.InstanceStatus
                		$vmObject | Add-Member -MemberType NoteProperty -Name "AvailabilitySetName" -Value " "
                		$vmObject | Add-Member -MemberType NoteProperty -Name "VIP" -Value $deployments.VirtualIPs[0].Address

                $result+= $vmObject  
                
			}
			else
			{
				$VMType="Virtual Machine";
				#break;
                		$vm = Get-AzureVM -ServiceName $ServiceName -Name $InstanceList.InstanceName 
                        $endpoints = Get-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name|Get-AzureEndpoint
                		$vip=($endpoints|Select Vip|Sort-Object -Property Vip -Unique)

                		$vmObject = New-Object PSObject
		        	$vmObject | Add-Member -MemberType NoteProperty -Name "SubscriptioName" -Value $sub
	
		        	$vmObject | Add-Member -MemberType NoteProperty -Name "ServiceName" -Value $ServiceName
		        	$vmObject | Add-Member -MemberType NoteProperty -Name "Type" -Value $VMType
		        	$vmObject | Add-Member -MemberType NoteProperty -Name "DeploymentId" -Value $deploymentId 
		        	$vmObject | Add-Member -MemberType NoteProperty -Name "InstanceName" -Value $InstanceList.InstanceName

		        	$vmObject | Add-Member -MemberType NoteProperty -Name "Status" -Value $vm.Status
                		$vmObject | Add-Member -MemberType NoteProperty -Name "AvailabilitySetName" -Value $vm.AvailabilitySetName
                		$vmObject | Add-Member -MemberType NoteProperty -Name "VIP" -Value $vip

                $result+= $vmObject  
			}
		}
	}
}

$result | Export-Csv C:\vmlist.csv -NoTypeInformation
'导出虚拟机信息完成'




