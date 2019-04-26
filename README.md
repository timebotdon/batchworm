# Description
Upon execution, this PoC first exploits the Invoke-MS16-032 EoP (@fuzzysecurity) vulnerability of Windows 7 x64 machines - can be swapped out for other exploits or run without one (requires admin). Gaining SYSTEM/Administrator privileges, the batch script attempts to trick domain users to visiting their local IT administrator - this is done by adjusting the IP to a static 169 private address. Credentials are dumped to a file when the Admin logs in to readjust the IP configuration. The worm uses said credentials to propagate itself through 3 methods listed below. In this PoC, a "pwned.txt" file is left behind on C root.

# Methods
## Recon
### Netstat
Parses netstat output to find potential hosts connected on port 445 (smb).

### ARP Table
Uses the cached ARP table to find potential hosts.

### Ping Sweep
Pings the entire 0/24 subnet of the current machine for any active hosts before attempting to login on port 445 (smb).

## Credential Dumping - Windows Credential Editor (WCE)
WCE is run on the background to dump administrator passwords to "dapw" C:\Windows\temp\dapw

## Persistence - Task Scheduler
Persistence is done through the task scheduler, though it's not currently implemented yet.
Commented due to various bugs.

## Propagation - Net Use
Administrator credentials is used here to map a shared drive to other hosts found in the above Recon methods. "main.bat" and "dapw" is then copied into the new host.

## Killswitch
Searches on the windows registry for "HKLM\SOFTWARE\Microsoft\isInstalled". If it's there, the batchworm will terminate.

## Remote execution - Windows Management Interface Command (WMIC) 
Uses the same credential file to execute remotely to other hosts.

# Configuration
IP addresses and target subnet can be updated in main.bat

# Building
1. Adjust "TargetName" and "SourceFiles0" in build/batchworm.SED and build/pl.SED accordingly to where the directory was downloaded to.
2. Run build-batchworm.bat. The executable will be outputed to the release folder.

# IOC Artifacts
* C:\Windows\Temp\IPX*.TMP - Windows IExpress extracted directory
* C:\Windows\Temp\dapw - dumped domain admin cleartext password
* C:\Windows\Temp\main.bat - batchworm
* C:\pwned.txt
* HKLM\SOFTWARE\Microsoft\isInstalled - batchworm killswitch registry

# Removal
1. Run remove-batchworm.bat to totally remove the artifacts.
2. If some files/registry items are still present in the system, remove as referenced in remove-batchworm.bat.
