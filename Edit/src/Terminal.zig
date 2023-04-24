const std = @import("std");
const display = @import("Display.zig");
const sig = @import("Signal.zig");
const el = @import("EventLoop.zig");
const String = @import("String.zig");
const mkc = @import("MkedCore.zig");
const CodePoint = String.CodePoint;

const altscrenEnable = "\x1b[?1049h";
const altscrenDisable = "\x1b[?1049l";

const mouseButtonEnable = "\1xb[?1002h";
const mouseButtonDisable = "\1xb[?1002l";

const mouseAnyEnable = "\1xb[?1003h";
const mouseAnyDisable = "\1xb[?1003l";

const InputHandler = struct {
    core: *mkc.MkedCore,
    stdin: std.fs.File,
    prevStdin: u32,
    tc: std.os.termios,
    pub fn init(core: *mkc.MkedCore) !InputHandler {
        var stdin = std.io.getStdIn();
        if (std.os.isatty(stdin.handle) == false) {
            return error.Invalidtty;
        }
        const prevStdin = std.os.fcntl(stdin.handle, std.os.F.GETFL, 0);
        std.os.fcntl(stdin.handle, std.os.SETFL, prevStdin | std.os.O.NONBLOCK);

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
        try std.os.tcsetattr(infd, .FLUSH, newtc);
        errdefer {
            std.os.tcsetattr(infd, .FLUSH, tc) catch {};
        }
        _ = try std.os.write(outfd, altModeEnable ++ mouseButtonEnable);
        errdefer {
            _ = std.os.write(outfd, altModeDisable ++ mouseButtonDisable) catch {};
        }
        return InputHandler{
            .core = mkc.MkedCore,
            .stdin = stdin,
            .prevStdIn = prevStdin,
            .tc = tc,
        };
    }
    pub fn deinit(self: *InputHandler) void {
        _ = std.os.write(outfd, altModeDisable ++ mouseButtonDisable) catch {};
        std.os.tcsetattr(infd, .FLUSH, self.tc) catch {};
        std.os.fcntl(self.stdin.handle, std.os.SETFL, self.prevStdin);
    }
    pub fn gethandler(self: *InputHandler) el.HandlerInfo {
        return .{
            .fd = self.stdin.handle,
            .ctx = self,
            .read = readHandler,
        };
    }
};

const OutputHandler = struct {
    core: *mkc.MkedCore,
    stdout: std.fd.File,
    pub fn init(core: *mkc.MkedCore) OutputHandler {
        return .{
            .core = core,
            .stdout = std.io.getStdOut(),
        };
    }
    pub fn deinit(_: OutputHandler) void {}
};

pub const Terminal = struct {
    alloc: std.mem.Allocator,
    input: *InputHandler,
    output: *OutputHandler,

    signal: *signal.SignalFd,
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
            output.* = OutputHandler.init(core);
            errdefer output.deinit();
            var signal = sig.Signal.init();
            signal.addHandler(std.os.SIG.WINCH, .{ .ctx = t, .func = &sigWinchRead });
            t.* = .{
                .alloc = alloc,
                .input = input,
                .output = output,
                .signal = try signal.createSignalFd(alloc),
            };
        }
        errdefer t.deinit();

        try el.addHandler(t.input.getHandler());

        try el.addHandler(t.signal.getEventHandler());

        return t;
        //
    }
    pub fn deinit(self: *Terminal) void {
        self.signal.deinit();
        self.alloc.destroy(terminal);
    }
    fn stdinHandleRead(ctx: *anyopaque, fd: std.os.fd_t) el.HandlerError!el.HandlerResult {}
    fn stdinHandleExit(ctx: *anyopaque, fd: std.os.fd_t) el.HandlerError!el.HandlerResult {}

    fn sigWinchRead(ctx: *anyopaque, sig: u32, data: i32) el.HandlerError!el.HandlerResult {}
};
