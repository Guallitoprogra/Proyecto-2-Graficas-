const fb = @import("framebuffer.zig");

pub const Window = struct {
    hwnd: HWND,
    bitmap_info: BITMAPINFO,

    pub fn open(title: [:0]const u8) !Window {
        // Esta parte crea una ventana normal de Windows usando la API Win32.
        const class_name = "ProyectoGraficasWindow";
        const instance = GetModuleHandleA(null);

        const window_class = WNDCLASSA{
            .style = CS_HREDRAW | CS_VREDRAW,
            .lpfnWndProc = windowProc,
            .cbClsExtra = 0,
            .cbWndExtra = 0,
            .hInstance = instance,
            .hIcon = null,
            .hCursor = null,
            .hbrBackground = null,
            .lpszMenuName = null,
            .lpszClassName = class_name,
        };

        _ = RegisterClassA(&window_class);

        const hwnd = CreateWindowExA(
            0,
            class_name,
            title,
            WS_OVERLAPPEDWINDOW | WS_VISIBLE,
            CW_USEDEFAULT,
            CW_USEDEFAULT,
            960,
            640,
            null,
            null,
            instance,
            null,
        ) orelse return error.WindowCreateFailed;

        _ = ShowWindow(hwnd, SW_SHOW);
        _ = UpdateWindow(hwnd);

        return .{
            .hwnd = hwnd,
            .bitmap_info = makeBitmapInfo(),
        };
    }

    pub fn isOpen(self: *Window) bool {
        // Aqui se leen los mensajes de Windows para saber si la ventana sigue abierta.
        _ = self;
        var message: MSG = undefined;
        while (PeekMessageA(&message, null, 0, 0, PM_REMOVE) != 0) {
            if (message.message == WM_QUIT) return false;
            _ = TranslateMessage(&message);
            _ = DispatchMessageA(&message);
        }
        return true;
    }

    pub fn draw(self: *Window, framebuffer: *const fb.Framebuffer) void {
        // StretchDIBits copia nuestro framebuffer pequeno y lo escala al tamano de la ventana.
        var rect: RECT = undefined;
        if (GetClientRect(self.hwnd, &rect) == 0) return;

        const window_width = rect.right - rect.left;
        const window_height = rect.bottom - rect.top;
        const hdc = GetDC(self.hwnd) orelse return;
        defer _ = ReleaseDC(self.hwnd, hdc);

        _ = StretchDIBits(
            hdc,
            0,
            0,
            window_width,
            window_height,
            0,
            0,
            fb.screen_width,
            fb.screen_height,
            &framebuffer.pixels,
            &self.bitmap_info,
            DIB_RGB_COLORS,
            SRCCOPY,
        );
    }
};

pub fn waitMilliseconds(ms: u32) void {
    Sleep(ms);
}

pub fn nowMilliseconds() u64 {
    return GetTickCount64();
}

pub fn isKeyDown(key: i32) bool {
    return GetAsyncKeyState(key) < 0;
}

fn makeBitmapInfo() BITMAPINFO {
    return .{
        .bmiHeader = .{
            .biSize = @sizeOf(BITMAPINFOHEADER),
            .biWidth = fb.screen_width,
            .biHeight = -fb.screen_height,
            .biPlanes = 1,
            .biBitCount = 32,
            .biCompression = BI_RGB,
            .biSizeImage = 0,
            .biXPelsPerMeter = 0,
            .biYPelsPerMeter = 0,
            .biClrUsed = 0,
            .biClrImportant = 0,
        },
        .bmiColors = .{.{ .rgbBlue = 0, .rgbGreen = 0, .rgbRed = 0, .rgbReserved = 0 }},
    };
}

fn windowProc(hwnd: HWND, message: UINT, w_param: WPARAM, l_param: LPARAM) callconv(.winapi) LRESULT {
    switch (message) {
        WM_CLOSE => {
            _ = DestroyWindow(hwnd);
            return 0;
        },
        WM_DESTROY => {
            PostQuitMessage(0);
            return 0;
        },
        else => return DefWindowProcA(hwnd, message, w_param, l_param),
    }
}

const HWND = ?*opaque {};
const HINSTANCE = ?*opaque {};
const HICON = ?*opaque {};
const HCURSOR = ?*opaque {};
const HBRUSH = ?*opaque {};
const HMENU = ?*opaque {};
const HDC = ?*opaque {};
const BOOL = i32;
const UINT = u32;
const DWORD = u32;
const WORD = u16;
const ATOM = WORD;
const WPARAM = usize;
const LPARAM = isize;
const LRESULT = isize;
const LPCSTR = [*:0]const u8;
const WNDPROC = *const fn (HWND, UINT, WPARAM, LPARAM) callconv(.winapi) LRESULT;

const POINT = extern struct {
    x: i32,
    y: i32,
};

const MSG = extern struct {
    hwnd: HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
};

const WNDCLASSA = extern struct {
    style: UINT,
    lpfnWndProc: WNDPROC,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: HINSTANCE,
    hIcon: HICON,
    hCursor: HCURSOR,
    hbrBackground: HBRUSH,
    lpszMenuName: ?LPCSTR,
    lpszClassName: LPCSTR,
};

const RECT = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

const RGBQUAD = extern struct {
    rgbBlue: u8,
    rgbGreen: u8,
    rgbRed: u8,
    rgbReserved: u8,
};

const BITMAPINFOHEADER = extern struct {
    biSize: DWORD,
    biWidth: i32,
    biHeight: i32,
    biPlanes: WORD,
    biBitCount: WORD,
    biCompression: DWORD,
    biSizeImage: DWORD,
    biXPelsPerMeter: i32,
    biYPelsPerMeter: i32,
    biClrUsed: DWORD,
    biClrImportant: DWORD,
};

const BITMAPINFO = extern struct {
    bmiHeader: BITMAPINFOHEADER,
    bmiColors: [1]RGBQUAD,
};

const CS_VREDRAW = 0x0001;
const CS_HREDRAW = 0x0002;
const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000));
const WS_OVERLAPPEDWINDOW = 0x00CF0000;
const WS_VISIBLE = 0x10000000;
const SW_SHOW = 5;
const WM_CLOSE = 0x0010;
const WM_DESTROY = 0x0002;
const WM_QUIT = 0x0012;
const PM_REMOVE = 0x0001;
const BI_RGB = 0;
const DIB_RGB_COLORS = 0;
const SRCCOPY = 0x00CC0020;

extern "kernel32" fn GetModuleHandleA(lpModuleName: ?LPCSTR) callconv(.winapi) HINSTANCE;
extern "kernel32" fn Sleep(dwMilliseconds: DWORD) callconv(.winapi) void;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
extern "user32" fn GetAsyncKeyState(vKey: i32) callconv(.winapi) i16;
extern "user32" fn RegisterClassA(lpWndClass: *const WNDCLASSA) callconv(.winapi) ATOM;
extern "user32" fn CreateWindowExA(dwExStyle: DWORD, lpClassName: LPCSTR, lpWindowName: LPCSTR, dwStyle: DWORD, x: i32, y: i32, nWidth: i32, nHeight: i32, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: ?*anyopaque) callconv(.winapi) HWND;
extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(.winapi) BOOL;
extern "user32" fn UpdateWindow(hWnd: HWND) callconv(.winapi) BOOL;
extern "user32" fn PeekMessageA(lpMsg: *MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) callconv(.winapi) BOOL;
extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) BOOL;
extern "user32" fn DispatchMessageA(lpMsg: *const MSG) callconv(.winapi) LRESULT;
extern "user32" fn DefWindowProcA(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(.winapi) void;
extern "user32" fn DestroyWindow(hWnd: HWND) callconv(.winapi) BOOL;
extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) BOOL;
extern "user32" fn GetDC(hWnd: HWND) callconv(.winapi) HDC;
extern "user32" fn ReleaseDC(hWnd: HWND, hDC: HDC) callconv(.winapi) i32;
extern "gdi32" fn StretchDIBits(hdc: HDC, xDest: i32, yDest: i32, DestWidth: i32, DestHeight: i32, xSrc: i32, ySrc: i32, SrcWidth: i32, SrcHeight: i32, lpBits: *const anyopaque, lpbmi: *const BITMAPINFO, iUsage: UINT, rop: DWORD) callconv(.winapi) i32;
