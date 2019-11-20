#Created By MSFT leizhang (leizha@microsoft.com) on Nov 20th, 2019

$logarray=@()

#login in to Azure
Connect-AzAccount -Environment AzureChinaCloud

#Loop Subscriptions
$SubscriptionNames = Get-AzSubscription
foreach ($sub in $SubscriptionNames)
{
        Select-AzSubscription -SubscriptionName $sub.Name 

        $subscriptionName = $sub.Name
        $subscriptionId = $sub.subscriptionId

        Write-Output "Processing " $sub.Name 
        
        $exports = Get-AzRoleAssignment -IncludeClassicAdministrators | Select RoleDefinitionName,DisplayName,SignInName,ObjectType,Scope 
        
        foreach ($datarow in $exports)
        {
                $output = new-object PSObject
                $output | add-member -Membertype NoteProperty -Name "SubscriptioName" -value "$($subscriptionName)"
                $output | add-member -Membertype NoteProperty -Name "SubscriptionId" -value "$($subscriptionId)"

                $output | add-member -Membertype NoteProperty -Name "RoleDefinitionName" -value "$($datarow.RoleDefinitionName)"
                $output | add-member -Membertype NoteProperty -Name "DisplayName" -value "$($datarow.DisplayName)"
                $output | add-member -Membertype NoteProperty -Name "SignInName" -value "$($datarow.SignInName)"

                $output | add-member -Membertype NoteProperty -Name "ObjectType" -value "$($datarow.ObjectType)"
                $output | add-member -Membertype NoteProperty -Name "Scope" -value "$($datarow.Scope)"

                $logarray += $output 
        }
    
}

$logArray | convertto-Csv -NoTypeInformation | out-file D:\export_rbac.csv -append -Encoding utf8 
Write-Output "Export RBAC successfully"