const std = @import("std");

pub fn main() void {
    if (0 == RegisterHotKey(null, 0, 0x4003, 0x2D)) return; // MOD_NOREPEAT | MOD_CTRL | MOD_SHIFT          , VK_INSERT
    if (0 == RegisterHotKey(null, 1, 0x4007, 0x2D)) return; // MOD_NOREPEAT | MOD_CTRL | MOD_SHIFT | MOD_ALT, VK_INSERT
    var msg: MSG = undefined;
    while (msg.get(null, 0, 0) > 0) {
        defer _ = msg.dispatch();
        if (0x0312 == msg.message) { // WM_HOTKEY
            var fmt_str: []const u8 = undefined;
            var inputs: [256]INPUT = undefined;
            var time: SYSTEMTIME = undefined;
            var buf: [256]u8 = undefined;
            switch (msg.wParam) {
                else => continue,
                0 => {
                    time.getLocal();
                    fmt_str = std.fmt.bufPrint(&buf, "{d}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}", .{ time.wYear, time.wMonth, time.wDay, time.wHour, time.wMinute, time.wSecond }) catch continue;
                },
                1 => {
                    time.getSystem();
                    fmt_str = std.fmt.bufPrint(&buf, "{d}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}Z", .{ time.wYear, time.wMonth, time.wDay, time.wHour, time.wMinute, time.wSecond }) catch continue;
                },
            }
            for (fmt_str, 0..) |char, i| {
                inputs[2*i..][0..2].* = .{
                    .ki(.{ .wScan = char, .dwFlags = 4 }),
                    .ki(.{ .wScan = char, .dwFlags = 6 }),
                };
            }
            INPUT.send(inputs[0..2*fmt_str.len]);
        }
    }
}

extern "user32" fn RegisterHotKey(?HWND, i32, u32, u32) callconv(.winapi) i32;
extern "user32" fn SendInput(u32, [*]const INPUT, i32) callconv(.winapi) u32;
extern "user32" fn GetMessageA(*MSG, ?HWND, u32, u32) callconv(.winapi) i32;
extern "user32" fn DispatchMessageA(*const MSG) callconv(.winapi) isize;
extern "kernel32" fn GetSystemTime(*SYSTEMTIME) callconv(.winapi) void;
extern "kernel32" fn GetLocalTime(*SYSTEMTIME) callconv(.winapi) void;

const HWND = std.os.windows.HWND;

const INPUT = extern struct {
    type: u32,
    input: extern union {
        mi: MOUSEINPUT,
        ki: KEYBDINPUT,
        hi: HARDWAREINPUT,
    },
    const MOUSEINPUT = extern struct {
        dx: i32 = 0,
        dy: i32 = 0,
        mouseData: i32 = 0,
        dwFlags: u32 = 0,
        time: u32 = 0,
        dwExtraInfo: usize = 0,
    };
    const KEYBDINPUT = extern struct {
        wVK: u16 = 0,
        wScan: u16 = 0,
        dwFlags: u32 = 0,
        time: u32 = 0,
        dwExtraInfo: usize = 0,
    };
    const HARDWAREINPUT = extern struct {
        uMsg: u32 = 0,
        wParamL: u16 = 0,
        wParamH: u16 = 0,
    };
    fn mi(m: MOUSEINPUT)    INPUT { return .{ .type = 0, .input = .{.mi = m} }; }
    fn ki(k: KEYBDINPUT)    INPUT { return .{ .type = 1, .input = .{.ki = k} }; }
    fn hi(h: HARDWAREINPUT) INPUT { return .{ .type = 2, .input = .{.hi = h} }; }
    fn send(inputs: []const INPUT) void {
        _ = SendInput(@truncate(inputs.len), inputs.ptr, @sizeOf(INPUT));
    }
};

const MSG = extern struct {
    hWnd: ?HWND,
    message: u32,
    wParam: usize,
    lParam: isize,
    time: u32,
    pt: [2]i32,
    lPrivate: u32,
    const get = GetMessageA;
    const dispatch = DispatchMessageA;
};

const SYSTEMTIME = extern struct {
    wYear: u16,
    wMonth: u16,
    wDayOfWeek: u16,
    wDay: u16,
    wHour: u16,
    wMinute: u16,
    wSecond: u16,
    wMilliseconds: u16,
    const getLocal = GetLocalTime;
    const getSystem = GetSystemTime;
};