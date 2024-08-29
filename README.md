XtremIO Health PRTG Sensor Script
Description
This PowerShell script is designed to monitor the health status and unacknowledged alerts of Dell EMC XtremIO storage systems and integrate with PRTG Network Monitor. It retrieves key health metrics and alert information from the XtremIO API and formats them for PRTG, allowing for easy monitoring and alerting of XtremIO system health.
Features

Retrieves and reports the following metrics:

System Health (100% if healthy, 0% otherwise)
Count of Active Unacknowledged Alerts


Provides details of up to 3 most recent major unacknowledged alerts
Handles SSL certificate errors for environments with self-signed certificates
Outputs results in PRTG-compatible XML format

Prerequisites

PowerShell 5.1 or later
PRTG Network Monitor
Access to XtremIO API (IP address/hostname, username, and password)

Installation

Clone this repository or download the XtremIO-Health-PRTG-Sensor.ps1 file.
Place the script in your PRTG Custom Sensors directory, typically:
C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML

Usage
In PRTG, create a new sensor using the "EXE/Script Advanced" sensor type. Use the following parameters:

Sensor Name: XtremIO Health Monitor
Parent Device: Your XtremIO device in PRTG
Inherit Access Rights: Yes
Scanning Interval: 5 minutes (or as needed)
EXE/Script: XtremIO-Health-PRTG-Sensor.ps1
Parameters: -XtremIOIP '%host' -Username '%linuxuser' -Password '%linuxpassword'

Replace %host, %linuxuser, and %linuxpassword with the appropriate placeholders for your PRTG setup.
Output
The script provides the following output:

System Health: 100% if healthy, 0% otherwise
Active Unacknowledged Alerts: Count of unacknowledged alerts
Details of up to 3 most recent major unacknowledged alerts (if any)

Customization
You can modify the script to adjust:

The number of major alerts displayed (currently set to 3)
The alert states considered as unacknowledged (currently 'outstanding' and 'clear_unacknowledged')
The severity level of alerts to display (currently set to "major")

Troubleshooting

Ensure that the XtremIO API is accessible from the PRTG probe server.
Verify that the provided credentials have sufficient permissions to access the XtremIO API.
Check PRTG logs for any execution errors.
For SSL certificate issues, consider importing the XtremIO's SSL certificate into the Windows certificate store on the PRTG server.


License
Distributed under the MIT License. See LICENSE file for more information.
Contact
Richard Travellin - richard.travellin@computacenter.com
Project Link: https://github.com/CC-Digital-Innovation/XtremIO-PRTG-Health-Sensor/
Acknowledgements

Dell EMC XtremIO
PRTG Network Monitor
