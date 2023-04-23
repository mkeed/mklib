const std = @import("std");
const el = @import("EventLoop.zig");

pub const FnHandler = *const fn (ctx: *anyopaque, sig: u32) el.HandlerError!el.HandlerResult;

pub const Signal = struct {
    handlers: [std.os.linux.NSIG]?FnHandler,
    pub fn init() Signal {
        return Signal{
            .handlers = [1]?FnHandler{null} ** std.os.linux.NSIG,
        };
    }
    pub fn addHandler(self: *Signal, signal: u32, handler: FnHandler) void {
        std.log.debug("adding signal {}", .{signal});
        if (signal < self.handlers.len) {
            self.handlers[signal] = handler;
        }
    }
    pub fn createSignalFd(self: Signal, alloc: std.mem.Allocator) !*SignalFd {
        var result = try alloc.create(SignalFd);
        errdefer alloc.destroy(result);

        var sigset = std.os.empty_sigset;
        for (self.handlers, 0..) |handler, idx| {
            if (handler != null) {
                std.os.linux.sigaddset(&sigset, @truncate(u6, idx));
            }
        }
        var oldset = std.os.empty_sigset;
        std.os.sigprocmask(std.os.SIG.BLOCK, &sigset, &oldset);
        errdefer {
            std.os.sigprocmask(std.os.SIG.BLOCK, &oldset, null);
        }
        const fd = try std.os.signalfd(-1, &sigset, std.os.linux.SFD.NONBLOCK | std.os.linux.SFD.CLOEXEC);
        result.* = SignalFd{
            .alloc = alloc,
            .fd = fd,
            .signal = self,
        };
        return result;
    }
};

pub const SignalFd = struct {
    alloc: std.mem.Allocator,
    fd: std.os.fd_t,
    signal: Signal,
    fn exitHandler(ctx: *anyopaque, fd: std.os.fd_t) el.HandlerError!el.HandlerResult {
        const self = @ptrCast(*SignalFd, @alignCast(@alignOf(*SignalFd), ctx));
        self.deinit();
        _ = fd;
        return .None;
    }

    fn readHandler(ctx: *anyopaque, fd: std.os.fd_t) el.HandlerError!el.HandlerResult {
        const self = @ptrCast(*SignalFd, @alignCast(@alignOf(*SignalFd), ctx));
        _ = self;

        var buf: [@sizeOf(std.os.linux.signalfd_siginfo)]u8 align(@alignOf(*std.os.linux.signalfd_siginfo)) = undefined;
        const len = std.os.read(fd, buf[0..]) catch {
            return el.HandlerError.LocalFatal;
        };
        if (len != buf.len) return el.HandlerResult.None;
        const siginfo = @ptrCast(*std.os.linux.signalfd_siginfo, &buf);
        std.log.err("{}", .{siginfo.*});
        return el.HandlerResult.None;
    }
    pub fn getEventHandler(self: *SignalFd) el.HandlerInfo {
        return .{
            .fd = self.fd,
            .ctx = self,
            .read = readHandler,
            .err = exitHandler,
            .exit = exitHandler,
        };
    }
    pub fn deinit(self: *SignalFd) void {
        std.os.close(self.fd);
        self.alloc.destroy(self);
    }
};
