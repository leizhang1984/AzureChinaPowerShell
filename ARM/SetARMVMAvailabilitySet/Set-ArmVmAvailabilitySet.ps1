<#

 
ScriptName : Set-ArmVmAvailabilitySet
Description : This script will add a VM to an Availability Set or chnage it's availability Set
Author : Samir Farhat (https://buildwindows.wordpress.com)
Version : 1.05

#Prerequisites#
- Azure Powershell 1.01 or later
- An Azure Subscription and an account which have the proviliges to : Remove a VM, Create a VM
- An existing Availability Set part of the same Resource Group than the VM

#How it works#
- Get the VM object (JSON)
- Save the JSON configuration to a file (To rebuild the VM wherever it goes wrong)
- Remove the VM (Only the configuration, all dependencies are kept ) 
- Modify the VM object (Add the AS, change the AS)
- Change the Storage config because the recration needs the disk attach option
- ReCreate the VM

##New features
#1.05
- Change the way to select a Subscription since the first one does not support Logins attached to different Azure Accounts
#1.04
- Bug fixing : Use the right object type when creating the AS object
- Add a test before stopping the VM to avoid Stopping an already stopped VM
#1.03
- Stop the VM before the deletion step
#1.02
- Fixed the Step 2 of 'Recreate VM' for VMs created from custom images
#1.01
- Fixed an issue with the Login-AzureRMAccount behaviour


#>


[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True,Position=1)]
   [string]$SubscriptionName,

   [Parameter(Mandatory=$True,Position=2)]
   [string]$ResourceGroup,

   [Parameter(Mandatory=$True,Position=3)]
   [string]$VmName,

   [Parameter(Mandatory=$True,Position=4)]
   [string]$AvailabilitySetName
)


#Functions
Function RunLog-Command([string]$Description, [ScriptBlock]$Command, [string]$LogFile){
Try{
$Output = $Description+'  ... '
Write-Host $Output -ForegroundColor Yellow
((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
$Result = Invoke-Command -ScriptBlock $Command 
}
Catch {
$ErrorMessage = $_.Exception.Message
$Output = 'Error '+$ErrorMessage
((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force
$Result = ""
}
Finally
{
if ($ErrorMessage -eq $null) {$Output = "[Completed]  $Description  ... "} else {$Output = "[Failed]  $Description  ... "}
((Get-Date -UFormat "[%d-%m-%Y %H:%M:%S] ") + $Output) | Out-File -FilePath $LogFile -Append -Force

}
Return $Result


}

Function LogintoAzure()
        {
        $Error_WrongCredentials = $True
        $AzureAccount = $null

        while ($Error_WrongCredentials) {

    Try {
        Write-Host "Info : Please, Enter the credentials of an Admin account of Azure" -ForegroundColor Cyan
        #$AzureCredentials = Get-Credential -Message "Please, Enter the credentials of an Admin account of your subscription"      
        $AzureAccount = Login-AzureRmAccount -EnvironmentName AzureChinaCloud

        if ($AzureAccount.Context.Tenant -eq $null) 
                  {
                   $Error_WrongCredentials = $True
                   $Output = " Warning : The Credentials for [" + $AzureAccount.Context.Account.id +"] are not valid or the user does not have Azure subscriptions "
                   Write-Host $Output -BackgroundColor Red -ForegroundColor Yellow
                   } 
                 else
                  {$Error_WrongCredentials = $false ; return $AzureAccount}
        }

    Catch {
        $Output = " Warning : The Credentials for [" + $AzureAccount.Context.Account.id +"] are not valid or the user does not have Azure subscriptions "
        Write-Host $Output -BackgroundColor Red -ForegroundColor Yellow
        Generate-LogVerbose -Output $logFile -Message  $Output 
        }

    Finally {
                
            }

}
        return $AzureAccount

        }
        
Function Select-Subscription ($SubscriptionName, $AzureAccount)
        {
        Select-AzureRmSubscription -SubscriptionName $SubscriptionName -TenantId $AzureAccount.Context.Tenant.TenantId
        }

Function Set-AsSetting ($VmObject, $AsName, $LogFile)
{

if ($AsName -eq 0) {
$VmObject.AvailabilitySetReference = $null
$VmObject.OSProfile = $null
$VmObject.StorageProfile.ImageReference = $null
if ($VmObject.StorageProfile.OsDisk.Image) {$VmObject.StorageProfile.OsDisk.Image = $null}
$VmObject.StorageProfile.OsDisk.CreateOption = 'Attach'
for ($s=1;$s -le $VmObject.StorageProfile.DataDisks.Count ; $s++ )
{
$VmObject.StorageProfile.DataDisks[$s-1].CreateOption = 'Attach'
}


$Description = "Recreating the Azure VM [$Vmname] : (Step 1 : Removing the VM...) "
$Command = {Remove-AzureRmVM -Name $VmObject.Name -ResourceGroupName $VmObject.ResourceGroupName -Force | Out-null}
RunLog-Command -Description $Description -Command $Command -LogFile $LogFile

Start-sleep 5

$Description = "Recreating the Azure VM [$Vmname] : (Step 2 : Creating the VM...) "
$Command = {New-AzureRmVM -ResourceGroupName $VmObject.ResourceGroupName -Location $VmObject.Location -VM $VmObject | Out-null}
RunLog-Command -Description $Description -Command $Command -LogFile $LogFile

}
else
{

$Description = "Getting the Availability Set : $AsName "
$Command = {(Get-AzureRmAvailabilitySet -ResourceGroupName $VmObject.ResourceGroupName -Name $ASName).Id}
$AsId = RunLog-Command -Description $Description -Command $Command -LogFile $LogFile
$AsObject = New-Object Microsoft.Azure.Management.Compute.Models.SubResource
$AsObject.Id = $AsId
$VmObject.AvailabilitySetReference = $AsObject
$VmObject.OSProfile = $null
$VmObject.StorageProfile.ImageReference = $null
if ($VmObject.StorageProfile.OsDisk.Image) {$VmObject.StorageProfile.OsDisk.Image = $null}
$VmObject.StorageProfile.OsDisk.CreateOption = 'Attach'
for ($s=1;$s -le $VmObject.StorageProfile.DataDisks.Count ; $s++ )
{
$VmObject.StorageProfile.DataDisks[$s-1].CreateOption = 'Attach'
}


$Description = "Recreating the Azure VM [$Vmname] : (Step 1 : Removing the VM...) "
$Command = {Remove-AzureRmVM -Name $VmObject.Name -ResourceGroupName $VmObject.ResourceGroupName -Force | Out-null}
RunLog-Command -Description $Description -Command $Command -LogFile $LogFile

Start-sleep 5

$Description = "Recreating the Azure VM [$Vmname] : (Step 2 : Creating the VM...) "
$Command = {New-AzureRmVM -ResourceGroupName $VmObject.ResourceGroupName -Location $VmObject.Location -VM $VmObject | Out-null}
RunLog-Command -Description $Description -Command $Command -LogFile $LogFile

}




}

Function Validate-VmExistence ($VmName, $VmRG, $logFile)
{
$VmExist = $false
$Description = "Validating the Vm Existence"
$Command = {Get-AzureRmVM | where { $_.ResourceGroupName -eq $VmRG -and $_.Name -eq $VmName}}
$IsExist = RunLog-Command -Description $Description -Command $Command -LogFile $LogFile
$IsExist = 
if ($IsExist) {$VmExist = $true}

return $VmExist
}

Function Validate-AsExistence ($ASName, $VmRG, $LogFile)
{
$AsExist = $false
$Description = "Validating the As Existence"
$Command = {Get-AzureRmAvailabilitySet -ResourceGroupName $VmRG -Name $ASName}
$IsExist = RunLog-Command -Description $Description -Command $Command -LogFile $LogFile
 
if ($IsExist) {$AsExist = $true}

return $AsExist
}



#Main
#Input
$Subscription = $SubscriptionName
$VmRG = $ResourceGroup
$ASName = $AvailabilitySetName

##Setting Global Paramaters##
$ErrorActionPreference = "Stop"
$date = Get-Date -UFormat "%Y-%m-%d-%H-%M"
$workfolder = Split-Path $script:MyInvocation.MyCommand.Path
$logFile = $workfolder+'\'+$date+'.log'
Write-Output "Steps will be tracked on the log file : [ $logFile ]" 

##Login to Azure##
$Description = "Connecting to Azure"
$Command = {LogintoAzure}
$AzureAccount = RunLog-Command -Description $Description -Command $Command -LogFile $LogFile


##Select the Subscription##
##Login to Azure##
$Description = "Selecting the Subscription : $Subscription"
#$Command = {Get-AzureRmSubscription | Out-GridView -PassThru | Select-AzureRmSubscription}

Select-AzureRmSubscription -SubscriptionName $SubscriptionName

#RunLog-Command -Description $Description -Command $Command -LogFile $LogFile


#Validate Input

$ValidateVm = Validate-Vmexistence -VmName $VmName -VmRG $VmRG -logFile $logFile
if ($ASName -eq 0) {$ValidateAs = $True} else { $ValidateAs = Validate-AsExistence -ASName $ASName -VmRG $VmRG -LogFile $logFile}

if ($ValidateVm -and $ValidateAs )
{Write-Output "Validation of [$VmName] and [$ASName] : Success" }
else {
Write-Output "Validation of [$VmName] and [$ASName] : Failed"
Write-Output "Validation of [$VmName] : $ValidateVm"
Write-Output "Validation of [$ASName] : $ValidateAs"
Return
}

#

#Get the Virtual Machine Object
$Description = "Getting the VM Object : $Vmname"
$Command = {Get-AzureRmVM -ResourceGroupName $VmRG -Name $Vmname }
$VmObject = RunLog-Command -Description $Description -Command $Command -LogFile $LogFile

#Get the Virtual Machine Object
$Description = "Stopping the VM : $Vmname"
$VMstate = (Get-AzureRmVM -ResourceGroupName $VmRG -Name $Vmname -Status).Statuses[1].code
if ($VMstate -ne 'PowerState/deallocated' -and $VMstate -ne 'PowerState/Stopped')
{
$Command = { $VmObject | Stop-AzureRmVM -StayProvisioned -Force | Out-Null}
RunLog-Command -Description $Description -Command $Command -LogFile $LogFile
}

#Export the VmObject to a file

$Description = "Exporting the VM Config to a file : $VmRG-$Vmname.json "
$Command = {ConvertTo-Json -InputObject $VmObject -Depth 100 | Out-File -FilePath $workfolder'\'$VmRG-$Vmname'.json'}
RunLog-Command -Description $Description -Command $Command -LogFile $LogFile


#Setting the AS#
Set-AsSetting -VmObject $VmObject -AsName $AsName -LogFile $LogFile
