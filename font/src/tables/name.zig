const std = @import("std");

pub const Record = struct {
    platform: u16,
    encoding: u16,
    language: u16,
    name: u16,
    nameStr: std.ArrayList(u8),
    pub fn init(
        alloc: std.mem.Allocator,
        str: []const u8,
        platform: u16,
        encoding: u16,
        language: u16,
        name: u16,
    ) !Record {
        var fbs = std.io.fixedBufferStream(str);
        var nameStr = std.ArrayList(u8).init(alloc);
        errdefer nameStr.deinit();
        const reader = fbs.reader();

        while (true) {
            var utf8Buf = std.mem.zeroes([4]u8);
            const val = reader.readIntBig(u16) catch |err| {
                switch (err) {
                    error.EndOfStream => break,
                }
            };
            if (val <= 0xD7FF or (val >= 0xE000 and val <= 0xFFFF)) {
                const len = try std.unicode.utf8Encode(val, utf8Buf[0..]);
                try nameStr.appendSlice(utf8Buf[0..len]);
            }
        }
        return Record{
            .platform = platform,
            .encoding = encoding,
            .language = language,
            .name = name,
            .nameStr = nameStr,
        };
    }
    pub fn deinit(self: Record) void {
        self.nameStr.deinit();
    }
};

pub const NAME = struct {
    records: std.ArrayList(Record),
    pub fn init(alloc: std.mem.Allocator) NAME {
        return NAME{
            .records = std.ArrayList(Record).init(alloc),
        };
    }
    pub fn deinit(self: NAME) void {
        for (self.records.items) |item| {
            item.deinit();
        }
        self.records.deinit();
    }
};

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !NAME {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    var name = NAME.init(alloc);
    errdefer name.deinit();

    const version = try reader.readIntBig(u16);
    _ = version; //todo
    const count = try reader.readIntBig(u16);
    const storageOffset = try reader.readIntBig(u16);
    if (storageOffset > data.len) return error.InvalidStorageOffset;
    const storage = data[storageOffset..];
    for (0..count) |_| {
        const platformId = try reader.readIntBig(u16);
        const encodingId = try reader.readIntBig(u16);
        const languageId = try reader.readIntBig(u16);
        const nameId = try reader.readIntBig(u16);
        const length = try reader.readIntBig(u16);
        const offset = try reader.readIntBig(u16);

        if (length + offset > storage.len) return error.InvalidString;

        const str = storage[offset..][0..length];
        var record = try Record.init(alloc, str, platformId, encodingId, languageId, nameId);
        errdefer record.deinit();
        std.log.info("platform:{} encoding:{} language:{} name:{}, str[{s}]", .{
            platformId,
            encodingId,
            languageId,
            nameId,
            record.nameStr.items,
        });
        try name.records.append(record);
    }
    return name;
}
