#Created By MSFT leizhang (leizha@microsoft.com) on Sep 13th, 2017
#Last Modified on Dec 29th, 2017

Clear-AzureProfile -Force

$logarray=@()

#For ARM Mode
Add-AzureRmAccount -EnvironmentName AzureChinaCloud

$SubscriptionNames = Get-AzureRMSubscription

foreach ($sub in $SubscriptionNames)
{
        Select-AzureRMSubscription -SubscriptionName $sub.Name 

        Write-Output "Processing " $sub.Name 

        $vmlist = Get-AzureRMVM

        foreach ($vm in $vmlist)
        {   
                #Get VM Status
                $vmStatus = Get-AzureRMVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
                $displayStatus = $vmStatus.Statuses.DisplayStatus[1]

                $output = new-object PSObject
                $output | add-member -Membertype NoteProperty -Name "Mode" -value "ARM"
                $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value "$($sub.Name)"
                $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "$($vm.ResourceGroupName)"
                $output | add-member -Membertype NoteProperty -Name "VMName" -value "$($vm.Name)"
                $output | add-member -Membertype NoteProperty -Name "OSType" -value "$($vm.StorageProfile.OsDisk.OsType)"
                
                $output | add-member -Membertype NoteProperty -Name "VMSize" -value "$($vm.HardwareProfile.VmSize)"
                $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($displayStatus)"
                
                #Availability Set
                if($vm.AvailabilitySetReference.Id)
                {
                    $avSetName = $vm.AvailabilitySetReference.Id.Split("/")[-1]
                }
                else
                {
                    $avSetName = "NULL"
                }
                $output | add-member -Membertype NoteProperty -Name "AvailabilitySetName" -value "$($avSetName)"

                #
                $isCustomerInitiatedMaintenanceAllowed = "False"
                $preMaintenanceWindowStartTime = "NULL"
                $preMaintenanceWindowEndTime = "NULL"

                $maintenanceWindowStartTime = "NULL"
                $maintenanceWindowEndTime = "NULL"

                $lastOperationResultCode = "NULL"
                $lastOperationMessage = "NULL"
  
                if($vmStatus.MaintenanceRedeployStatus)
                {
                   $isCustomerInitiatedMaintenanceAllowed= $vmStatus.MaintenanceRedeployStatus.IsCustomerInitiatedMaintenanceAllowed
                   $preMaintenanceWindowStartTime= $vmStatus.MaintenanceRedeployStatus.PreMaintenanceWindowStartTime
                   $preMaintenanceWindowEndTime= $vmStatus.MaintenanceRedeployStatus.PreMaintenanceWindowEndTime

                   $maintenanceWindowStartTime= $vmStatus.MaintenanceRedeployStatus.MaintenanceWindowStartTime
                   $maintenanceWindowEndTime= $vmStatus.MaintenanceRedeployStatus.MaintenanceWindowEndTime

                   $lastOperationResultCode= $vmStatus.MaintenanceRedeployStatus.LastOperationResultCode
                   $lastOperationMessage= $vmStatus.MaintenanceRedeployStatus.LastOperationMessage 
                }

                $output | add-member -Membertype NoteProperty -Name "IsCustomerInitiatedMaintenanceAllowed" -value "$($IsCustomerInitiatedMaintenanceAllowed)"
                $output | add-member -Membertype NoteProperty -Name "PreMaintenanceWindowStartTime" -value "$($PreMaintenanceWindowStartTime)"
                $output | add-member -Membertype NoteProperty -Name "PreMaintenanceWindowEndTime" -value "$($PreMaintenanceWindowEndTime)"

                $output | add-member -Membertype NoteProperty -Name "MaintenanceWindowStartTime" -value "$($MaintenanceWindowStartTime)"
                $output | add-member -Membertype NoteProperty -Name "MaintenanceWindowEndTime" -value "$($MaintenanceWindowEndTime)"

                $output | add-member -Membertype NoteProperty -Name "LastOperationResultCode" -value "$($LastOperationResultCode)"
                $output | add-member -Membertype NoteProperty -Name "LastOperationMessage" -value "$($LastOperationMessage)"

                $logarray += $output               
        }
  }

Write-Output "ARM is Done, prepare for ASM"

#For ASM Mode
Add-AzureAccount -Environment AzureChinaCloud

$SubscriptionNames = Get-AzureSubscription

foreach ($sub in $SubscriptionNames)
{ 
    Select-AzureSubscription -SubscriptionName $sub.SubscriptionName -Current

    Write-Output "Processing " $sub.SubscriptionName

    $vmlist = get-azureVM 

    foreach($vm in $vmlist)
    {
            #Get VM Status
            $vmstatus = $vm.status

            $output = new-object PSObject
            $output | add-member -Membertype NoteProperty -Name "Mode" -value "ASM"
            $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value $sub.SubscriptionName
            $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "ASM Default Resource Group"
            $output | add-member -Membertype NoteProperty -Name "VMName" -value "$($vm.name)"
            $output | add-member -Membertype NoteProperty -Name "OSType" -value "$($vm.VM.OSVirtualHardDisk.OS)"

            $output | add-member -Membertype NoteProperty -Name "VMSize" -value "$($vm.InstanceSize)"
            $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($vmstatus)"
			$output | add-member -Membertype NoteProperty -Name "AvailabilitySetName" -value "$($vm.AvailabilitySetName)"			
            
            # ASM VM Maintenance Value is EMPTY
            $output | add-member -Membertype NoteProperty -Name "IsCustomerInitiatedMaintenanceAllowed" -value "$($IsCustomerInitiatedMaintenanceAllowed)"
            $output | add-member -Membertype NoteProperty -Name "PreMaintenanceWindowStartTime" -value "$($PreMaintenanceWindowStartTime)"
            $output | add-member -Membertype NoteProperty -Name "PreMaintenanceWindowEndTime" -value "$($PreMaintenanceWindowEndTime)"

            $output | add-member -Membertype NoteProperty -Name "MaintenanceWindowStartTime" -value "$($MaintenanceWindowStartTime)"
            $output | add-member -Membertype NoteProperty -Name "MaintenanceWindowEndTime" -value "$($MaintenanceWindowEndTime)"

            $output | add-member -Membertype NoteProperty -Name "LastOperationResultCode" -value "$($LastOperationResultCode)"
            $output | add-member -Membertype NoteProperty -Name "LastOperationMessage" -value "$($LastOperationMessage)"

            $logarray += $output
    }
}

#write the logarray to a CSV file.
$logArray | convertto-Csv -NoTypeInformation | out-file D:\azureVMList.csv -append -Encoding utf8 
Write-Output "Export Success, please check azureacl file in Disk D:"




