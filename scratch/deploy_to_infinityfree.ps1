$ftpBase = "ftp://ftpupload.net/htdocs"
$ftpUsername = "if0_43267863"
$ftpPassword = "oxbrse54OmM"

$filesToUpload = @(
    @{ Local = "G:\oitoto\index.html"; Remote = "$ftpBase/index.html" },
    @{ Local = "G:\oitoto\.htaccess"; Remote = "$ftpBase/.htaccess" },
    @{ Local = "G:\oitoto\preview\index.html"; Remote = "$ftpBase/preview/index.html" },
    @{ Local = "G:\oitoto\preview\customer_app_preview.html"; Remote = "$ftpBase/preview/customer_app_preview.html" },
    @{ Local = "G:\oitoto\api\index.php"; Remote = "$ftpBase/api/index.php" },
    @{ Local = "G:\oitoto\backend\public\index.php"; Remote = "$ftpBase/backend/public/index.php" },
    @{ Local = "G:\oitoto\backend\src\Controllers\ServiceAreaController.php"; Remote = "$ftpBase/backend/src/Controllers/ServiceAreaController.php" }
)

foreach ($item in $filesToUpload) {
    $localFile = $item.Local
    $remoteUrl = $item.Remote
    Write-Host "Uploading $localFile to $remoteUrl..."
    try {
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
        Write-Host "  -> SUCCESS: $($response.StatusDescription.Trim())"
        $response.Close()
    } catch {
        Write-Host "  -> ERROR: $_"
    }
}
Write-Host "Completed InfinityFree Upload!"
