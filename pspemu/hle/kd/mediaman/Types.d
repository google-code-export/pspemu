module pspemu.hle.kd.mediaman.Types;

public import pspemu.hle.kd.Types;

/** Enumeration for UMD drive state */
enum PspUmdState
{
	PSP_UMD_NOT_PRESENT = 0x01,
	PSP_UMD_PRESENT     = 0x02,
	PSP_UMD_CHANGED     = 0x04,
	PSP_UMD_INITING     = 0x08,
	PSP_UMD_INITED      = 0x10,
	PSP_UMD_READY       = 0x20,
};