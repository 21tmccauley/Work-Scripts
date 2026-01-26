function Get-CMCollectionSelection {
    <#
    .SYNOPSIS
        Prompts for an SCCM/ConfigMgr collection name and returns its computers.
    .OUTPUTS
        PSCustomObject with CollectionName and Computers, or $null if none found/failed.
    #>
    try {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction Stop
        $originalLocation = Get-Location
        try {
            $SiteCode = Get-PSDrive -PSProvider CMSite
            Set-Location "$($SiteCode.Name):\"
            Write-Host ""
            $collectionName = Read-Host "Enter the collection name"
            $computers = @((Get-CMDevice -CollectionName $collectionName).Name)
            if ($computers.Count -eq 0) {
                Write-Host "No computers found in collection '$collectionName'" -ForegroundColor Red
                return $null
            }
            return [PSCustomObject]@{
                CollectionName = $collectionName
                Computers      = $computers
            }
        }
        finally {
            Set-Location $originalLocation
        }
    }
    catch {
        Write-Host ""
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "Make sure Configuration Manager module is available and you have proper permissions." -ForegroundColor Yellow
        return $null
    }
}

function Invoke-SingleComputerPing {
    Write-Host ""
    $computer = Read-Host "Enter computer name"
    if ([string]::IsNullOrWhiteSpace($computer)) {
        Write-Host "No computer name entered." -ForegroundColor Red
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    Write-Host ""
    $isOnline = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction SilentlyContinue
    $status = if ($isOnline) { "Online" } else { "Offline" }
    $color = if ($isOnline) { "Green" } else { "Red" }
    Write-Host "$computer : $status" -ForegroundColor $color
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-ParallelPing {
    try {
        $selection = Get-CMCollectionSelection
        if (-not $selection) {
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            return
        }
        $computers = $selection.Computers

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
        
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host ""
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "Make sure Configuration Manager module is available and you have proper permissions." -ForegroundColor Yellow
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Show-TUI {
    while ($true) {
        Clear-Host
        
        # Title
        Write-Host "========================================" -ForegroundColor DarkCyan
        Write-Host "         Tech Tooling TUI" -ForegroundColor DarkCyan
        Write-Host "========================================" -ForegroundColor DarkCyan
        Write-Host ""
        
        # Menu options
        Write-Host "1. Single computer name" -ForegroundColor Yellow
        Write-Host "2. Computer group" -ForegroundColor Yellow
        Write-Host "3. Exit" -ForegroundColor Yellow
        Write-Host ""
        
        # Get user input
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" {
                Invoke-SingleComputerPing
            }
            "2" {
                Invoke-ParallelPing
            }
            "3" {
                Write-Host ""
                Write-Host "Exiting..." -ForegroundColor Yellow
                break
            }
            default {
                Write-Host ""
                Write-Host "Invalid option. Press any key to continue..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
        
        if ($choice -eq "3") { break }
    }
}

# Run the TUI
Show-TUI
