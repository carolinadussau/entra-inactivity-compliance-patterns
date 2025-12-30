<#
Daily inactivity report (reference template)

Purpose:
- Generate a report of inactive Entra ID user accounts
- Safe-by-default: does NOT disable accounts
- Designed for compliance review workflows (e.g. C5-style controls)

Notes:
- Uses Microsoft Graph sign-in logs
- Lookback period is retention-aware (default: 30 days)
- All identifiers are placeholders
#>

# === CONFIGURATION (PLACEHOLDERS) ===
$tenantId     = "<TENANT_ID>"
$clientId     = "<CLIENT_ID>"
$clientSecret = "<CLIENT_SECRET_VALUE>"

$daysInactive = 30
$outDir = ".\out"
$today = Get-Date -Format "yyyy-MM-dd"
$outFile = Join-Path $outDir "InactiveUsers-$today.csv"

# === PREPARE OUTPUT ===
if (!(Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

# === CONNECT TO MICROSOFT GRAPH (CLIENT SECRET) ===
$secureSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($clientId, $secureSecret)

Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $credential | Out-Null

# === DEFINE CUTOFF DATE ===
$cutoff = (Get-Date).ToUniversalTime().AddDays(-$daysInactive)

# === RETRIEVE USERS (INCLUDE GUESTS) ===
$users = Get-MgUser -All -Property `
    "Id,UserPrincipalName,DisplayName,Department,AccountEnabled,Mail,UserType"

# === RETRIEVE SIGN-IN LOGS (RETENTION-LIMITED) ===
$signIns = Get-MgAuditLogSignIn -All
$signInLookup = @{}

$signIns |
    Where-Object { $_.UserPrincipalName } |
    Group-Object { $_.UserPrincipalName.ToLower() } |
    ForEach-Object {
        $latest = $_.Group |
            Sort-Object CreatedDateTime -Descending |
            Select-Object -First 1

        $signInLookup[$_.Name] = $latest.CreatedDateTime
    }

# === BUILD REPORT ===
$report = foreach ($user in $users) {

    $upn = $user.UserPrincipalName
    $lastLogin = if ($upn) { $signInLookup[$upn.ToLower()] } else { $null }

    if ($lastLogin) {
        $lastLoginDate = [datetime]$lastLogin
        $daysSince = [math]::Floor(
            ((Get-Date).ToUniversalTime() - $lastLoginDate).TotalDays
        )

        $status = if ($lastLoginDate -lt $cutoff) {
            "Inactive"
        } else {
            "Active"
        }

        $lastLoginFormatted = $lastLoginDate.ToString("yyyy-MM-dd HH:mm")
    }
    else {
        $status = "No Sign-In Record"
        $daysSince = "N/A"
        $lastLoginFormatted = "Never"
    }

    # --- BASIC EXCLUSION EXAMPLE ---
    # Unlicensed internal accounts (shared/service) are excluded,
    # Guest users remain in scope.
    $hasLicense = $false
    try {
        $licenses = Get-MgUserLicenseDetail -UserId $user.Id -ErrorAction SilentlyContinue
        $hasLicense = ($licenses.Count -gt 0)
    } catch {}

    if (
        ($status -eq "Inactive" -or $status -eq "No Sign-In Record") -and
        ($user.UserType -eq "Guest" -or $hasLicense)
    ) {
        [PSCustomObject]@{
            UserPrincipalName   = $upn
            DisplayName         = $user.DisplayName
            UserType            = $user.UserType
            Department          = $user.Department
            AccountEnabled      = $user.AccountEnabled
            LastSignIn          = $lastLoginFormatted
            DaysSinceLastSignIn = $daysSince
            Status              = $status
        }
    }
}

# === EXPORT REPORT ===
$report | Export-Csv -NoTypeInformation -Path $outFile

Write-Output "Report written to: $outFile"
Write-Output "Users flagged for review: $($report.Count)"
