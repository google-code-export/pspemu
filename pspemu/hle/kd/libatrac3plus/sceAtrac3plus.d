module pspemu.hle.kd.libatrac3plus.sceAtrac3plus;

import pspemu.hle.ModuleNative;
import pspemu.hle.HleEmulatorState;

class Atrac3Object {
	void *buf;
	SceSize bufsize;
	int nloops;
}

struct PspBufferInfo {
	u8* pucWritePositionFirstBuf;
	u32 uiWritableByteFirstBuf;
	u32 uiMinWriteByteFirstBuf;
	u32 uiReadPositionFirstBuf;

	u8* pucWritePositionSecondBuf;
	u32 uiWritableByteSecondBuf;
	u32 uiMinWriteByteSecondBuf;
	u32 uiReadPositionSecondBuf;
}

class sceAtrac3plus : ModuleNative {
	void initNids() {
		mixin(registerd!(0x7A20E7AF, sceAtracSetDataAndGetID));
		mixin(registerd!(0x868120B5, sceAtracSetLoopNum));
		mixin(registerd!(0x9AE849A7, sceAtracGetRemainFrame));
		mixin(registerd!(0x6A8C3CD5, sceAtracDecodeData));
		mixin(registerd!(0x61EB33F5, sceAtracReleaseAtracID));
		mixin(registerd!(0x780F88D1, sceAtracGetAtracID));
		mixin(registerd!(0x36FAABFB, sceAtracGetNextSample));
		mixin(registerd!(0xE88F759B, sceAtracGetInternalErrorInfo));
	    mixin(registerd!(0x5D268707, sceAtracGetStreamDataInfo));
	    mixin(registerd!(0x7DB31251, sceAtracAddStreamData));
	    mixin(registerd!(0x83E85EA0, sceAtracGetSecondBufferInfo));
	    mixin(registerd!(0x83BF7AFD, sceAtracSetSecondBuffer));
	    mixin(registerd!(0xE23E3A35, sceAtracGetNextDecodePosition));
	    mixin(registerd!(0xA2BBA8BE, sceAtracGetSoundSample));
	    mixin(registerd!(0xCA3CA3D2, sceAtracGetBufferInfoForReseting));
	    mixin(registerd!(0x644E5607, sceAtracResetPlayPosition));
	}
	
	/**
	 * Creates a new Atrac ID from the specified data
	 *
	 * @param buf - the buffer holding the atrac3 data, including the RIFF/WAVE header.
	 * @param bufsize - the size of the buffer pointed by buf
	 *
	 * @return the new atrac ID, or < 0 on error 
	*/
	int sceAtracSetDataAndGetID(void *buf, SceSize bufsize) {
		logWarning("Not implemented sceAtracSetDataAndGetID");
		Atrac3Object atrac3Object = new Atrac3Object();
		atrac3Object.buf = buf;
		atrac3Object.bufsize = bufsize;
		return cast(int)hleEmulatorState.uniqueIdFactory.add(atrac3Object);
	}
	
	/**
	 * Sets the number of loops for this atrac ID
	 *
	 * @param atracID - the atracID
	 * @param nloops - the number of loops to set
	 *
	 * @return < 0 on error, otherwise 0
	 *
	*/
	int sceAtracSetLoopNum(int atracID, int nloops) {
		Atrac3Object atrac3Object = hleEmulatorState.uniqueIdFactory.get!Atrac3Object(atracID);
		atrac3Object.nloops = nloops;
		return 0;
	}
	
	/**
	 * Gets the remaining (not decoded) number of frames
	 * 
	 * @param atracID - the atrac ID
	 * @param outRemainFrame - pointer to a integer that receives either -1 if all at3 data is already on memory, 
	 *  or the remaining (not decoded yet) frames at memory if not all at3 data is on memory 
	 *
	 * @return < 0 on error, otherwise 0
	 *
	*/
	int sceAtracGetRemainFrame(int atracID, int *outRemainFrame) {
		Atrac3Object atrac3Object = hleEmulatorState.uniqueIdFactory.get!Atrac3Object(atracID);
		logWarning("Not implemented sceAtracGetRemainFrame(%d, %s)", atracID, outRemainFrame);
		*outRemainFrame = 0;
		return 0;
	}
	
	/**
	 * Decode a frame of data. 
	 *
	 * @param atracID        - the atrac ID
	 * @param outSamples     - pointer to a buffer that receives the decoded data of the current frame
	 * @param outN           - pointer to a integer that receives the number of audio samples of the decoded frame
	 * @param outEnd         - pointer to a integer that receives a boolean value indicating if the decoded frame is the last one
	 * @param outRemainFrame - pointer to a integer that receives either -1 if all at3 data is already on memory, 
	 *                         or the remaining (not decoded yet) frames at memory if not all at3 data is on memory
	 *
	 * @return < 0 on error, otherwise 0
	 */
	int sceAtracDecodeData(int atracID, u16 *outSamples, int *outN, int *outEnd, int *outRemainFrame) {
		//logInfo("Not implemented sceAtracDecodeData(%d)", atracID);

		Atrac3Object atrac3Object = hleEmulatorState.uniqueIdFactory.get!Atrac3Object(atracID);
		*outSamples = 0;
		*outN = 0;
		*outEnd = 0;
		*outRemainFrame = 0;
		return 0;
	}
	
	/**
	 * It releases an atrac ID
	 *
	 * @param atracID - the atrac ID to release
	 *
	 * @return < 0 on error
	 *
	*/
	int sceAtracReleaseAtracID(int atracID) {
		hleEmulatorState.uniqueIdFactory.remove!Atrac3Object(atracID);
		return 0;
	}
	
	void sceAtracGetAtracID() {
		unimplemented_notice();
	}
	
	/**
	 * Gets the number of samples of the next frame to be decoded.
	 *
	 * @param atracID - the atrac ID
	 * @param outN - pointer to receives the number of samples of the next frame.
	 *
	 * @return < 0 on error, otherwise 0
	 *
	 */
	int sceAtracGetNextSample(int atracID, int *outN) {
		*outN = 0;
		//unimplemented_notice();
		logTrace("Not implemented sceAtracGetNextSample");
		return 0;
	}

	int sceAtracGetInternalErrorInfo(int atracID, int *piResult) {
		*piResult = 0;
		return 0;
	}
	
	/**
	 *
	 * @param atracID - the atrac ID
	 * @param writePointer - Pointer to where to read the atrac data
	 * @param availableBytes - Number of bytes available at the writePointer location
	 * @param readOffset - Offset where to seek into the atrac file before reading
	 *
	 * @return < 0 on error, otherwise 0
	*/
	int sceAtracGetStreamDataInfo(int atracID, u8** writePointer, u32* availableBytes, u32* readOffset) {
		unimplemented();
		return 0;
	}
	
	/**
	 *
	 * @param atracID - the atrac ID
	 * @param bytesToAdd - Number of bytes read into location given by sceAtracGetStreamDataInfo().
	 *
	 * @return < 0 on error, otherwise 0
	*/
	int sceAtracAddStreamData(int atracID, uint bytesToAdd) {
		unimplemented();
		return 0;
	}
		
	int sceAtracGetSecondBufferInfo(int atracID, u32 *puiPosition, u32 *puiDataByte) {
		unimplemented_notice();
		return 0;
	}

	int sceAtracSetSecondBuffer(int atracID, u8 *pucSecondBufferAddr, u32 uiSecondBufferByte) {
		unimplemented_notice();
		//unimplemented();
		return 0;
	}

	int sceAtracGetNextDecodePosition(int atracID, u32 *puiSamplePosition) {
		unimplemented_notice();
		return 0;
	}

	int sceAtracGetSoundSample(int atracID, int *piEndSample, int *piLoopStartSample, int *piLoopEndSample) {
		unimplemented_notice();
		return 0;
	}

	int sceAtracGetBufferInfoForReseting(int atracID, u32 uiSample, PspBufferInfo *pBufferInfo) {
		unimplemented_notice();
		return 0;
	}

	int sceAtracResetPlayPosition(int atracID, u32 uiSample, u32 uiWriteByteFirstBuf, u32 uiWriteByteSecondBuf) {
		unimplemented_notice();
		return 0;
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceAtrac3plus"));
}
