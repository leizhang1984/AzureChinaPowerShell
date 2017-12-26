#登录并验证
Add-AzureRmAccount -EnvironmentName AzureChinaCloud

#选择当前订阅
$subscriptionName = 'SubscriptionName'
Select-AzureRmSubscription -SubscriptionName $subscriptionName

#设置资源组
$rgName = "LeiCloudService-Migrated"

#设置虚拟机名称
$vmName = "LeiVM01"

#设置虚拟机的高可用性集
$avSetName = 'LEI-AVBSET'

#获得高可用性集
$avSet = Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $avSetName

#设置高可用性集的故障域为2,
$avSet.PlatformFaultDomainCount = 2

#更新
Update-AzureRmAvailabilitySet -AvailabilitySet $avSet -Sku Aligned

$avSet = Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $avSetName

foreach($vmInfo in $avSet.VirtualMachinesReferences)
{
  $vm = Get-AzureRmVM -ResourceGroupName $rgName | Where-Object {$_.Id -eq $vmInfo.id}
  #需要在关机下执行
  Stop-AzureRmVM -ResourceGroupName $rgName -Name $vm.Name -Force
  ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $rgName -VMName $vm.Name
  
  #然后开机
  Start-AzureRmVM -ResourceGroupName $rgName -Name $vm.Name
}


#如果我们想查看Managed Disk的URL，可以执行下面的命令
foreach($vmInfo in $avSet.VirtualMachinesReferences)
{
  $vm = Get-AzureRmVM -ResourceGroupName $rgName | Where-Object {$_.Id -eq $vmInfo.id}
  #需要在关机下执行
  Stop-AzureRmVM -ResourceGroupName $rgName -Name $vm.Name -Force
  
  $mdiskURL = Grant-AzureRmDiskAccess -ResourceGroupName $rgName -DiskName $vm.StorageProfile.OsDisk.Name -Access Read -DurationInSecond 3600
  Write-Output($mdiskURL)
  
   #然后开机
  #Start-AzureRmVM -ResourceGroupName $rgName -Name $vm.Name
}
