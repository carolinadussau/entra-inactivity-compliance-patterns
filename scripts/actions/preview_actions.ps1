<#
Preview actions based on the inactivity report CSV.
No changes are performed.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

if (!(Test-Path $CsvPath)) {
    Write-Error "CSV not found: $CsvPath"
    exit 1
}

$rows = Import-Csv $CsvPath

Write-Output "Previewing $($rows.Count) accounts:"
foreach ($r in $rows) {
    Write-Output ("Would review: {0} | Status={1} | LastSignIn={2}" -f `
        $r.UserPrincipalName, $r.Status, $r.LastSignIn)
}

Write-Output "Preview complete. No accounts were modified."
