@ECHO OFF

SET F=
REM SET F=%F% -cov
SET F=%F% -O
SET F=%F% -release
REM SET F=%F% -inline
SET F=%F% -Jutil\gen

SET P=
SET P=%P% res\psp.res

SET P=%P% src\core\memory.d
SET P=%P% src\core\cpu.d
SET P=%P% src\core\gpu.d
SET P=%P% src\core\controller.d
SET P=%P% src\core\hle\bios.d
SET P=%P% src\core\hle\bios_graphics.d
SET P=%P% src\core\hle\bios_io.d
SET P=%P% src\core\hle\loader.d
SET P=%P% src\core\disassembler\cpu_disasm.d
SET P=%P% src\core\disassembler\gpu_disasm.d

SET P=%P% src\core\hle\kernel.d
SET P=%P% src\core\hle\kernel\kd\*.d

SET P=%P% src\utils\common.d
SET P=%P% src\utils\opengl.d
SET P=%P% src\utils\glcontrol.d
SET P=%P% src\utils\expression.d
SET P=%P% src\utils\simpleimage.d
SET P=%P% src\utils\joystick.d

SET P=%P% src\gui\ext\gui.d
SET P=%P% src\gui\ext\graphicsbuffer.d
SET P=%P% src\gui\ext\hexedit.d
REM SET P=%P% src\gui\min\gui.d

SET L=

IF NOT EXIST "dmd\windows\bin\dfl.exe" (
	PUSHD dmd
	CALL setup.bat
	POPD dmd
)

PUSHD util\gen
..\..\dmd\php cpu_gen.php
POPD

DEL /Q pspemu.exe 2> NUL > NUL
dmd\windows\bin\rcc -32 res\psp.rc -ores\psp.res
dmd\windows\bin\dfl %F% %P% %L% -ofpspemu
DEL /Q *.obj *.map res\psp.res 2> NUL > NUL
