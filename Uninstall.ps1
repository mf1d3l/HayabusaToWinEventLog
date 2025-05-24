# Remove the scheduled task
Unregister-ScheduledTask -TaskName "HayabusaToWinEventLog" -Confirm:$false

# Remove install folder
Remove-Item -Recurse -Force "c:\Program Files\HayabusaToWinEventLog"
