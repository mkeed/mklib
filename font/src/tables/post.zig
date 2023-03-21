const std = @import("std");

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !HHEA {
    _ = alloc;
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    const versionMajor = try reader.readIntBig(u16);
    const versionMinor = try reader.readIntBig(u16);
    const italicAngle = try font.Fixed.initFromReader(reader);
    const underLinePosition = try reader.readIntBig(i16);
}
