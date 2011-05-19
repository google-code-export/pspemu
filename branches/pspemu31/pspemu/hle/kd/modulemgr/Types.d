module pspemu.hle.kd.modulemgr.Types;

public import pspemu.hle.kd.Types;

struct SceKernelLMOption {
	SceSize size;
	SceUID  mpidtext;
	SceUID  mpiddata;
	uint    flags;
	char    position;
	char    access;
	char    creserved[2];
}

struct SceKernelSMOption {
	SceSize size;
	SceUID  mpidstack;
	SceSize stacksize;
	int     priority;
	uint    attribute;
}

struct SceModuleInfo {
	ushort modattribute;
	ubyte  modversion[2];
	char   modname[27];
	char   terminal;
	void*  gp_value;
	void*  ent_top;
	void*  ent_end;
	void*  stub_top;
	void*  stub_end;
}

enum PspModuleInfoAttr {
	PSP_MODULE_USER			= 0,
	PSP_MODULE_NO_STOP		= 0x0001,
	PSP_MODULE_SINGLE_LOAD	= 0x0002,
	PSP_MODULE_SINGLE_START	= 0x0004,
	PSP_MODULE_KERNEL		= 0x1000,
};
