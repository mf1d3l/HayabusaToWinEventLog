# Author: mfidel
# This script executes the Yamato-Security Hayabusa CLI utility and saves the output to a CSV.
# The resulting CSV entries are written to the Windows Event Log.
# The script is greatly inspired from AutorunsToWinEventlog authored by Chris Long (@Centurion) and Andy Robbins (@_wald0)

# Define the event log source
$eventSource = "Hayabusa"
$eventLogName = "Application"

# Define minimum rule level to process (informational, low, medium, high, critical, emergency)
$logLevel = "medium" 

# Check if the event source exists, if not, create it
if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
    New-EventLog -LogName $eventLogName -Source $eventSource
}

$HayabusaDir = "C:\Program Files\HayabusaToWinEventLog"

# Find the Hayabusa executable
$hayabusaExe = Get-ChildItem -Path $HayabusaDir -Recurse -Filter "*.exe" |
    Where-Object { $_.Name -match "hayabusa" }

# Start Hayabusa
& $hayabusaExe.FullName csv-timeline -O -l -w -m $logLevel --time-offset 15m -o $HayabusaDir\hayabusa.csv

# Import Csv output
$hayabusaArray = Import-Csv $HayabusaDir\hayabusa.csv

# Remove output file
Remove-Item $HayabusaDir\hayabusa.csv

# Populate EventLog
Foreach ($item in $hayabusaArray) {
	switch ($item.Level) {
        "emer" { $EventID = 1001 } 
        "crit" { $EventID = 1002 }  
        "high" { $EventID = 1003 } 
        "med"  { $EventID = 1004 }
		"low"  { $EventID = 1005 }
        "info" { $EventID = 1006 }
		Default { $EventID = 9999 }
  }
  $itemData = $(Write-Output $item  | Out-String -Width 1000)
  Write-EventLog -LogName $eventLogName -Source $eventSource -EntryType Information -EventId $EventID -Message $itemData
}
