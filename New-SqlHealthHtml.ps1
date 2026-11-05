function New-SqlHealthHtml {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [object[]]$Databases,
        [object[]]$Disks,
        [object[]]$Jobs,
        [object[]]$Blocking
    )

    function ConvertTo-Section {
        param([string]$Title, [object[]]$Data, [string]$EmptyText)

        if (-not ($Data | Where-Object { $_ })) {
            return "<h2>$Title</h2><p>$EmptyText</p>"
        }
        $html = $Data | ConvertTo-Html -Fragment | Out-String
        $html = $html -replace '<td>OK</td>',       '<td class="ok">OK</td>'
        $html = $html -replace '<td>WARNING</td>',  '<td class="warning">WARNING</td>'
        $html = $html -replace '<td>CRITICAL</td>', '<td class="critical">CRITICAL</td>'
        return "<h2>$Title</h2>$html"
    }

    $style = @"
<style>
body{font-family:Arial,sans-serif;margin:24px;color:#222}
h1{color:#1F4E78}
h2{margin-top:28px;border-bottom:2px solid #1F4E78;padding-bottom:4px}
table{border-collapse:collapse;margin-top:8px}
th,td{border:1px solid #bbb;padding:5px 10px;text-align:left}
th{background:#1F4E78;color:#fff}
td.ok{background:#C6EFCE;color:#006100}
td.warning{background:#FFEB9C;color:#9C5700}
td.critical{background:#FFC7CE;color:#9C0006}
.summary span{display:inline-block;padding:6px 14px;margin-right:8px;border-radius:4px;font-weight:bold}
.s-ok{background:#C6EFCE;color:#006100}
.s-warning{background:#FFEB9C;color:#9C5700}
.s-critical{background:#FFC7CE;color:#9C0006}
</style>
"@

    $statuses = @()
    foreach ($row in @($Databases)) { if ($row) { $statuses += $row.BackupStatus, $row.CheckDbStatus } }
    foreach ($row in (@($Disks) + @($Jobs) + @($Blocking))) { if ($row) { $statuses += $row.Status } }

    $crit = @($statuses | Where-Object { $_ -eq 'CRITICAL' }).Count
    $warn = @($statuses | Where-Object { $_ -eq 'WARNING' }).Count
    $ok   = @($statuses | Where-Object { $_ -eq 'OK' }).Count
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm"

    $summary = "<div class='summary'><span class='s-critical'>$crit critical</span><span class='s-warning'>$warn warning</span><span class='s-ok'>$ok ok</span></div>"

    $sections = @(
        "<h1>SQL Server Health Report</h1>",
        "<p>Generated $stamp</p>",
        $summary,
        (ConvertTo-Section -Title "Databases: backups and CHECKDB" -Data $Databases -EmptyText "No user databases found."),
        (ConvertTo-Section -Title "Disk space"                     -Data $Disks     -EmptyText "No disk data returned."),
        (ConvertTo-Section -Title "SQL Agent jobs"                 -Data $Jobs      -EmptyText "No enabled Agent jobs found."),
        (ConvertTo-Section -Title "Blocking"                       -Data $Blocking  -EmptyText "No blocking detected.")
    )

    $page = "<!DOCTYPE html><html><head><meta charset='utf-8'><title>SQL Server Health Report</title>$style</head><body>" +
            ($sections -join "`n") + "</body></html>"

    $page | Set-Content -Path $Path -Encoding utf8
}
