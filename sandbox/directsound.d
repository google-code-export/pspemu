import std.c.windows.windows;
import std.c.windows.com;
import std.stdio;

pragma(lib, "ole32.lib");

/**
 * http://ftp.san.ru/unix/soft.cvs/wine.git/wine-git/dlls/quartz/tests/dsoundrender.c
 * http://www.flipcode.com/archives/DirectShow_For_Media_Playback_In_Windows-Part_III_Customizing_Graphs.shtml
 */

const uint COINIT_MULTITHREADED = 0x0;

static const GUID CLSID_DSoundRender = {0x79376820, 0x07D0, 0x11CF, [0xA2, 0x4D, 0x0, 0x20, 0xAF, 0xD7, 0x97, 0x67]};

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

//LPDIRECTSOUND directSound;

extern (Windows) {
	HRESULT CoInitializeEx(void* pvReserved, DWORD dwCoInit);
	HRESULT function(LPGUID lpGuid, LPDIRECTSOUND * ppDS, LPUNKNOWN pUnkOuter) DirectSoundCreate;
}


int main(string[] args) {
	if (FAILED(CoInitializeEx(null, COINIT_MULTITHREADED))) {
		writefln("Error CoInitializeEx");
		return -1;
	}
	
	LPUNKNOWN dsoundRender;
	
	if (FAILED(CoCreateInstance(&CLSID_DSoundRender, null, 1u, &IID_IUnknown, cast(void *)&dsoundRender))) {
		writefln("Error DSoundRender");
		return -1;
	}
	
	dsoundRender.AddRef();
	dsoundRender.QueryInterface(null, null);
	dsoundRender.Release();
	
	//writefln("%08X", cast(uint)cast(void *)&dsoundRender.AddRef);
	//writefln("%08X", cast(uint)cast(void *)&dsoundRender.QueryInterface);
	
	/*
	auto lib = LoadLibraryA("dsound.dll");
	DirectSoundCreate = cast(typeof(DirectSoundCreate))GetProcAddress(lib, "DirectSoundCreate");
	//writefln("%08X, %08X", cast(uint)lib, cast(uint)DirectSoundCreate);
	
	CLSID_DSoundRender
	
	if (FAILED(DirectSoundCreate(null, &directSound, null))) {
		writefln("Error DirectSoundCreate");
		return -1;
	}
	
	//ulong v;
	
	//directSound.GetCaps(&v);
	writefln("%08X", cast(uint)cast(void *)&(directSound.GetCaps));
	writefln("%08X", cast(uint)cast(void *)&(directSound.AddRef));
	writefln("%08X", cast(uint)cast(void *)&(directSound.Release));
	*/
	
	return 0;
}
