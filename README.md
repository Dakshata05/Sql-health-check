# SQL Server Health Check

PowerShell + dbatools script that checks backup age and CHECKDB age for every
user database on one or more SQL Server instances, and writes a CSV and HTML report.

## What it checks
- Age of the last full backup (warning if older than 1 day, critical if none)
- Age of the last good CHECKDB (warning if older than 7 days or never run)
- Database size and recovery model

## Requirements
- PowerShell 7
- dbatools module (`Install-Module dbatools -Scope CurrentUser`)
- Permission to connect to the SQL Server instances

## Usage
    .\Invoke-SqlHealthCheck.ps1 -SqlInstance "SQL01","SQL02"

Reports and logs are written to the `output` folder.

## Scheduling
Run daily with Windows Task Scheduler or a SQL Server Agent CmdExec job step.

## Notes
- Built and tested on a local SQL Server Developer Edition instance.
- An unreachable server logs a warning and does not stop the rest.
- `-TrustServerCertificate` is for local practice instances only.
