#Add-AzAccount
$logarray=@()

$SubscriptionNames = Get-AzSubscription

foreach ($sub in $SubscriptionNames)
{
        Select-AzSubscription -SubscriptionName $sub.Name 
        if($sub.Name -eq "us-mall")
        {
            #Get VM first
            $vmsss = Get-AzVMSS
            foreach ($vmss in $vmsss)
            {
                $vmssVMs = Get-AzVmssVM -ResourceGroupName $vmss.ResourceGroupName -VMScaleSetName $vmss.Name
             
                foreach ($vmssVM in $vmssVMs)
                {         
                    $output = new-object PSObject
                    $output | add-member -Membertype NoteProperty -Name "SubscriptionName" -value $sub.Name
                    $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value $vmssVM.ResourceGroupName    
                    
                    Write-Output "Processing" $vmssVM.Name

                    $output | add-member -Membertype NoteProperty -Name "VMSSInstance" -value $vmssVM.Name
                    $output | add-member -Membertype NoteProperty -Name "SKU" -value $vmssVM.Sku.Name
                    #$vmssInstanceName = $vmssInstance.Name

                    $nicInfo = Get-AzNetworkInterface -VirtualMachineScaleSetName $vmss.Name -ResourceGroupName $vmss.ResourceGroupName -VirtualMachineIndex $vmssVM.InstanceId
                    $subnetId = $nicInfo.IpConfigurations[0].Subnet.Id
                    $vnetString = ($subnetId -split '/virtualNetworks/') -split ('/subnets/')
                    $vnetName = $vnetString[1]
                    $subnetName = $vnetString[2]

                    $output | add-member -Membertype NoteProperty -Name "VNet Name" -value $vnetName
                    $output | add-member -Membertype NoteProperty -Name "Subnet Name" -value $subnetName

                    $logarray += $output      
                 }
              }
        }      
}

#write the logarray to a CSV file.
$output_csvpath = $pwd.Path + "\exportvmssInstance.csv"

$logArray | convertto-Csv -NoTypeInformation | out-file $output_csvpath -append -Encoding utf8 
Write-Output "Export Success, please check azureacl file in:" + $output_csvpath