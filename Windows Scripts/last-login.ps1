$computers = @("Computer1", "Computer2", "Computer3")

foreach ($computer in $computers) {
    try {
        $lastBoot = Get-CimInstance -ComputerName $computer -ClassName Win32_OperatingSystem -ErrorAction Stop
        [PSCustomObject]@{
            ComputerName = $computer
            LastBootTime = $lastBoot.LastBootUpTime
            Status = "Online"
        }
    }
    catch {
        [PSCustomObject]@{
            ComputerName = $computer
            LastBootTime = "N/A"
            Status = "Offline/Error"
        }
    }
}