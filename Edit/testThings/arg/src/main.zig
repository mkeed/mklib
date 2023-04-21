const std = @import("std");
const arg = @import("ArgParse");

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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var v = try arg.parseArgs(RunInfo, alloc, ArgDef);
    defer v.deinit();
    for (v.fileList.items) |file| {
        std.log.info("File:{s}", .{file.items});
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
