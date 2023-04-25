const std = @import("std");
const arg = @import("ArgParse");
const Terminal = @import("Terminal.zig").Terminal;
const el = @import("EventLoop.zig");
const Display = @import("Display.zig");
const MkedCore = @import("MkedCore.zig").MkedCore;
const RunInfo = struct {
    fileList: std.ArrayList(std.ArrayList(u8)),

    pub fn init(alloc: std.mem.Allocator) RunInfo {
        return RunInfo{
            .fileList = std.ArrayList(std.ArrayList(u8)).init(alloc),
        };
    }
    pub fn deinit(self: RunInfo) void {
        for (self.fileList.items) |item| {
            item.deinit();
        }
        self.fileList.deinit();
    }
};

const ArgDef = arg.ProcInfo{
    .args = &.{
        .{
            .longName = "files",
            .short = 'f',
            .fieldName = "fileList",
            .docs = "File List to edit",
        },
    },
    .defaultList = "fileList",
    .docs = "test",
};

pub const mked = struct {
    alloc: std.mem.Allocator,
    core: *MkedCore,
    terminal: *Terminal,
    event: *el.EventLoop,
    pub fn init(alloc: std.mem.Allocator, event: *el.EventLoop) !*mked {
        var self = try alloc.create(mked);
        errdefer alloc.destroy(self);

        var core = try alloc.create(MkedCore);
        errdefer alloc.destroy(core);
        core.* = MkedCore.init(alloc, self);
        errdefer core.deinit();
        var terminal = try Terminal.init(alloc, event, core);
        self.* = mked{
            .alloc = alloc,
            .core = core,
            .terminal = terminal,
            .event = event,
        };

        try event.addPreHandler(.{ .ctx = self, .func = &preEventHandler });

        return self;
    }

    pub fn preEventImpl(self: *mked) !void {
        while (self.terminal.input.inputQueue.readItem()) |item| {
            switch (item) {
                .keyboard => |key| {
                    if (key.key == .F12) {
                        self.core.close();
                    }
                },
                .mouse => {},
            }
        }
        try self.terminal.output.draw(Display.disp);
    }

    fn preEventHandler(ctx: *anyopaque) void {
        const self = el.ctxTo(mked, ctx);
        self.preEventImpl() catch {};
    }

    pub fn deinit(self: *mked) void {
        self.core.deinit();
        self.terminal.deinit();
        self.alloc.destroy(self);
    }
};
