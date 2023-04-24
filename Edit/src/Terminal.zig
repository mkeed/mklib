const std = @import("std");
const display = @import("Display.zig");
const sig = @import("Signal.zig");
const el = @import("EventLoop.zig");
const String = @import("String.zig");
const mkc = @import("MkedCore.zig");
const CodePoint = String.CodePoint;

const InputHandler = struct {
    core: *mkc.MkedCore,
    stdin: std.fs.File,
    prevStdin: u32,
    pub fn init(core: *mkc.MkedCore) !InputHandler {
        var stdin = std.io.getStdIn();
        if (std.os.isatty(stdin.handle) == false) {
            return error.Invalidtty;
        }
        const prevStdin = std.os.fcntl(stdin.handle, std.os.F.GETFL, 0);
        std.os.fcntl(stdin.handle, std.os.SETFL, prevStdin | std.os.O.NONBLOCK);
        return InputHandler{
            .core = mkc.MkedCore,
            .stdin = stdin,
            .prevStdIn = prevStdin,
        };
    }
    pub fn deinit(self: *InputHandler) void {
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
