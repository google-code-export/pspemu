module pspemu.hle.kd.sysmem.Types;

public import pspemu.hle.kd.Types;

/** Specifies the type of allocation used for memory blocks. */
enum PspSysMemBlockTypes {
	/** Allocate from the lowest available address. */
	PSP_SMEM_Low = 0,
	/** Allocate from the highest available address. */
	PSP_SMEM_High,
	/** Allocate from the specified address. */
	PSP_SMEM_Addr
}

struct PspSysmemPartitionInfo {
	SceSize size;
	uint startaddr;
	uint memsize;
	uint attr;
}

/** Structure of a UID control block */
struct uidControlBlock {
    uidControlBlock* parent;
    uidControlBlock* nextChild;
    uidControlBlock* type;   //(0x8)
    u32 UID;                 //(0xC)
    char* name;              //(0x10)
	ubyte unk;
	ubyte size;              // Size in words
    short attribute;
    uidControlBlock* nextEntry;
}
