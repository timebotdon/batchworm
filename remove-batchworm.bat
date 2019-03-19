@echo off
:: Run as admin!

set ldir=C:\Windows\Temp

reg delete HKLM\SOFTWARE\Microsoft /v isInstalled /f
schtasks /delete /TN "Microsoft\Windows\SoftwareProtectionPlatform\Platform Maintenance" /F
del /f "%ldir%\dapw"
del /f "%ldir%\main.bat"
del /f C:\pwned.txt
for /f "delims=" %%a in ('"dir /b C:\Windows\Temp\IPX*.TMP"') do rmdir /s /q "C:\Windows\Temp\%%a"
for /f "delims=" %%b in ('"dir /b %temp%\IPX*"') do rmdir /s /q "%temp%\%%b"