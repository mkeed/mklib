const std = @import("std");

pub const Buffer = struct {
    alloc: std.mem.Allocator,
    lines: std.ArrayList(std.ArrayList(u8)),
    isCRLF: bool,
    pub fn init(alloc: std.mem.Allocator, reader: anytype) !Buffer {
        var readbuf = std.ArrayList(u8).init(alloc);
        defer readbuf.deinit();

        //
    }
};
