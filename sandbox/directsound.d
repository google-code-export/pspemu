import std.c.windows.windows;
import std.c.windows.com;
import std.stdio;
import std.conv;
import std.string;
import std.array;

pragma(lib, "ole32.lib");

const uint COINIT_MULTITHREADED = 0x0;
const uint CLSCTX_INPROC_SERVER = 1u;

extern (Windows) {
	HRESULT CoInitializeEx(void* pvReserved, DWORD dwCoInit);
}

/**
 * http://ftp.san.ru/unix/soft.cvs/wine.git/wine-git/dlls/quartz/tests/dsoundrender.c
 * http://www.flipcode.com/archives/DirectShow_For_Media_Playback_In_Windows-Part_III_Customizing_Graphs.shtml
 * http://www.codeproject.com/KB/audio-video/dshowencoder.aspx
 * http://msdn.microsoft.com/en-us/library/dd389098(v=vs.85).aspx
 */

static const GUID CLSID_OpenMGOmgSourceFilter = { 0x855FBD04, 0x8AD5, 0x40B2, [ 0xAA, 0x34, 0xA6, 0x58, 0x1E, 0x59, 0x83, 0x1C ] };
static const GUID CLSID_OMG_TRANSFORM         = { 0x98660581, 0xC9A8, 0x4C92, [ 0xB4, 0x80, 0xF2, 0x7D, 0xE3, 0xC3, 0xAA, 0xB4 ] };
static const GUID CLSID_WavDest               = { 0x3c78b8e2, 0x6c4d, 0x11d1, [ 0xad, 0xe2, 0x00, 0x00, 0xf8, 0x75, 0x4b, 0x99 ] };
static const GUID CLSID_File_writer           = { 0x8596E5F0, 0x0DA5, 0x11D0, [ 0xBD, 0x21, 0x00, 0xA0, 0xC9, 0x11, 0xCE, 0x86 ] };




/*
_DATA:00000000 _IID_IUnknown   dd 0
_DATA:00000004                 dd 0
_DATA:00000008                 dd 0C0h
_DATA:0000000C                 dd 46000000h

*/

alias void* IReferenceClock;
alias void* IEnumMediaTypes;
alias void* IEnumFilters;

alias void* REFERENCE_TIME;
alias void* FILTER_INFO;
alias void* FILTER_STATE;
alias uint AM_MEDIA_TYPE;

enum PIN_DIRECTION : uint {
	PINDIR_INPUT  = 0,
	PINDIR_OUTPUT = PINDIR_INPUT + 1
}

struct PIN_INFO {
	IBaseFilter *pFilter;
	PIN_DIRECTION dir;
	wchar achName[128];
	
	string toString() {
		return std.string.format("PIN_INFO('%s', '%s')", achName[0..std.string.indexOf(achName, cast(wchar)0)], to!string(dir));
	}
}

alias DWORD* DWORD_PTR;

extern (System) {
    //MIDL_INTERFACE("")
    static const IID IID_IFileSourceFilter = { 0x56a868a6, 0x0ad4, 0x11ce, [ 0xb0, 0x3a, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70 ] };
    interface IFileSourceFilter : IUnknown {
        HRESULT Load(LPCOLESTR pszFileName, const AM_MEDIA_TYPE *pmt);
        HRESULT GetCurFile(LPOLESTR *ppszFileName, AM_MEDIA_TYPE *pmt);
    };
    
    static const IID IID_IFileSinkFilter = { 0xa2104830, 0x7c70, 0x11cf, [ 0x8b, 0xce, 0x00, 0xaa, 0x00, 0xa3, 0xf1, 0xa6 ] };
    interface IFileSinkFilter : IUnknown {
    	HRESULT SetFileName(LPCOLESTR pszFileName, const AM_MEDIA_TYPE *pmt);
        HRESULT GetCurFile(LPOLESTR *ppszFileName, AM_MEDIA_TYPE *pmt);
    };
	
	//MIDL_INTERFACE("56a86891-0ad4-11ce-b03a-0020af0ba770")
    interface IPin : IUnknown {
		HRESULT Connect(IPin *pReceivePin, const AM_MEDIA_TYPE *pmt);
		HRESULT ReceiveConnection(IPin *pConnector, const AM_MEDIA_TYPE *pmt);
		HRESULT Disconnect();
		HRESULT ConnectedTo(IPin **pPin);
		HRESULT ConnectionMediaType(AM_MEDIA_TYPE *pmt);
		HRESULT QueryPinInfo(PIN_INFO *pInfo);
		HRESULT QueryDirection(PIN_DIRECTION *pPinDir);
		HRESULT QueryId(LPWSTR *Id);
		HRESULT QueryAccept(const AM_MEDIA_TYPE *pmt);
		HRESULT EnumMediaTypes(IEnumMediaTypes **ppEnum);
        HRESULT QueryInternalConnections(IPin **apPin, ULONG *nPin);
        HRESULT EndOfStream();
        HRESULT BeginFlush();
        HRESULT EndFlush();
        HRESULT NewSegment(REFERENCE_TIME tStart, REFERENCE_TIME tStop, double dRate);
    };
    
    //MIDL_INTERFACE("56a86892-0ad4-11ce-b03a-0020af0ba770")
    interface IEnumPins : IUnknown {
        HRESULT Next(ULONG cPins, IPin* ppPins, ULONG *pcFetched);
        HRESULT Skip(ULONG cPins);
        HRESULT Reset();
        HRESULT Clone(IEnumPins **ppEnum);
    };

	//MIDL_INTERFACE("56a8689f-0ad4-11ce-b03a-0020af0ba770")
    interface IFilterGraph : IUnknown {
        HRESULT AddFilter(IBaseFilter pFilter, LPCWSTR pName);
        HRESULT RemoveFilter(IBaseFilter *pFilter);
        HRESULT EnumFilters(IEnumFilters **ppEnum);
        HRESULT FindFilterByName(LPCWSTR pName, IBaseFilter **ppFilter);
        HRESULT ConnectDirect(IPin *ppinOut, IPin *ppinIn, const AM_MEDIA_TYPE *pmt);
        HRESULT Reconnect(IPin *ppin);
        HRESULT Disconnect(IPin *ppin);
        HRESULT SetDefaultSyncSource();
    };
    
    static const IID IID_IGraphBuilder = { 0x56a868a9, 0x0ad4, 0x11ce, [0xb0, 0x3a, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70] };
    interface IGraphBuilder : IFilterGraph {
        HRESULT Connect(IPin ppinOut, IPin ppinIn);
        HRESULT Render(IPin ppinOut);
        HRESULT RenderFile(LPCWSTR lpcwstrFile, LPCWSTR lpcwstrPlayList);
        HRESULT AddSourceFilter( LPCWSTR lpcwstrFileName, LPCWSTR lpcwstrFilterName, IBaseFilter **ppFilter);
        HRESULT SetLogFile(DWORD_PTR hFile);
        HRESULT Abort();
        HRESULT ShouldOperationContinue();
    };
	
	static const IID IID_IPersist     = { 0x0000010c, 0x0000, 0x0000, [0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 ] };
    interface IPersist : IUnknown {
        HRESULT GetClassID(CLSID *pClassID);
    }

	static const IID IID_IMediaFilter = { 0x56a86899, 0x0ad4, 0x11ce, [0xb0, 0x3a, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70] };
    interface IMediaFilter : IPersist {
        HRESULT Stop();
        HRESULT Pause();
        HRESULT Run(REFERENCE_TIME tStart);
        HRESULT GetState(DWORD dwMilliSecsTimeout, FILTER_STATE *State);
        HRESULT SetSyncSource(IReferenceClock *pClock);
        HRESULT GetSyncSource(IReferenceClock **pClock);
        
    };
	
	static const IID IID_IBaseFilter = { 0x56A86895, 0x0AD4, 0x11CE, [0xB0, 0x3A, 0x00, 0x20, 0xAF, 0x0B, 0xA7, 0x70 ] };
    interface IBaseFilter : IMediaFilter {
        HRESULT EnumPins(IEnumPins *ppEnum);
        HRESULT FindPin(LPCWSTR Id, IPin *ppPin);
        HRESULT QueryFilterInfo(FILTER_INFO *pInfo);
        HRESULT JoinFilterGraph(IFilterGraph pGraph, LPCWSTR pName);
        HRESULT QueryVendorInfo(LPWSTR *pVendorInfo);
    };

}

alias void* LPCDSBUFFERDESC;
alias void* LPLPDIRECTSOUNDBUFFER;
alias void* LPDIRECTSOUNDBUFFER;
alias void* LPDSCAPS;
alias GUID* LPGUID;
alias IDirectSound LPDIRECTSOUND;
alias IUnknown     LPUNKNOWN;

extern (System) {
	static const GUID CLSID_DSoundRender = {0x79376820, 0x07D0, 0x11CF, [0xA2, 0x4D, 0x0, 0x20, 0xAF, 0xD7, 0x97, 0x67]};
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


static const GUID CLSID_FilterGraph = { 0xe436ebb3, 0x524f, 0x11ce, [ 0x9f, 0x53, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70 ] };

IGraphBuilder graphBuilder;
IBaseFilter sourceFilter;
IBaseFilter omgTransform;
IBaseFilter waveDest;
IBaseFilter fileWriter;

/*
extern (C) {
    extern IID IID_IBaseFilter;
}
*/



int main(string[] args) {
	/*
	OpenMG OmgSource Filter
	File name: c:\program files\common files\sony shared\openmg\omgsrc.ax
	CLSID: {855FBD04-8AD5-40B2-AA34-A6581E59831C}
	Merit: 00600000 = MERIT_NORMAL
	*/
	
	if (FAILED(CoInitializeEx(null, COINIT_MULTITHREADED))) {
		writefln("Error CoInitializeEx");
		return -1;
	}
	
	if (FAILED(CoCreateInstance(&CLSID_FilterGraph, null, CLSCTX_INPROC_SERVER, &IID_IGraphBuilder, cast(void*)&graphBuilder))) {
		writefln("Failed to create CLSID_FilterGraph");
		return -1;
	}
	
	if (FAILED(CoCreateInstance(&CLSID_OpenMGOmgSourceFilter, null, CLSCTX_INPROC_SERVER, &IID_IBaseFilter, cast(void*)&sourceFilter))) {
		writefln("Failed to create CLSID_OpenMGOmgSourceFilter");
		return -1;
	}

	if (FAILED(CoCreateInstance(&CLSID_OMG_TRANSFORM, null, CLSCTX_INPROC_SERVER, &IID_IBaseFilter, cast(void*)&omgTransform))) {
		writefln("Failed to create CLSID_OMG_TRANSFORM");
		return -1;
	}

	if (FAILED(CoCreateInstance(&CLSID_WavDest, null, CLSCTX_INPROC_SERVER, &IID_IBaseFilter, cast(void*)&waveDest))) {
		writefln("Failed to create CLSID_WavDest");
		return -1;
	}

	if (FAILED(CoCreateInstance(&CLSID_File_writer, null, CLSCTX_INPROC_SERVER, &IID_IBaseFilter, cast(void*)&fileWriter))) {
		writefln("Failed to create CLSID_File_writer");
		return -1;
	}
	
	IFileSourceFilter fileSourceFilter;
	sourceFilter.QueryInterface(&IID_IFileSourceFilter, cast(void**)&fileSourceFilter);
	
	IFileSinkFilter fileSinkFilter;
	fileWriter.QueryInterface(&IID_IFileSinkFilter, cast(void**)&fileSinkFilter);
	
	fileSourceFilter.Load(cast(wchar *)"1.oma\0", null);
	fileSinkFilter.SetFileName(cast(wchar *)"1.wav\0", null);

	graphBuilder.AddFilter(sourceFilter, null);
	graphBuilder.AddFilter(omgTransform, null);
	graphBuilder.AddFilter(waveDest, null);
	graphBuilder.AddFilter(fileWriter, null);
	
	//IEnumPins enumPins;
	IPin      SourceOutPin;
	IPin      OmgTransformInPin;
	IPin      OmgTransformOutPin;
	IPin      WavDestInPin;
	IPin      WavDestOutPin;
	IPin      FileWriterInPin;
	//ULONG     fetched;
	//sourceFilter.EnumPins(&enumPins);
	
	sourceFilter.FindPin("Output", &SourceOutPin);
	omgTransform.FindPin("Input", &OmgTransformInPin);
	graphBuilder.Connect(SourceOutPin, OmgTransformInPin);
	
	omgTransform.FindPin("Output", &OmgTransformOutPin);
	omgTransform.FindPin("In", &WavDestInPin);
	graphBuilder.Connect(OmgTransformOutPin, WavDestInPin);

	omgTransform.FindPin("Out", &WavDestOutPin);
	omgTransform.FindPin("in", &FileWriterInPin);
	graphBuilder.Connect(WavDestOutPin, FileWriterInPin);
	
	graphBuilder.Render(SourceOutPin);
	
	//graphBuilder.ren
	//graphBuilder.Render();
	
	//FindPin
	
	//enumPins.Reset();
	//enumPins.Next(1, &OutPin, &fetched);
	//enumPins.Release();

	/*	
	PIN_INFO pinInfo;
	OutPin.QueryPinInfo(&pinInfo);
	
	writefln("%s", pinInfo);
	*/
	

	return 0;
}

/+




//LPDIRECTSOUND directSound;


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
+/