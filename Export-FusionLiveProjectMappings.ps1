param(
    [Parameter(Mandatory = $true)]
    [string]$ProcedurePath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$sql = Get-Content -Raw -LiteralPath $ProcedurePath
$rows = New-Object System.Collections.Generic.List[string]
$workspaceMatches = [regex]::Matches($sql, '(?ms)(?:IF|ELSE IF)\s+@WorkSpaceId\s*=\s*(\d+)(.*?)(?=\r?\n(?:ELSE IF|ELSE)\s+@WorkSpaceId|\r?\n\*/|\z)')

foreach ($workspaceMatch in $workspaceMatches) {
    $workspaceId = [int]$workspaceMatch.Groups[1].Value
    $block = $workspaceMatch.Groups[2].Value
    $mappingMatches = [regex]::Matches($block, "WHEN\s+FolderName\s+LIKE\s+'([^']*)'\s+THEN\s+'([^']*)'", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    foreach ($mappingMatch in $mappingMatches) {
        $folderPattern = $mappingMatch.Groups[1].Value.Replace("'", "''")
        $projectNumber = $mappingMatch.Groups[2].Value.Replace("'", "''")
        $rows.Add("($workspaceId, '$folderPattern', '$projectNumber')")
    }

    $defaultMatch = [regex]::Match($block, "ELSE\s+'([^']+)'\s+END", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($defaultMatch.Success) {
        $projectNumber = $defaultMatch.Groups[1].Value.Replace("'", "''")
        $rows.Add("($workspaceId, '%', '$projectNumber')")
    }
}

$values = $rows | Sort-Object -Unique
if ($values.Count -eq 0) {
    throw 'No workspace/project mappings were found.'
}

$script = @"
USE [FLDataMart]
GO

MERGE dbo.FusionLiveProjectMapping AS target
USING (VALUES
    $($values -join ",`r`n    ")
) AS source (WorkSpaceId, FolderPattern, ProjectNumber)
ON target.WorkSpaceId = source.WorkSpaceId
AND target.FolderPattern = source.FolderPattern
WHEN MATCHED THEN
    UPDATE SET ProjectNumber = source.ProjectNumber, IsActive = 1
WHEN NOT MATCHED THEN
    INSERT (WorkSpaceId, FolderPattern, ProjectNumber)
    VALUES (source.WorkSpaceId, source.FolderPattern, source.ProjectNumber);
GO
"@

Set-Content -LiteralPath $OutputPath -Value $script -Encoding ASCII
Write-Host "Exported $($values.Count) mappings to $OutputPath"
