param(
    [string[]]$SqlInstance = "localhost",
    [string]$OutputPath = "$PSScriptRoot\output",
    [int]$KeepDays = 14,
    [switch]$TrustServerCertificate
)

$ErrorActionPreference = "Stop"

Import-Module dbatools
if ($TrustServerCertificate) { Set-DbatoolsInsecureConnection -SessionOnly | Out-Null }

. "$PSScriptRoot\Get-SqlHealthReport.ps1"
. "$PSScriptRoot\Get-SqlDiskReport.ps1"
. "$PSScriptRoot\Get-SqlJobReport.ps1"
. "$PSScriptRoot\Get-SqlBlockingReport.ps1"
. "$PSScriptRoot\New-SqlHealthHtml.ps1"

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$date = Get-Date -Format "yyyy-MM-dd"
Start-Transcript -Path (Join-Path $OutputPath "run_$date.log") -Append | Out-Null

try {
    $report   = Get-SqlHealthReport   -SqlInstance $SqlInstance
    $disks    = Get-SqlDiskReport     -SqlInstance $SqlInstance
    $jobs     = Get-SqlJobReport      -SqlInstance $SqlInstance
    $blocking = Get-SqlBlockingReport -SqlInstance $SqlInstance

    $report | Export-Csv (Join-Path $OutputPath "sql_health_$date.csv") -NoTypeInformation
    $disks  | Export-Csv (Join-Path $OutputPath "sql_disks_$date.csv")  -NoTypeInformation
    $jobs   | Export-Csv (Join-Path $OutputPath "sql_jobs_$date.csv")   -NoTypeInformation
    if ($blocking) {
        $blocking | Export-Csv (Join-Path $OutputPath "sql_blocking_$date.csv") -NoTypeInformation
    }

    New-SqlHealthHtml -Path (Join-Path $OutputPath "sql_health_$date.html") `
        -Databases $report -Disks $disks -Jobs $jobs -Blocking $blocking

    Get-ChildItem $OutputPath -File |
        Where-Object LastWriteTime -lt (Get-Date).AddDays(-$KeepDays) |
        Remove-Item

    $bad = @($report   | Where-Object { $_.BackupStatus -ne 'OK' -or $_.CheckDbStatus -ne 'OK' }).Count +
           @($disks    | Where-Object { $_.Status -ne 'OK' }).Count +
           @($jobs     | Where-Object { $_.Status -ne 'OK' }).Count +
           @($blocking | Where-Object { $_ }).Count
    $dbCount = @($report | Where-Object { $_ }).Count

    Write-Output "Report written for $dbCount database(s). $bad item(s) need attention."
}
catch {
    Write-Error "Health check failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Stop-Transcript | Out-Null
}
