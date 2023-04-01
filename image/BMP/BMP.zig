const std = @import("std");

const Header = struct {
    const MagicVal = enum {
        BM,
        BA,
        CI,
        CP,
        IC,
        PT,
        pub fn fromBytes(val: [2]u8) !MagicVal {
            if (std.mem.eql(u8, "BM", &val)) return MagicVal.BM;
            if (std.mem.eql(u8, "BA", &val)) return MagicVal.BA;
            if (std.mem.eql(u8, "CI", &val)) return MagicVal.CI;
            if (std.mem.eql(u8, "CP", &val)) return MagicVal.CP;
            if (std.mem.eql(u8, "IC", &val)) return MagicVal.IC;
            if (std.mem.eql(u8, "PT", &val)) return MagicVal.PT;
            return error.InvalidMagic;
        }
    };
    magic: MagicVal,
    fileSize: u32,
    offset: u32,
    headerLen: u32,
};

fn readHeader(data: []const u8) !Header {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    const magic = try Header.MagicVal.fromBytes(try reader.readBytesNoEof(2));
    const fileSize = try reader.readIntLittle(u32);
    _ = try reader.readIntLittle(u16);
    _ = try reader.readIntLittle(u16);
    const offset = try reader.readIntLittle(u32);
    const headerLen = try reader.readIntLittle(u32);
    const header = Header{
        .magic = magic,
        .fileSize = fileSize,
        .offset = offset,
        .headerLen = headerLen,
    };

    switch (header.headerLen) {
        12 => {
            const width = try reader.readIntLittle(u16);
            const height = try reader.readIntLittle(u16);
            const planes = try reader.readIntLittle(u16);
            const bpp = try reader.readIntLittle(u16);
            std.log.err("w:{} h:{} p:{} bpp:{}", .{ width, height, planes, bpp });
        },
        64 => {
            //
            return error.OS22XBITMAPHEADERNotImplemented;
        },
        16 => {
            // only first 16 byte fields
            return error.OS22XBITMAPHEADERsHORTNotImplemented;
        },
        40 => {
            return error.BITMAPINFOHEADERNotImplemented;
        },
        52 => {
            return error.BITMAPV2INFOHEADERNotImplemented;
        },
        56 => {
            return error.BITMAPV3INFOHEADERNotImplemented;
        },
        108 => {
            const width = try reader.readIntLittle(u32);
            const height = try reader.readIntLittle(u32);
            const planes = try reader.readIntLittle(u16);
            const bpp = try reader.readIntLittle(u16);
            const compression = try std.meta.intToEnum(CompressionMethod, try reader.readIntLittle(u32));
            const imageSize = try reader.readIntLittle(u32);
            const horizontalResolution = try reader.readIntLittle(u32);
            const verticalResolution = try reader.readIntLittle(u32);
            const numColours = try reader.readIntLittle(u32);
            const numberOfImportantColours = try reader.readIntLittle(u32);
            std.log.err("w:{} h:{} p:{} bpp:{} comp:{} imageSize:{} horiz:{} vert:{} numColours:{} numberOfImportant:{}", .{
                width,
                height,
                planes,
                bpp,
                compression,
                imageSize,
                horizontalResolution,
                verticalResolution,
                numColours,
                numberOfImportantColours,
            });

            std.log.err("{}:{x}", .{ fbs.pos, fbs.pos });
        },
        124 => {
            return error.BITMAPV5HEADERNotImplemented;
        },
        else => {
            return error.InvalidHeaderLen;
        },
    }
    return header;
}

const CompressionMethod = enum(u8) {
    RGB = 0,
    RLE8 = 1,
    RLE4 = 2,
    BITFIELDS = 3,
    JPEG = 4,
    PNG = 5,
    ALPHABITFIELDS = 6,
    CMYK = 11,
    CMYKRLE8 = 12,
    CMYKRLE4 = 13,
};

pub fn parse(data: []const u8, Image: anytype) !void {
    _ = Image;
    const header = try readHeader(data);
    std.log.err("{} [{}:{x}]", .{ header, header.offset, header.offset });
}

test {
    const img = @embedFile("basiog01.bmp");
    try parse(img, .{});
}
