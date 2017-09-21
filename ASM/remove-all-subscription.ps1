Add-AzureAccount -Environment AzureChinaCloud

$SubscriptionNames = Get-AzureSubscription | select -ExpandProperty SubscriptionName 

$result=@()
foreach ($sub in $SubscriptionNames)
{ 
	Remove-AzureSubscription -SubscriptionName $sub
}