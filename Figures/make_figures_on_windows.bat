@echo off

REM search for inkscape.exe in path
for %%a in (inkscape.exe) do set prog="%%~$PATH:a"
if not %prog% == "" (
	if exist %prog% goto :found
	set prog=
) else (
	echo Inkscape not in path...
)

REM try looking for the registry value, query for the default (/ve) path (useback enquotes key name)
REM remove line that repeats reg key name and concatenate words of second line
REM discard reg type etc. until REG_SZ, and keep the rest (actual path)
setlocal EnableDelayedExpansion

for /f "useback tokens=*" %%a in (
	`reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\inkscape.exe"^
	/ve ^| findstr /L /V HKEY_LOCAL_MACHINE`
) do (
	for %%b in (%%a) do (
		if %%b == REG_SZ (
			set str=
		) else (
			set str=!str! %%b
		)
	)
)

REM our expansion caused an initial space, remove it
set prog="!str:~1!"

setlocal DisableDelayedExpansion

if not %prog% == "" (
	if exist %prog% goto :found
	set prog=
) else (
	echo Inkscape not found in registry...
)

REM last resort, try direct paths

for %%a in ("%ProgramFiles(x86)%\Inkscape\inkscape.exe" "%ProgramFiles%\Inkscape\inkscape.exe") do (
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

REM actual transformation of .svg in .pdf + .pdf_tex (if called with includesvg from a tex file) or to .pdf
for %%A in (*.svg ..\beamertheme\*.svg) do (
	pushd %%~dpA
	echo %%~nA.pdf

	for /f %%i in ('dir /b /o:d "%%~nA.svg" "%%~nA.pdf"') do set B=%%i
	if "%%~nxA"=="!B!" (
		>nul findstr /R "\\includesvg.*{%%~nA}" ..\*.tex && (
			%prog% -C -z --file="%%~fA" --export-pdf="%%~dpnA.pdf" --export-latex
		) || (
			%prog% -C -z --file="%%~fA" --export-pdf="%%~dpnA.pdf"
		)
	)

	popd
)
setlocal DisableDelayedExpansion

popd

:eof
