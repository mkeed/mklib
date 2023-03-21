const std = @import("std");

pub const CMAP = struct {};

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !CMAP {
    _ = alloc;
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    const version = try reader.readIntBig(u16);
    if (version != 0) return error.InvalidVersion;
    const numTables = try reader.readIntBig(u16);

    for (0..numTables) |_| {
        const platformID = try std.meta.intToEnum(PlatformID, try reader.readIntBig(u16));
        const encoding_val = try reader.readIntBig(u16);
        const encodingId: Encoding = switch (platformID) {
            .Unicode => .{ .unicode = try std.meta.intToEnum(UnicodeEncoding, encoding_val) },
            .Windows => .{ .windows = try std.meta.intToEnum(WindowsEncoding, encoding_val) },
            .ISO => .{ .iso = try std.meta.intToEnum(ISOEncoding, encoding_val) },
            else => return error.NotImplemented,
        };
        const offset = try reader.readIntBig(u32);
        std.log.info("plat:{} encode:{} offset:{}", .{ platformID, encodingId, offset });

        const subTable = data[offset..];
        const format = std.mem.readIntSliceBig(u16, subTable[0..]);
        std.log.info("Format:{}", .{format});
        switch (format) {
            4 => {},
            else => return error.NotImplemented,
        }
    }
    return CMAP{};
}

fn parseformat4(data: []const u8) !Format4 {}

const PlatformID = enum(u16) {
    Unicode = 0,
    Macintosh = 1,
    ISO = 2,
    Windows = 3,
    Custom = 4,
};

const UnicodeEncoding = enum(u16) {
    Unicode1_0 = 0,
    Unicode1_1 = 1,
    ISO_IEC = 2,
    Unicode2_0_BMP = 3,
    Unicode2_0_Full = 4,
    Unicode_Varation = 5,
    Unicode_full = 6,
};

const WindowsEncoding = enum(u16) {
    Symbol = 0,
    Unicode_BMP = 1,
    ShiftJIS = 2,
    PRC = 3,
    Big5 = 4,
    Wansung = 5,
    Johab = 6,
    Unicode_Full = 10,
};

const ISOEncoding = enum(u16) {
    Ascii = 0,
    ISO10646 = 1,
    ISO8859_1 = 2,
};

const Encoding = union(enum) {
    windows: WindowsEncoding,
    unicode: UnicodeEncoding,
    iso: ISOEncoding,
};
