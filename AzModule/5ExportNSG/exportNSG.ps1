#Created By MSFT leizhang (leizha@microsoft.com) on Oct 19th, 2020

$logarray=@()

#For ARM Mode
Add-AzAccount -EnvironmentName AzureChinaCloud

$SubscriptionNames = Get-AzSubscription

foreach ($sub in $SubscriptionNames)
{
        Select-AzSubscription -SubscriptionName $sub.Name 

        Write-Output "Processing " $sub.Name 

        $vmlist = Get-AzVM
        foreach ($vm in $vmlist)
        {
            Write-Output "Processing " $vm.Name

            #Get Azure ARM VM NICs
            $NicsCount = $vm.NetworkProfile.NetworkInterfaces.Count

            #Get VM Status
            $vmstatus = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).Statuses.DisplayStatus[1]

            for($i=0; $i -lt $NicsCount; $i++)
            {
                $NiCs = Get-AzNetworkInterface | Where { $_.Id -eq $vm.NetworkProfile.NetworkInterfaces[$i].Id}

                $NSGId = $NiCs.NetworkSecurityGroup.Id

                $NSGs =  Get-AzNetworkSecurityGroup -ResourceGroupName $vm.ResourceGroupName | Where { $_.Id -eq $NSGId} 

                if($NSGs)
                {
                        # NSG Existing then display
                        $Rules = $NSGs | Get-AzNetworkSecurityRuleConfig | Select * 
                        foreach($Rule in $Rules)
                        {
                                $output = new-object PSObject
                                $output | add-member -Membertype NoteProperty -Name "Mode" -value "ARM"
                                $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value "$($sub.Name)"
                                $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "$($vm.ResourceGroupName)"
                                $output | add-member -Membertype NoteProperty -Name "VMName" -value "$($vm.Name)"
                                $output | add-member -Membertype NoteProperty -Name "OSType" -value "$($vm.StorageProfile.OsDisk.OsType)"
                                $output | add-member -Membertype NoteProperty -Name "VMSize" -value "$($vm.HardwareProfile.VmSize)"

                                $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($vmstatus)"
                                $output | add-member -Membertype NoteProperty -Name "NICName" -value "$($NiCs.name)"

                                $output | add-member -Membertype NoteProperty -Name "PortName" -value "$($Rule.Name)"
                                $output | add-member -Membertype NoteProperty -Name "ExternalPort" -value "$($Rule.SourcePortRange)"
                                $output | add-member -Membertype NoteProperty -Name "InternalPort" -value "$($Rule.DestinationPortRange)"
                                $output | add-member -Membertype NoteProperty -Name "protocol" -value "$($Rule.Protocol)"

                                $output | add-member -Membertype NoteProperty -Name "RemoteSubnet" -value "$($Rule.SourceAddressPrefix)"
                                $output | add-member -Membertype NoteProperty -Name "Description" -value  "$($Rule.Description)"
                                $output | add-member -Membertype NoteProperty -Name "Permission" -value "$($Rule.Access)"
                                $output | add-member -Membertype NoteProperty -Name "Tag" -value "$($vm.Tags)"

                                $logarray += $output 
                                #add the current machinename, port and ACL to the array.
                        }
                }
                else
                {
                            # NSG is not Exising, then warning
                            $output = new-object PSObject
                            $output | add-member -Membertype NoteProperty -Name "Mode" -value "ARM"
                            $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value "$($sub.Name)"
                            $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "$($vm.ResourceGroupName)"
                            $output | add-member -Membertype NoteProperty -Name "VMName" -value "$($vm.name)"
                            $output | add-member -Membertype NoteProperty -Name "OSType" -value "$($vm.StorageProfile.OsDisk.OsType)"
                            $output | add-member -Membertype NoteProperty -Name "VMSize" -value "$($vm.HardwareProfile.VmSize)"

                            $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($vmstatus)"
                            $output | add-member -Membertype NoteProperty -Name "NICName" -value "$($NiCs.name)"

                            $output | add-member -Membertype NoteProperty -Name "PortName" -value "*"
                            $output | add-member -Membertype NoteProperty -Name "ExternalPort" -value "*"
                            $output | add-member -Membertype NoteProperty -Name "InternalPort" -value "*"
                            $output | add-member -Membertype NoteProperty -Name "protocol" -value "*"

                            $output | add-member -Membertype NoteProperty -Name "RemoteSubnet" -value "*"
                            $output | add-member -Membertype NoteProperty -Name "Description" -value  "Open NSG to All Source IP"
                            $output | add-member -Membertype NoteProperty -Name "Permission" -value "permit"
                            $output | add-member -Membertype NoteProperty -Name "Tag" -value "$($vm.Tags)"

                            $logarray += $output 
                            #add the current machinename, port and ACL to the array.
                }
            }
        }
}

#write the logarray to a CSV file.
$logArray | convertto-Csv -NoTypeInformation | out-file D:\azurevmnsg.csv -append -Encoding utf8 
Write-Output "Export Success, please check azureacl file in Disk D:"




