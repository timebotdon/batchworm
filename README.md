# batchworm
Worm PoC on batch

## Description
Upon execution, this PoC first exploits the Invoke-MS16-032 EoP (@fuzzysecurity) vulnerability of Windows 7 x64 machines - this can be swapped out for other exploits or run without one. Gaining SYSTEM/Administrator privileges, the batch script attempts to trick domain users to visiting their local IT administrator - this is done by adjusting the IP to a static 169 private address. Credentials are dumped to a file when the Admin logs in to readjust the IP configuration. The worm uses said credentials to propagate itself through 3 methods listed below.

## Spreading Methods
### Method 1: Netstat
Uses the netstat command to find potential hosts connected on port 445.

### Method 2: ARP Table
Same as method 1, uses the cached ARP table to find potential hosts.

### Method 3: Subnet
Pings the entire 0/24 subnet of the current machine for any active hosts before attempting to login on port 445.

## Configuration
IP addresses and target subnet can be updated in main.bat

## Building
1. Adjust "TargetName" and "SourceFiles0" in build/batchworm.SED and build/pl.SED accordingly to where the directory was downloaded to.
2. Run build-batchworm.bat. The executable will be outputed to the release folder.

## IOC Artifacts
* C:\Windows\Temp\IPX*.TMP - Windows IExpress extracted directory
* C:\Windows\Temp\dapw - dumped domain admin cleartext password
* C:\Windows\Temp\main.bat - batchworm
* C:\pwned.txt
* HKLM\SOFTWARE\Microsoft\isInstalled - batchworm killswitch registry

## Removal
1. Run remove-batchworm.bat to totally remove the artifacts.
2. If some files/registry items are still present in the system, remove as referenced in remove-batchworm.bat.
