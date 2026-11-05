function Get-SqlDiskReport {
    param(
        [string[]]$SqlInstance = "localhost",
        [int]$WarningPct  = 20,
        [int]$CriticalPct = 10
    )

    foreach ($inst in $SqlInstance) {
        $computer = ($inst -split '\\')[0]

        try {
            $disks = Get-DbaDiskSpace -ComputerName $computer -EnableException
        }
        catch {
            Write-Warning "Could not read disks on $computer : $($_.Exception.Message)"
            continue
        }

        foreach ($d in $disks) {
            $freePct = [math]::Round($d.PercentFree, 1)
            $status  = if ($freePct -lt $CriticalPct) { "CRITICAL" }
                       elseif ($freePct -lt $WarningPct) { "WARNING" }
                       else { "OK" }

            [PSCustomObject]@{
                Instance = $inst
                Drive    = $d.Name
                SizeGB   = [math]::Round($d.Capacity.Gigabyte, 1)
                FreeGB   = [math]::Round($d.Free.Gigabyte, 1)
                FreePct  = $freePct
                Status   = $status
            }
        }
    }
}
