param(
[Parameter(Mandatory=$true)]
[String]$subscriptionId,
[Parameter(Mandatory=$true)]
[String]$OutputFilePath
)
Add-AzureAccount -Environment AzureChinaCloud
Select-AzureSubscription -SubscriptionId $subscriptionId
$vms=Get-AzureVM|where{$_.AvailabilitySetName -eq $null -and $_.Status -eq "ReadyRole"}
$result=@()
foreach($vm in $vms)
{
    $deploymentId = (Get-AzureDeployment -ServiceName $vm.ServiceName).DeploymentId
    $endpoints = Get-AzureVM -ServiceName $vm.ServiceName -Name $vm.Name|Get-AzureEndpoint
    $vip=($endpoints|Select Vip|Sort-Object -Property Vip -Unique)

    $obj=New-Object PSObject
    $obj|Add-Member NoteProperty ServiceName($vm.ServiceName)
    $obj|Add-Member NoteProperty DeploymentId($deploymentId)
    $obj|Add-Member NoteProperty InstanceName($vm.InstanceName)
    $obj|Add-Member NoteProperty PublicIPName($vm.PublicIPName)    
    $obj|Add-Member NoteProperty PublicIP($vm.PublicIPAddress)
    $obj|Add-Member NoteProperty VIP($vip)
    $result+=$obj
}
$result|Select ServiceName,DeploymentId,InstanceName,PublicIPName,PublicIP,VIP|Export-Csv -Path $OutputFilePath