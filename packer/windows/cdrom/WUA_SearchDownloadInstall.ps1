if (Test-Path -Path "E:\WUA_SearchDownloadInstall.vbs" -PathType Leaf) {
  $action = New-ScheduledTaskAction -Execute "C:\Windows\System32\cscript.exe" -Argument "E:\WUA_SearchDownloadInstall.vbs /Automate"
} elseif(Test-Path -Path "F:\WUA_SearchDownloadInstall.vbs" -PathType Leaf) {
  $action = New-ScheduledTaskAction -Execute "C:\Windows\System32\cscript.exe" -Argument "F:\WUA_SearchDownloadInstall.vbs /Automate"
} else {
  throw "Scipt disk not attached"
}

$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date -Format t)
Register-ScheduledTask -TaskName "WinUpdate" -Action $action -Trigger $trigger
Start-ScheduledTask -TaskName "WinUpdate"
while ((Get-ScheduledTask -TaskName "WinUpdate").State  -ne 'Ready') {
  Write-Verbose -Message "Waiting on scheduled task..."
  Start-Sleep -Seconds 60
}
$returnCode = (Get-ScheduledTaskInfo -TaskName "WinUpdate").LastTaskResult
Write-Host ""
exit $returnCode
