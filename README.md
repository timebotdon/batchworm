# Description
Duct tape batch script worm. Primarily uses IExpress - a Windows file binder - as a means to package and quickly create executables. Upon execution, this PoC first exploits the Invoke-MS16-032 EoP (@fuzzysecurity) vulnerability of Windows 7 x64 machines - can be swapped out for other exploits or removed totally (the batch script requires admin however). Gaining SYSTEM privileges, the worm attempts to trick domain users to visiting their local IT administrator - this is done by disabling their internet connection via adjusting the IP configuration to a static private address. Credentials are dumped to a file when the Admin logs in to reconfigure the IP address. The worm uses said credentials to propagate itself through 3 methods as listed below. In this PoC, a "pwned.txt" file is left behind on C root.

# Methods
## Recon
1. Netstat - Parses netstat output to find potential hosts connected on port 445 (smb) before propagating.
2. ARP Table - Uses the cached ARP table to find potential hosts before connecting.

3. Ping Sweep - Pings the entire 0/24 subnet of the current machine for any active hosts before attempting to login on port 445 (smb).

## Credential Dumping
Windows Credential Editor (WCE) - WCE is run on the background to dump administrator credentials to "dapw" C:\Windows\temp\dapw

## Persistence
Task Scheduler - Persistence is done through the task scheduler.

## Propagation
Net Use - Administrator credentials is used here to map a shared drive to other hosts found in the above Recon methods. "main.bat" and "dapw" is then copied into the new host.

## Remote execution - Windows Management Interface Command (WMIC) 
Uses the same credential file to execute remotely to other hosts.

# Configuration
IP addresses and target subnet can be updated in main.bat.

## Building
1. Adjust "TargetName" and "SourceFiles0" in build/batchworm.SED and build/pl.SED accordingly to where the directory was downloaded to. by default, the directory should be set to "C:\batchworm"
2. Run build-batchworm.bat. The executable will be outputed to "release" folder.

# IOC Artifacts
## File system
* C:\Users\[user]\Appdata\Local\Temp\IPX*.TMP - Windows IExpress extracted directory in %TEMP%.
* C:\Windows\Temp\IPX*.TMP - Windows IExpress extracted directory in Windows temp.
* C:\Windows\Temp\dapw - Captured domain admin cleartext credentials.
* C:\Windows\Temp\main.bat - Batchworm script.
* C:\pwned.txt - Post-morterm artifact.

## Registry
* HKLM\SOFTWARE\Microsoft\isInstalled - Batchworm infection marker.

## Task schedule
* Microsoft\Windows\SoftwareProtectionPlatform\PlatformMaintenance - Persistence.

# Prevention (Killswitch)
The batchworm searches the windows registry for "HKLM\SOFTWARE\Microsoft\killswitch". If present, the batchworm will terminate at startup.

# Removal
1. Run remove-batchworm.bat to totally remove the artifacts.
2. If some files/registry items are still present in the system, remove as referenced in remove-batchworm.bat.
