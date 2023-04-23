const std = @import("std");
const display = @import("Display.zig");
const signal = @import("Signal.zig");
const el = @import("EventLoop.zig");
const String = @import("String.zig");
const CodePoint = String.CodePoint;
const Face = display.Face;
const Colour = display.Colour;
pub const horizontalBlockChars = [_]CodePoint{
    //0x20, //  space
    0x258F, // 1/8
    0x258E, // 1/4
    0x258D, // 3/8
    0x258C, // 1/2
    0x258B, // 5/8
    0x258A, // 3/4
    0x2589, // 7/8
    0x2588, // FULL
};

pub const verticalBlockChars = [_]CodePoint{
    //0x20, // SPACE
    0x2581, // 1/8
    0x2582, // 1/4
    0x2583, // 3/8
    0x2584, // 1/2
    0x2585, // 5/8
    0x2586, // 3/4
    0x2587, // 7/8
    0x2588, // FULL
};

pub const shades = [_]CodePoint{
    0x20,
    0x2591, //light
    0x2592, //medium
    0x2593, //dark
    0x2588, //FULL
};

const all = horizontalBlockChars ++ verticalBlockChars ++ shades;

const blocks = [16][]const CodePoint{
    &.{0x20}, //NONE
    &.{ 0x2574, 0x2578 }, //LEFT
    &.{ 0x2575, 0x2579 }, //UP
    &.{ 0x2576, 0x257A }, //RIGHT
    &.{ 0x2577, 0x257B }, //DOWN
    &.{ 0x2503, 0x257D, 0x257F, 0x2503 }, //UPDOWN
    &.{ 0x2500, 0x257C, 0x257E, 0x2501 }, //LEFTRIGHT
    &.{ 0x250C, 0x250D, 0x250E, 0x250F }, //DOWNRIGHT
    &.{ 0x2510, 0x2511, 0x2512, 0x2513 }, //DOWNLEFT
    &.{ 0x2514, 0x2515, 0x2516, 0x2517 }, //UPRIGHT
    &.{ 0x2518, 0x2519, 0x251A, 0x251B }, //UPLEFT
    &.{ 0x251C, 0x251D, 0x251E, 0x251F, 0x2520, 0x2521, 0x2522, 0x2523 }, //UPDOWNRIGHT
    &.{ 0x2524, 0x2525, 0x2526, 0x2527, 0x2528, 0x2529, 0x252A, 0x252B }, //UPDOWNLEFT
    &.{ 0x252C, 0x252D, 0x252E, 0x252F, 0x2530, 0x2531, 0x2532, 0x2533 }, //LEFTRIGHTDOWN
    &.{ 0x2534, 0x2535, 0x2536, 0x2537, 0x2538, 0x2539, 0x253A, 0x253B }, //LEFTRIGHTUP
    &.{ 0x253c, 0x253d, 0x253e, 0x253f, 0x2540, 0x2541, 0x2542, 0x2543, 0x2544, 0x2545, 0x2546, 0x2547, 0x2548, 0x2549, 0x254A, 0x254B }, //ALL
};
const CSI = "\x1B[";
const DCS = "\x1BP";
const SetFG = CSI ++ "38;";
const SetBG = CSI ++ "48;";
pub fn getBlockVertical(size: u3) CodePoint {
    return verticalBlockChars[size];
}

pub fn getBlockHorizontal(size: u3) CodePoint {
    return horizontalBlockChars[size];
}

fn setColor(writer: anytype, face: Face) !void {
    try std.fmt.format(writer, SetFG ++ "2;{};{};{}m" ++ SetBG ++ "2;{};{};{}m", .{
        face.fg.red,
        face.fg.green,
        face.fg.blue,
        face.bg.red,
        face.bg.green,
        face.bg.blue,
    });
}

pub fn resetColour(writer: anytype) !void {
    try std.fmt.format(writer, CSI ++ "0m", .{});
}

pub const Terminal = struct {
    alloc: std.mem.Allocator,
    stdin: std.fs.File,
    stdout: std.fs.File,
    signal: *signal.SignalFd,
    pub fn init(alloc: std.mem.Allocator, event: *el.EventLoop) !*Terminal {
        var t = try alloc.create(Terminal);
        errdefer alloc.destroy(t);
        var stdin = std.io.getStdIn();
        if (std.os.isatty(stdin.handle) == false) {
            return error.Invalidtty;
        }
        var stdout = std.io.getStdOut();
        var signal = Signal.Signal.init();
        signal.addHandler(std.os.SIG.WINCH, .{ .ctx = t, .func = &sigWinchRead });
        t.* = .{
            .alloc = alloc,
            .stdin = stdin,
            .stdout = stdout,
            .signal = try signal.createSignalFd(alloc),
        };
        try el.addHandler(.{
            .fd = stdin.fd,
            .ctx = t,
            .read = &stdinHandleRead,
            .err = &stdinHandleExit,
            .exit = &stdinHandleExit,
        });

        return t;
        //
    }
    fn stdinHandleRead(ctx: *anyopaque, fd: std.os.fd_t) el.HandlerError!el.HandlerResult {}
    fn stdinHandleExit(ctx: *anyopaque, fd: std.os.fd_t) el.HandlerError!el.HandlerResult {}

    fn sigWinchRead(ctx: *anyopaque, sig: u32, data: i32) el.HandlerError!el.HandlerResult {}
};

test {
    var stdout = std.io.getStdOut();
    var writer = stdout.writer();
    for (blocks) |b| {
        for (b) |item| {
            try std.fmt.format(writer, "{s}", .{String.CPFmt(item)});
        }
        try std.fmt.format(writer, "\n", .{});
    }
    for (all) |item| {
        try std.fmt.format(writer, "{s}\n", .{String.CPFmt(item)});
    }
}
