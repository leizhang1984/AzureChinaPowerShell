$URL="Plese put Azure Blob SAS Token Here"

$uri = $URL.split('?')[0]
$sas = $URL.split('?')[1]
    
$newurl = $uri + "?restype=container&comp=list&" + $sas 
    
#Invoke REST API
$body = Invoke-RestMethod -uri $newurl

#cleanup answer and convert body to XML
$xml = [xml]$body.Substring($body.IndexOf('<'))

#use only the relative Path from the returned objects
$files = $xml.ChildNodes.Blobs.Blob.Name

#regenerate the download URL incliding the SAS token
$files | ForEach-Object { $uri + "/" + $_ + "?" + $sas }  