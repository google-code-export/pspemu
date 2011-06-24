module pspemu.utils.Path;

import std.path;
import std.c.windows.windows;
import std.windows.registry;
import std.string;
import std.process;

//import dfl.all;

class ApplicationPaths {
	__gshared string executablePath;
	__gshared string startupPath;
	
	@property static void initialize(string[] args) {
		ApplicationPaths.executablePath = args[0];
		ApplicationPaths.startupPath = current();
	}
	
	@property static string exe() {
		return std.path.rel2abs(cast(string)std.path.dirname(executablePath));
	}

	@property static string current() {
		return cast(string)std.path.curdir;
	}

	@property static string startup() {
		return startupPath;
	}

	/*@property static string userAppData() {
		return cast(string)Application.userAppDataBasePath;
	}*/
}

extern (Windows) BOOL ShellExecuteEx(void* lpExecInfo);

void RunAsAdmin(string lpFile, string lpParameters = "", HWND hWnd = cast(HWND)null) {
	static struct SHELLEXECUTEINFOW {
		DWORD     cbSize;
		ULONG     fMask;
		HWND      hwnd;
		LPCTSTR   lpVerb;
		LPCTSTR   lpFile;
		LPCTSTR   lpParameters;
		LPCTSTR   lpDirectory;
		int       nShow;
		HINSTANCE hInstApp;
		LPVOID    lpIDList;
		LPCTSTR   lpClass;
		HKEY      hkeyClass;
		DWORD     dwHotKey;
		union {
			HANDLE hIcon;
			HANDLE hMonitor;
		}
		HANDLE    hProcess;
	}

    SHELLEXECUTEINFOW sei;

    sei.cbSize          = SHELLEXECUTEINFOW.sizeof;
    sei.hwnd            = hWnd;
    sei.fMask           = 0x00000100 | 0x00000400; // SEE_MASK_FLAG_DDEWAIT | SEE_MASK_FLAG_NO_UI
    sei.lpVerb          = "runas";
    sei.lpFile          = std.string.toStringz(lpFile);
    sei.lpParameters    = std.string.toStringz(lpParameters);
    sei.nShow           = SW_HIDE;

    if (!ShellExecuteEx(&sei)) throw(new Exception("ShellExecuteEx failed"));
}

//LoadIconA(32518);

/+void SetUacShield(HWND hwnd) {
	SendMessageA(hwnd, 0x0000160c/*BCM_SETSHIELD*/, 0, 1);
}+/
