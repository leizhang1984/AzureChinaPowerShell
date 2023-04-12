#Add-AzAccount

$logarray=@()
#This CSV file MUST HAVE following Column
#roleInstanceName

#Please modify CSV path first
$csvpath = $pwd.Path + "\vmlist.csv"

#Start to Process CSV File
$P = Import-Csv -Path $csvpath


$SubscriptionNames = Get-AzSubscription
#loop subscription
foreach ($sub in $SubscriptionNames)
{
     Select-AzSubscription -SubscriptionName $sub.Name
     #loop csv row
     foreach ($rows in $p)
     {
         $vmname = $rows.roleInstanceName   
     }
}


<#
foreach ($rows in $p)
{
        $SubscriptionNames = Get-AzSubscription
        foreach ($sub in $SubscriptionNames)
        {
             Select-AzSubscription -SubscriptionName $sub.Name 
    
             $vmname = $rows.roleInstanceName

             if($vmname.contains("-vmss_"))
             {
                    $vmssname_id_split = $vmname.split("_")
                    $vmssname = $vmssname_id_split[0]
                    $vmssindex = $vmssname_id_split[1]

                    $VMSSs = Get-AzVMSS -VMScaleSetName $vmssname
                    if ($VMSSs -ne $null)
                    {
                        $vm = Get-AzNetworkInterface -VirtualMachineScaleSetName $VMSSs.Name -ResourceGroupName $VMSSs.ResourceGroupName -VirtualMachineIndex "$vmssindex"
                        $vmss_privateip = $vm.IpConfigurations[0].PrivateIpAddress
                        Write-Host "$vmname" "的内网IP地址是：" $vmss_privateip

                        $output = new-object PSObject
                        $output | add-member -Membertype NoteProperty -Name "roleInstanceName" -value $vmname
                        $output | add-member -Membertype NoteProperty -Name "privateIP" -value $vmss_privateip

        	            break
                    }
             }
             else
             {
                    $vm = Get-AzVM | Where-Object {$_.Name -eq $vmname}
                    
                    if($vm)
                    {
                        $NiCs = Get-AzNetworkInterface | Where { $_.Id -eq $vm.NetworkProfile.NetworkInterfaces[0].Id}
                        $vm_privateip = $NiCs.IpConfigurations[0].PrivateIpAddress
                        
                        Write-Host "$vmname" "的内网IP地址是：" $vm_privateip
                        $output = new-object PSObject
                        $output | add-member -Membertype NoteProperty -Name "roleInstanceName" -value $vmname
                        $output | add-member -Membertype NoteProperty -Name "privateIP" -value $vm_privateip

                        break
                    }
              }
        }
}
#>

#write the logarray to a CSV file.
$output_csvpath = $pwd.Path + "\vmlist_output.csv"

$logArray | convertto-Csv -NoTypeInformation | out-file $output_csvpath -append -Encoding utf8 
Write-Output "Export Success, please check azureacl file in:" + $output_csvpath