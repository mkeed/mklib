const std = @import("std");
const Display = @import("Display.zig");
const sig = @import("Signal.zig");
const el = @import("EventLoop.zig");
const String = @import("String.zig");
const mkc = @import("MkedCore.zig");
const CodePoint = String.CodePoint;
const App = @import("App.zig");
const Input = @import("Terminal/Input.zig");
const Output = @import("Terminal/Output.zig");
const altScreenEnable = "\x1b[?1049h";
const altScreenDisable = "\x1b[?1049l";

const mouseButtonEnable = "\x1b[?1002h";
const mouseButtonDisable = "\x1b[?1002l";

const mouseAnyEnable = "\x1b[?1003h";
const mouseAnyDisable = "\x1b[?1003l";

pub const InputQueue = std.fifo.LinearFifo(App.InputEvent, .Dynamic);

const InputHandler = struct {
    core: *mkc.MkedCore,
    stdin: std.fs.File,
    prevStdin: usize,
    tc: std.os.termios,
    inputQueue: InputQueue,
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
        newtc.cc[Input.VMIN] = 1;
        try std.os.tcsetattr(stdin.handle, .FLUSH, newtc);
        errdefer {
            std.os.tcsetattr(stdin.handle, .FLUSH, tc) catch {};
        }
        return InputHandler{
            .core = core,
            .stdin = stdin,
            .prevStdin = prevStdin,
            .tc = tc,
            .inputQueue = InputQueue.init(core.alloc),
        };
    }
    pub fn deinit(self: *InputHandler) void {
        std.os.tcsetattr(self.stdin.handle, .FLUSH, self.tc) catch {};
        _ = std.os.fcntl(self.stdin.handle, std.os.F.SETFL, self.prevStdin) catch {};
        self.inputQueue.deinit();
    }
    pub fn getHandler(self: *InputHandler) el.HandlerInfo {
        return .{
            .fd = self.stdin.handle,
            .ctx = self,
            .read = readHandler,
        };
    }
    fn readHandler(ctx: *anyopaque, fd: std.os.fd_t) el.HandlerError!el.HandlerResult {
        const self = el.ctxTo(InputHandler, ctx);
        _ = fd;
        var buffer: [4096]u8 = undefined;
        const len = self.stdin.read(buffer[0..]) catch |err| {
            switch (err) {
                error.WouldBlock => {
                    return el.HandlerResult.None;
                },
                else => {
                    return el.HandlerError.GlobalFatal;
                },
            }
        };

        Input.read(buffer[0..len], &self.inputQueue) catch return el.HandlerResult.Done;

        return el.HandlerResult.None;
    }
};

const OutputHandler = struct {
    core: *mkc.MkedCore,
    stdout: std.fs.File,
    drawBuffer: std.ArrayList(u8),
    terminalSize: Display.Pos,
    pub fn init(core: *mkc.MkedCore, alloc: std.mem.Allocator) !OutputHandler {
        var self = OutputHandler{
            .core = core,
            .stdout = std.io.getStdOut(),
            .drawBuffer = std.ArrayList(u8).init(alloc),
            .terminalSize = .{ .x = 0, .y = 0 },
        };
        _ = try std.os.write(self.stdout.handle, altScreenEnable ++ mouseAnyEnable);

        return self;
    }
    pub fn deinit(self: OutputHandler) void {
        _ = std.os.write(self.stdout.handle, altScreenDisable ++ mouseAnyDisable) catch {};
        self.drawBuffer.deinit();
    }

    pub fn draw(self: *OutputHandler, disp: Display.ScreenDisplay) !void {
        self.drawBuffer.clearRetainingCapacity();
        var writer = self.drawBuffer.writer();
        try Output.write(disp, writer);
        _ = try self.stdout.write(self.drawBuffer.items);
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
            output.* = try OutputHandler.init(core, alloc);
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
        t.updateWinSize();
        try event.addHandler(t.input.getHandler());

        try event.addHandler(t.signal.getEventHandler());

        return t;
        //
    }
    pub fn deinit(self: *Terminal) void {
        self.input.deinit();
        self.alloc.destroy(self.input);
        self.output.deinit();
        self.alloc.destroy(self.output);
        self.signal.deinit();
        self.alloc.destroy(self);
    }

    fn updateWinSize(self: *Terminal) void {
        var ws: std.os.system.winsize = undefined;
        if (std.os.system.ioctl(self.input.stdin.handle, std.os.system.T.IOCGWINSZ, @ptrToInt(&ws)) == 0) {
            self.output.terminalSize = .{ .x = ws.ws_col, .y = ws.ws_row };
        }
    }

    fn sigWinchRead(ctx: *anyopaque, signal: u32, data: i32) el.HandlerError!el.HandlerResult {
        const self = el.ctxTo(Terminal, ctx);
        self.updateWinSize();
        _ = signal;
        _ = data;
        return el.HandlerResult.None;
    }
};
