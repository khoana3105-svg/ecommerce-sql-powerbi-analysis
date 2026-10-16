# Run only the isolated EcommerceSalesPortfolio exercise; Windows Authentication.
# No server settings or login permissions are changed. No existing tables are dropped.
param([string]$Server = 'localhost')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$runtimeOutput = Join-Path $projectRoot 'outputs\sql_server'
[void][System.IO.Directory]::CreateDirectory($runtimeOutput)
$connection = New-Object System.Data.SqlClient.SqlConnection
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = $Server
$builder['Initial Catalog'] = 'master'
$builder['Integrated Security'] = $true
$builder['Connect Timeout'] = 10
$builder['Encrypt'] = $true
$builder['TrustServerCertificate'] = $true
$connection.ConnectionString = $builder.ConnectionString
$resultSets = @()
$batchCount = 0
$loadedNow = $false
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandTimeout = 120
    $command.CommandText = "SELECT CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128))"
    $version = [string]$command.ExecuteScalar()
    $command.CommandText = "SELECT CASE WHEN DB_ID(N'EcommerceSalesPortfolio') IS NULL THEN 0 ELSE 1 END"
    $exists = [int]$command.ExecuteScalar()
    $existingTableCount = 0
    if ($exists -eq 1) {
        $command.CommandText = 'SELECT COUNT(*) FROM EcommerceSalesPortfolio.sys.tables WHERE is_ms_shipped = 0'
        $existingTableCount = [int]$command.ExecuteScalar()
    }
    if ($existingTableCount -eq 0) {
        $loadText = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'sql\01_tao_va_nap.sql'))
        foreach ($batch in [regex]::Split($loadText, '(?im)^\s*GO\s*\r?$')) {
            if ($batch.Trim()) {
                $command.CommandText = $batch
                [void]$command.ExecuteNonQuery()
            }
        }
        $loadedNow = $true
    }
    $connection.ChangeDatabase('EcommerceSalesPortfolio')
    # Recheck all source table counts even when reusing an existing practice DB.
    $expectedCounts = @(Import-Csv -LiteralPath (Join-Path $projectRoot 'outputs\table_counts_expected.csv'))
    foreach ($expected in $expectedCounts) {
        if ($expected.TableName -notmatch '^\w+$') { throw 'Invalid expected table name' }
        $command.CommandText = 'SELECT COUNT_BIG(*) FROM dbo.[' + $expected.TableName + ']'
        $actualCount = [long]$command.ExecuteScalar()
        if ($actualCount -ne [long]$expected.ExpectedRows) {
            throw "Row count mismatch in $($expected.TableName): $actualCount"
        }
    }
    $practiceText = [System.IO.File]::ReadAllText((Join-Path $projectRoot 'sql\02_thuc_hanh.sql'))
    foreach ($batch in [regex]::Split($practiceText, '(?im)^\s*GO\s*\r?$')) {
        if (-not $batch.Trim()) { continue }
        $batchCount++
        $command.CommandText = $batch
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
        $dataset = New-Object System.Data.DataSet
        try {
            [void]$adapter.Fill($dataset)
            foreach ($table in $dataset.Tables) {
                $setIndex = $resultSets.Count + 1
                $filename = 'result_{0:d2}.csv' -f $setIndex
                $records = @(
                    foreach ($row in $table.Rows) {
                        $record = [ordered]@{}
                        foreach ($column in $table.Columns) {
                            $value = $row[$column.ColumnName]
                            if ($value -is [DBNull]) { $value = $null }
                            elseif ($value -is [datetime]) { $value = $value.ToString('yyyy-MM-ddTHH:mm:ss') }
                            elseif ($value -is [System.IFormattable]) {
                                $value = $value.ToString($null, [System.Globalization.CultureInfo]::InvariantCulture)
                            }
                            $record[$column.ColumnName] = $value
                        }
                        [pscustomobject]$record
                    }
                )
                if ($records.Count -gt 0) {
                    $records | Export-Csv -LiteralPath (Join-Path $runtimeOutput $filename) -NoTypeInformation -Encoding UTF8
                } else {
                    $header = (@($table.Columns | ForEach-Object { '"' + $_.ColumnName.Replace('"', '""') + '"' }) -join ',')
                    [System.IO.File]::WriteAllText((Join-Path $runtimeOutput $filename), $header + "`n", [System.Text.Encoding]::UTF8)
                }
                $resultSets += [pscustomobject]@{
                    File = $filename
                    Batch = $batchCount
                    Rows = $table.Rows.Count
                    Columns = @($table.Columns | ForEach-Object ColumnName)
                }
            }
        } finally { $adapter.Dispose(); $dataset.Dispose() }
    }
    $command.CommandText = 'SELECT COUNT(*) FROM sys.foreign_keys; SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled = 1 OR is_not_trusted = 1;'
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $foreignKeys = New-Object System.Data.DataSet
    [void]$adapter.Fill($foreignKeys)
    $fkCount = [int]$foreignKeys.Tables[0].Rows[0][0]
    $untrustedFKs = [int]$foreignKeys.Tables[1].Rows[0][0]
    $adapter.Dispose(); $foreignKeys.Dispose()
    if ($fkCount -ne 36 -or $untrustedFKs -ne 0) { throw 'Foreign key verification failed' }
    $summary = [ordered]@{
        Status = 'executed'
        VerifiedAtUTC = [datetime]::UtcNow.ToString('o')
        SqlServerVersion = $version
        Database = 'EcommerceSalesPortfolio'
        LoadedThisRun = $loadedNow
        SourceTablesChecked = $expectedCounts.Count
        ForeignKeys = $fkCount
        DisabledOrUntrustedForeignKeys = $untrustedFKs
        PracticeBatches = $batchCount
        ResultSets = $resultSets
    }
    $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $runtimeOutput 'execution.json') -Encoding UTF8
    Write-Output "SQL Server $version : execution succeeded; $($expectedCounts.Count) source tables verified; $($resultSets.Count) result sets exported."
} catch {
    if ($connection.State -eq [System.Data.ConnectionState]::Open) {
        $rollback = $connection.CreateCommand()
        $rollback.CommandText = 'IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;'
        try { [void]$rollback.ExecuteNonQuery() } finally { $rollback.Dispose() }
    }
    throw
} finally { $connection.Dispose() }
