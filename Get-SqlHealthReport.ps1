function Get-SqlHealthReport {
    param(
        [string[]]$SqlInstance = "localhost",
        [int]$MaxBackupAgeDays = 1,
        [int]$MaxCheckDbAgeDays = 7
    )

    foreach ($inst in $SqlInstance) {
        try {
            $dbs     = Get-DbaDatabase -SqlInstance $inst -ExcludeSystem -EnableException
            $backups = Get-DbaLastBackup -SqlInstance $inst -EnableException
            $checks  = Get-DbaLastGoodCheckDb -SqlInstance $inst -EnableException
        }
        catch {
            Write-Warning "Could not check $inst : $($_.Exception.Message)"
            continue
        }

        foreach ($db in $dbs) {
            $b = $backups | Where-Object Database -eq $db.Name
            $c = $checks  | Where-Object Database -eq $db.Name

            $backupAge = if ($b.LastFullBackup) { [int]((Get-Date) - [datetime]$b.LastFullBackup).TotalDays } else { $null }
            $checkAge  = if ($c.LastGoodCheckDb) { [int]((Get-Date) - [datetime]$c.LastGoodCheckDb).TotalDays } else { $null }

            $backupStatus = if ($null -eq $backupAge) { "CRITICAL" }
                            elseif ($backupAge -gt $MaxBackupAgeDays) { "WARNING" }
                            else { "OK" }

            $checkStatus  = if ($null -eq $checkAge) { "WARNING" }
                            elseif ($checkAge -gt $MaxCheckDbAgeDays) { "WARNING" }
                            else { "OK" }

            [PSCustomObject]@{
                Instance       = $inst
                Database       = $db.Name
                SizeMB         = [math]::Round($db.Size, 1)
                RecoveryModel  = $db.RecoveryModel
                BackupAgeDays  = $backupAge
                BackupStatus   = $backupStatus
                CheckDbAgeDays = $checkAge
                CheckDbStatus  = $checkStatus
            }
        }
    }
}
