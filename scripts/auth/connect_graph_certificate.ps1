# Reference: Microsoft Graph certificate authentication (app-only)
# Placeholders only. Do not commit real values.

$tenantId   = "<TENANT_ID>"
$clientId   = "<CLIENT_ID>"
$thumbprint = "<CERT_THUMBPRINT>"

Connect-MgGraph -TenantId $tenantId -ClientId $clientId -CertificateThumbprint $thumbprint
