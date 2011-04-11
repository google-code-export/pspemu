module pspemu.hle.SystemHle;

import pspemu.hle.PspUID;
import pspemu.hle.SyscallHandler;
import pspemu.hle.MemoryManager;
import pspemu.hle.PspModuleManager;

class SystemHle
{
    public PspUID pspUID;
    public SyscallHandler syscallHandler;
    public MemoryManager memoryManager;
    public PspModuleManager pspModuleManager;

    this()
    {
        this.pspUID = new PspUID();
        this.memoryManager = new MemoryManager();
        this.pspModuleManager = new PspModuleManager();
        this.syscallHandler = new SyscallHandler(this);
    }
}