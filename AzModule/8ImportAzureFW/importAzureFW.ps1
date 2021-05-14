
#Created By MSFT leizhang (leizha@microsoft.com) on 2021-05-14
#max support 2 rows


#Please modify CSV path first
$csvpath = "D:\fw_blacklist.csv"


#Start to Process CSV File
$p = Import-Csv -Path $csvpath


#Login to Azure China
Add-AzAccount -Environment AzureChinaCloud

#loop

$i=0


foreach ($rows in $p)
{
        $SourceAddress=@()
        $DestinAddress=@()

        try
        {
        	$SubscriptionId = $rows.subscriptionid.Trim()
            $RGName = $rows.rgname.Trim()
            $FWName = $rows.firwallname.Trim()

            $CollectionName = $rows.rulecollectionename.Trim()
            $Priority = $rows.priority.Trim()
            $Action = $rows.action.Trim()
            $Rulename = $rows.rulename.Trim()

            $Protocol = $rows.protocol.Trim()
            $SourceAddressArray = $rows.sourceaddress.Trim()
            $SourceAddress = $SourceAddressArray.Split(",")

            
            $DestinAddressArray = $rows.destinationaddress.Trim()
            $DestinAddress = $DestinAddressArray.Split(",")

            $DestinPorts = $rows.destinationports.Trim()

            #select the subscription Id
            Select-AzSubscription -SubscriptionId $SubscriptionId

            $Azfw = Get-AzFirewall -ResourceGroupName $RGName -Name $FWName

            #如果不为空
            if($Azfw -ne $null)
            {
                if($i -eq 0)
                {
                    
                    $rule1 = New-AzFirewallNetworkRule -Name $Rulename -SourceAddress $SourceAddress -Protocol $Protocol -DestinationAddress $DestinAddress -DestinationPort $DestinPorts
                        
                }
                elseif ($i -eq 1)
                {
                    $rule2 = New-AzFirewallNetworkRule -Name $Rulename -SourceAddress $SourceAddress -Protocol $Protocol -DestinationAddress $DestinAddress -DestinationPort $DestinPorts
                        
                }
            }

            $i=$i+1

            if($i -eq 2)
            {
                    $NetRuleCollection = New-AzFirewallNetworkRuleCollection -Name $CollectionName -Priority $Priority -Rule $rule1, $rule2 -ActionType $Action
                    $Azfw.NetworkRuleCollections.Add($NetRuleCollection)
                    Set-AzFirewall -AzureFirewall $Azfw

                    write-host "更新防火墙成功！！！"      
            }
        }
      
        catch [Exception] 
        {
                write-host $_.Exception.Message;
        }
        Finally
        {

        }      
 }  

