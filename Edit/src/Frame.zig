const std = @import("std");

const Display = union(enum) {
    vertical: SplitFrame,
    horizontal: SplitFrame,
    display: *BufferView,
};

pub const Frame = struct {
    alloc: std.mem.Allocator,
    pub fn init(alloc: std.mem.Allocator) Frame {
        return .{
            .alloc = alloc,
        };
    }
};
