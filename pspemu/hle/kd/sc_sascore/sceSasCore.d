module pspemu.hle.kd.sc_sascore.sceSasCore;

import pspemu.hle.ModuleNative;
import pspemu.hle.HleEmulatorState;

enum WaveformEffectType {
    PSP_SAS_EFFECT_TYPE_OFF   = -1,
    PSP_SAS_EFFECT_TYPE_ROOM  =  0,
    PSP_SAS_EFFECT_TYPE_UNK1  =  1,
    PSP_SAS_EFFECT_TYPE_UNK2  =  2,
    PSP_SAS_EFFECT_TYPE_UNK3  =  3,
    PSP_SAS_EFFECT_TYPE_HALL  =  4,
    PSP_SAS_EFFECT_TYPE_SPACE =  5,
    PSP_SAS_EFFECT_TYPE_ECHO  =  6,
    PSP_SAS_EFFECT_TYPE_DELAY =  7,
    PSP_SAS_EFFECT_TYPE_PIPE  =  8,
}

struct SasVoice {
	bool playing;
	int pitch;
	
	bool ended() {
		return !playing;
	}
}

struct SasCore {
	int grainSamples;
	int maxVoices;
	int outMode;
	int sampleRate;
	int leftVol;
	int rightVol;
	bool waveformEffectIsDry;
	bool waveformEffectIsWet;
	WaveformEffectType waveformEffectType;
	SasVoice[32] _voices;
	
	SasVoice[] voices() {
		return _voices[0..maxVoices];
	}
}

class sceSasCore : ModuleNative {
	void initNids() {
		mixin(registerd!(0x42778A9F, __sceSasInit));
	    mixin(registerd!(0x019B25EB, __sceSasSetADSR));
	    mixin(registerd!(0x267A6DD2, __sceSasRevParam));
	    mixin(registerd!(0x2C8E6AB3, __sceSasGetPauseFlag));
	    mixin(registerd!(0x33D4AB37, __sceSasRevType));
	    mixin(registerd!(0x440CA7D8, __sceSasSetVolume));
	    mixin(registerd!(0x50A14DFC, __sceSasCoreWithMix));
	    mixin(registerd!(0x5F9529F6, __sceSasSetSL));
	    mixin(registerd!(0x68A46B95, __sceSasGetEndFlag));
	    mixin(registerd!(0x74AE582A, __sceSasGetEnvelopeHeight));
	    mixin(registerd!(0x76F01ACA, __sceSasSetKeyOn));
	    mixin(registerd!(0x787D04D5, __sceSasSetPause));
	    mixin(registerd!(0x99944089, __sceSasSetVoice));
	    mixin(registerd!(0x9EC3676A, __sceSasSetADSRmode));
	    mixin(registerd!(0xA0CF2FA4, __sceSasSetKeyOff));
	    mixin(registerd!(0xA3589D81, __sceSasCore));
	    mixin(registerd!(0xAD84D37F, __sceSasSetPitch));
	    mixin(registerd!(0xB7660A23, __sceSasSetNoise));
	    mixin(registerd!(0xCBCD4F79, __sceSasSetSimpleADSR));
	    mixin(registerd!(0xD5A229C9, __sceSasRevEVOL));
	    mixin(registerd!(0xF983B186, __sceSasRevVON));
	}

	uint __sceSasInit(SasCore* sasCore, int grainSamples, int maxVoices, int outMode, int sampleRate) {
		// Example: <PTR>, 256, 32, 0, 44100
		logWarning("Not implemented __sceSasInit(%08X, %d, %d, %d, %d)", currentMemory().getPointerReverse(sasCore), grainSamples, maxVoices, outMode, sampleRate);

		sasCore.grainSamples = grainSamples;
		sasCore.maxVoices    = maxVoices;
		sasCore.outMode      = outMode;
		sasCore.sampleRate   = sampleRate;
		//*sasCorePtr = hleEmulatorState.uniqueIdFactory.add!SasCore(sasCore);
		
		return 0;
	}

	/**
	 * Return a bitfield indicating the end of the voices.
	 *
	 * @param  sasCore  Core
	 *
	 * @return  A set of flags indiciating the end of the voices.
	 */
    uint __sceSasGetEndFlag(SasCore* sasCore) {
		uint endFlags;
		foreach (k, ref voice; sasCore.voices) {
			if (voice.ended) endFlags |= (1 << k); 
		}
		return endFlags;
    }

    uint __sceSasRevType(SasCore* sasCore, WaveformEffectType waveformEffectType) {
    	sasCore.waveformEffectType = waveformEffectType;
    	return 0;
    }

    uint __sceSasRevVON(SasCore* sasCore, bool waveformEffectIsDry, bool waveformEffectIsWet) {
    	sasCore.waveformEffectIsDry = waveformEffectIsDry;
    	sasCore.waveformEffectIsWet = waveformEffectIsWet;
    	return 0;
    }

    uint __sceSasRevEVOL(SasCore* sasCore, int leftVol, int rightVol) {
    	sasCore.leftVol  = leftVol;
    	sasCore.rightVol = rightVol;
    	return 0;
    }

    uint __sceSasCore(SasCore* sasCore, void* sasOut) {
    	logTrace("Not implemented __sceSasCore");
    	return 0;
    }

    int __sceSasSetVoice(SasCore* sasCore, int voice, void* vagAddr, int size, int loopmode) {
    	logTrace("Not implemented __sceSasSetVoice");
		return 0;
    }

    int __sceSasSetPitch(SasCore* sasCore, int voice, int pitch) {
    	sasCore.voices[voice].pitch = pitch;
		return 0;
    }

	/**
	 *
	 * @param  voice     Voice
	 * @param  flag      Bitfield to set each envelope on or off.
	 * @param  attack    ADSR Envelope's attack.
	 * @param  decay     ADSR Envelope's decay.
	 * @param  sustain   ADSR Envelope's sustain.
	 * @param  release   ADSR Envelope's release.
	 */
	int __sceSasSetADSR(SasCore* sasCore, int voice, uint flag, uint attack, uint decay, uint sustain, uint release) {
		logTrace("Not implemented __sceSasSetADSR");
		return 0;
	}

    int __sceSasSetVolume() {
    	unimplemented_notice();
    	return 0;
    }
	

	int __sceSasRevParam() { unimplemented_notice(); return 0; }
    int __sceSasGetPauseFlag() { unimplemented_notice(); return 0; }
    int __sceSasCoreWithMix() { unimplemented_notice(); return 0; }
    int __sceSasSetSL() { unimplemented_notice(); return 0; }
    int __sceSasGetEnvelopeHeight() { unimplemented_notice(); return 0; }
    int __sceSasSetKeyOn() { unimplemented_notice(); return 0; }
    int __sceSasSetPause() { unimplemented_notice(); return 0; }
    int __sceSasSetADSRmode() { unimplemented_notice(); return 0; }
    int __sceSasSetKeyOff() { unimplemented_notice(); return 0; }
    int __sceSasSetNoise() { unimplemented_notice(); return 0; }
    int __sceSasSetSimpleADSR() { unimplemented_notice(); return 0; }
}

static this() {
	mixin(ModuleNative.registerModule("sceSasCore"));
}