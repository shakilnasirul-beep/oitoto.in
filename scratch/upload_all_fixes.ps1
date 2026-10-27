$ftpBase = "ftp://ftpupload.net/htdocs"
$ftpUsername = "if0_43267863"
$ftpPassword = "oxbrse54OmM"

$filesToUpload = @(
    @{ Local = "G:\oitoto\admin\index.html"; Remote = "$ftpBase/admin/index.html" },
    @{ Local = "G:\oitoto\api\index.php"; Remote = "$ftpBase/api/index.php" },
    @{ Local = "G:\oitoto\backend\src\Controllers\AdminController.php"; Remote = "$ftpBase/backend/src/Controllers/AdminController.php" }
)

foreach ($item in $filesToUpload) {
    $localFile = $item.Local
    $remoteUrl = $item.Remote
    Write-Host "Uploading $localFile to $remoteUrl..."

    $request = [System.Net.FtpWebRequest]::Create($remoteUrl)
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
    Write-Host "Response: $($response.StatusDescription)"
    $response.Close()
}

Write-Host "All files uploaded successfully!"
