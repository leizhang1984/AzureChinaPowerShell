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
  Stop-AzureRmVM -ResourceGroupName $rgName -Name $vm.Name -Force
  ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $rgName -VMName $vm.Name
  Start-AzureRmVM -ResourceGroupName $rgName -Name $vm.Name
}










