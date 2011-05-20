module pspemu.core.controller.Controller;

import pspemu.utils.CircularList;
public import pspemu.hle.kd.ctrl.Types;

class Controller {
	CircularList!(SceCtrlData) sceCtrlDataFrames;
	SceCtrlData sceCtrlData;
	
	this() {
		sceCtrlDataFrames = new CircularList!(SceCtrlData)();
	}
	
	public void push() {
		sceCtrlDataFrames.enqueue(sceCtrlData);
		sceCtrlData.TimeStamp++;
	}
	
	public ref SceCtrlData readAt(int n) {
		return this.sceCtrlDataFrames.readFromTail(-(n + 1));
	}
}