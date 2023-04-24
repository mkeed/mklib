const std = @import("std");
const arg = @import("ArgParse");
const Terminal = @import("Terminal.zig").Terminal;
const el = @import("EventLoop.zig");

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
    pub fn init(alloc: std.mem.Allocator, event: *el.EventLoop) !mked {
        var core = try alloc.create(MkedCore);
        errdefer alloc.destroy(core);
        core.* = MkedCore.init(alloc);
        errdefer core.deinit();

        var terminal = try Terminal.init(alloc, event, core);

        return mked{
            .alloc = alloc,
            .core = core,
            .terminal = terminal,
        };
    }
    pub fn deinit(self: mked) void {
        self.core.deinit();
    }
};
