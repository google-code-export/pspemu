@ECHO OFF
REM http://www.digitalmars.com/d/2.0/changelog.html
SET PATH="%CD%\windows\bin";%PATH%

SET DMD_HTTP=http://pspemu.googlecode.com/files/dmd_old_pspemu.7z
SET DMD_ZIP=dmd_old_pspemu.7z

ECHO Preparing DMD and DFL...
IF NOT EXIST "windows\bin\dmd.exe" (
	IF NOT EXIST "%DMD_ZIP%" (
		ECHO Downloading %DMD_HTTP%...
		httpget.exe %DMD_HTTP% %DMD_ZIP%
	)
	7z.exe -bd -y x %DMD_ZIP%
	IF NOT EXIST "windows\bin\dmd.exe" (
		ECHO Error installing DMD and DFL
		EXIT /B
	)
)
