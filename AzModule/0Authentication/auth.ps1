Clear-AzContext -Scope CurrentUser

Get-AzContext 

$creds = Get-Credential
Connect-AzAccount -Environment AzureChinaCloud -Credential $creds