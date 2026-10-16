# Build dashboard views only in the dedicated portfolio DB, then export CSVs.
param([string]$Server = 'localhost')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'powerbi\data'
[void][IO.Directory]::CreateDirectory($out)
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = $Server
$builder['Initial Catalog'] = 'EcommerceSalesPortfolio'
$builder['Integrated Security'] = $true
$builder['Connect Timeout'] = 10
$builder['Encrypt'] = $true
$builder['TrustServerCertificate'] = $true
$connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandTimeout = 120
    $text = [IO.File]::ReadAllText((Join-Path $root 'sql\03_powerbi_views.sql'))
    foreach ($batch in [regex]::Split($text, '(?im)^\s*GO\s*\r?$')) {
        if ($batch.Trim()) { $command.CommandText = $batch; [void]$command.ExecuteNonQuery() }
    }
    foreach ($name in @('FactOrders','FactOrderItems','DimProducts','DimCustomers')) {
        $command.CommandText = 'SELECT * FROM dbo.bi_' + $name
        $table = New-Object System.Data.DataTable
        $reader = $command.ExecuteReader()
        $table.Load($reader)
        $records = @(
            foreach ($row in $table.Rows) {
                $record = [ordered]@{}
                foreach ($column in $table.Columns) {
                    $value = $row[$column.ColumnName]
                    if ($value -is [DBNull]) { $value = $null }
                    elseif ($value -is [datetime]) { $value = $value.ToString('yyyy-MM-dd') }
                    elseif ($value -is [IFormattable]) { $value = $value.ToString($null,[Globalization.CultureInfo]::InvariantCulture) }
                    $record[$column.ColumnName] = $value
                }
                [pscustomobject]$record
            }
        )
        $records | Export-Csv -LiteralPath (Join-Path $out ($name + '.csv')) -Encoding UTF8 -NoTypeInformation
        Write-Output ($name + ': ' + $records.Count)
        $table.Dispose()
    }
} finally { $connection.Dispose() }
