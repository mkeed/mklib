const std = @import("std");
const font = @import("../font.zig");

const POSTA = struct {
    italicAngle: font.Fixed,
    underLinePosition: i16,
    underLineThickness: i16,
    isFixedPitch: u32,
    minMemType42: u32,
    maxMemType42: u32,
    minMemType1: u32,
    maxMemType1: u32,

    glyphs: std.ArrayList(std.ArrayList(u8)),
};

const POST = struct {};

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !POST {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();

    const versionMajor = try reader.readIntBig(u16);
    const versionMinor = try reader.readIntBig(u16);
    std.log.info("version:{}.{}", .{ versionMajor, versionMinor });

    const italicAngle = try font.Fixed.initFromReader(reader);

    const underLinePosition = try reader.readIntBig(i16);
    const underLineThickness = try reader.readIntBig(i16);
    const isFixedPitch = try reader.readIntBig(u32);
    const minMemType42 = try reader.readIntBig(u32);
    const maxMemType42 = try reader.readIntBig(u32);
    const minMemType1 = try reader.readIntBig(u32);
    const maxMemType1 = try reader.readIntBig(u32);

    std.log.info("italic:{} underLinePos:{} underLineThick:{} isFixed:{} type42[{}=>{}] type1[{}=>{}]", .{
        italicAngle,
        underLinePosition,
        underLineThickness,
        isFixedPitch,
        minMemType42,
        maxMemType42,
        minMemType1,
        maxMemType1,
    });
    var stringsList = std.ArrayList(std.ArrayList(u8)).init(alloc);
    defer {
        for (stringsList.items) |item| {
            item.deinit();
        }
        stringsList.deinit();
    }
    if (versionMajor > 1) {
        const numGlyphs = try reader.readIntBig(u16);
        const stringStart = fbs.pos + numGlyphs * 2;
        const strings = data[stringStart..];

        var idx: usize = 0;
        while (idx < strings.len) {
            const len = strings[idx];
            idx += 1;
            const subString = strings[idx..][0..len];
            idx += len;

            var subStringVal = std.ArrayList(u8).init(alloc);
            errdefer subStringVal.deinit();
            try subStringVal.appendSlice(subString);
            try stringsList.append(subStringVal);
        }

        for (0..numGlyphs) |_| {
            const index = try reader.readIntBig(u16);
            std.log.info("GlyphIndex[{}", .{index});
            if (index >= 258) {
                const subIndex = index - 258;
                const subString = stringsList.items[subIndex].items;

                std.log.info("sub:[{s}]", .{subString});
            }
        }
    }
    return POST{};
}
