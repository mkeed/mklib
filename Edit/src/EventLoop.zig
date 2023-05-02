const std = @import("std");

pub fn ctxTo(comptime T: type, ctx: *anyopaque) *T {
    return @ptrCast(*T, @alignCast(@alignOf(T), ctx));
}

pub const HandlerError = error{
    GlobalFatal, //Kill everything and shutdown
    LocalFatal, //Kill just this handler and continue
};

pub const HandlerResult = enum {
    None,
    Done,
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
    pub const HandleResult = enum {
        Close,
        EndProgram,
        None,

        pub fn combine(self: HandleResult, other: HandleResult) HandleResult {
            switch (self) {
                .EndProgram => return .EndProgram,
                .Close => {
                    if (other == .EndProgram) {
                        return .EndProgram;
                    } else {
                        return .Close;
                    }
                },
                .None => {
                    return other;
                },
            }
        }
    };
    fn callFunc(self: HandlerInfo, func: FnHandler) HandleResult {
        const result = func(self.ctx, self.fd) catch |err| {
            switch (err) {
                error.GlobalFatal => return .EndProgram,
                error.LocalFatal => return .Close,
            }
        };
        switch (result) {
            .None => return .None,
            .Done => return .Close,
        }
    }
    pub fn handleEvents(self: HandlerInfo, revents: i16) HandleResult {
        var result: HandleResult = .None;
        if ((revents & std.os.POLL.IN) != 0) {
            if (self.read) |func| {
                result = result.combine(self.callFunc(func));
            }
        }
        if ((revents & std.os.POLL.OUT) != 0) {
            if (self.write) |func| {
                result = result.combine(self.callFunc(func));
            }
        }
        if ((revents & std.os.POLL.PRI) != 0) {
            if (self.pri) |func| {
                result = result.combine(self.callFunc(func));
            }
        }
        if ((revents & std.os.POLL.HUP) != 0) {
            if (self.hup) |func| {
                result = result.combine(self.callFunc(func));
            } else {
                result = .Close;
            }
        }
        if ((revents & std.os.POLL.ERR) != 0) {
            if (self.err) |func| {
                result = result.combine(self.callFunc(func));
            } else {
                result = .Close;
            }
        }
        if ((revents & std.os.POLL.NVAL) != 0) {
            result = .Close;
        }
        return result;
    }
    pub fn deinit(self: HandlerInfo) void {
        if (self.exit) |func| {
            _ = self.callFunc(func);
        }
    }
};

pub const PreEventHandlerFn = *const fn (ctx: *anyopaque) void;

pub const PreEventHandler = struct {
    ctx: *anyopaque,
    func: PreEventHandlerFn,
};

pub const CloseOption = enum {
    Finished,
};

pub const EventLoop = struct {
    alloc: std.mem.Allocator,
    pollfds: std.ArrayList(std.os.pollfd),
    handlers: std.ArrayList(HandlerInfo),
    pre_event_handlers: std.ArrayList(PreEventHandler),
    close: ?CloseOption = null,
    pub fn init(alloc: std.mem.Allocator) EventLoop {
        return EventLoop{
            .alloc = alloc,
            .pollfds = std.ArrayList(std.os.pollfd).init(alloc),
            .handlers = std.ArrayList(HandlerInfo).init(alloc),
            .pre_event_handlers = std.ArrayList(PreEventHandler).init(alloc),
        };
    }
    pub fn deinit(self: EventLoop) void {
        for (self.handlers.items) |handler| {
            if (handler.exit) |func| {
                _ = func(handler.ctx, handler.fd) catch {};
            }
        }
        self.pre_event_handlers.deinit();
        self.handlers.deinit();
        self.pollfds.deinit();
    }

    pub fn addPreHandler(self: *EventLoop, handler: PreEventHandler) !void {
        try self.pre_event_handlers.append(handler);
    }

    pub fn addHandler(self: *EventLoop, handler: HandlerInfo) !void {
        try self.handlers.append(handler);
    }

    pub fn run(self: *EventLoop) !void {
        var toRemove = std.ArrayList(std.os.fd_t).init(self.alloc);
        defer toRemove.deinit();
        mainLoop: while (self.handlers.items.len > 0) {
            for (self.pre_event_handlers.items) |item| {
                item.func(item.ctx);
            }
            if (self.close) |close| {
                switch (close) {
                    .Finished => {
                        break :mainLoop;
                    },
                }
            }
            try self.pollfds.ensureTotalCapacity(self.handlers.items.len);
            self.pollfds.clearRetainingCapacity();
            for (self.handlers.items) |handler| {
                std.log.err("adding poll {}\n", .{handler.fd});
                try self.pollfds.append(handler.pollfd());
            }
            std.log.err("Poll {} items\n", .{self.pollfds.items.len});
            const num = std.os.poll(self.pollfds.items, -1) catch |err| {
                std.log.err("System Failed: {}", .{err});
                break :mainLoop;
            };
            std.log.err("Poll  returned {} items\n", .{num});
            if (num == 0) {
                continue :mainLoop;
            }
            for (self.pollfds.items, 0..) |pollfd, idx| {
                if (pollfd.revents != 0) {
                    std.log.err("Results :{x} {}\n", .{ pollfd.revents, pollfd.fd });
                    switch (self.handlers.items[idx].handleEvents(pollfd.revents)) {
                        .Close => {
                            try toRemove.append(pollfd.fd);
                        },
                        .EndProgram => {
                            break :mainLoop;
                        },
                        .None => {},
                    }
                }
            }
            for (toRemove.items) |fd| {
                std.log.err("Removing fd:{}\n", .{fd});
                for (self.handlers.items, 0..) |item, idx| {
                    if (item.fd == fd) {
                        _ = self.handlers.swapRemove(idx);
                    }
                }
            }
        }
    }
};
