const std = @import("std");

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !HHEA {
    _ = alloc;
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();

    const version = try reader.readIntBig(u16);
    const count = try reader.readIntBig(u16);
    const storageOffset = try reader.readIntBig(u16);

    for (0..count) |idx| {}
}
