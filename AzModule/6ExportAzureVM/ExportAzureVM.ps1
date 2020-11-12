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


            $NiCs = Get-AzNetworkInterface | Where { $_.Id -eq $vm.NetworkProfile.NetworkInterfaces[0].Id}

            $output = new-object PSObject
            $output | add-member -Membertype NoteProperty -Name "Mode" -value "ARM"
            $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value "$sub.Name"
            $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "$($vm.ResourceGroupName)"
            $output | add-member -Membertype NoteProperty -Name "VMName" -value "$($vm.Name)"
            $output | add-member -Membertype NoteProperty -Name "OSType" -value "$($vm.StorageProfile.OsDisk.OsType)"
            $output | add-member -Membertype NoteProperty -Name "VMSize" -value "$($vm.HardwareProfile.VmSize)"

            $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($vmstatus)"
            $output | add-member -Membertype NoteProperty -Name "NICName" -value "$($NiCs.name)"
            $output | add-member -Membertype NoteProperty -Name "PrivateIP" -value "$($NiCs.IpConfigurations[0].PrivateIpAddress)"


            $logarray += $output 
            #add the current machinename, port and ACL to the array.

        }
}

#write the logarray to a CSV file.
$logArray | convertto-Csv -NoTypeInformation | out-file D:\exportazurevm.csv -append -Encoding utf8 
Write-Output "Export Success, please check azureacl file in Disk D:"




