Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"

# Save original location
$originalLocation = Get-Location

# Get the site code
$SiteCode = Get-PSDrive -PSProvider CMSite
Set-Location "$($SiteCode.Name):\"

$collectionName = Read-Host "Enter the collection name"
$computers = (Get-CMDevice -CollectionName $collectionName).Name

# Create synchronized counter for progress tracking
$completed = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new()
$total = $computers.Count
$lock = [System.Threading.ReaderWriterLockSlim]::new()

Write-Host "`nChecking online status of $total computers...`n" -ForegroundColor Green

$results = $computers | ForEach-Object -Parallel {
    $computer = $_
    $completed = $using:completed
    $total = $using:total
    $lock = $using:lock

    # Check if computer is online using Test-Connection
    $isOnline = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction SilentlyContinue
    $status = if ($isOnline) { "Online" } else { "Offline" }
    
    # Update progress after completion
    $completed.TryAdd($computer, $true) | Out-Null
    $completedCount = $completed.Count
    $percentComplete = [math]::Round(($completedCount / $total) * 100, 1)
    
    # Synchronized progress output
    $lock.EnterWriteLock()
    try {
        $color = if ($status -eq "Online") { "Green" } else { "Red" }
        Write-Host "[$completedCount/$total] ($percentComplete%) $computer : $status" -ForegroundColor $color
    }
    finally {
        $lock.ExitWriteLock()
    }
    
    return [PSCustomObject]@{
        Computer = $computer
        Status = $status
    }
} -ThrottleLimit 50

Write-Host "`nCompleted processing all $total computers.`n" -ForegroundColor Green

# $results | Format-Table -AutoSize

# Restore original location
Set-Location $originalLocation