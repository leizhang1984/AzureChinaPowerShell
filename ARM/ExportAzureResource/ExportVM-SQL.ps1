#Created By MSFT leizhang (leizha@microsoft.com) on Sep 12th, 2017

Clear-AzureProfile -Force

$logarray=@()

Write-Output "Prepare for ASM"

#For ASM Mode
Add-AzureAccount -Environment AzureChinaCloud

$SubscriptionNames = Get-AzureSubscription

foreach ($sub in $SubscriptionNames)
{ 
        Select-AzureSubscription -SubscriptionName $sub.SubscriptionName -Current

        Write-Output "Processing " $sub.SubscriptionName

        $vmlist = Get-AzureVM 

        foreach($vm in $vmlist)
        {
                #Get VM Status
                $vmstatus = $vm.status

                $output = new-object PSObject
                $output | add-member -Membertype NoteProperty -Name "Mode" -value "ASM"
                $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value $sub.SubscriptionName
                $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "ASM Default Resource Group"
                $output | add-member -Membertype NoteProperty -Name "Location" -value "$($vm.location)"

                $output | add-member -Membertype NoteProperty -Name "VMName" -value "$($vm.name)"
                $output | add-member -Membertype NoteProperty -Name "VMSize" -value "$($vm.HardwareProfile.VmSize)"
                $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($vmstatus)"
               
                $logarray += $output 
                #add the Azure VM
        }

        #Get Azure SQL Server
        $sqlsvrlist = Get-AzureSqlDatabaseServer

        foreach ($sqlsvr in $sqlsvrlist)
        {
                $sqldblist = Get-AzureSqlDatabase -ServerName $sqlsvr.ServerName

                foreach ($sqldb in $sqldblist) 
                {
                        if($sqldb.Name -ne "master")
                        {
                            $output = new-object PSObject
                            $output | add-member -Membertype NoteProperty -Name "Mode" -value "ASM"
                            $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value $sub.SubscriptionName
                            $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "ASM Default Resource Group"
                            $output | add-member -Membertype NoteProperty -Name "Location" -value "$($sqlsvr.Location)"

                            $output | add-member -Membertype NoteProperty -Name "SQL Server Name" -value "$($sqlsvr.ServerName)"
                            $output | add-member -Membertype NoteProperty -Name "SQL Database Name" -value "$($sqldb.Name)"
                            $output | add-member -Membertype NoteProperty -Name "DBSize" -value "$($sqldb.ServiceObjectiveName)"
               
                            $logarray += $output 
                            #add the SQL Server
                        }
                }
        }
}



#For ARM Mode
Add-AzureRmAccount -EnvironmentName AzureChinaCloud

$SubscriptionNames = Get-AzureRMSubscription

foreach ($sub in $SubscriptionNames)
{
        Select-AzureRMSubscription -SubscriptionName $sub.Name 

        Write-Output "Processing " $sub.Name 
        $rglist = Get-AzureRmResourceGroup

        foreach ($rg in $rglist)
        {
                #Get Azure RM VM
                $vmlist = Get-AzureRMVM -ResourceGroupName $rg.ResourceGroupName

                foreach ($vm in $vmlist)
                {   
                        #Get VM Status
                        $vmstatus = (get-azurermvm -ResourceGroupName $rg.ResourceGroupName -Name $vm.Name -Status).Statuses.DisplayStatus[1]

                        $output = new-object PSObject
                        $output | add-member -Membertype NoteProperty -Name "Mode" -value "ARM"
                        $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value "$($sub.Name)"
                        $output | add-member -Membertype NoteProperty -Name "ResourceGroupName" -value "$($rg.ResourceGroupName)"
                        $output | add-member -Membertype NoteProperty -Name "Location" -value "$($vm.Location)"

                        $output | add-member -Membertype NoteProperty -Name "VMName" -value "$($vm.Name)"
                        $output | add-member -Membertype NoteProperty -Name "VMSize" -value "$($vm.HardwareProfile.VMSize)"
                        $output | add-member -Membertype NoteProperty -Name "VMStatus" -value "$($vmstatus)"

                        $logarray += $output 
                        #add the Azure VM                      
                }   
        }
      
  }



#write the logarray to a CSV file.
$logArray | convertto-Csv -NoTypeInformation | out-file D:\azureVM-SQLList.csv -append -Encoding utf8 
Write-Output "Export Success, please check azureacl file in Disk D:"



