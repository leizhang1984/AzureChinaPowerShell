Add-AzAccount

$logarray=@()

$subs = Get-AzSubscription 
foreach ($sub in $subs)
{
    Select-AzSubscription -SubscriptionId $sub.SubscriptionId
    $vnets = Get-AzVirtualNetwork
    foreach ($vnet in $vnets)
    {
        $virtualNetworkName = $vnet.Name
        $subnetNames = $vnet.Subnets.Name
        foreach ($subnetName in $subnetNames) 
        {
            $subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName
            $subnetMask = $subnet.AddressPrefix.Split("/")[1]
            $netmaskLength = [Math]::Pow(2, 32 - [int]$subnetMask)
            $availableIpAddresses = $netmaskLength - 5 - $subnet.IpConfigurations.Count         
            
            $output = new-object PSObject
            $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value $sub.Name

            $output | add-member -Membertype NoteProperty -Name "VNet Name" -value $vnet.Name
            $output | add-member -Membertype NoteProperty -Name "Subnet Name" -value $subnetName.ToString()

            $output | add-member -Membertype NoteProperty -Name "Total Private IP" -value $netmaskLength.ToString()
            $output | add-member -Membertype NoteProperty -Name "Used Private IP" -value $subnet.IpConfigurations.Count  
            $output | add-member -Membertype NoteProperty -Name "Available Private IP" -value $availableIpAddresses.ToString()
            $logarray += $output      
         }
    }
}

$csvpath = $pwd.Path + "\export_vnetprivateips.csv"
$logArray | convertto-Csv -NoTypeInformation | out-file $csvpath -append -Encoding utf8 
Write-Output "Export VNet Private IP successfully"