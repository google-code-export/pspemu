import std.c.windows.windows;
import std.c.windows.com;
import std.stdio;

pragma(lib, "ole32.lib");

const uint COINIT_MULTITHREADED = 0x0;

alias void* LPCDSBUFFERDESC;
alias void* LPLPDIRECTSOUNDBUFFER;
alias void* LPDIRECTSOUNDBUFFER;
alias void* LPDSCAPS;
alias GUID* LPGUID;

extern (System) {
	interface IDirectSound : IUnknown {
	    // IDirectSound methods
	    HRESULT CreateSoundBuffer    (LPCDSBUFFERDESC lpcDSBufferDesc, LPLPDIRECTSOUNDBUFFER lplpDirectSoundBuffer, IUnknown* pUnkOuter );
	    HRESULT GetCaps              (LPDSCAPS lpDSCaps);
	    HRESULT DuplicateSoundBuffer (LPDIRECTSOUNDBUFFER, LPDIRECTSOUNDBUFFER *);
	    HRESULT SetCooperativeLevel  (HWND, DWORD);
	    HRESULT Compact              ();
	    HRESULT GetSpeakerConfig     (LPDWORD);
	    HRESULT SetSpeakerConfig     (DWORD);
	    HRESULT Initialize           (LPGUID);
	}
}

alias IDirectSound LPDIRECTSOUND;
alias IUnknown     LPUNKNOWN;

LPDIRECTSOUND directSound;

extern (Windows) {
	HRESULT CoInitializeEx(void* pvReserved, DWORD dwCoInit);
	HRESULT function(LPGUID lpGuid, LPDIRECTSOUND * ppDS, LPUNKNOWN pUnkOuter) DirectSoundCreate;
}


int main(string[] args) {
	if (FAILED(CoInitializeEx(null, COINIT_MULTITHREADED))) {
		writefln("Error CoInitializeEx");
		return -1;
	}
	
	auto lib = LoadLibraryA("dsound.dll");
	DirectSoundCreate = cast(typeof(DirectSoundCreate))GetProcAddress(lib, "DirectSoundCreate");
	//writefln("%08X, %08X", cast(uint)lib, cast(uint)DirectSoundCreate);
	
	if (FAILED(DirectSoundCreate(null, &directSound, null))) {
		writefln("Error DirectSoundCreate");
		return -1;
	}
	
	//ulong v;
	
	//directSound.GetCaps(&v);
	writefln("%08X", cast(uint)cast(void *)&(directSound.GetCaps));
	writefln("%08X", cast(uint)cast(void *)&(directSound.AddRef));
	writefln("%08X", cast(uint)cast(void *)&(directSound.Release));
	
	return 0;
}
