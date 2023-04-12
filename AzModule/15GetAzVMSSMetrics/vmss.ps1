#Add-AzAccount
$logarray=@()

$startTime = "2023/2/20 18:00:00"
$endTime = "2023/2/27 18:00:00"

    $SubscriptionNames = Get-AzSubscription
    foreach ($sub in $SubscriptionNames)
    {
            Select-AzSubscription -SubscriptionName $sub.Name 
        
            #$subscriptionName = $sub.Name
            #$subscriptionId = $sub.subscriptionId

            Write-Output "Processing " $sub.Name 
       
            $VMSSs=Get-AzVMSS
            foreach ($vmss in $VMSSs)
            {
                for ($i=0; $i -lt $vmss.Sku.Capacity; $i++)
                {
                    $instance=Get-AzVmssVM -ResourceGroupName  $vmss.ResourceGroupName -VMScaleSetName $vmss.Name -InstanceId $i

                    $inbound_flow = Get-AzMetric -ResourceId $instance.Id -MetricName "Inbound Flows" -TimeGrain 00:15:00 -StartTime $startTime -EndTime $endTime
                    $outbount_flow = Get-AzMetric -ResourceId $instance.Id -MetricName "Outbound Flows" -TimeGrain 00:15:00 -StartTime $startTime -EndTime $endTime

                    $inboundResult = $inbound_flow.data | Where-Object {$_.Average -gt "200000"}
                    #$outboundResult = $outbount_flow.data

                    for ($j=0; $j -lt $inboundResult.Count; $j++)
                    {
                        $result = $inboundResult[$j].Average
                       
                        $output = new-object PSObject
                        $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value $sub.Name

                        $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value $vmss.ResourceGroupName
                        $output | add-member -Membertype NoteProperty -Name "VMSSName" -value $vmss.Name

                        $output | add-member -Membertype NoteProperty -Name "VMName" -value $instance.Name
                        $output | add-member -Membertype NoteProperty -Name "Inbound_Flow" -value $inboundResult[$j].Average
                        #$output | add-member -Membertype NoteProperty -Name "Outbount_Flow" -value $outboundResult[$j].Average
                        $logarray += $output      
                        

                    }

                }        	
            }
    }
$csvpath = $pwd.Path + "\export_Flows.csv"
$logArray | convertto-Csv -NoTypeInformation | out-file $csvpath -append -Encoding utf8 
Write-Output "Export Flows successfully"
