module pspemu.hle.kd.audio.sceAudio_driver; // kd/audio.prx (sceAudio_Driver)

//debug = DEBUG_AUDIO;
//debug = DEBUG_SYSCALL;

//version = DISABLE_SOUND;

import std.c.windows.windows;

import core.thread;

import pspemu.core.audio.Audio;

import pspemu.hle.Module;
import pspemu.hle.ModuleNative;
import pspemu.hle.kd.audio.Types;

import pspemu.utils.Logger;

class sceAudio_driver : ModuleNative {
	struct Channel {
		bool reserved;
		int  samplecount;
		PspAudioFormats format;
		int numchannels() { return (format == PspAudioFormats.PSP_AUDIO_FORMAT_MONO) ? 1 : 2; }
		int dataCount() { return samplecount * numchannels; }
	}
	
	Channel channels[8]; // PSP_AUDIO_CHANNEL_MAX
	Audio audio;

	void initNids() {
		mixin(registerd!(0x13F592BC, sceAudioOutputPannedBlocking));
		mixin(registerd!(0x5EC81C55, sceAudioChReserve));
		mixin(registerd!(0x6FC46853, sceAudioChRelease));
		mixin(registerd!(0x8C1009B2, sceAudioOutput));
		mixin(registerd!(0x136CAF51, sceAudioOutputBlocking));
		mixin(registerd!(0xE2D56B2D, sceAudioOutputPanned));
		mixin(registerd!(0xE9D97901, sceAudioGetChannelRestLen));
		mixin(registerd!(0xCB2E439E, sceAudioSetChannelDataLen));
		mixin(registerd!(0x95FD0C2D, sceAudioChangeChannelConfig));
		mixin(registerd!(0xB7E1D8E7, sceAudioChangeChannelVolume));

		mixin(registerd!(0x01562BA3, sceAudioOutput2ReserveFunction));
		mixin(registerd!(0x2D53F36E, sceAudioOutput2OutputBlockingFunction));
		mixin(registerd!(0x43196845, sceAudioOutput2ReleaseFunction));
		mixin(registerd!(0xB011922F, sceAudioGetChannelRestLengthFunction));

		mixin(registerd!(0x086E5895, sceAudioInputBlocking));
		mixin(registerd!(0x7DE61688, sceAudioInputInit));
	}

	void initModule() {
		audio = new Audio;
		currentEmulatorState().display.onStop += delegate() {
			audio.stop();
		};
	}

	void shutdownModule() {
		audio.stop();
	}

	int freeChannelIndex() {
		foreach (n, ref channel; channels) {
			if (!channel.reserved) return n;
		}
		return -1;
	}

	bool validChannelIndex(int index) {
		return (index >= 0 && index < channels.length);
	}

	static float volumef(int shortval) { return (cast(float)shortval) / cast(float)0xFFFF; }

	// @TODO: Unknown.
	void sceAudioOutput2ReserveFunction() {
		unimplemented();
	}

	// @TODO: Unknown.
	void sceAudioOutput2OutputBlockingFunction() {
		unimplemented();
	}

	// @TODO: Unknown.
	void sceAudioOutput2ReleaseFunction() {
		unimplemented();
	}

	// @TODO: Unknown.
	void sceAudioGetChannelRestLengthFunction() {
		unimplemented();
	}

	int _sceAudioOutputPannedBlocking(int channel, int leftvol, int rightvol, void *buf, bool blocking) {
		// Invalid channel.
		if (!validChannelIndex(channel)) {
			Logger.log(Logger.Level.WARNING, "sceAudio_driver", "sceAudioOutputPannedBlocking.invalidChannel!");
			return -1;
		}
		
		auto cchannel = channels[channel];
		bool playing = true;

		Logger.log(Logger.Level.TRACE, "sceAudio_driver", "sceAudioOutputPannedBlocking(channel=%d, leftvol=%d, rightvol=%d, buf_length=%d)", channel, leftvol, rightvol, cchannel.dataCount);

		float toFloat(short sample) { return cast(float)sample / cast(float)(0x8000 - 1); }
		
		auto samples_short = (cast(short*)buf)[0..cchannel.dataCount];
		
		auto writeDelegate = delegate() {
			try {
				audio.writeWait(channel, cchannel.numchannels, samples_short, volumef(leftvol), volumef(rightvol));
			} catch (Throwable o) {
				Logger.log(Logger.Level.ERROR, "sceAudio_driver", "sceAudioOutputPannedBlocking: %s", o);
			}
			playing = false;
		};

		if (blocking) {
			currentThreadState().waitingBlock(writeDelegate);
		} else {
			Thread audioNonBlockingThread = new Thread(writeDelegate);
			audioNonBlockingThread.name = "audioNonBlockingThread";
			audioNonBlockingThread.start();
		}
		
		return 0;
	}

	/**
	  * Output panned audio of the specified channel (blocking)
	  *
	  * @param channel  - The channel number.
	  * @param leftvol  - The left volume.
	  * @param rightvol - The right volume.
	  * @param buf      - Pointer to the PCM data to output.
	  *
	  * @return 0 on success, an error if less than 0.
	  */
	int sceAudioOutputPannedBlocking(int channel, int leftvol, int rightvol, void* buf) {
		return _sceAudioOutputPannedBlocking(channel, leftvol, rightvol, buf, /*blocking = */ true);
	}
	
	/**
	 * Output panned audio of the specified channel
	 *
	 * @param channel  - The channel number.
	 * @param leftvol  - The left volume.
	 * @param rightvol - The right volume.
	 * @param buf      - Pointer to the PCM data to output.
	 *
	 * @return 0 on success, an error if less than 0.
	 */
	int sceAudioOutputPanned(int channel, int leftvol, int rightvol, void *buf) {
		return _sceAudioOutputPannedBlocking(channel, leftvol, rightvol, buf, /*blocking = */ false);
	}
	
	/**
	 * Output audio of the specified channel
	 *
	 * @param channel - The channel number.
	 * @param vol - The volume.
	 * @param buf - Pointer to the PCM data to output.
	 *
	 * @return 0 on success, an error if less than 0.
	 */
	int sceAudioOutput(int channel, int vol, void* buf) {
		return sceAudioOutputPanned(channel, vol, vol, buf);
	}

	/**
	 * Get count of unplayed samples remaining
	 *
	 * @param channel - The channel number.
	 *
	 * @return Number of samples to be played, an error if less than 0.
	 */
	int sceAudioGetChannelRestLen(int channel) {
		unimplemented();
		return -1;
	}

	/**
	 * Change the output sample count, after it's already been reserved
	 *
	 * @param channel     - The channel number.
	 * @param samplecount - The number of samples to output in one output call.
	 *
	 * @return 0 on success, an error if less than 0.
	 */
	int sceAudioSetChannelDataLen(int channel, int samplecount) {
		unimplemented();
		return -1;
	}

	/**
	 * Change the format of a channel
	 *
	 * @param channel - The channel number.
	 * @param format  - One of ::PspAudioFormats
	 *
	 * @return 0 on success, an error if less than 0.
	 */
	int sceAudioChangeChannelConfig(int channel, int format) {
		unimplemented();
		return -1;
	}
	
	/**
	 * Change the volume of a channel
	 *
	 * @param channel  - The channel number.
	 * @param leftvol  - The left volume.
	 * @param rightvol - The right volume.
	 *
	 * @return 0 on success, an error if less than 0.
	 */
	int sceAudioChangeChannelVolume(int channel, int leftvol, int rightvol) {
		unimplemented();
		return -1;
	}

	/**
	 * Output audio of the specified channel (blocking)
	 *
	 * @param channel - The channel number.
	 * @param vol     - The volume.
	 * @param buf     - Pointer to the PCM data to output.
	 *
	 * @return 0 on success, an error if less than 0.
	 */
	int sceAudioOutputBlocking(int channel, int vol, void* buf) {
		return sceAudioOutputPannedBlocking(channel, vol, vol, buf);
	}

	/**
	  * Allocate and initialize a hardware output channel.
	  *
	  * @param channel     - Use a value between 0 - 7 to reserve a specific channel.
	  *                      Pass PSP_AUDIO_NEXT_CHANNEL to get the first available channel.
	  * @param samplecount - The number of samples that can be output on the channel per
	  *                      output call.  It must be a value between ::PSP_AUDIO_SAMPLE_MIN
	  *                      and ::PSP_AUDIO_SAMPLE_MAX, and it must be aligned to 64 bytes
	  *                      (use the ::PSP_AUDIO_SAMPLE_ALIGN macro to align it).
	  * @param format      - The output format to use for the channel.  One of ::PspAudioFormats.
	  *
	  * @return The channel number on success, an error code if less than 0.
	  */
	int sceAudioChReserve(int channel, int samplecount, PspAudioFormats format) {
		// Select a free channel.
		if (channel == PSP_AUDIO_NEXT_CHANNEL) channel = freeChannelIndex;

		// Invalid channel.
		if (!validChannelIndex(channel)) return -1;

		// Sets the information of the channel.
		channels[channel] = Channel(true, samplecount, format);
		
		debug (DEBUG_AUDIO) writefln("sceAudioChReserve(channel=%d, samplecount=%d, format=%d)", channel, samplecount, format);

		// Returns the channel.
		return channel;
	}

	/**
	  * Release a hardware output channel.
	  *
	  * @param channel - The channel to release.
	  *
	  * @return 0 on success, an error if less than 0.
	  */
	int sceAudioChRelease(int channel) {
		if (!validChannelIndex(channel)) return -1;
		channels[channel].reserved = false;
		return 0;
	}

	/**
	 * Perform audio input (blocking)
	 *
	 * @param samplecount - Number of samples.
	 * @param freq        - Either 44100, 22050 or 11025.
	 * @param buf         - Pointer to where the audio data will be stored.
	 *
	 * @return 0 on success, an error if less than 0.
	 */
	int sceAudioInputBlocking(int samplecount, int freq, void* buf) {
		unimplemented();
		return -1;
	}

	/**
	 * Init audio input
	 *
	 * @param unknown1 - Unknown. Pass 0.
	 * @param gain - Gain.
	 * @param unknown2 - Unknown. Pass 0.
	 *
	 * @return 0 on success, an error if less than 0.
	 */
	int sceAudioInputInit(int unknown1, int gain, int unknown2) {
		unimplemented();
		return -1;
	}
}

static this() {
	mixin(ModuleNative.registerModule("sceAudio_driver"));
}
