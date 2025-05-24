# Remove the scheduled task
Unregister-ScheduledTask -TaskName "HayabusaToWinEventLog" -Confirm:$false

# Remove AutorunsToWinEventLog folder
Remove-Item -Recurse -Force "c:\Program Files\HayabusaToWinEventLog"
