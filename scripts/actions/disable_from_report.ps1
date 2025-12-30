<#
Disable accounts from a CSV report.

Safety model:
- Preview-only unless -Execute is explicitly provided.
- Assumes Connect-MgGraph has already been run.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [switch]$Execute
)

if (!(Test-Path $CsvPath)) {
    Write-Error "CSV not found: $CsvPath"
    exit 1
}

$rows = Import-Csv $CsvPath

if (-not $Execute) {
    Write-Output "Preview mode only. Use -Execute to perform changes."
    foreach ($r in $rows) {
        Write-Output ("PREVIEW: Would disable {0}" -f $r.UserPrincipalName)
    }
    exit 0
}

Write-Output "EXECUTE mode enabled."

foreach ($r in $rows) {
    try {
        Set-MgUser -UserId $r.UserPrincipalName -AccountEnabled:$false
        Write-Output ("Disabled: {0}" -f $r.UserPrincipalName)
    }
    catch {
        Write-Output ("Failed: {0} | {1}" -f $r.UserPrincipalName, $_.Exception.Message)
    }
}
