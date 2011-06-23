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

enum AdsrFlags {
	hasAttack  = 0b_0001,
	hasDecay   = 0b_0010,
	hasSustain = 0b_0100,
	hasRelease = 0b_1000,
}

const int PSP_SAS_VOICES_MAX = 32;
const int PSP_SAS_GRAIN_SAMPLES = 256;
const int PSP_SAS_VOL_MAX = 0x1000;
const int PSP_SAS_LOOP_MODE_OFF = 0;
const int PSP_SAS_LOOP_MODE_ON = 1;
const int PSP_SAS_PITCH_MIN = 0x1;
const int PSP_SAS_PITCH_BASE = 0x1000;
const int PSP_SAS_PITCH_MAX = 0x4000;
const int PSP_SAS_NOISE_FREQ_MAX = 0x3F;
const int PSP_SAS_ENVELOPE_HEIGHT_MAX = 0x40000000;
const int PSP_SAS_ENVELOPE_FREQ_MAX = 0x7FFFFFFF;
const int PSP_SAS_ADSR_CURVE_MODE_LINEAR_INCREASE = 0;
const int PSP_SAS_ADSR_CURVE_MODE_LINEAR_DECREASE = 1;
const int PSP_SAS_ADSR_CURVE_MODE_LINEAR_BENT = 2;
const int PSP_SAS_ADSR_CURVE_MODE_EXPONENT_REV = 3;
const int PSP_SAS_ADSR_CURVE_MODE_EXPONENT = 4;
const int PSP_SAS_ADSR_CURVE_MODE_DIRECT = 5;
const int PSP_SAS_ADSR_ATTACK = 1;
const int PSP_SAS_ADSR_DECAY = 2;
const int PSP_SAS_ADSR_SUSTAIN = 4;
const int PSP_SAS_ADSR_RELEASE = 8;
    
enum OutputMode : uint {
    PSP_SAS_OUTPUTMODE_STEREO = 0,
    PSP_SAS_OUTPUTMODE_MULTICHANNEL = 1,
}


struct SasVoice {
	bool playing;
	int pitch;
	uint attack;
	uint decay;
	uint sustain;
	uint release;
	
	bool ended() {
		return !playing;
	}
}

struct SasCore {
	int  grainSamples;
	int  maxVoices;
	int  outMode;
	int  sampleRate;
	int  leftVol;
	int  rightVol;
	bool waveformEffectIsDry;
	bool waveformEffectIsWet;
	int  waveformEffectLeftVol;
	int  waveformEffectRightVol;
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

	/**
	 * Initialized a sasCore structure.
	 * Note: PSP can only handle one at a time.
	 *
	 * @example __sceSasInit(&sasCore, PSP_SAS_GRAIN_SAMPLES, PSP_SAS_VOICES_MAX, OutputMode.PSP_SAS_OUTPUTMODE_STEREO, 44100);
	 *
	 * @param   sasCore       Pointer to a SasCore structure that will contain information.
	 * @param   grainSamples  Number of grainSamples
	 * @param   maxVoices     Max number of voices
	 * @param   outMode       Out Mode
	 * @param   sampleRate    Sample Rate
	 *
	 * @return  0 on success
	 */
	uint __sceSasInit(SasCore* sasCore, int grainSamples, int maxVoices, OutputMode outMode, int sampleRate) {
		
		if (grainSamples > PSP_SAS_GRAIN_SAMPLES) throw(new Exception("Invalid grainSamples"));
		if (maxVoices    > PSP_SAS_VOICES_MAX   ) throw(new Exception("Invalid maxVoices"));
		
		//logWarning("Not implemented __sceSasInit(%08X, %d, %d, %d, %d)", currentMemory().getPointerReverse(sasCore), grainSamples, maxVoices, outMode, sampleRate);

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

	/**
	 * Sets the WaveformEffectType to the specified sasCore.
	 *
	 * @param  sasCore             Core
	 * @param  waveformEffectType  Effect
	 *
	 * @return 0 on success.
	 */
    uint __sceSasRevType(SasCore* sasCore, WaveformEffectType waveformEffectType) {
    	sasCore.waveformEffectType = waveformEffectType;
    	return 0;
    }

	/**
	 * Sets the waveformEffectIsDry and waveformEffectIsWet to the specified sasCore.
	 *
	 * @param  sasCore             Core
	 * @param  waveformEffectIsDry waveformEffectIsDry
	 * @param  waveformEffectIsWet waveformEffectIsWet
	 *
	 * @return 0 on success.
	 */
    uint __sceSasRevVON(SasCore* sasCore, bool waveformEffectIsDry, bool waveformEffectIsWet) {
    	sasCore.waveformEffectIsDry = waveformEffectIsDry;
    	sasCore.waveformEffectIsWet = waveformEffectIsWet;
    	return 0;
    }

	/**
	 * Sets the effect left and right volumes for the specified sasCore.
	 *
	 * @param  sasCore     Core
	 * @param  leftVol     Left volume
	 * @param  rightVol    Right volume
	 *
	 * @return 0 on success
	 */
    uint __sceSasRevEVOL(SasCore* sasCore, int leftVol, int rightVol) {
    	sasCore.waveformEffectLeftVol  = leftVol;
    	sasCore.waveformEffectRightVol = rightVol;
    	return 0;
    }

	/**
	 *
	 */
    int __sceSasSetVoice(SasCore* sasCore, int voice, void* vagAddr, int size, int loopmode) {
    	unimplemented_notice();
		return 0;
    }

	/**
	 * Sets the pitch for a sasCore.voice.
	 *
	 * @param  sasCore  SasCore
	 * @param  voice    Voice
	 * @param  pitch    Pitch to set
	 *
	 * @return 0 on success
	 */
    int __sceSasSetPitch(SasCore* sasCore, int voice, int pitch) {
    	auto voicePtr = &sasCore.voices[voice];
    	
    	voicePtr.pitch = pitch;
		return 0;
    }

	/**
	 * Sets the ADSR (Attack Decay Sustain Release) for a sasCore.voice.
	 *
	 * @param  sasCore  SasCore
	 * @param  voice    Voice
	 * @param  flag     Bitfield to set each envelope on or off.
	 * @param  attack   ADSR Envelope's attack type.
	 * @param  decay    ADSR Envelope's decay type.
	 * @param  sustain  ADSR Envelope's sustain type.
	 * @param  release  ADSR Envelope's release type.
	 *
	 * @return 0 on success.
	 */
	int __sceSasSetADSR(SasCore* sasCore, int voice, AdsrFlags flag, uint attack, uint decay, uint sustain, uint release) {
		auto voicePtr = &sasCore.voices[voice];
		
		if (flag & AdsrFlags.hasAttack ) voicePtr.attack  = attack;
		if (flag & AdsrFlags.hasDecay  ) voicePtr.decay   = decay;
		if (flag & AdsrFlags.hasSustain) voicePtr.sustain = sustain;
		if (flag & AdsrFlags.hasRelease) voicePtr.release = release;

		return 0;
	}

    int __sceSasSetVolume() {
    	unimplemented_notice();
    	return 0;
    }
	

	int __sceSasRevParam() {
		unimplemented_notice();
		return 0;
	}

    int __sceSasGetPauseFlag() {
    	unimplemented_notice();
    	return 0;
    }

    int __sceSasCoreWithMix() {
    	unimplemented_notice();
    	return 0;
    }

    int __sceSasSetSL() {
    	unimplemented_notice();
    	return 0;
    }

    int __sceSasGetEnvelopeHeight() {
    	unimplemented_notice();
    	return 0;
    }

    int __sceSasSetKeyOn() {
    	unimplemented_notice();
    	return 0;
    }
    
    int __sceSasSetPause() {
    	unimplemented_notice();
    	return 0;
    }

    int __sceSasSetADSRmode() {
    	unimplemented_notice();
    	return 0;
    }

    int __sceSasSetKeyOff() {
    	unimplemented_notice();
    	return 0;
    }

    int __sceSasSetNoise() {
    	unimplemented_notice();
    	return 0;
    }

    int __sceSasSetSimpleADSR() {
    	unimplemented_notice();
    	return 0;
    }
    
	uint __sceSasCore(SasCore* sasCore, void* sasOut) {
		unimplemented_notice();
		return 0;
    }
}

static this() {
	mixin(ModuleNative.registerModule("sceSasCore"));
}