$logarray=@()
$SubscriptionNames = Get-AzSubscription
foreach ($sub in $SubscriptionNames)
{
        Select-AzSubscription -SubscriptionName $sub.Name 

        $subscriptionName = $sub.Name
        $subscriptionId = $sub.subscriptionId

        Write-Output "Processing " $sub.Name 
        
        $assignedIdentitities = Get-AzUserAssignedIdentity
        
        foreach ($assignIdentity in $assignedIdentitities)
        {
		    $identityName = $assignIdentity.Name
		    $rgName = $assignIdentity.ResourceGroupName

		    $associatedResources = Get-AzUserAssignedIdentityAssociatedResource -Name $identityName -ResourceGroupName $rgName
            foreach ($associatedResource in $associatedResources)
		    {
					$output = new-object PSObject
					$output | add-member -Membertype NoteProperty -Name "ManageIdentityName" -value $identityName
					$output | add-member -Membertype NoteProperty -Name "ManageIdentityResourceGroup" -value $rgName

					$output | add-member -Membertype NoteProperty -Name "Associated Resources" -value $associatedResource.Name
					$output | add-member -Membertype NoteProperty -Name "Associated Resource Group" -value $associatedResource.ResourceGroup
					$output | add-member -Membertype NoteProperty -Name "SubscriptionName" -value $associatedResource.SubscriptionDisplayName

					#$output | add-member -Membertype NoteProperty -Name "Associated Resource Type" -value $associatedResources.ResourceType

					$logarray += $output 
            }
        }
    
}

$csvpath = $pwd.Path + "\export_MIAssociateResource.csv"
$logArray | convertto-Csv -NoTypeInformation | out-file $csvpath -append -Encoding utf8 
Write-Output "Export Managed Identity successfully"