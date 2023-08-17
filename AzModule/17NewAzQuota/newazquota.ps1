#Install-Module Az.Quota

$subid = "d7f49630-34b4-4321-a5fd-fda48b934d2c"
$scope = "subscriptions/" + $subid + "/providers/Microsoft.Compute/locations/westus3"


$currentVaule = 13300
$requestvaule = 15000
$step = 100
$loopnum = ($requestvaule-$currentVaule)/$step

$skuname = "standardLSv3Family"
#standardDv5Family,standardEASv4Family
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
}


