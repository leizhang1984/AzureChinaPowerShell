$logarray=@()

Login-AzureRmAccount -EnvironmentName AzureChinaCloud
#登录账户，账户最好是有Azure AD管理员权限的

$SubscriptionNames = Get-AzureRMSubscription

foreach ($sub in $SubscriptionNames)
{
    #选择订阅
    Select-AzureRMSubscription -SubscriptionName $sub.Name 

 
    #获得Service Admin和 Co-Admin
    $records = Get-AzureRmRoleAssignment -IncludeClassicAdministrators | SELECT DisplayName,SignInName,RoleDefinitionName
    foreach ($record in $records)
    {
        $output = new-object PSObject
        $output | add-member -Membertype NoteProperty -Name "DisplayName" -value "$($record.DisplayName)"
        $output | add-member -Membertype NoteProperty -Name "SignInName" -value "$($record.SignInName)"
        $output | add-member -Membertype NoteProperty -Name "SubscriptionName" -value "$($sub.Name)"
        $output | add-member -Membertype NoteProperty -Name "RoleDefinitionName" -value "$($record.RoleDefinitionName)"

        $result = Get-AzureRmRoleDefinition -Name $record.RoleDefinitionName
        $output | add-member -Membertype NoteProperty -Name "Action" -value "$($result.Actions)"
        $output | add-member -Membertype NoteProperty -Name "NotAction" -value "$($result.NotActions)"
        $output | add-member -Membertype NoteProperty -Name "DataAction" -value "$($result.DataAction)"
        $output | add-member -Membertype NoteProperty -Name "NotDataAction" -value "$($result.NotDataAction)"

        $logarray += $output 
    }
}

$logArray | convertto-Csv -NoTypeInformation | out-file D:\azurerole.csv -append -Encoding utf8 
Write-Output "Export Success, please check export file in Disk D:"
