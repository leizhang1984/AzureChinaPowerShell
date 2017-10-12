#参考文档：https://michaelcollier.wordpress.com/2017/05/03/copy-managed-images/

#登录image 所在的订阅
Add-AzureRMAccount -Environment AzureChinaCloud

#这里修改为，源订阅ID
$sourceSubscriptionId =  '[订阅ID]'

Select-AzureRmSubscription -SubscriptionId $sourceSubscriptionId

#这里修改为，源订阅，资源组名称
$resourceGroupName = 'HPCPOC8'

#这里修改为，源订阅，捕获镜像的虚拟机名称
$vmName = 'testnode0'

#这里修改为，源订阅，源image所在的Region
$region = 'China North'

#这里修改为，源订阅，源image的名称
$imageName = 'workerImage9'

#Create a snapshot
$vm = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vmName

$disk = Get-AzureRmDisk -ResourceGroupName $resourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name

$snapshot = New-AzureRmSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $region

#snapshot name不允许有空格
$regionTrim = $region.Replace(' ','')

$snapshotName = $imageName + "-" + $regionTrim + "-snapshot"

New-AzureRmSnapshot -ResourceGroupName $resourceGroupName -Snapshot $snapshot -SnapshotName $snapshotName

$snap = Get-AzureRmSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName

$snapSasUrl = Grant-AzureRmSnapshotAccess -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName -DurationInSecond 3600 -Access Read
 





#Copy the snapshot to a different region for a different subscription
#登录目标订阅
Add-AzureRMAccount -Environment AzureChinaCloud

#这里修改为，目标订阅ID
$destSubscriptionId =  '[订阅ID]'

Select-AzureRmSubscription -SubscriptionId $destSubscriptionId

#这里修改为，目标订阅，目标资源组
$destResourceGroupName = 'LeiDemo-RG'

#这里修改为，目标订阅的存储账户名称。请先手动创建
$destStorageAccountName = 'leichinanorth'

这里修改为，目标订阅的存储账户的container name，必须为小写
$destContainerName = 'private'

#这里修改，目标订阅，存储账户所在的Region
$destRegionName = 'China North'

$destStorageContext = (Get-AzureRmStorageAccount -ResourceGroupName $destResourceGroupName -Name $destStorageAccountName).Context

New-AzureStorageContainer -Name $destContainerName -Context $destStorageContext -Permission Off
 
$imageBlobName = $imageName + '-NEW'

# 开始拷贝，时间比较长
Start-AzureStorageBlobCopy -AbsoluteUri $snapSasUrl.AccessSAS -DestContainer $destContainerName -DestContext $destStorageContext -DestBlob $imageBlobName

Get-AzureStorageBlobCopyState -Container $destContainerName -Blob $imageBlobName -Context $destStorageContext -WaitForComplete
 
# Get the full URI to the blob
$osDiskVhdUri = ($destStorageContext.BlobEndPoint + $destContainerName + "/" + $imageBlobName)

# Build up the snapshot configuration, using the Destination storage account's resource ID
$snapshotConfig = New-AzureRmSnapshotConfig -AccountType StandardLRS `
                                            -OsType Windows `
                                            -Location $destRegionName `
                                            -CreateOption Import `
                                            -SourceUri $osDiskVhdUri `
                                            -StorageAccountId "/subscriptions/${destSubscriptionId}/resourceGroups/${destResourceGroupName}/providers/Microsoft.Storage/storageAccounts/${destStorageAccountName}"

#snapshot name不允许有空格
$destRegionTrim = $destRegionName.Replace(' ','')

$destSnapshotName = $imageName + "-" + $destRegionTrim + "-snap"

# Create the new snapshot in the Destination region
$destSnap = New-AzureRmSnapshot -ResourceGroupName $destResourceGroupName -SnapshotName $destSnapshotName -Snapshot $snapshotConfig



#Create an Image in Destination Subscription 
$imageConfig = New-AzureRmImageConfig -Location $destRegionName
 
Set-AzureRmImageOsDisk -Image $imageConfig -OsType Windows -OsState Generalized -SnapshotId $destSnap.Id
 
New-AzureRmImage -ResourceGroupName $destResourceGroupName -ImageName $imageName -Image $imageConfig


#执行完毕，在目标订阅创建image成功！
