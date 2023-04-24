const std = @import("std");
const display = @import("Display.zig");
const sig = @import("Signal.zig");
const el = @import("EventLoop.zig");
const String = @import("String.zig");
const mkc = @import("MkedCore.zig");
const CodePoint = String.CodePoint;

const altScreenEnable = "\x1b[?1049h";
const altScreenDisable = "\x1b[?1049l";

const mouseButtonEnable = "\x1b[?1002h";
const mouseButtonDisable = "\x1b[?1002l";

const mouseAnyEnable = "\x1b[?1003h";
const mouseAnyDisable = "\x1b[?1003l";
const VMIN = 6;
const InputHandler = struct {
    core: *mkc.MkedCore,
    stdin: std.fs.File,
    prevStdin: usize,
    tc: std.os.termios,
    pub fn init(core: *mkc.MkedCore) !InputHandler {
        var stdin = std.io.getStdIn();
        if (std.os.isatty(stdin.handle) == false) {
            return error.Invalidtty;
        }
        const prevStdin = try std.os.fcntl(stdin.handle, std.os.F.GETFL, 0);
        _ = try std.os.fcntl(stdin.handle, std.os.F.SETFL, prevStdin | std.os.O.NONBLOCK);
        errdefer {
            _ = std.os.fcntl(stdin.handle, std.os.F.SETFL, prevStdin) catch {};
        }
        const tc = try std.os.tcgetattr(stdin.handle);
        var newtc = tc;
        newtc.iflag &= ~(std.os.linux.BRKINT |
            std.os.linux.ICRNL |
            std.os.linux.INPCK |
            std.os.linux.ISTRIP |
            std.os.linux.IXON);
        newtc.oflag &= ~(std.os.linux.OPOST);
        newtc.cflag |= std.os.linux.CS8;
        newtc.lflag &= ~(std.os.linux.ECHO | std.os.linux.ICANON | std.os.linux.IEXTEN | std.os.linux.ISIG);
        newtc.cc[VMIN] = 1;
        try std.os.tcsetattr(stdin.handle, .FLUSH, newtc);
        errdefer {
            std.os.tcsetattr(stdin.handle, .FLUSH, tc) catch {};
        }
        return InputHandler{
            .core = core,
            .stdin = stdin,
            .prevStdin = prevStdin,
            .tc = tc,
        };
    }
    pub fn deinit(self: *InputHandler) void {
        std.os.tcsetattr(self.stdin.handle, .FLUSH, self.tc) catch {};
        _ = std.os.fcntl(self.stdin.handle, std.os.F.SETFL, self.prevStdin) catch {};
    }
    pub fn getHandler(self: *InputHandler) el.HandlerInfo {
        return .{
            .fd = self.stdin.handle,
            .ctx = self,
            .read = readHandler,
        };
    }
    fn readHandler(ctx: *anyopaque, fd: std.os.fd_t) el.HandlerError!el.HandlerResult {
        _ = ctx;
        _ = fd;
        return el.HandlerResult.None;
    }
};

const OutputHandler = struct {
    core: *mkc.MkedCore,
    stdout: std.fs.File,
    pub fn init(core: *mkc.MkedCore) !OutputHandler {
        var self = OutputHandler{
            .core = core,
            .stdout = std.io.getStdOut(),
        };
        _ = try std.os.write(self.stdout.handle, altScreenEnable ++ mouseButtonEnable);

        return self;
    }
    pub fn deinit(self: OutputHandler) void {
        _ = std.os.write(self.stdout.handle, altScreenDisable ++ mouseButtonDisable) catch {};
    }
};

pub const Terminal = struct {
    alloc: std.mem.Allocator,
    input: *InputHandler,
    output: *OutputHandler,

    signal: sig.SignalFd,
    pub fn init(alloc: std.mem.Allocator, event: *el.EventLoop, core: *mkc.MkedCore) !*Terminal {
        var t = try alloc.create(Terminal);
        {
            errdefer alloc.destroy(t);
            var input = try alloc.create(InputHandler);
            errdefer alloc.destroy(input);
            input.* = try InputHandler.init(core);
            errdefer input.deinit();
            var output = try alloc.create(OutputHandler);
            errdefer alloc.destroy(output);
            output.* = try OutputHandler.init(core);
            errdefer output.deinit();
            var signal = sig.Signal.init();
            signal.addHandler(std.os.SIG.WINCH, .{ .ctx = t, .func = &sigWinchRead });
            t.* = .{
                .alloc = alloc,
                .input = input,
                .output = output,
                .signal = try signal.createSignalFd(),
            };
        }
        errdefer t.deinit();

        try event.addHandler(t.input.getHandler());

        try event.addHandler(t.signal.getEventHandler());

        return t;
        //
    }
    pub fn deinit(self: *Terminal) void {
        self.signal.deinit();
        self.alloc.destroy(self);
    }

    fn sigWinchRead(ctx: *anyopaque, signal: u32, data: i32) el.HandlerError!el.HandlerResult {
        _ = ctx;
        _ = signal;
        _ = data;
        return el.HandlerResult.None;
    }
};
