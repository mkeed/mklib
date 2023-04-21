const std = @import("std");
const ap = @import("ArgParser.zig");

const args = ap.ArgInfo{
    .args = &.{
        .{ .longName = "files", .short = 'f', .docs = "Files to edit", .fieldName = "files" },
    },
    .defaultList = "files",
    .docs = "A text editor",
};

pub const initOpts = struct {
    pub fn init(alloc: std.mem.Allocator) initOpts {}
    files: std.ArrayList(std.ArrayList(u8)),
};

pub const mked = struct {
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator, initOpts: InitOptions) !mked {}
};
