module pspemu.hle.MemoryManager;

import pspemu.hle.ModuleManager;
public import pspemu.hle.kd.sysmem.Types;
import pspemu.hle.kd.sysmem.SysMemUserForUser;
import pspemu.core.Memory;

class MemoryManager {
	Memory memory;
	ModuleManager moduleManager;
	SysMemUserForUser sysMemUserForUser;
	
	public this(Memory memory, ModuleManager moduleManager) {
		this.memory = memory;
		this.moduleManager = moduleManager;		
		this.sysMemUserForUser = moduleManager.get!(SysMemUserForUser);
	}
	
	public uint alloc(PspPartition partition, string name, PspSysMemBlockTypes type, uint size, uint addr = 0) {
		SceUID mem = this.sysMemUserForUser.sceKernelAllocPartitionMemory(partition, name, type, size, addr);
		return this.sysMemUserForUser.sceKernelGetBlockHeadAddr(mem);
	}
	
	public uint allocAt(PspPartition partition, string name, uint size, uint addr) {
		return alloc(partition, name, PspSysMemBlockTypes.PSP_SMEM_Addr, size, addr);
	}
	
	public uint allocHeap(PspPartition partition, string name, uint size) {
		return alloc(partition, name, PspSysMemBlockTypes.PSP_SMEM_Low, size);
	}
	
	public uint allocStack(PspPartition partition, string name, uint size) {
		return alloc(partition, name, PspSysMemBlockTypes.PSP_SMEM_High, size) + size;
	}
	
	/*
	public uint allocBytes(ubyte[] bytes) {
		allocHeap();
		auto allocPartition = memoryPartition.allocLow(bytes.length, 8);
		emulatorState.memory.twrite(allocPartition.low, bytes); 
		return allocPartition.low;
	}
	*/
}