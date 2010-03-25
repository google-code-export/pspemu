@ECHO OFF
REM http://minpspw.sourceforge.net/
SET PSPSDK=%CD%/../dev/pspsdk
SET LIBS=-lpspaudiolib -lpspaudio -lpspgum -lpspgu -lm -lpsprtc -lpspdebug -lpspdisplay -lpspge -lpspctrl -lpspsdk -lc -lpspnet -lpspnet_inet -lpspnet_apctl -lpspnet_resolver -lpsputility -lpspuser -lpspkernel
REM SET FLAGS=-G0 -Wall -O2 -g -gstabs
SET FLAGS=-Wall -g

CALL :BUILD polyphonic

REM CALL :BUILD mytest "common/callbacks.c"
REM CALL :BUILD test_zlib "-lz"
REM CALL :BUILD test_malloc
REM CALL :BUILD test_file
REM CALL :BUILD test_sprintf
REM CALL :BUILD test1
REM CALL :BUILD test2
REM CALL :BUILD ortho "common/callbacks.c common/vram.c"
REM CALL :BUILD polyphonic
REM CALL :BUILD vertex "common/callbacks.c common/vram.c common/menu.c"

EXIT /B

:BUILD
	SET BASE=%1
	SET PARAMS=%~2
	c:\pspsdk\bin\psp-gcc -I. -I"%PSPSDK%/psp/sdk/include" -L. -L"%PSPSDK%/psp/sdk/lib" -D_PSP_FW_VERSION=150 %FLAGS% %BASE%.c %PARAMS% %LIBS% -o %BASE%.elf
	c:\pspsdk\bin\psp-fixup-imports %BASE%.elf
	IF EXIST STRIP_ELF (
		c:\pspsdk\bin\psp-strip %BASE%.elf
	)
EXIT /B