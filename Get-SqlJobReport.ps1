function Get-SqlJobReport {
    param(
        [string[]]$SqlInstance = "localhost"
    )

    foreach ($inst in $SqlInstance) {
        try {
            $jobs = Get-DbaAgentJob -SqlInstance $inst -EnableException
        }
        catch {
            Write-Warning "Could not read Agent jobs on $inst : $($_.Exception.Message)"
            continue
        }

        foreach ($j in ($jobs | Where-Object IsEnabled)) {
            $status = if ($j.LastRunOutcome -eq 'Failed') { "CRITICAL" } else { "OK" }

            [PSCustomObject]@{
                Instance    = $inst
                Job         = $j.Name
                LastRunDate = $j.LastRunDate
                LastOutcome = $j.LastRunOutcome
                Status      = $status
            }
        }
    }
}
