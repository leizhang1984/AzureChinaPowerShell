#Created By MSFT leizhang (leizha@microsoft.com) on July 10th, 2017
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
            Write-Output "Processing " $vm.Name

            #Get Azure ARM VM NICs
            $NicsCount = $vm.NetworkProfile.NetworkInterfaces.Count

            #Get VM Status
            $vmstatus = (get-azurermvm -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).Statuses.DisplayStatus[1]

            for($i=0; $i -lt $NicsCount; $i++)
            {
                $NiCs = Get-AzureRmNetworkInterface | Where { $_.Id -eq $vm.NetworkProfile.NetworkInterfaces[$i].Id}

                $NSGId = $NiCs.NetworkSecurityGroup.Id

                $NSGs =  Get-AzureRmNetworkSecurityGroup -ResourceGroupName $vm.ResourceGroupName | Where { $_.Id -eq $NSGId} 

                if($NSGs)
                {
                        # NSG Existing then display
                        $Rules = $NSGs | Get-AzureRmNetworkSecurityRuleConfig | Select * 
                        foreach($Rule in $Rules)
                        {
                                $output = new-object PSObject
                                $output | add-member -Membertype NoteProperty -Name "Mode" -value "ARM"
                                $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value "$($sub.Name)"
                                $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "$($vm.ResourceGroupName)"
                                $output | add-member -Membertype NoteProperty -Name "VMName" -value "$($vm.Name)"
                                $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($vmstatus)"
                                $output | add-member -Membertype NoteProperty -Name "NICName" -value "$($NiCs.name)"

                                $output | add-member -Membertype NoteProperty -Name "PortName" -value "$($Rule.Name)"
                                $output | add-member -Membertype NoteProperty -Name "ExternalPort" -value "$($Rule.SourcePortRange)"
                                $output | add-member -Membertype NoteProperty -Name "InternalPort" -value "$($Rule.DestinationPortRange)"
                                $output | add-member -Membertype NoteProperty -Name "protocol" -value "$($Rule.Protocol)"

                                $output | add-member -Membertype NoteProperty -Name "RemoteSubnet" -value "$($Rule.SourceAddressPrefix)"
                                $output | add-member -Membertype NoteProperty -Name "Description" -value  "$($Rule.Description)"
                                $output | add-member -Membertype NoteProperty -Name "Permission" -value "$($Rule.Access)"

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
                            $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($vmstatus)"
                            $output | add-member -Membertype NoteProperty -Name "NICName" -value "$($NiCs.name)"

                            $output | add-member -Membertype NoteProperty -Name "PortName" -value "*"
                            $output | add-member -Membertype NoteProperty -Name "ExternalPort" -value "*"
                            $output | add-member -Membertype NoteProperty -Name "InternalPort" -value "*"
                            $output | add-member -Membertype NoteProperty -Name "protocol" -value "*"

                            $output | add-member -Membertype NoteProperty -Name "RemoteSubnet" -value "*"
                            $output | add-member -Membertype NoteProperty -Name "Description" -value  "Open NSG to All Source IP"
                            $output | add-member -Membertype NoteProperty -Name "Permission" -value "permit"

                            $logarray += $output 
                            #add the current machinename, port and ACL to the array.
                }
            }
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
        Write-Output "Processing " $vm.Name

        #get the endpoints for this VM
        $Port = Get-AzureEndpoint -vm $vm 

        #get the length of the portarray
        $PortLength = $Port.length

        #get the ACL's for this VM
        $acl = Get-AzureAclConfig -vm $vm

        #Number of ACL rules
        $AclLength = $acl.Rules.Count

        #Get VM Status
        $vmstatus = $vm.status

        #Walk through the endpoints
        for($i=0; $i -lt $PortLength; $i++)
        {
            #If ACL Length is ZERO
            if($AclLength -eq 0)
            {
                $output = new-object PSObject
                $output | add-member -Membertype NoteProperty -Name "Mode" -value "ASM"
                $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value $sub.SubscriptionName
                $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "ASM Default Resource Group"
                $output | add-member -Membertype NoteProperty -Name "VMName" -value "$($vm.name)"
                $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($vmstatus)"
                $output | add-member -Membertype NoteProperty -Name "NICName" -value "ASM Default NIC"

                $output | add-member -Membertype NoteProperty -Name "PortName" -value "$($port[$i].name)"
                $output | add-member -Membertype NoteProperty -Name "ExternalPort" -value "$($port[$i].port)"
                $output | add-member -Membertype NoteProperty -Name "InternalPort" -value "$($port[$i].localport)"
                $output | add-member -Membertype NoteProperty -Name "protocol" -value "$($port[$i].protocol)"

                $output | add-member -Membertype NoteProperty -Name "RemoteSubnet" -value "*"
                $output | add-member -Membertype NoteProperty -Name "Description" -value "Open ACL to All Source IP"
                $output | add-member -Membertype NoteProperty -Name "Permission" -value "permit"

                $logarray += $output #add the current machinename, port and ACL to the array.
            }

            #walk through the ACL for each endpoint and add them to an object
            for($n=0; $n -lt $AclLength; $N++)
            {
                $output = new-object PSObject
                $output | add-member -Membertype NoteProperty -Name "Mode" -value "ASM"
                $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value $sub.SubscriptionName
                $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "ASM Default Resource Group"
                $output | add-member -Membertype NoteProperty -Name "VMName" -value "$($vm.name)"
                $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($vmstatus)"
                $output | add-member -Membertype NoteProperty -Name "NICName" -value "ASM Default NIC"

                $output | add-member -Membertype NoteProperty -Name "PortName" -value "$($port[$i].name)"
                $output | add-member -Membertype NoteProperty -Name "ExternalPort" -value "$($port[$i].port)"
                $output | add-member -Membertype NoteProperty -Name "InternalPort" -value "$($port[$i].localport)"
                $output | add-member -Membertype NoteProperty -Name "protocol" -value "$($port[$i].protocol)"
                if($AclLength -gt 1)
                {
                    $output | add-member -Membertype NoteProperty -Name "RemoteSubnet" -value "$($acl.remotesubnet[$n])"
                    $output | add-member -Membertype NoteProperty -Name "Description" -value "$($acl.Description[$n])"
                    $output | add-member -Membertype NoteProperty -Name "Permission" -value "$($acl.Action[$n])"
                }
                else
                {
                    $output | add-member -Membertype NoteProperty -Name "RemoteSubnet" -value "$($acl.remotesubnet)"
                    $output | add-member -Membertype NoteProperty -Name "Description" -value "$($acl.Description)"
                    $output | add-member -Membertype NoteProperty -Name "Permission" -value "$($acl.Action)"
                }
                $logarray += $output #add the current machinename, port and ACL to the array.
            }
        }

    }
}

#write the logarray to a CSV file.
$logArray | convertto-Csv -NoTypeInformation | out-file D:\azureacl-nsg.csv -append -Encoding utf8 
Write-Output "Export Success, please check azureacl file in Disk D:"




