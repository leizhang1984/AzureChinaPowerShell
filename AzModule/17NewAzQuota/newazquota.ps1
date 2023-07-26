$subid = "[YourSubscroptionID]"
$scope = "subscriptions/" + $subid + "/providers/Microsoft.Compute/locations/westus3"


$currentVaule = 10000
$requestvaule = 20000
$step = 1000
$loopnum = ($requestvaule-$currentVaule)/$step

$skuname = "standardESv5Family"
#standardDv5Family,
#Get-AzQuota -Scope $scope | Where-Object { $_.Name -eq "standardESv5Family" }

#for ($i=1;$i -l $loopnum;$i++)
for($i=1; $i -le $loopnum; $i++)
{
	$newvalue = [int]$currentVaule + [int]$i * [int]$step 
    $limit = New-AzQuotaLimitObject -Value $newvalue

    Write-Output "Processing " $newvalue
    $result = New-AzQuota -Scope $scope -ResourceName $skuname -Name $skuname -Limit $limit
    
    Write-Output "Start Sleeping for 30 Seconds "
    Start-Sleep -Seconds 30
    
    Write-Output "Sleeping end"
    #if($result.

}


