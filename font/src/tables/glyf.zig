const std = @import("std");

pub fn parse(data: []const u8, alloc: std.mem.Allocator, numGlyfs: usize) !GLYF {
    _ = alloc;
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    for (0..numGlyfs) |_| {
        const numberOfContoures = try reader.readIntBig(i16);
        const xMin = try reader.readIntBig(i16);
        const yMin = try reader.readIntBig(i16);
        const xMax = try reader.readIntBig(i16);
        const yMax = try reader.readIntBig(i16);
        std.log.info("Contours:{} [{}:{} => {}:{}] ", .{ numberOfContours, xMin, yMin, xMax, ymax });
        
    }
}
