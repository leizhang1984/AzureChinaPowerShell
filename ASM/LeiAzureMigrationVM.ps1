<#
Modified by Lei Zhang on 2016-04-29
#>

Param 
(
    #源订阅ID
    [string] $SourceSubscriptionId="bb931fa7-0e76-4e96-8200-dd35e45cb1a1",

    #源云服务名称
    [string] $SourceCloudServiceName="telinga-dc01",

    #源虚拟机名称
    [string] $SourceVMName="telinga-dc01",

    #源Azure Storage Container Name
    [string] $SourceStorageContainerName="vhds",

    #目标订阅ID
    [string] $DestSubscritpionId="9b3137f8-08c6-4647-8c5b-5161b763a705",

    #目标云服务名称
    [string] $DestCloudServiceName="telinga-dc01-new",

    #目标虚拟机名称
    [string] $DestVMName="telinga-dc01-new",

    #目标存储账户名称
    [string] $DestStorageAccountName="telingastorage",

    #目标Azure Storage Container Name	
    [string] $DestStorageContainerName="vhds",

    #目标虚拟机所在数据中心，分别为China North和China East
    [string] $DestLocationName="China North",

    #目标虚拟机所在虚拟网络名称
    [string] $DestVNetName="net-telinga",

    #目标虚拟机所在子网名称
    [string] $DestSubNet="Subnet-1",

    #目标虚拟机磁盘文件后缀
    [string] $DiskNameSuffix="-prem"
)

$IsSameSub = $false

if (($SourceSubscriptionId -eq $DestSubscritpionId) -or ($DestSubscritpionId -eq ""))
{
	Write-Host "VM is copied at the same subscription！" -ForegroundColor Green
	$IsSameSub = $true
	$DestSubscritpionId = $SourceSubscriptionId
}

if ($SourceStorageContainerName -eq "")
{
	Write-Host "Using the default source storage container vhds！" -ForegroundColor Green
	$SourceStorageContainerName = "vhds"
}

if ($DestStorageContainerName -eq "")
{
	Write-Host "Using the default destination storage container vhds！" -ForegroundColor Green
	$DestStorageContainerName = "vhds"
}

if ($DestLocationName -eq "")
{
	$DestLocationName = "China East"
}

if ($DestSubNet -eq "")
{
	$DestSubNet = "Subnet-1"
}

if (($DiskNameSuffix -eq $null) -or ($DiskNameSuffix -eq ""))
{
	$DiskNameSuffix = "-prem"
	Write-Host "Set the copyed Disk Name Suffix as:"+ $DiskNameSuffix -ForegroundColor Green
}

Write-Host "`t================= Migration Setting =======================" -ForegroundColor Green
Write-Host "`t  Source Subscription ID 		 = $SourceSubscriptionId           " -ForegroundColor Green
Write-Host "`t Source Cloud Service Name 	 = $SourceCloudServiceName       " -ForegroundColor Green
Write-Host "`t            Source VM Name 	 = $SourceVMName                 " -ForegroundColor Green
Write-Host "`t      Dest Subscription ID 	 = $DestSubscritpionId         	 " -ForegroundColor Green
Write-Host "`t   Dest Cloud Service Name 	 = $DestCloudServiceName         " -ForegroundColor Green
Write-Host "`t Dest Storage Account Name 	 = $DestStorageAccountName       " -ForegroundColor Green
Write-Host "`t Source Storage Container Name = $SourceStorageContainerName   " -ForegroundColor Green
Write-Host "`t Dest Storage Container Name 	 = $DestStorageContainerName   "   -ForegroundColor Green
Write-Host "`t             Dest Location 	 = $DestLocationName             " -ForegroundColor Green
Write-Host "`t                 Dest VNET = $DestVNetName                 	 " -ForegroundColor Green
Write-Host "`t               Dest Subnet = $DestSubNet                 	 	 " -ForegroundColor Green
Write-Host "`t               Disk Name Prefix = $DiskNameSuffix    	 	 " -ForegroundColor Green
Write-Host "`t===============================================================" -ForegroundColor Green

#######################################################################
#  Verify Azure Source Subscription and Azure Desination Subscription
#######################################################################
Write-Host "Please verify the Source Azure Subscription" -ForegroundColor Green
Add-AzureAccount -Environment AzureChinaCloud

Write-Host "Please verify the Destination Azure Subscription" -ForegroundColor Green
Add-AzureAccount -Environment AzureChinaCloud

$ErrorActionPreference = "Stop"

try{ stop-transcript|out-null }
catch [System.InvalidOperationException] { }

$workingDir = (Get-Location).Path
$log = $workingDir + "\VM-" + $SourceCloudServiceName + "-" + $SourceVMName + ".log"
Start-Transcript -Path $log -Append -Force

Select-AzureSubscription -SubscriptionId $SourceSubscriptionId

#######################################################################
#  Check if the VM is shut down 
#  Stopping the VM is a required step so that the file system is consistent when you do the copy operation. 
#  Azure does not support live migration at this time.. 
#######################################################################
$sourceVM = Get-AzureVM –ServiceName $SourceCloudServiceName –Name $SourceVMName
if ( $sourceVM -eq $null )
{
    Write-Host "[ERROR] - The source VM doesn't exist. Exiting." -ForegroundColor Red
    Exit
}

# check if VM is shut down
if ( $sourceVM.Status -notmatch "Stopped" )
{
    Write-Host "[Warning] - Stopping the VM is a required step so that the file system is consistent when you do the copy operation. Azure does not support live migration at this time. If you’d like to create a VM from a generalized image, sys-prep the Virtual Machine before stopping it." -ForegroundColor Yellow
    $ContinueAnswer = Read-Host "`n`tDo you wish to stop $SourceVMName now? (Y/N)"
    If ($ContinueAnswer -ne "Y") { Write-Host "`n Exiting." -ForegroundColor Red; Exit }
    $sourceVM | Stop-AzureVM  -StayProvisioned

    # wait until the VM is shut down
    $sourceVMStatus = (Get-AzureVM –ServiceName $SourceCloudServiceName –Name $SourceVMName).Status
    while ($sourceVMStatus -notmatch "Stopped") 
    {
        Write-Host "Waiting VM $vmName to shut down, current status is $sourceVMStatus" -ForegroundColor Green
        Sleep -Seconds 5
        $sourceVMStatus = (Get-AzureVM –ServiceName $SourceCloudServiceName –Name $SourceVMName).Status
    } 
}

# exporting the source vm to a configuration file, you can restore the original VM by importing this config file
# see more information for Import-AzureVM
$vmConfigurationPath = $workingDir + "\ExportedVMConfig-" + $SourceCloudServiceName + "-" + $SourceVMName +".xml"
Write-Host "Exporting VM configuration to $vmConfigurationPath" -ForegroundColor Green
$sourceVM | Export-AzureVM -Path $vmConfigurationPath

#######################################################################
#  Copy the vhds of the source vm 
#  You can choose to copy all disks including os and data disks by specifying the
#  parameter -DataDiskOnly to be $false. The default is to copy only data disk vhds
#  and the new VM will boot from the original os disk. 
#######################################################################

$sourceOSDisk = $sourceVM.VM.OSVirtualHardDisk
$sourceDataDisks = $sourceVM.VM.DataVirtualHardDisks

# Get source storage account information, not considering the data disks and os disks are in different accounts
$sourceStorageAccountName = $sourceOSDisk.MediaLink.Host -split "\." | select -First 1
$sourceStorageAccount = Get-AzureStorageAccount –StorageAccountName $sourceStorageAccountName
$sourceStorageKey = (Get-AzureStorageKey -StorageAccountName $sourceStorageAccountName).Primary 

Select-AzureSubscription -SubscriptionId $DestSubscritpionId
# Create destination context
$destStorageAccount = Get-AzureStorageAccount | ? {$_.StorageAccountName -eq $DestStorageAccountName} | select -first 1
if ($destStorageAccount -eq $null)
{
    New-AzureStorageAccount -StorageAccountName $DestStorageAccountName -Location $DestLocationName
    $destStorageAccount = Get-AzureStorageAccount -StorageAccountName $DestStorageAccountName
}
$DestStorageAccountName = $destStorageAccount.StorageAccountName
$destStorageKey = (Get-AzureStorageKey -StorageAccountName $DestStorageAccountName).Primary

$sourceContext = New-AzureStorageContext  –StorageAccountName $sourceStorageAccountName -StorageAccountKey $sourceStorageKey -Environment AzureChinaCloud
$destContext = New-AzureStorageContext  –StorageAccountName $DestStorageAccountName -StorageAccountKey $destStorageKey

# Create a container of vhds if it doesn't exist
Set-AzureSubscription -CurrentStorageAccountName $DestStorageAccountName -SubscriptionId $DestSubscritpionId
#if ((Get-AzureStorageContainer -Context $destContext -Name vhds -ErrorAction SilentlyContinue) -eq $null)
if ((Get-AzureStorageContainer -Name $DestStorageContainerName -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Host "Creating a container vhds in the destination storage account." -ForegroundColor Green
#    New-AzureStorageContainer -Context $destContext -Name vhds
	New-AzureStorageContainer -Name $DestStorageContainerName	 
}

$allDisks = @($sourceOSDisk) + $sourceDataDisks
$destDataDisks = @()
# Copy all data disk vhds
# Start all async copy requests in parallel.
foreach($disk in $allDisks)
{
    $blobName = $disk.MediaLink.Segments[2]
    # copy all data disks 
    Write-Host "Starting copying data disk $($disk.DiskName) at $(get-date)." -ForegroundColor Green
    $sourceBlob = "https://" + $disk.MediaLink.Host + "/" + $SourceStorageContainerName + "/"
    $targetBlob = $destStorageAccount.Endpoints[0] + $DestStorageContainerName + "/"
    $azcopylog = "azcopy-" + $SourceCloudServiceName + "-" + $SourceVMName +".log"

    Write-Host "Start copy vhd to destination storage account"  -ForegroundColor Green
    #Write-Host .\azcopy\AzCopy\AzCopy.exe /Source:$sourceBlob /Dest:$targetBlob /SourceKey:$sourceStorageKey /DestKey:$destStorageKey /Pattern:$blobName /SyncCopy /v:$azcopylog -ForegroundColor Green

    #cd 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy'
    #AzCopy.exe /Source:$sourceBlob /Dest:$targetBlob /SourceKey:$sourceStorageKey /DestKey:$destStorageKey /Pattern:$blobName /SyncCopy /v:$azcopylog
     
    #cd D:\AzCopy
    #.\AzCopy.exe /Source:$sourceBlob /Dest:$targetBlob /SourceKey:$sourceStorageKey /DestKey:$destStorageKey /Pattern:$blobName /SyncCopy /v:$azcopylog 

    #Start-AzureStorageBlobCopy is too slow
    Start-AzureStorageBlobCopy -SrcContainer $SourceStorageContainerName -SrcBlob $blobName -DestContainer $DestStorageContainerName -DestBlob $blobName -Context $sourceContext -DestContext $destContext -Force

    if ($disk –eq $sourceOSDisk)
    {
        $destOSDisk = $targetBlob + $blobName
    }
    else
    {
        $destDataDisks += $targetBlob + $blobName
    }
}


# Wait until all vhd files are copied.
$CopyStatusReportInterval = 15
$diskComplete = @()
do
{
    Write-Host "`n[WORKITEM] - Waiting for all disk copy to complete. Checking status every $CopyStatusReportInterval seconds." -ForegroundColor Yellow
    # check status every 30 seconds
    Sleep -Seconds $CopyStatusReportInterval
    foreach ( $disk in $allDisks)
    {
        if ($diskComplete -contains $disk)
        {
            Continue
        }
        $blobName = $disk.MediaLink.Segments[2]
        $copyState = Get-AzureStorageBlobCopyState -Blob $blobName -Container vhds -Context $destContext
        if ($copyState.Status -eq "Success")
        {
            Write-Host "`n[Status] - Success for disk copy $($disk.DiskName) at $($copyState.CompletionTime)" -ForegroundColor Green
            $diskComplete += $disk
        }
        else
        {
            if ($copyState.TotalBytes -gt 0)
            {
                $percent = ($copyState.BytesCopied / $copyState.TotalBytes) * 100
                Write-Host "`n[Status] - $('{0:N2}' -f $percent)% Complete for disk copy $($disk.DiskName)" -ForegroundColor Green
            }
        }
    }
} 
while($diskComplete.Count -lt $allDisks.Count)



# Create OS and data disks 
Write-Host "Add VM OS Disk. OS "+ $sourceOSDisk.OS +"diskName:" + $sourceOSDisk.DiskName + "Medialink:"+ $destOSDisk  -ForegroundColor Green

# 设置源VM的Disk Name和目标VM的Disk Name
$disknameOS = $sourceOSDisk.DiskName
if($IsSameSub)
{
    #OSDisk, 如果在同一个订阅下，则增加后缀以区分VHD文件名
    $disknameOS = $sourceOSDisk.DiskName + $DiskNameSuffix
}

Add-AzureDisk -OS $sourceOSDisk.OS -DiskName $disknameOS -MediaLocation $destOSDisk
# Attached the copied data disks to the new VM
foreach($currenDataDisk in $destDataDisks)
{
    $diskName = ($sourceDataDisks | ? {$currenDataDisk.EndsWith($_.MediaLink.Segments[2])}).DiskName
    if($IsSameSub)
    {
        #DataDisk, 如果在同一个订阅下，则增加后缀以区分VHD文件名
        $diskName = ($sourceDataDisks | ? {$currenDataDisk.EndsWith($_.MediaLink.Segments[2])}).DiskName + $DiskNameSuffix
    }
    Write-Host "Add VM Data Disk $diskName" -ForegroundColor Green
    Add-AzureDisk -DiskName $diskName -MediaLocation $currenDataDisk
}

Write-Host "Import VM from " $vmConfigurationPath -ForegroundColor Green
Set-AzureSubscription -SubscriptionId $DestSubscritpionId -CurrentStorageAccountName $DestStorageAccountName


# Manually change the data diskname in the same subscription coz it can't be same
if($IsSameSub)
{
	$ContinueAnswer = Read-Host "`n`tPlease update the Diskname in the configuration file "+ $vmConfigurationPath +", just add your suffix $DiskNameSuffix to the filename! Then press ENTER to continue.."
}
# Import VM from previous exported configuration plus vnet info
if (( Get-AzureService | Where { $_.ServiceName -eq $DestCloudServiceName } ).Count -eq 0 )
{
    New-AzureService -ServiceName $DestCloudServiceName -Location $DestLocationName
}

Write-Host "`n import-AzureVM -Path $vmConfiygurationPath | Set-AzureSubnet -SubnetNames $DestSubNet | New-AzureVM -ServiceName $DestCloudServiceName -VNetName $DestVNetName -WaitForBoot" -ForegroundColor Green

Import-AzureVM -Path $vmConfigurationPath | Set-AzureSubnet -SubnetNames $DestSubNet | New-AzureVM -ServiceName $DestCloudServiceName -VNetName $DestVNetName -WaitForBoot

