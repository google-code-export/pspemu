@ECHO OFF
CALL ..\prepare.bat
psp-gcc -I. -I"%PSPSDK%/psp/sdk/include" -L. -L"%PSPSDK%/psp/sdk/lib" -D_PSP_FW_VERSION=150 -Wall -g -O0 thread_start.c ../emits.c -lpspdebug -lpspge -lpspdisplay -lpspsdk -lc -lpspuser -lpspkernel -o thread_start.elf
REM psp-gcc -I. -I"%PSPSDK%/psp/sdk/include" -L. -L"%PSPSDK%/psp/sdk/lib" -D_PSP_FW_VERSION=150 -Wall -g -O0 thread_start.c ../emits.c -lpspdebug -lpspge -lpspdisplay -lpspsdk -lc -lpspuser -o thread_start.elf
IF EXIST thread_start.elf (
	psp-fixup-imports thread_start.elf
	COPY /Y thread_start.elf thread_start_strip.elf > NUL 2> NUL
	psp-strip thread_start_strip.elf
	mksfo "thread_start" PARAM.SFO
	pack-pbp EBOOT.PBP PARAM.SFO NULL NULL NULL NULL NULL thread_start_strip.elf NULL
)