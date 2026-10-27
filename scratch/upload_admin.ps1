$ftpServer = "ftp://ftpupload.net/htdocs/admin/index.html"
$ftpUsername = "if0_43267863"
$ftpPassword = "oxbrse54OmM"
$localFile = "G:\oitoto\admin\index.html"

Write-Host "Uploading $localFile to $ftpServer..."
$request = [System.Net.FtpWebRequest]::Create($ftpServer)
$request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$request.Credentials = New-Object System.Net.NetworkCredential($ftpUsername, $ftpPassword)
$request.UseBinary = $true
$request.UsePassive = $true
$request.KeepAlive = $false

$fileBytes = [System.IO.File]::ReadAllBytes($localFile)
$request.ContentLength = $fileBytes.Length

$requestStream = $request.GetRequestStream()
$requestStream.Write($fileBytes, 0, $fileBytes.Length)
$requestStream.Close()

$response = $request.GetResponse()
Write-Host "Upload Status: $($response.StatusDescription)"
$response.Close()
Write-Host "Upload complete!"
