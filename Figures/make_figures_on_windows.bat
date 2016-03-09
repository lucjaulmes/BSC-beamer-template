@echo off

REM search for inkscape.exe in path
for %%a in (inkscape.exe) do set prog=%%~$PATH:a
if not "%prog%" == "" (
	if exist "%prog%" goto :found
)

REM try looking for the registry value
echo Inkscape not in path...
REM reg query for the app path (useback to "" key name), query default value of reg key (/ve)
REM remove line that repeats reg key name
REM which contain reg type etc. until REG_SZ, and keep the rest (actual path)
for /f "useback tokens=*" %%a in (`REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\inkscape.exe" /ve ^| findstr /L /V HKEY_LOCAL_MACHINE`) do (

	setlocal EnableDelayedExpansion

	for %%b in (%%a) do (
		if %%b == REG_SZ (
			set prog=
		) else (
			set prog=!prog! %%b
		)
	)

	setlocal DisableDelayedExpansion

	REM our expansion caused an initial space, remove it
	set prog=%prog:~1%
)
if not "%prog%" == "" (
	if exist "%prog%" goto :found
)

REM last resort, try direct paths
echo Inkscape not found in registry...

for %%a in ("C:\Program Files (x86)\Inkscape\inkscape.exe" "C:\Program Files\Inkscape\inkscape.exe") do (
	if exist %%a (
		set prog=%%a
		goto :found
	)
)

echo.
echo ERROR : Inkscape wasn't found
echo Try installing Inkscape, or adding the directory containing inkscape.exe to your path
echo.
pause
goto :eof

:found
echo Inkscape found at %prog%
echo.

pushd %~dp0

setlocal EnableDelayedExpansion

REM actual transformation of .svg in .pdf + .pdf_tex
for %%A in (*.svg ..\beamertheme\*.svg) do (
	pushd %%~dpA
	echo %%~nA.pdf
	
	for /f %%i in ('dir /b /o:d "%%~nA.svg" "%%~nA.pdf"') do set B=%%i
	if "%%~nxA"=="!B!" (
		>nul findstr /R "\\includesvg.*{%%~nA}" ..\*.tex && (
			"%prog%" -C -z --file="%%~nxA" --export-pdf="%%~nA.pdf" --export-latex
		) || (
			"%prog%" -C -z --file="%%~nxA" --export-pdf="%%~nA.pdf"
		)
	)
	
	popd
)

setlocal DisableDelayedExpansion

popd

:eof

