<#
.SYNOPSIS
Monitors health status and unacknowledged alerts for XtremIO systems and outputs the results to PRTG.

.DESCRIPTION
This script retrieves health status and active alerts from the XtremIO API for a specific cluster. It outputs PRTG sensor results with information on system health, number of unacknowledged alerts, and details of critical unacknowledged alerts if any. It also includes debug information about alert statuses.

.PARAMETER XtremIOIP
The IP address or hostname of the XtremIO management system.

.PARAMETER Username
The username for accessing the XtremIO API.

.PARAMETER Password
The password for accessing the XtremIO API.

.INPUTS
None.

.OUTPUTS
Outputs PRTG sensor results with information on system health and unacknowledged alerts for the specified XtremIO system.

.NOTES
Author: Richard Travellin
Date: 8/29/2024
Version: 1.3

.EXAMPLE
./XtremIO-Health-PRTG-Sensor.ps1 -XtremIOIP "192.168.1.100" -Username "admin" -Password "password"
This example runs the script to check health status and unacknowledged alerts for the XtremIO system at the specified IP address using the provided credentials.
#>

# XtremIO Health PRTG Sensor Script

param(
    [string]$XtremIOIP,
    [string]$Username,
    [string]$Password
)

# Function to output PRTG error message
function Write-PrtgError {
    param([string]$ErrorMessage)
    Write-Host "<prtg><error>1</error><text>$ErrorMessage</text></prtg>"
    exit
}

# Ignore SSL certificate errors (remove this in production)
if (-not ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type) {
    add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) { return true; }
        }
"@
}
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set up API request
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username, $Password)))
$headers = @{ Authorization = "Basic $base64AuthInfo"; Accept = "application/json" }

# Get cluster health
try {
    $clusterUri = "https://$XtremIOIP/api/json/v3/types/clusters"
    $response = Invoke-RestMethod -Uri $clusterUri -Headers $headers -Method Get
    $clusterDetails = Invoke-RestMethod -Uri $response.clusters[0].href -Headers $headers -Method Get
}
catch {
    Write-PrtgError "Failed to retrieve cluster health: $($_.Exception.Message)"
}

# Get alerts
try {
    $alertsUri = "https://$XtremIOIP/api/json/v3/types/alerts"
    $alertsResponse = Invoke-RestMethod -Uri $alertsUri -Headers $headers -Method Get
}
catch {
    Write-PrtgError "Failed to retrieve alerts: $($_.Exception.Message)"
}

# Process alerts
$unacknowledgedCount = 0
$majorUnacknowledgedAlerts = @()

foreach ($alert in $alertsResponse.alerts) {
    $alertDetails = Invoke-RestMethod -Uri $alert.href -Headers $headers -Method Get
    $alertName = $alertDetails.content.'assoc-obj-name'
    $severity = $alertDetails.content.severity
    $alertState = $alertDetails.content.'alert-state'
    
    # Convert Unix timestamp (milliseconds) to local time
    $raiseTime = (Get-Date "1970-01-01 00:00:00").AddMilliseconds([long]$alertDetails.content.'raise-time').ToLocalTime()
    
    if ($alertState -in @('outstanding', 'clear_unacknowledged')) {
        $unacknowledgedCount++
        if ($severity -eq "major") {
            $majorUnacknowledgedAlerts += "[$($raiseTime.ToString('MMM dd, yyyy hh:mm tt'))] $alertName ($severity): $($alertDetails.content.description)"
        }
    }
}

# Output PRTG XML
Write-Host "<prtg>"


# System Health
$healthState = $clusterDetails.content.'sys-health-state'
$healthValue = if ($healthState -eq "healthy") { 100 } else { 0 }
Write-Host "<result>
<channel>System Health</channel>
<value>$healthValue</value>
<unit>Percent</unit>
<limitmode>1</limitmode>
<limitminerror>100</limitminerror>
</result>"

# Unacknowledged Alerts Count
Write-Host "<result>
<channel>Active Unacknowledged Alerts</channel>
<value>$unacknowledgedCount</value>
<unit>Count</unit>
<limitmode>1</limitmode>
<limitmaxwarning>0</limitmaxwarning>
</result>"

# Major Unacknowledged Alerts Details
if ($majorUnacknowledgedAlerts.Count -gt 0) {
    $alertText = "Major Unacknowledged Alerts (showing up to 3 most recent):`n"
    $alertText += ($majorUnacknowledgedAlerts | Select-Object -First 3 | ForEach-Object { "- $_" }) -join "`n"
    $encodedAlertText = [System.Security.SecurityElement]::Escape($alertText)
    Write-Host "<text>$encodedAlertText</text>"
}

Write-Host "</prtg>"