$Disk = Get-CimInstance -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$FileSize = $Disk.FreeSpace - ($Disk.Size * 0.05)
$FilePath ="c:\zero.tmp"
$ArraySize = 64kb
$ZeroArray = new-object byte[]($ArraySize)

$Stream = [io.File]::OpenWrite($FilePath)
try {
    $CurFileSize = 0
    while($CurFileSize -lt $FileSize) {
        $Stream.Write($ZeroArray, 0, $ZeroArray.Length)
        $CurFileSize += $ZeroArray.Length
    }
} finally {
    if($Stream) {
        $Stream.Close()
    }
}

Remove-Item -Path $FilePath -Force
