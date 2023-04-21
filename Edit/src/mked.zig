const std = @import("std");
const arg = @import("ArgParse");
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

pub fn run(alloc: std.mem.Allocator) !void {
    var v = try arg.parseArgs(RunInfo, alloc, ArgDef) orelse return;
    defer v.deinit();
    for (v.fileList.items) |file| {
        std.log.info("File:{s}", .{file.items});
    }
}

pub const mked = struct {
    alloc: std.mem.Allocator,
    core: MkedCore,

    pub fn init(alloc: std.mem.Allocator) mked {
        return mked{
            .alloc = alloc,
            .core = MkedCore.init(alloc),
        };
    }
};
