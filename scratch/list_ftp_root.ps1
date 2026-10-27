$ftpServer = "ftp://ftpupload.net/htdocs/"
$request = [System.Net.FtpWebRequest]::Create($ftpServer)
$request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
$request.Credentials = New-Object System.Net.NetworkCredential('if0_43267863', 'oxbrse54OmM')
$response = $request.GetResponse()
$reader = New-Object System.IO.StreamReader($response.GetResponseStream())
$list = $reader.ReadToEnd()
Write-Host "FTP Root Directory:"
Write-Host $list
$reader.Close()
$response.Close()
