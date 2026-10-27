$ftpServer = "ftp://ftpupload.net/htdocs/admin/index.html"
$request = [System.Net.FtpWebRequest]::Create($ftpServer)
$request.Method = [System.Net.WebRequestMethods+Ftp]::GetFileSize
$request.Credentials = New-Object System.Net.NetworkCredential('if0_43267863', 'oxbrse54OmM')
$response = $request.GetResponse()
Write-Host "FTP File Size on Server: $($response.ContentLength) bytes"
$response.Close()
