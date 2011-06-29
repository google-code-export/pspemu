@ECHO OFF
CALL %~dp0\prepare.bat
SET BASE_FILE=%1
SET C_FILES=%BASE_FILE%.c
SET ELF_FILE=%BASE_FILE%.elf
psp-gcc -I. -I"%PSPSDK%/psp/sdk/include" -L. -L"%PSPSDK%/psp/sdk/lib" -D_PSP_FW_VERSION=150 -Wall -g -O0 %C_FILES% -lpspumd -lpsppower -lpspdebug -lpspgu -lpspgum -lpspge -lpspdisplay -lpspsdk -lc -lpspuser -lpspkernel -lpsprtc -o %ELF_FILE%
IF EXIST %ELF_FILE% (
	psp-fixup-imports %ELF_FILE%
)