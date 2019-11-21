#Created By MSFT leizhang (leizha@microsoft.com) on Nov 20th, 2019

#login in to Azure
Connect-AzAccount -Environment AzureChinaCloud


#Read CSV file exported by another Powershell
#https://github.com/leizhang1984/AzureChinaPowerShell/tree/master/AzModule/1ExportRBAC

#This CSV file MUST HAVE following Column
#SubscriptioName	
#SubscriptionId	
#RoleDefinitionName	
#DisplayName	
#SignInName	
#ObjectType	
#Scope

#WARNING: Please Modity Column DisplayName and SingInName if necessary

#Please modify CSV path first
$csvpath = "D:\export_rbac.csv"

#Start to Process CSV File
$P = Import-Csv -Path $csvpath
foreach ($rows in $p)
{
        try
        {
                Select-AzSubscription -SubscriptionId $rows.SubscriptionId
                #if($rows.RoleDefinitionName -notmatch ("ServiceAdministrator") -and $rows.RoleDefinitionName -notmatch ("AccountAdministrator"))
                #{
                        New-AzRoleAssignment -SignInName $rows.SignInName -RoleDefinitionName $rows.RoleDefinitionName -Scope $rows.Scope
                #}
        }
        Catch
        {
                Write-Error "Processing with a Error, Resume Next"
        }
}


Write-Error "Processing Finish"