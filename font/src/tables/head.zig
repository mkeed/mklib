const std = @import("std");

pub const HEAD = struct {
    unitsPerEm: u16,
    xMin: i16,
    yMin: i16,
    xMax: i16,
    yMax: i16,
    bold: bool,
    italic: bool,
    underline: bool,
    outline: bool,
    shadow: bool,
    condensed: bool,
    extended: bool,
    lowestRecPPEM: u16,
    indexToLocFormat: i16,
    glyphDataFormat: i16,

    pub fn format(value: HEAD, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "unitsPerEM:[{}]\n", .{value.unitsPerEm});
        try std.fmt.format(writer, "min:[{}:{}] max:[{}:{}]\n", .{
            value.xMin,
            value.yMin,
            value.xMax,
            value.yMax,
        });

        try std.fmt.format(writer, "bold:[{}] italic:[{}] underline:[{}] outline:[{}]\n shadow:[{}] condensed:[{}] extended:[{}]\n", .{
            value.bold,
            value.italic,
            value.underline,
            value.outline,
            value.shadow,
            value.condensed,
            value.extended,
        });
        try std.fmt.format(writer, " lowestRecPPEM:{}\n", .{value.lowestRecPPEM});
    }
};
const font = @import("../font.zig");

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !HEAD {
    _ = alloc;
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    const majorVersion = try reader.readIntBig(u16);
    if (majorVersion != 1) return error.InvalidHeadVersion;
    const minorVersion = try reader.readIntBig(u16);
    if (minorVersion != 0) return error.InvalidHeadVersion;

    const revision = try font.Fixed.initFromReader(reader);
    _ = revision;
    const checksumAdjustment = try reader.readIntBig(u32);
    _ = checksumAdjustment;
    const magicNumber = try reader.readIntBig(u32);
    if (magicNumber != 0x5F0F3CF5) {
        return error.InvalidMagicNumber;
    }

    const flags = try reader.readIntBig(u16);
    _ = flags;

    const unitsPerEm = try reader.readIntBig(u16);
    const created = try reader.readIntBig(i64);
    const modified = try reader.readIntBig(i64);
    _ = created;
    _ = modified;
    const xMin = try reader.readIntBig(i16);
    const yMin = try reader.readIntBig(i16);
    const xMax = try reader.readIntBig(i16);
    const yMax = try reader.readIntBig(i16);

    const macStyle = try reader.readIntBig(u16);
    const bold = @truncate(u1, macStyle) == 1;
    const italic = @truncate(u1, macStyle >> 1) == 1;
    const underline = @truncate(u1, macStyle >> 2) == 1;
    const outline = @truncate(u1, macStyle >> 3) == 1;
    const shadow = @truncate(u1, macStyle >> 4) == 1;
    const condensed = @truncate(u1, macStyle >> 5) == 1;
    const extended = @truncate(u1, macStyle >> 6) == 1;

    const lowestRecPPEM = try reader.readIntBig(u16);
    const fontDirectionHint = try reader.readIntBig(i16);
    _ = fontDirectionHint;
    const indexToLocFormat = try reader.readIntBig(i16);

    const glyphDataFormat = try reader.readIntBig(i16);

    return HEAD{
        .unitsPerEm = unitsPerEm,
        .xMin = xMin,
        .yMin = yMin,
        .xMax = xMax,
        .yMax = yMax,
        .bold = bold,
        .italic = italic,
        .underline = underline,
        .outline = outline,
        .shadow = shadow,
        .condensed = condensed,
        .extended = extended,
        .lowestRecPPEM = lowestRecPPEM,
        .indexToLocFormat = indexToLocFormat,
        .glyphDataFormat = glyphDataFormat,
    };
}
