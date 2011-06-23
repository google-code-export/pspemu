module pspemu.hle.kd.libatrac3plus.sceAtrac3plus;

import pspemu.hle.ModuleNative;
import pspemu.hle.HleEmulatorState;
import pspemu.utils.String;
import pspemu.hle.kd.SystemErrors;
import std.stream;
import std.intrinsic;
import pspemu.utils.StructUtils;
import pspemu.utils.MathUtils;

enum CodecType {
	Unknown  = 0,
    AT3      = 1, // "AT3"
    AT3_PLUS = 2, // "AT3PLUS"
}

static struct OMA {
	alias be!uint uint_be;
	alias be!short short_be;
	
	uint_be   magic    = uint_be(0x45413301);
	short_be  capacity = short_be(OMA.sizeof);
	short_be  unk      = short_be(-1);
	uint_be   unk1     = uint_be(0x00000000);
	uint_be   unk2     = uint_be(0x010f5000);
	uint_be   unk3     = uint_be(0x00040000);
	uint_be   unk4     = uint_be(0x0000f5ce);
	uint_be   unk5     = uint_be(0xd2929132);
	uint_be   unk6     = uint_be(0x2480451c);

	// Must set from AT3.
	uint   omaInfo;
	
	ubyte[60] pad;
	
	static assert (OMA.sizeof == 0x60); 
}

class Atrac3Object {
	ubyte[] buf;
	int nloops;
	CodecType type;
	Format format;
	Fact fact;
	LoopInfo[] loops;
	uint dataOffset;
	uint writeBufferSize;
	uint writeBufferGuestPtr;
	
	void writeOma(Stream stream) {
		OMA oma;
		oma.omaInfo = format.omaInfo;
		stream.write(TA(oma));
		stream.copyFrom(new MemoryStream(buf[dataOffset..$]));
	}

	static struct Format {
		ushort  compressionCode;
		ushort  atracChannels;
		uint    atracSampleRate;
		uint    atracBitrate;
		ushort  atracBytesPerFrame;
		ushort  hiBytesPerSample;
		uint[6] unk;
		uint    omaInfo;
	}
	
	static struct Fact {
		uint atracEndSample;
		uint atracSampleOffset;
	}
	
	static struct LoopInfo {
		uint cuePointID;
		uint type;
		uint startSample;
		uint endSample;
		uint fraction;
		uint playCount;
	}

	// Codec Type
    const ushort AT3_MAGIC      = 0x0270; // "AT3"
    const ushort AT3_PLUS_MAGIC = 0xFFFE; // "AT3PLUS"

    // RIFF Chunks
    const uint RIFF_MAGIC = 0x46464952; // "RIFF"
    const uint WAVE_MAGIC = 0x45564157; // "WAVE"
    const uint FMT_CHUNK_MAGIC = 0x20746D66; // "FMT "
    const uint FACT_CHUNK_MAGIC = 0x74636166; // "FACT"
    const uint SMPL_CHUNK_MAGIC = 0x6C706D73; // "SMPL"
    const uint DATA_CHUNK_MAGIC = 0x61746164; // "DATA"
    
    public this(ubyte[] buf) {
    	this.buf = buf;
    	this.dump();

    	this.analyzeAtracHeader();
    }
    
	
    @property public CodecType codecType() {
		switch (format.compressionCode) {
			case AT3_MAGIC     : return CodecType.AT3;
			case AT3_PLUS_MAGIC: return CodecType.AT3_PLUS;
			default:
				return CodecType.Unknown;
			break;
		}
    }
    
	public void analyzeAtracHeader() {
		static struct RiffHeader {
			char[4] riffMagic = "RIFF";
			uint size;
			char[4] waveMagic = "WAVE";
		}

		static struct ChunkHeader {
			char[4] magic;
			uint    size;
			
			static assert(ChunkHeader.sizeof == 8);
			
			string toString() {
				return std.string.format("ChunkHeader(%s, %d)", magic, size);
			}
		}
		
		void processChunks(Stream stream, int offset, int level = 0) {
			while (!stream.eof) {
				ChunkHeader chunkHeader;
				stream.read(TA(chunkHeader));
				writefln("CHUNK(%d): %s", level, chunkHeader);
				Stream chunkStream = new SliceStream(stream, stream.position, stream.size);
				
				// Level + 1
				//processChunks(chunkStream, offset + stream.position);
				
				switch (chunkHeader.magic) {
					case "fmt ":
						chunkStream.read(TA(format));
					break;
					case "fact":
						chunkStream.read(TA(fact));
					break;
					case "smpl":
						uint checkNumLoops;
						chunkStream.position = 28;
						chunkStream.read(checkNumLoops);
						
						chunkStream.position = 36;
						loops.length = 0;
						foreach (n; 0..checkNumLoops) {
							LoopInfo loopInfo;
							chunkStream.read(TA(loopInfo));
							loops ~= loopInfo;
						}
					break;
					case "data":
						// Found data.
						dataOffset = cast(uint)(offset + stream.position);
						return;
					break;
					default:
						writefln("   -- UNPROCESSED CHUNK");
					break;
				}
				
				stream.seekCur(nextAlignedValue(cast(long)chunkHeader.size, cast(long)2));
			}
		}
		
		Stream bufStream = new MemoryStream(buf);
		RiffHeader riffHeader;
		bufStream.read(TA(riffHeader));
		if (riffHeader.riffMagic != RiffHeader.init.riffMagic) throw(new Exception("Not a RIFF file"));
		if (riffHeader.waveMagic != RiffHeader.init.waveMagic) throw(new Exception("Not a RIFF.WAVE file"));
		
		processChunks(new SliceStream(bufStream, RiffHeader.sizeof, RiffHeader.sizeof + riffHeader.size), RiffHeader.sizeof);
	}
	
	void dump() {
    	writefln("-------- Size(%d)", buf.length);
		dumpHex(buf[0..0x100]);
	}
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

		mixin(registerd!(0x0E2A73AB, sceAtracSetData));
		mixin(registerd!(0xD6A5F2F7, sceAtracGetMaxSample));
		mixin(registerd!(0xFAA4F89B, sceAtracGetLoopStatus));
		
	    mixin(registerd!(0xA554A158, sceAtracGetBitrate));
	    mixin(registerd!(0xB3B5D042, sceAtracGetOutputChannel));
	}
	
	int sceAtracGetOutputChannel() {
		unimplemented();
		return 0;
	}
	
	/**
	 * Gets the bitrate.
	 *
	 * @param atracID    - the atracID
	 * @param outBitrate - pointer to a integer that receives the bitrate in kbps
	 *
	 * @return < 0 on error, otherwise 0
	 *
	*/
	int sceAtracGetBitrate(int atracID, int *outBitrate) {
		unimplemented();
		return 0;
	}
	
	int sceAtracSetData(int atracID, u8 *pucBufferAddr, u32 uiBufferByte) {
		unimplemented();
		return 0;
	}
	
	/**
	 * Gets the maximum number of samples of the atrac3 stream.
	 *
	 * @param atracID - the atrac ID
	 * @param outMax  - pointer to a integer that receives the maximum number of samples.
	 *
	 * @return < 0 on error, otherwise 0
	 *
	 */
	int sceAtracGetMaxSample(int atracID, int* outMax) {
		*outMax = 2048;
		//unimplemented();
		return 0;
	}

	int sceAtracGetLoopStatus(int atracID, int *piLoopNum, u32 *puiLoopStatus) {
		unimplemented();
		return 0;
	}

	/**
	 * Creates a new Atrac ID from the specified data
	 *
	 * @param buf     - the buffer holding the atrac3 data, including the RIFF/WAVE header.
	 * @param bufsize - the size of the buffer pointed by buf
	 *
	 * @return the new atrac ID, or < 0 on error 
	*/
	int sceAtracSetDataAndGetID(void *buf, SceSize bufsize) {
		unimplemented_notice();
		logWarning("Not implemented sceAtracSetDataAndGetID");
		Atrac3Object atrac3Object = new Atrac3Object((cast(ubyte*)buf)[0..bufsize]);
		
		//scope omaOut = new std.stream.File("temp.oma", FileMode.OutNew);
		//atrac3Object.writeOma(omaOut);
		
		return cast(int)hleEmulatorState.uniqueIdFactory.add(atrac3Object);
	}
	
	/**
	 * Sets the number of loops for this atrac ID
	 *
	 * @param atracID - the atracID
	 * @param nloops  - the number of loops to set
	 *
	 * @return < 0 on error, otherwise 0
	 *
	*/
	int sceAtracSetLoopNum(int atracID, int nloops) {
		unimplemented_notice();
		Atrac3Object atrac3Object = getAtrac3ObjectById(atracID);
		atrac3Object.nloops = nloops;
		return 0;
	}
	
	/**
	 * Gets the remaining (not decoded) number of frames
	 * 
	 * @param atracID        - the atrac ID
	 * @param outRemainFrame - pointer to a integer that receives either -1 if all at3 data is already on memory, 
	 *                         or the remaining (not decoded yet) frames at memory if not all at3 data is on memory 
	 *
	 * @return < 0 on error, otherwise 0
	 *
	*/
	int sceAtracGetRemainFrame(int atracID, int *outRemainFrame) {
		unimplemented_notice();
		Atrac3Object atrac3Object = getAtrac3ObjectById(atracID);
		logWarning("Not implemented sceAtracGetRemainFrame(%d, %s)", atracID, outRemainFrame);
		*outRemainFrame = 0;
		return 0;
	}
	
	Atrac3Object getAtrac3ObjectById(int atracID) {
		return hleEmulatorState.uniqueIdFactory.get!Atrac3Object(atracID);
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
		unimplemented_notice();

		Atrac3Object atrac3Object = getAtrac3ObjectById(atracID);
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
		unimplemented_notice();
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
	 * @param outN    - pointer to receives the number of samples of the next frame.
	 *
	 * @return < 0 on error, otherwise 0
	 *
	 */
	int sceAtracGetNextSample(int atracID, int *outN) {
		*outN = 0;
		unimplemented_notice();
		logTrace("Not implemented sceAtracGetNextSample");
		return 0;
	}

	int sceAtracGetInternalErrorInfo(int atracID, int *piResult) {
		unimplemented_notice();
		*piResult = 0;
		return 0;
	}
	
	/**
	 *
	 * @param atracID        - the atrac ID
	 * @param writePointer   - Pointer to where to read the atrac data
	 * @param availableBytes - Number of bytes available at the writePointer location
	 * @param readOffset     - Offset where to seek into the atrac file before reading
	 *
	 * @return < 0 on error, otherwise 0
	*/
	int sceAtracGetStreamDataInfo(int atracID, u8** writePointer, u32* availableBytes, u32* readOffset) {
		Atrac3Object atrac3Object = getAtrac3ObjectById(atracID);
		
		*writePointer   = cast(u8*)atrac3Object.writeBufferGuestPtr; // @FIXME!!
		*availableBytes = cast(u32)atrac3Object.writeBufferSize;
		*readOffset     = atrac3Object.dataOffset;

		return 0;
	}
	
	/**
	 *
	 * @param atracID    - the atrac ID
	 * @param bytesToAdd - Number of bytes read into location given by sceAtracGetStreamDataInfo().
	 *
	 * @return < 0 on error, otherwise 0
	*/
	int sceAtracAddStreamData(int atracID, int bytesToAdd) {
		unimplemented();

		Atrac3Object atrac3Object = getAtrac3ObjectById(atracID);
		
		logInfo("sceAtracAddStreamData(%d, %d)", atracID, bytesToAdd);

		return 0;
	}

	int sceAtracGetSecondBufferInfo(int atracID, u32 *puiPosition, u32 *puiDataByte) {
		Atrac3Object atrac3Object = getAtrac3ObjectById(atracID);
		
		return SceKernelErrors.ERROR_ATRAC_SECOND_BUFFER_NOT_NEEDED;
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
		Atrac3Object atrac3Object = getAtrac3ObjectById(atracID);
		atrac3Object.writeBufferSize = 4096;
		atrac3Object.writeBufferGuestPtr = hleEmulatorState.memoryManager.malloc(atrac3Object.writeBufferSize);
		*piEndSample = atrac3Object.fact.atracEndSample;
		if (atrac3Object.loops.length > 0) {
			*piLoopStartSample = atrac3Object.loops[0].startSample;
			*piLoopEndSample   = atrac3Object.loops[0].endSample;
		} else {
			*piLoopStartSample = -1;
			*piLoopEndSample   = -1;
		}
		
		//unimplemented_notice();
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
