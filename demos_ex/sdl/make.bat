@ECHO OFF
CALL ..\prepare.bat
psp-gcc -I. -I"%PSPSDK%/psp/sdk/include" -L. -L"%PSPSDK%/psp/sdk/lib" -D_PSP_FW_VERSION=150 -Wall -g -O0 main.c -lSDL -lpspgu -lpspaudio -lpspctrl -lpspirkeyb -lpsppower -lpsphprm -lpspdebug -lpspge -lpspdisplay -lpspsdk -lc -lpspuser -lpspkernel -o main.elf
IF EXIST main.elf (
	psp-fixup-imports main.elf
)