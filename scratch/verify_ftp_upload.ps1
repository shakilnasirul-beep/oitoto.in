$ftpBase = "ftp://ftpupload.net/htdocs"
$ftpUsername = "if0_43267863"
$ftpPassword = "oxbrse54OmM"

$checkFiles = @(
    "index.html",
    ".htaccess",
    "preview/index.html",
    "preview/customer_app_preview.html",
    "api/index.php",
    "backend/src/Controllers/ServiceAreaController.php"
)

Write-Host "=== VERIFYING LIVE FILES ON INFINITYFREE FTP SERVER ==="
foreach ($f in $checkFiles) {
    $remoteUrl = "$ftpBase/$f"
    try {
        $reqSize = [System.Net.FtpWebRequest]::Create($remoteUrl)
        $reqSize.Method = [System.Net.WebRequestMethods+Ftp]::GetFileSize
        $reqSize.Credentials = New-Object System.Net.NetworkCredential($ftpUsername, $ftpPassword)
        $respSize = $reqSize.GetResponse()
        $size = $respSize.ContentLength
        $respSize.Close()

        $reqDate = [System.Net.FtpWebRequest]::Create($remoteUrl)
        $reqDate.Method = [System.Net.WebRequestMethods+Ftp]::GetDateTimestamp
        $reqDate.Credentials = New-Object System.Net.NetworkCredential($ftpUsername, $ftpPassword)
        $respDate = $reqDate.GetResponse()
        $date = $respDate.LastModified
        $respDate.Close()

        Write-Host "[OK] $f -> Size: $size bytes | Modified: $date"
    } catch {
        Write-Host "[FAIL] $f -> Error: $_"
    }
}
