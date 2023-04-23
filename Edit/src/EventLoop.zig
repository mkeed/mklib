const std = @import("std");

pub const HandlerError = error{
    GlobalFatal, //Kill everything and shutdown
    LocalFatal, //Kill just this handler and continue
};

pub const HandlerResult = enum {
    None,
    Exit,
};

pub const FnHandler = *const fn (ctx: *anyopaque, fd: std.os.fd_t) HandlerError!HandlerResult;

pub const HandlerInfo = struct {
    fd: std.os.fd_t,
    ctx: *anyopaque,
    read: ?FnHandler = null,
    write: ?FnHandler = null,
    hup: ?FnHandler = null,
    pri: ?FnHandler = null,
    err: ?FnHandler = null,
    exit: ?FnHandler = null,
    pub fn pollfd(self: HandlerInfo) std.os.pollfd {
        var events: i16 = 0;
        if (self.read != null) events |= std.os.POLL.IN;
        if (self.write != null) events |= std.os.POLL.OUT;
        if (self.pri != null) events |= std.os.POLL.PRI;
        return .{
            .fd = self.fd,
            .events = events,
            .revents = 0,
        };
    }
};

pub const SignalHandler = struct {
    ctx: *anyopaque,
    func: FnHandler,
};

pub const EventLoop = struct {
    alloc: std.mem.Allocator,
    pollfds: std.ArrayList(std.os.pollfd),
    handlers: std.ArrayList(HandlerInfo),
    signalHandlers: [std.os.NSIG]?SignalHandler,
    pub fn init(alloc: std.mem.Allocator) EventLoop {
        return EventLoop{
            .alloc = alloc,
            .pollfds = std.ArrayList(std.os.pollfd).init(alloc),
            .handlers = std.ArrayList(HandlerInfo),
        };
    }

    pub fn run(self: *EventLoop) !void {
        while (true) {
            try self.pollfds.ensureTotalCapacity(self.handlers.items.len);
            self.pollfds.clearRetainingCapacity();
            for (self.handlers.items, 0..) |handler, idx| {
                try self.pollfds.append(handler.pollfd());
            }
            //const num = std.os.poll(self.pollfds.items,
        }
    }
};
