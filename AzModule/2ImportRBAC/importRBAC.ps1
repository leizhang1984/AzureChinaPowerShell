#Created By MSFT leizhang (leizha@microsoft.com) on Nov 20th, 2019
#Updated 2022-06-22

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
$csvpath = $pwd.Path + "\export_rbac.csv"

#Start to Process CSV File
$P = Import-Csv -Path $csvpath
foreach ($rows in $p)
{
        try
        {
                Select-AzSubscription -SubscriptionId $rows.SubscriptionId
                if($rows.ObjectType -eq "ServicePrincipal")
                {
                    $objId = Get-AzADServicePrincipal -DisplayName $rows.DisplayName      	
                }
                elseif ($rows.ObjectType -eq "Group")
                {
                    $objId = Get-AzADGroup -DisplayName $rows.DisplayName
                }
                elseif ($rows.ObjectType -eq "User")
                {
                     $objId = Get-AzADUser -ObjectId $rows.SignInName
                }
                if ($objId -ne $null) 
                {
                    New-AzRoleAssignment -ObjectId $objId.Id -RoleDefinitionName $rows.RoleDefinitionName -Scope $rows.Scope
                }
        }
        Catch
        {
                Write-Error "Processing with a Error, Resume Next"
        }
}


Write-Error "Processing Finish"