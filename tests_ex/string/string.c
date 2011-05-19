//#pragma compile, "%PSPSDK%/bin/psp-gcc" -I. -I"%PSPSDK%/psp/sdk/include" -L. -L"%PSPSDK%/psp/sdk/lib" -D_PSP_FW_VERSION=150 -Wall -g -O0 string.c ../common/emits.c -lpspsdk -lc -lpspuser -lpspkernel -o test.elf
//#pragma compile, "%PSPSDK%/bin/psp-fixup-imports" string.elf

#include <pspkernel.h>
#include <pspthreadman.h>
#include <pspdebug.h>
#include <stdio.h>
#include <string.h>
#include <../emits.h>

PSP_MODULE_INFO("THREAD TEST", 0, 1, 1);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER | THREAD_ATTR_VFPU);

int main(int argc, char** argv) {
	char buffer[128];
	
	pspDebugScreenInit();
	
	sprintf(buffer, "%d", (u32)0);
	emitString(buffer);
	pspDebugScreenPrintf("%s\n", buffer);
	
	sprintf(buffer, "%d", (u32)100000);
	emitString(buffer);
	pspDebugScreenPrintf("%s\n", buffer);
	
	sprintf(buffer, "%lld", (u64)100000);
	emitString(buffer);
	pspDebugScreenPrintf("%s\n", buffer);

	sceKernelExitGame();
	return 0;
}
