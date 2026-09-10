[CmdletBinding(SupportsShouldProcess)]
# Supports -WhatIf and -Confirm so a caller can preview or approve the edit.
param(
    [Parameter(Mandatory = $true)]
    [string]$ProcedurePath,

    [Parameter(Mandatory = $true)]
    [int]$WorkSpaceId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[^%_\[\]]+$')]
    [string]$ProjectNumber,

    [string]$FolderPattern,

    [string]$BackupPath,

    [string]$ServerInstance,

    [string]$Database = 'FLDataMart',

    [switch]$ApplyToDatabase,

    [switch]$SyncWithDatabase
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Fail before reading or writing anything if the target is not a real file.
if (-not (Test-Path -LiteralPath $ProcedurePath -PathType Leaf)) {
    throw "Procedure file was not found: $ProcedurePath"
}

if ([string]::IsNullOrWhiteSpace($FolderPattern)) {
    # Project numbers are unique, so matching the number anywhere in FolderName
    # reproduces the requested LIKE '%project-number%' behavior.
    $FolderPattern = "%$ProjectNumber%"
}

# A custom pattern is allowed for legacy descriptive folder names, but it must
# still be a valid SQL LIKE pattern so the generated WHEN clause can match text.
if (-not $FolderPattern.Contains('%')) {
    throw 'FolderPattern must be a SQL LIKE pattern containing at least one % wildcard.'
}

$resolvedProcedurePath = (Resolve-Path -LiteralPath $ProcedurePath).Path

if (($ApplyToDatabase -or $SyncWithDatabase) -and [string]::IsNullOrWhiteSpace($ServerInstance)) {
    throw '-ServerInstance is required when -ApplyToDatabase or -SyncWithDatabase is specified.'
}

function Get-ProcedureDefinitionFromDatabase {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetServer,

        [Parameter(Mandatory = $true)]
        [string]$TargetDatabase
    )

    if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
        throw 'Invoke-Sqlcmd was not found. Install/import the SqlServer PowerShell module before using database options.'
    }

    # OBJECT_DEFINITION returns the current stored procedure body from SQL
    # Server, ensuring the edit starts from the deployed definition rather than
    # from a stale local file.
    $query = "SELECT OBJECT_DEFINITION(OBJECT_ID(N'dbo.raw_loading_documents_metadata')) AS ProcedureDefinition;"
    $result = Invoke-Sqlcmd -Query $query -ServerInstance $TargetServer -Database $TargetDatabase -ErrorAction Stop
    $definition = [string]$result.ProcedureDefinition

    if ([string]::IsNullOrWhiteSpace($definition)) {
        throw 'The stored procedure dbo.raw_loading_documents_metadata was not found or its definition could not be read.'
    }

    return $definition
}

function Publish-ProcedureToDatabase {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SqlFilePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetServer,

        [Parameter(Mandatory = $true)]
        [string]$TargetDatabase
    )

    # Invoke-Sqlcmd understands SSMS batch separators such as GO. The source
    # file is normally a CREATE PROCEDURE script, so execute a temporary ALTER
    # version against the already-existing database procedure.
    if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
        throw 'Invoke-Sqlcmd was not found. Install/import the SqlServer PowerShell module before using -ApplyToDatabase.'
    }

    $executionFile = Join-Path $env:TEMP ("raw_loading_documents_metadata_upd_{0}.sql" -f ([guid]::NewGuid().ToString('N')))
    try {
        $sql = Get-Content -LiteralPath $SqlFilePath -Raw
        $alterSql = $sql -replace '(?im)^\s*CREATE\s+(?:OR\s+ALTER\s+)?PROCEDURE\b', 'ALTER PROCEDURE'
        Set-Content -LiteralPath $executionFile -Value $alterSql -Encoding ASCII

        Invoke-Sqlcmd -InputFile $executionFile -ServerInstance $TargetServer -Database $TargetDatabase -ErrorAction Stop
    }
    finally {
        Remove-Item -LiteralPath $executionFile -Force -ErrorAction SilentlyContinue
    }
}

function Complete-ProcedureUpdate {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$EditedLines
    )

    if ($SyncWithDatabase) {
        # Deploy the edited definition first. The local script is changed only
        # after SQL Server accepts the ALTER PROCEDURE batch.
        $executionFile = Join-Path $env:TEMP ("raw_loading_documents_metadata_upd_{0}.sql" -f ([guid]::NewGuid().ToString('N')))
        try {
            Set-Content -LiteralPath $executionFile -Value $EditedLines -Encoding ASCII
            Publish-ProcedureToDatabase -SqlFilePath $executionFile -TargetServer $ServerInstance -TargetDatabase $Database

            # Keep the local source deployable on its own after synchronization.
            $localSql = ($EditedLines -join "`r`n") -replace '(?im)^\s*CREATE\s+PROCEDURE\b', 'CREATE OR ALTER PROCEDURE'
            Set-Content -LiteralPath $resolvedProcedurePath -Value $localSql -Encoding ASCII
        }
        finally {
            Remove-Item -LiteralPath $executionFile -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        # File-only mode retains the original behavior: back up and write the
        # local SQL file, then optionally deploy it if -ApplyToDatabase was set.
        Copy-Item -LiteralPath $resolvedProcedurePath -Destination $BackupPath -Force
        Set-Content -LiteralPath $resolvedProcedurePath -Value $EditedLines -Encoding ASCII

        if ($ApplyToDatabase -and $PSCmdlet.ShouldProcess("$ServerInstance/$Database", 'Alter the stored procedure in SQL Server')) {
            Publish-ProcedureToDatabase -SqlFilePath $resolvedProcedurePath -TargetServer $ServerInstance -TargetDatabase $Database
        }
    }
}

if ($SyncWithDatabase) {
    # Download the deployed procedure before making any changes. This is the
    # authoritative rollback copy requested for database-synchronized edits.
    $databaseDefinition = Get-ProcedureDefinitionFromDatabase -TargetServer $ServerInstance -TargetDatabase $Database
    $lines = [System.Collections.Generic.List[string]]($databaseDefinition -split "`r?`n")
}
else {
    $lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $resolvedProcedurePath)
}

if ([string]::IsNullOrWhiteSpace($BackupPath)) {
    # Keep the backup beside the edited procedure and make each default backup
    # unique to the second in which the change is made.
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $suffix = if ($SyncWithDatabase) { 'database_backup' } else { 'file_backup' }
    $BackupPath = "$resolvedProcedurePath.$suffix.$timestamp.sql"
}

# In database-sync mode, save the downloaded SQL definition as the backup before
# editing it. In file-only mode, preserve the existing file backup behavior.
if ($SyncWithDatabase) {
    Set-Content -LiteralPath $BackupPath -Value $lines -Encoding ASCII
}

$workspaceHeaderRegex = '^\s*(?:IF|ELSE IF)\s+@WorkSpaceId\s*=\s*(\d+)\s*$'
$workspaceHeaders = New-Object System.Collections.Generic.List[object]

# Record every top-level workspace header with its line number. Line positions
# let the script edit only the correct workspace block without reformatting the
# rest of the stored procedure.
for ($index = 0; $index -lt $lines.Count; $index++) {
    $match = [regex]::Match($lines[$index], $workspaceHeaderRegex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($match.Success) {
        $workspaceHeaders.Add([pscustomobject]@{
                Index = $index
                WorkSpaceId = [int]$match.Groups[1].Value
            })
    }
}

if ($workspaceHeaders.Count -eq 0) {
    throw 'No @WorkSpaceId sections were found in the procedure.'
}

$existingHeader = $workspaceHeaders | Where-Object WorkSpaceId -eq $WorkSpaceId | Select-Object -First 1

if ($existingHeader) {
    # Existing workspace: insert one WHEN branch into its current CASE.
    $sectionStart = $existingHeader.Index
    $nextHeader = $workspaceHeaders | Where-Object Index -gt $sectionStart | Select-Object -First 1
    $sectionEnd = if ($nextHeader) { $nextHeader.Index - 1 } else { $lines.Count - 1 }

    # Prevent accidental duplicate mappings. The comparison is against the
    # ProjectNumber returned by the CASE, not merely against its LIKE pattern.
    $existingProject = $false
    for ($index = $sectionStart; $index -le $sectionEnd; $index++) {
        if ($lines[$index] -match "^\s*WHEN\s+FolderName\s+LIKE\s+'.*'\s+THEN\s+'$([regex]::Escape($ProjectNumber))'\s*$") {
            $existingProject = $true
            break
        }
    }

    if ($existingProject) {
        throw "ProjectNumber '$ProjectNumber' already exists in WorkSpaceId $WorkSpaceId. No changes were made."
    }

    $whenLineIndex = -1
    $whenIndent = "`t`t`t`t`t`t"
    # Reuse the indentation of the first existing WHEN line. This keeps the
    # generated branch consistent with the procedure's local formatting.
    for ($index = $sectionStart; $index -le $sectionEnd; $index++) {
        if ($lines[$index] -match '^(\s*)WHEN\s+FolderName\s+LIKE') {
            $whenLineIndex = $index
            $whenIndent = $Matches[1]
            break
        }
    }

    if ($whenLineIndex -lt 0) {
        throw "No WHEN mapping lines were found in WorkSpaceId $WorkSpaceId."
    }

    $caseElseIndex = -1
    # The new WHEN must be placed before ELSE so it is evaluated as part of the
    # CASE. Searching only after the first WHEN avoids matching unrelated ELSE
    # statements earlier in the workspace block.
    for ($index = $whenLineIndex + 1; $index -le $sectionEnd; $index++) {
        if ($lines[$index] -match '^\s*ELSE\s+(?:NULL|''[^'']+'')\s+END\s*$') {
            $caseElseIndex = $index
            break
        }
    }

    if ($caseElseIndex -lt 0) {
        throw "No CASE ELSE line was found in WorkSpaceId $WorkSpaceId."
    }

    $newLine = "${whenIndent}WHEN FolderName LIKE '$FolderPattern' THEN '$ProjectNumber'"
    if ($PSCmdlet.ShouldProcess($resolvedProcedurePath, "Add project $ProjectNumber to WorkSpaceId $WorkSpaceId")) {
        $lines.Insert($caseElseIndex, $newLine)
        Complete-ProcedureUpdate -EditedLines $lines

        Write-Output "Added WorkSpaceId $WorkSpaceId / ProjectNumber $ProjectNumber. Backup: $BackupPath"
    }
    return
}

# New workspace: add a complete ELSE IF section immediately before the final
# dim_rpt_project fallback. The fallback is deliberately identified by both
# its standalone ELSE/BEGIN shape and the nearby table name, because CASE ELSE
# lines also occur elsewhere in the procedure.
$fallbackElseIndex = -1
for ($index = $lines.Count - 2; $index -ge 0; $index--) {
    if ($lines[$index] -match '^\s*ELSE\s*$' -and $lines[$index + 1] -match '^\s*BEGIN\s*$') {
        # The fallback UPDATE and dim_rpt_project join are within the next few
        # lines in the current procedure. Keep this bounded to avoid matching a
        # later unrelated occurrence of the table name.
        $lookAhead = [Math]::Min($index + 8, $lines.Count - 1)
        $fallbackText = ($lines[$index..$lookAhead] -join "`n")
        if ($fallbackText -match 'dim_rpt_project') {
            $fallbackElseIndex = $index
            break
        }
    }
}

if ($fallbackElseIndex -lt 0) {
    throw 'The final dim_rpt_project fallback section was not found.'
}

$newSection = @(
    # These lines intentionally mirror the existing procedure's workspace
    # section structure so the generated SQL can be reviewed easily in SSMS.
    "ELSE IF @WorkSpaceId = $WorkSpaceId",
    "`tBEGIN",
    "`t`tUPDATE dbo.raw_fusionLive_documents_metadata",
    "`t`tSET ProjectNumber = CASE",
    "`t`t`t`tWHEN FolderName LIKE '$FolderPattern' THEN '$ProjectNumber'",
    "`t`t`t`tELSE NULL END",
    "`t`tWHERE WorkSpaceId = @WorkSpaceId;",
    "`tEND"
)

if ($PSCmdlet.ShouldProcess($resolvedProcedurePath, "Add WorkSpaceId $WorkSpaceId with ProjectNumber $ProjectNumber")) {
    for ($offset = 0; $offset -lt $newSection.Count; $offset++) {
        $lines.Insert($fallbackElseIndex + $offset, $newSection[$offset])
    }
    Complete-ProcedureUpdate -EditedLines $lines

    Write-Output "Added WorkSpaceId $WorkSpaceId with ProjectNumber $ProjectNumber. Backup: $BackupPath"
}
