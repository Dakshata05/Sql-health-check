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

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$date = Get-Date -Format "yyyy-MM-dd"
Start-Transcript -Path (Join-Path $OutputPath "run_$date.log") -Append | Out-Null

try {
    $report = Get-SqlHealthReport -SqlInstance $SqlInstance

    $report | Export-Csv (Join-Path $OutputPath "sql_health_$date.csv") -NoTypeInformation

    $style = "<style>body{font-family:Arial}table{border-collapse:collapse}th,td{border:1px solid #999;padding:4px 8px}th{background:#1F4E78;color:#fff}</style>"
    $report | ConvertTo-Html -Title "SQL Server Health Report" -Head $style `
        -PreContent "<h2>SQL Server Health Report - $date</h2>" |
        Out-File (Join-Path $OutputPath "sql_health_$date.html")

    Get-ChildItem $OutputPath -File |
        Where-Object LastWriteTime -lt (Get-Date).AddDays(-$KeepDays) |
        Remove-Item

    Write-Output "Report written for $($report.Count) database(s)."
}
catch {
    Write-Error "Health check failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Stop-Transcript | Out-Null
}
