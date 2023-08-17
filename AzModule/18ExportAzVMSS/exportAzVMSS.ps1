#Add-AzAccount

$logarray=@()

$SubscriptionNames = Get-AzSubscription
#loop subscription
foreach ($sub in $SubscriptionNames)
{
     Select-AzSubscription -SubscriptionId $sub.SubscriptionId
     #loop csv row
     Write-Output "Processing " $sub.Name 

     $VMSSs=Get-AzVMSS
     foreach ($vmss in $VMSSs)
     {
        $output = new-object PSObject

        $output | add-member -Membertype NoteProperty -Name "SubscriptionName" -value $sub.Name
        $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value $vmss.ResourceGroupName

        $output | add-member -Membertype NoteProperty -Name "VMSS Name" -value $vmss.Name
        $output | add-member -Membertype NoteProperty -Name "Instance" -value $vmss.Sku.Capacity
        $output | add-member -Membertype NoteProperty -Name "Size" -value $vmss.Sku.Name
        $output | add-member -Membertype NoteProperty -Name "Location" -value $vmss.Location
        $output | add-member -Membertype NoteProperty -Name "Status" -value $vmss.ProvisioningState

        $logarray += $output
     }
}
$today = Get-Date -Format "yyyy-MM-dd"

#write the logarray to a CSV file.
$output_csvpath = $pwd.Path + "\" + $today + "vmsslist.csv"

$logArray | convertto-Csv -NoTypeInformation | out-file $output_csvpath -append -Encoding utf8 
Write-Output "Export Success, please check vmss list in:" + $output_csvpath