#Add-AzAccount

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
            $cidr =  $subnet.AddressPrefix.Split("/")[0] + "/" + $subnet.AddressPrefix.Split("/")[1]

            $outputstring = "ipv4_is_in_range(ipaddress," + """$cidr"")," + """$subnetName"","
        
            
            $output = new-object PSObject
            $output | add-member -Membertype NoteProperty -Name "VNet Name" -value $vnet.Name
            $output | add-member -Membertype NoteProperty -Name "Query" -value $outputstring
            $logarray += $output      
         }
    }
}
$today = Get-Date -Format "yyyy-MM-dd"
$csvpath = $pwd.Path + "\" + $today + "exportvnetsubnetkusto.csv"
$logArray | convertto-Csv -NoTypeInformation | out-file $csvpath -append -Encoding utf8 
Write-Output "Export VNet Private IP successfully"