#Created By MSFT leizhang (leizha@microsoft.com) on 2021-08-04

$logarray=@()

#For ARM Mode
Add-AzAccount -EnvironmentName AzureChinaCloud

$SubscriptionNames = Get-AzSubscription

foreach ($sub in $SubscriptionNames)
{
        Select-AzSubscription -SubscriptionName $sub.Name 

        Write-Output "Processing Subscription: " $sub.Name 

        #$vnetlist = Get-AzVirtualNetwork -ResourceGroupName demo-rg -Name demo_vnet
        $vnetlist = Get-AzVirtualNetwork
        foreach ($vnet in $vnetlist)
        {
            Write-Output "Processing Virtual Network: " $vnet.Name

            foreach ($subnet in $vnet.Subnets)
            {
                 #Search
                 $NSGs =  Get-AzNetworkSecurityGroup -ResourceGroupName $vnet.ResourceGroupName | Where { $_.Id -eq $subnet.NetworkSecurityGroup.Id} 
                 if($NSGs)
                 {   
                     foreach ($rule in $NSGs.DefaultSecurityRules)
                     {
                        # NSG Existing then display
                        $output = new-object PSObject

                        $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value "$($sub.Name)"
                        $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "$($vnet.ResourceGroupName)"
                        $output | add-member -Membertype NoteProperty -Name "VNet Name" -value "$($vnet.Name)"
                        $output | add-member -Membertype NoteProperty -Name "Location" -value "$($vnet.Location)"
                        $output | add-member -Membertype NoteProperty -Name "AddressSpace" -value "$($vnet.AddressSpaceText)"

                        $output | add-member -Membertype NoteProperty -Name "Subnet" -value "$($subnet.Name)"
                        $output | add-member -Membertype NoteProperty -Name "Subnet AddressPrefix" -value "$($subnet.AddressPrefix)"

                        # NSG Existing then display
                        $output | add-member -Membertype NoteProperty -Name "NSG Name" -value "$($NSGs.Name)"

                        $output | add-member -Membertype NoteProperty -Name "Rule Name" -value "$($rule.Name)"
                        $output | add-member -Membertype NoteProperty -Name "Rule Description" -value "$($rule.Description)"
                        $output | add-member -Membertype NoteProperty -Name "Rule Protocol" -value "$($rule.Protocol)"
                        $output | add-member -Membertype NoteProperty -Name "Rule SourcePortRange" -value "$($rule.SourcePortRange)"
                        $output | add-member -Membertype NoteProperty -Name "Rule DestinationPortRange" -value "$($rule.DestinationPortRange)"

                        $output | add-member -Membertype NoteProperty -Name "Rule SourceAddressPrefix" -value "$($rule.SourceAddressPrefix)"
                        $output | add-member -Membertype NoteProperty -Name "Rule DestinationAddressPrefix" -value "$($rule.DestinationAddressPrefix)"
                        $output | add-member -Membertype NoteProperty -Name "Rule Access" -value "$($rule.Access)"
                        $output | add-member -Membertype NoteProperty -Name "Rule Priority" -value "$($rule.Priority)"
                        $output | add-member -Membertype NoteProperty -Name "Rule Direction" -value "$($rule.Direction)"
                     }
                 }
                 else
                 {    
                        $output = new-object PSObject

                        $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value "$($sub.Name)"
                        $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "$($vnet.ResourceGroupName)"
                        $output | add-member -Membertype NoteProperty -Name "VNet Name" -value "$($vnet.Name)"
                        $output | add-member -Membertype NoteProperty -Name "Location" -value "$($vnet.Location)"
                        $output | add-member -Membertype NoteProperty -Name "AddressSpace" -value "$($vnet.AddressSpaceText)"

                        $output | add-member -Membertype NoteProperty -Name "Subnet" -value "$($subnet.Name)"
                        $output | add-member -Membertype NoteProperty -Name "Subnet AddressPrefix" -value "$($subnet.AddressPrefix)"

                        # NSG is not Exising, then warning
                        $output | add-member -Membertype NoteProperty -Name "Rule Name" -value ""
                        $output | add-member -Membertype NoteProperty -Name "Rule Description" -value ""
                        $output | add-member -Membertype NoteProperty -Name "Rule Protocol" -value ""
                        $output | add-member -Membertype NoteProperty -Name "Rule SourcePortRange" -value ""
                        $output | add-member -Membertype NoteProperty -Name "Rule DestinationPortRange" -value ""

                        $output | add-member -Membertype NoteProperty -Name "Rule SourceAddressPrefix" -value ""
                        $output | add-member -Membertype NoteProperty -Name "Rule DestinationAddressPrefix" -value ""
                        $output | add-member -Membertype NoteProperty -Name "Rule Access" -value ""
                        $output | add-member -Membertype NoteProperty -Name "Rule Priority" -value ""
                        $output | add-member -Membertype NoteProperty -Name "Rule Direction" -value ""
                 }

                 #add to the array
                 $logarray += $output 
            }
            
        }
}

#write the logarray to a CSV file.
$logArray | convertto-Csv -NoTypeInformation | out-file D:\azurevnetnsg.csv -append -Encoding utf8 
Write-Output "Export Success, please check azurevnetnsg.csv in Disk D:"




