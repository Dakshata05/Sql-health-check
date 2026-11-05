function Get-SqlBlockingReport {
    param(
        [string[]]$SqlInstance = "localhost",
        [int]$MaxWaitSeconds = 30
    )

    $query = @"
SELECT r.session_id AS BlockedSession,
       r.blocking_session_id AS BlockingSession,
       DB_NAME(r.database_id) AS DatabaseName,
       r.wait_type AS WaitType,
       r.wait_time / 1000 AS WaitSeconds
FROM sys.dm_exec_requests AS r
WHERE r.blocking_session_id <> 0;
"@

    foreach ($inst in $SqlInstance) {
        try {
            $rows = Invoke-DbaQuery -SqlInstance $inst -Database master -Query $query -EnableException
        }
        catch {
            Write-Warning "Could not check blocking on $inst : $($_.Exception.Message)"
            continue
        }

        foreach ($r in $rows) {
            [PSCustomObject]@{
                Instance        = $inst
                BlockedSession  = $r.BlockedSession
                BlockingSession = $r.BlockingSession
                Database        = $r.DatabaseName
                WaitType        = $r.WaitType
                WaitSeconds     = $r.WaitSeconds
                Status          = if ($r.WaitSeconds -gt $MaxWaitSeconds) { "CRITICAL" } else { "WARNING" }
            }
        }
    }
}
