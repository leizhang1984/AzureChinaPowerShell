$subid = "074b8f7e-9eb5-4c38-b5f9-a39cf7876bdb"
$region = "southeastasia"
$scope = "subscriptions/" + $subid + "/providers/Microsoft.Compute/locations/" + $region 

$skuname = "standardDSv5Family"
#standardDSv5Family,
$result = Get-AzQuota -Scope $scope | Where-Object { $_.Name -eq $skuname }
$currentValue = $result.Limit.Value

$requestValue = 4000
$step = 100
$loopnum = ($requestValue-$currentValue)/$step


#for ($i=1;$i -l $loopnum;$i++)
for($i=1; $i -le $loopnum; $i++)
{
	$newvalue = [int]$currentValue + [int]$i * [int]$step 
    $limit = New-AzQuotaLimitObject -Value $newvalue

    Write-Output "Processing " $newvalue
    $result = New-AzQuota -Scope $scope -ResourceName $skuname -Name $skuname -Limit $limit
    
    Write-Output "Start Sleeping for 30 Seconds "
    Start-Sleep -Seconds 30
    
    Write-Output "Sleeping end"
    #if($result.

}


