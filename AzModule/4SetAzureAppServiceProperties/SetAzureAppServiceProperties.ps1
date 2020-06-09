#Created By MSFT leizhang (leizha@microsoft.com) on 2020-06-08

$logarray=@()

#login in to Azure
Connect-AzAccount -Environment AzureChinaCloud

#Loop Subscriptions
$SubscriptionNames = Get-AzSubscription
foreach ($sub in $SubscriptionNames)
{
        Select-AzSubscription -SubscriptionName $sub.Name 

        $subscriptionName = $sub.Name
        $subscriptionId = $sub.subscriptionId

        $functions= Get-AzWebApp
        
        foreach ($row in $functions)
        {
                $output = new-object PSObject

				$output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value "$($subscriptionName)"
                $output | add-member -Membertype NoteProperty -Name "SubscriptionId" -value "$($subscriptionId)"

				$OutboundIpAddresses= $row.OutboundIpAddresses
                $output | add-member -Membertype NoteProperty -Name "OutboundIpAddresses" -value "$($OutboundIpAddresses)"

				$PossibleOutboundIpAddresses= $row.PossibleOutboundIpAddresses
                $output | add-member -Membertype NoteProperty -Name PossibleOutboundIpAddresses-value "$($PossibleOutboundIpAddresses)"

                #SetFunction Properties
				Set-AzWebApp -ResourceGroupName $row.ResourceGroup -Name $row.Name -HttpLoggingEnabled $true -DetailedErrorLoggingEnabled $true -HttpsOnly $true

				#SetFunction AccessRestriction
				Add-AzWebAppAccessRestrictionRule -ResourceGroupName $row.ResourceGroup -WebAppName $row.Name -Name SbuxIP -Priority 300 -Action Allow -IpAddress 167.220.255.103/32
				
				#https://github.com/MicrosoftDocs/azure-docs/issues/31095
				#SCMIP do not support CLI/PowerShell
				#$row.SiteConfig.ScmIpSecurityRestrictionsUseMain=$true
				
				
				
                $logarray += $output 
        }
    
}

#$logArray | convertto-Csv -NoTypeInformation | out-file D:\azurefunction.csv -append -Encoding utf8 
Write-Output "Operation successfully"