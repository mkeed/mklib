pub const CMAP = struct {};

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !CMAP {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    const version = reader.readIntBig(u16);
    if (version != 0) return error.InvalidVersion;
    const numTables = reader.readIntBig(u16);

    for (0..numTables) |idx| {
        //        const platformID =
    }
}
