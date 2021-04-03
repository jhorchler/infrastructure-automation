$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\cscript.exe" -Argument "F:\WUA_SearchDownloadInstall.vbs /Automate"
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
