#Created By MSFT leizhang (leizha@microsoft.com) on 2021-08-16
#Please run 
#Install-Module -name AzureAD
#for the first time


$logarray=@()

#login in to Azure
Connect-AzureAD -AzureEnvironmentName AzureChinaCloud

#Loop Subscriptions
$exports = Get-AzureADUser
        
foreach ($datarow in $exports)
{
        $output = new-object PSObject
        $output | add-member -Membertype NoteProperty -Name "ObjectId" -value $datarow.ObjectId
        $output | add-member -Membertype NoteProperty -Name "DisplayName" -value $datarow.DisplayName
        $output | add-member -Membertype NoteProperty -Name "UserPrincipalName" -value $datarow.UserPrincipalName
        if($datarow.dirsyncenabled -ne $null)
        {
            $output | add-member -Membertype NoteProperty -Name "dirsyncenabled" -value "Windows Server AD"
            
        }
        else
        {
            $output | add-member -Membertype NoteProperty -Name "dirsyncenabled" -value "Azure Active Directory"
        }

        $logarray += $output 
}
    

$logArray | convertto-Csv -NoTypeInformation | out-file D:\export_aaduser.csv -append -Encoding utf8 
Write-Output "Export AAD Account successfully"