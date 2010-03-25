module pspemu.hle.Types;

alias char  SceChar8;
alias short SceShort16;
alias int   SceInt32;
alias long  SceInt64;
alias long  SceLong64;

alias ushort SceUShort16;
alias uint   SceUInt32;
alias ulong  SceUInt64;

/** UIDs are used to describe many different kernel objects. */
alias uint SceUID;

/* Misc. kernel types. */
alias uint SceSize;
alias int SceSSize;

alias ubyte SceUChar;
alias uint SceUInt;

/* File I/O types. */
alias int SceMode;
alias SceInt64 SceOff;
alias SceInt64 SceIores;

/* Date and time. */
struct ScePspDateTime {
	ushort	year;
	ushort 	month;
	ushort 	day;
	ushort 	hour;
	ushort 	minute;
	ushort 	second;
	uint 	microsecond;
}

alias uint SceKernelThreadEntry;
alias uint SceKernelCallbackFunction;

//alias int function(SceSize args, void *argp) SceKernelThreadEntry;
//alias int function(int arg1, int arg2, void *arg) SceKernelCallbackFunction;

/** Structure to hold the event flag information */
struct SceKernelEventFlagInfo {
	SceSize 	size;
	char 		name[32];
	SceUInt 	attr;
	SceUInt 	initPattern;
	SceUInt 	currentPattern;
	int 		numWaitThreads;
}

/** 64-bit system clock type. */
struct SceKernelSysClock {
	SceUInt32   low;
	SceUInt32   hi;
}

struct SceKernelThreadInfo {
	/** Size of the structure */
	SceSize     size;
	/** Nul terminated name of the thread */
	char    	name[32];
	/** Thread attributes */
	SceUInt     attr;
	/** Thread status */
	int     	status;
	/** Thread entry point */
	SceKernelThreadEntry    entry;
	/** Thread stack pointer */
	void *  	stack;
	/** Thread stack size */
	int     	stackSize;
	/** Pointer to the gp */
	void *  	gpReg;
	/** Initial priority */
	int     	initPriority;
	/** Current priority */
	int     	currentPriority;
	/** Wait type */
	int     	waitType;
	/** Wait id */
	SceUID  	waitId;
	/** Wakeup count */
	int     	wakeupCount;
	/** Exit status of the thread */
	int     	exitStatus;
	/** Number of clock cycles run */
	SceKernelSysClock   runClocks;
	/** Interrupt preemption count */
	SceUInt     intrPreemptCount;
	/** Thread preemption count */
	SceUInt     threadPreemptCount;
	/** Release count */
	SceUInt     releaseCount;
}

struct SceKernelEventFlagOptParam {
	SceSize 	size;
}

/** Additional options used when creating threads. */
struct SceKernelThreadOptParam {
	/** Size of the ::SceKernelThreadOptParam structure. */
	SceSize 	size;
	/** UID of the memory block (?) allocated for the thread's stack. */
	SceUID 		stackMpid;
}

/** Attribute for threads. */
enum PspThreadAttributes {
	/** Enable VFPU access for the thread. */
	PSP_THREAD_ATTR_VFPU = 0x00004000,
	/** Start the thread in user mode (done automatically 
	  if the thread creating it is in user mode). */
	PSP_THREAD_ATTR_USER = 0x80000000,
	/** Thread is part of the USB/WLAN API. */
	PSP_THREAD_ATTR_USBWLAN = 0xa0000000,
	/** Thread is part of the VSH API. */
	PSP_THREAD_ATTR_VSH = 0xc0000000,
	/** Allow using scratchpad memory for a thread, NOT USABLE ON V1.0 */
	PSP_THREAD_ATTR_SCRATCH_SRAM = 0x00008000,
	/** Disables filling the stack with 0xFF on creation */
	PSP_THREAD_ATTR_NO_FILLSTACK = 0x00100000,
	/** Clear the stack when the thread is deleted */
	PSP_THREAD_ATTR_CLEAR_STACK = 0x00200000,
}

struct SceKernelMppInfo {
	SceSize 	size;
	char 	name[32];
	SceUInt 	attr;
	int 	bufSize;
	int 	freeSize;
	int 	numSendWaitThreads;
	int 	numReceiveWaitThreads;
}

struct SceKernelSemaInfo {
	/** Size of the ::SceKernelSemaInfo structure. */
	SceSize 	size;
	/** NUL-terminated name of the semaphore. */
	char 		name[32];
	/** Attributes. */
	SceUInt 	attr;
	/** The initial count the semaphore was created with. */
	int 		initCount;
	/** The current count. */
	int 		currentCount;
	/** The maximum count. */
	int 		maxCount;
	/** The number of threads waiting on the semaphore. */
	int 		numWaitThreads;
}

struct SceKernelSemaOptParam {
	/** Size of the ::SceKernelSemaOptParam structure. */
	SceSize 	size;
}

enum PspKernelErrorCodes
{
	SCE_KERNEL_ERROR_OK	 = 0,	
	SCE_KERNEL_ERROR_ERROR	 = 0x80020001,	
	SCE_KERNEL_ERROR_NOTIMP	= 0x80020002,	
	SCE_KERNEL_ERROR_ILLEGAL_EXPCODE	= 0x80020032,	
	SCE_KERNEL_ERROR_EXPHANDLER_NOUSE	= 0x80020033,	
	SCE_KERNEL_ERROR_EXPHANDLER_USED	= 0x80020034,	
	SCE_KERNEL_ERROR_SYCALLTABLE_NOUSED	= 0x80020035,	
	SCE_KERNEL_ERROR_SYCALLTABLE_USED	= 0x80020036,	
	SCE_KERNEL_ERROR_ILLEGAL_SYSCALLTABLE	= 0x80020037,	
	SCE_KERNEL_ERROR_ILLEGAL_PRIMARY_SYSCALL_NUMBER	= 0x80020038,	
	SCE_KERNEL_ERROR_PRIMARY_SYSCALL_NUMBER_INUSE	= 0x80020039,	
	SCE_KERNEL_ERROR_ILLEGAL_CONTEXT	= 0x80020064,	
	SCE_KERNEL_ERROR_ILLEGAL_INTRCODE	= 0x80020065,	
	SCE_KERNEL_ERROR_CPUDI	= 0x80020066,	
	SCE_KERNEL_ERROR_FOUND_HANDLER	= 0x80020067,	
	SCE_KERNEL_ERROR_NOTFOUND_HANDLER	= 0x80020068,	
	SCE_KERNEL_ERROR_ILLEGAL_INTRLEVEL	= 0x80020069,	
	SCE_KERNEL_ERROR_ILLEGAL_ADDRESS	= 0x8002006a,	
	SCE_KERNEL_ERROR_ILLEGAL_INTRPARAM	= 0x8002006b,	
	SCE_KERNEL_ERROR_ILLEGAL_STACK_ADDRESS	= 0x8002006c,	
	SCE_KERNEL_ERROR_ALREADY_STACK_SET	= 0x8002006d,	
	SCE_KERNEL_ERROR_NO_TIMER	= 0x80020096,	
	SCE_KERNEL_ERROR_ILLEGAL_TIMERID	= 0x80020097,	
	SCE_KERNEL_ERROR_ILLEGAL_SOURCE	= 0x80020098,	
	SCE_KERNEL_ERROR_ILLEGAL_PRESCALE	= 0x80020099,	
	SCE_KERNEL_ERROR_TIMER_BUSY	= 0x8002009a,	
	SCE_KERNEL_ERROR_TIMER_NOT_SETUP	= 0x8002009b,	
	SCE_KERNEL_ERROR_TIMER_NOT_INUSE	= 0x8002009c,	
	SCE_KERNEL_ERROR_UNIT_USED	= 0x800200a0,	
	SCE_KERNEL_ERROR_UNIT_NOUSE	= 0x800200a1,	
	SCE_KERNEL_ERROR_NO_ROMDIR	= 0x800200a2,	
	SCE_KERNEL_ERROR_IDTYPE_EXIST	= 0x800200c8,	
	SCE_KERNEL_ERROR_IDTYPE_NOT_EXIST	= 0x800200c9,	
	SCE_KERNEL_ERROR_IDTYPE_NOT_EMPTY	= 0x800200ca,	
	SCE_KERNEL_ERROR_UNKNOWN_UID	= 0x800200cb,	
	SCE_KERNEL_ERROR_UNMATCH_UID_TYPE	= 0x800200cc,	
	SCE_KERNEL_ERROR_ID_NOT_EXIST	= 0x800200cd,	
	SCE_KERNEL_ERROR_NOT_FOUND_UIDFUNC	= 0x800200ce,	
	SCE_KERNEL_ERROR_UID_ALREADY_HOLDER	= 0x800200cf,	
	SCE_KERNEL_ERROR_UID_NOT_HOLDER	= 0x800200d0,	
	SCE_KERNEL_ERROR_ILLEGAL_PERM	= 0x800200d1,	
	SCE_KERNEL_ERROR_ILLEGAL_ARGUMENT	= 0x800200d2,	
	SCE_KERNEL_ERROR_ILLEGAL_ADDR	= 0x800200d3,	
	SCE_KERNEL_ERROR_OUT_OF_RANGE	= 0x800200d4,	
	SCE_KERNEL_ERROR_MEM_RANGE_OVERLAP	= 0x800200d5,	
	SCE_KERNEL_ERROR_ILLEGAL_PARTITION	= 0x800200d6,	
	SCE_KERNEL_ERROR_PARTITION_INUSE	= 0x800200d7,	
	SCE_KERNEL_ERROR_ILLEGAL_MEMBLOCKTYPE	= 0x800200d8,	
	SCE_KERNEL_ERROR_MEMBLOCK_ALLOC_FAILED	= 0x800200d9,	
	SCE_KERNEL_ERROR_MEMBLOCK_RESIZE_LOCKED	= 0x800200da,	
	SCE_KERNEL_ERROR_MEMBLOCK_RESIZE_FAILED	= 0x800200db,	
	SCE_KERNEL_ERROR_HEAPBLOCK_ALLOC_FAILED	= 0x800200dc,	
	SCE_KERNEL_ERROR_HEAP_ALLOC_FAILED	= 0x800200dd,	
	SCE_KERNEL_ERROR_ILLEGAL_CHUNK_ID	= 0x800200de,	
	SCE_KERNEL_ERROR_NOCHUNK	= 0x800200df,	
	SCE_KERNEL_ERROR_NO_FREECHUNK	= 0x800200e0,	
	SCE_KERNEL_ERROR_LINKERR	= 0x8002012c,	
	SCE_KERNEL_ERROR_ILLEGAL_OBJECT	= 0x8002012d,	
	SCE_KERNEL_ERROR_UNKNOWN_MODULE	= 0x8002012e,	
	SCE_KERNEL_ERROR_NOFILE	= 0x8002012f,	
	SCE_KERNEL_ERROR_FILEERR	= 0x80020130,	
	SCE_KERNEL_ERROR_MEMINUSE	= 0x80020131,	
	SCE_KERNEL_ERROR_PARTITION_MISMATCH	= 0x80020132,	
	SCE_KERNEL_ERROR_ALREADY_STARTED	= 0x80020133,	
	SCE_KERNEL_ERROR_NOT_STARTED	= 0x80020134,	
	SCE_KERNEL_ERROR_ALREADY_STOPPED	= 0x80020135,	
	SCE_KERNEL_ERROR_CAN_NOT_STOP	= 0x80020136,	
	SCE_KERNEL_ERROR_NOT_STOPPED	= 0x80020137,	
	SCE_KERNEL_ERROR_NOT_REMOVABLE	= 0x80020138,	
	SCE_KERNEL_ERROR_EXCLUSIVE_LOAD	= 0x80020139,	
	SCE_KERNEL_ERROR_LIBRARY_NOT_YET_LINKED	= 0x8002013a,	
	SCE_KERNEL_ERROR_LIBRARY_FOUND	= 0x8002013b,	
	SCE_KERNEL_ERROR_LIBRARY_NOTFOUND	= 0x8002013c,	
	SCE_KERNEL_ERROR_ILLEGAL_LIBRARY	= 0x8002013d,	
	SCE_KERNEL_ERROR_LIBRARY_INUSE	= 0x8002013e,	
	SCE_KERNEL_ERROR_ALREADY_STOPPING	= 0x8002013f,	
	SCE_KERNEL_ERROR_ILLEGAL_OFFSET	= 0x80020140,	
	SCE_KERNEL_ERROR_ILLEGAL_POSITION	= 0x80020141,	
	SCE_KERNEL_ERROR_ILLEGAL_ACCESS	= 0x80020142,	
	SCE_KERNEL_ERROR_MODULE_MGR_BUSY	= 0x80020143,	
	SCE_KERNEL_ERROR_ILLEGAL_FLAG	= 0x80020144,	
	SCE_KERNEL_ERROR_CANNOT_GET_MODULELIST	= 0x80020145,	
	SCE_KERNEL_ERROR_PROHIBIT_LOADMODULE_DEVICE	= 0x80020146,	
	SCE_KERNEL_ERROR_PROHIBIT_LOADEXEC_DEVICE	= 0x80020147,	
	SCE_KERNEL_ERROR_UNSUPPORTED_PRX_TYPE	= 0x80020148,	
	SCE_KERNEL_ERROR_ILLEGAL_PERM_CALL	= 0x80020149,	
	SCE_KERNEL_ERROR_CANNOT_GET_MODULE_INFORMATION	= 0x8002014a,	
	SCE_KERNEL_ERROR_ILLEGAL_LOADEXEC_BUFFER	= 0x8002014b,	
	SCE_KERNEL_ERROR_ILLEGAL_LOADEXEC_FILENAME	= 0x8002014c,	
	SCE_KERNEL_ERROR_NO_EXIT_CALLBACK	= 0x8002014d,	
	SCE_KERNEL_ERROR_NO_MEMORY	= 0x80020190,	
	SCE_KERNEL_ERROR_ILLEGAL_ATTR	= 0x80020191,	
	SCE_KERNEL_ERROR_ILLEGAL_ENTRY	= 0x80020192,	
	SCE_KERNEL_ERROR_ILLEGAL_PRIORITY	= 0x80020193,	
	SCE_KERNEL_ERROR_ILLEGAL_STACK_SIZE	= 0x80020194,	
	SCE_KERNEL_ERROR_ILLEGAL_MODE	= 0x80020195,	
	SCE_KERNEL_ERROR_ILLEGAL_MASK	= 0x80020196,	
	SCE_KERNEL_ERROR_ILLEGAL_THID	= 0x80020197,	
	SCE_KERNEL_ERROR_UNKNOWN_THID	= 0x80020198,	
	SCE_KERNEL_ERROR_UNKNOWN_SEMID	= 0x80020199,	
	SCE_KERNEL_ERROR_UNKNOWN_EVFID	= 0x8002019a,	
	SCE_KERNEL_ERROR_UNKNOWN_MBXID	= 0x8002019b,	
	SCE_KERNEL_ERROR_UNKNOWN_VPLID	= 0x8002019c,	
	SCE_KERNEL_ERROR_UNKNOWN_FPLID	= 0x8002019d,	
	SCE_KERNEL_ERROR_UNKNOWN_MPPID	= 0x8002019e,	
	SCE_KERNEL_ERROR_UNKNOWN_ALMID	= 0x8002019f,	
	SCE_KERNEL_ERROR_UNKNOWN_TEID	= 0x800201a0,	
	SCE_KERNEL_ERROR_UNKNOWN_CBID	= 0x800201a1,	
	SCE_KERNEL_ERROR_DORMANT	= 0x800201a2,	
	SCE_KERNEL_ERROR_SUSPEND	= 0x800201a3,	
	SCE_KERNEL_ERROR_NOT_DORMANT	= 0x800201a4,	
	SCE_KERNEL_ERROR_NOT_SUSPEND	= 0x800201a5,	
	SCE_KERNEL_ERROR_NOT_WAIT	= 0x800201a6,	
	SCE_KERNEL_ERROR_CAN_NOT_WAIT	= 0x800201a7,	
	SCE_KERNEL_ERROR_WAIT_TIMEOUT	= 0x800201a8,	
	SCE_KERNEL_ERROR_WAIT_CANCEL	= 0x800201a9,	
	SCE_KERNEL_ERROR_RELEASE_WAIT	= 0x800201aa,	
	SCE_KERNEL_ERROR_NOTIFY_CALLBACK	= 0x800201ab,	
	SCE_KERNEL_ERROR_THREAD_TERMINATED	= 0x800201ac,	
	SCE_KERNEL_ERROR_SEMA_ZERO	= 0x800201ad,	
	SCE_KERNEL_ERROR_SEMA_OVF	= 0x800201ae,	
	SCE_KERNEL_ERROR_EVF_COND	= 0x800201af,	
	SCE_KERNEL_ERROR_EVF_MULTI	= 0x800201b0,	
	SCE_KERNEL_ERROR_EVF_ILPAT	= 0x800201b1,	
	SCE_KERNEL_ERROR_MBOX_NOMSG	= 0x800201b2,	
	SCE_KERNEL_ERROR_MPP_FULL	= 0x800201b3,	
	SCE_KERNEL_ERROR_MPP_EMPTY	= 0x800201b4,	
	SCE_KERNEL_ERROR_WAIT_DELETE	= 0x800201b5,	
	SCE_KERNEL_ERROR_ILLEGAL_MEMBLOCK	= 0x800201b6,	
	SCE_KERNEL_ERROR_ILLEGAL_MEMSIZE	= 0x800201b7,	
	SCE_KERNEL_ERROR_ILLEGAL_SPADADDR	= 0x800201b8,	
	SCE_KERNEL_ERROR_SPAD_INUSE	= 0x800201b9,	
	SCE_KERNEL_ERROR_SPAD_NOT_INUSE	= 0x800201ba,	
	SCE_KERNEL_ERROR_ILLEGAL_TYPE	= 0x800201bb,	
	SCE_KERNEL_ERROR_ILLEGAL_SIZE	= 0x800201bc,	
	SCE_KERNEL_ERROR_ILLEGAL_COUNT	= 0x800201bd,	
	SCE_KERNEL_ERROR_UNKNOWN_VTID	= 0x800201be,	
	SCE_KERNEL_ERROR_ILLEGAL_VTID	= 0x800201bf,	
	SCE_KERNEL_ERROR_ILLEGAL_KTLSID	= 0x800201c0,	
	SCE_KERNEL_ERROR_KTLS_FULL	= 0x800201c1,	
	SCE_KERNEL_ERROR_KTLS_BUSY	= 0x800201c2,	
	SCE_KERNEL_ERROR_PM_INVALID_PRIORITY	= 0x80020258,	
	SCE_KERNEL_ERROR_PM_INVALID_DEVNAME	= 0x80020259,	
	SCE_KERNEL_ERROR_PM_UNKNOWN_DEVNAME	= 0x8002025a,	
	SCE_KERNEL_ERROR_PM_PMINFO_REGISTERED	= 0x8002025b,	
	SCE_KERNEL_ERROR_PM_PMINFO_UNREGISTERED	= 0x8002025c,	
	SCE_KERNEL_ERROR_PM_INVALID_MAJOR_STATE	= 0x8002025d,	
	SCE_KERNEL_ERROR_PM_INVALID_REQUEST	= 0x8002025e,	
	SCE_KERNEL_ERROR_PM_UNKNOWN_REQUEST	= 0x8002025f,	
	SCE_KERNEL_ERROR_PM_INVALID_UNIT	= 0x80020260,	
	SCE_KERNEL_ERROR_PM_CANNOT_CANCEL	= 0x80020261,	
	SCE_KERNEL_ERROR_PM_INVALID_PMINFO	= 0x80020262,	
	SCE_KERNEL_ERROR_PM_INVALID_ARGUMENT	= 0x80020263,	
	SCE_KERNEL_ERROR_PM_ALREADY_TARGET_PWRSTATE	= 0x80020264,	
	SCE_KERNEL_ERROR_PM_CHANGE_PWRSTATE_FAILED	= 0x80020265,	
	SCE_KERNEL_ERROR_PM_CANNOT_CHANGE_DEVPWR_STATE	= 0x80020266,	
	SCE_KERNEL_ERROR_PM_NO_SUPPORT_DEVPWR_STATE	= 0x80020267,	
	SCE_KERNEL_ERROR_DMAC_REQUEST_FAILED	= 0x800202bc,	
	SCE_KERNEL_ERROR_DMAC_REQUEST_DENIED	= 0x800202bd,	
	SCE_KERNEL_ERROR_DMAC_OP_QUEUED	= 0x800202be,	
	SCE_KERNEL_ERROR_DMAC_OP_NOT_QUEUED	= 0x800202bf,	
	SCE_KERNEL_ERROR_DMAC_OP_RUNNING	= 0x800202c0,	
	SCE_KERNEL_ERROR_DMAC_OP_NOT_ASSIGNED	= 0x800202c1,	
	SCE_KERNEL_ERROR_DMAC_OP_TIMEOUT	= 0x800202c2,	
	SCE_KERNEL_ERROR_DMAC_OP_FREED	= 0x800202c3,	
	SCE_KERNEL_ERROR_DMAC_OP_USED	= 0x800202c4,	
	SCE_KERNEL_ERROR_DMAC_OP_EMPTY	= 0x800202c5,	
	SCE_KERNEL_ERROR_DMAC_OP_ABORTED	= 0x800202c6,	
	SCE_KERNEL_ERROR_DMAC_OP_ERROR	= 0x800202c7,	
	SCE_KERNEL_ERROR_DMAC_CHANNEL_RESERVED	= 0x800202c8,	
	SCE_KERNEL_ERROR_DMAC_CHANNEL_EXCLUDED	= 0x800202c9,	
	SCE_KERNEL_ERROR_DMAC_PRIVILEGE_ADDRESS	= 0x800202ca,	
	SCE_KERNEL_ERROR_DMAC_NO_ENOUGHSPACE	= 0x800202cb,	
	SCE_KERNEL_ERROR_DMAC_CHANNEL_NOT_ASSIGNED	= 0x800202cc,	
	SCE_KERNEL_ERROR_DMAC_CHILD_OPERATION	= 0x800202cd,	
	SCE_KERNEL_ERROR_DMAC_TOO_MUCH_SIZE	= 0x800202ce,	
	SCE_KERNEL_ERROR_DMAC_INVALID_ARGUMENT	= 0x800202cf,	
	SCE_KERNEL_ERROR_MFILE	= 0x80020320,	
	SCE_KERNEL_ERROR_NODEV	= 0x80020321,	
	SCE_KERNEL_ERROR_XDEV	= 0x80020322,	
	SCE_KERNEL_ERROR_BADF	= 0x80020323,	
	SCE_KERNEL_ERROR_INVAL	= 0x80020324,	
	SCE_KERNEL_ERROR_UNSUP	= 0x80020325,	
	SCE_KERNEL_ERROR_ALIAS_USED	= 0x80020326,	
	SCE_KERNEL_ERROR_CANNOT_MOUNT	= 0x80020327,	
	SCE_KERNEL_ERROR_DRIVER_DELETED	= 0x80020328,	
	SCE_KERNEL_ERROR_ASYNC_BUSY	= 0x80020329,	
	SCE_KERNEL_ERROR_NOASYNC	= 0x8002032a,	
	SCE_KERNEL_ERROR_REGDEV	= 0x8002032b,	
	SCE_KERNEL_ERROR_NOCWD	= 0x8002032c,	
	SCE_KERNEL_ERROR_NAMETOOLONG	= 0x8002032d,	
	SCE_KERNEL_ERROR_NXIO	= 0x800203e8,	
	SCE_KERNEL_ERROR_IO	= 0x800203e9,	
	SCE_KERNEL_ERROR_NOMEM	= 0x800203ea,	
	SCE_KERNEL_ERROR_STDIO_NOT_OPENED	= 0x800203eb,	
	SCE_KERNEL_ERROR_CACHE_ALIGNMENT	= 0x8002044c,	
	SCE_KERNEL_ERROR_ERRORMAX	= 0x8002044d,	
}