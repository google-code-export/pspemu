@echo off
copy build.rf build2.rf
echo. >> build2.rf
echo -v >> build2.rf
REM echo " -v" >> build2.rf
c:\dev\dmd2\windows\bin\dmd @build2.rf