const std = @import("std");

const OS2 = struct {
    version: u16,
    xAvgCharWidth: i16,
    usWeightClass: u16,
    usWidthClass: u16,
    fsType: u16,
    ySubscriptXSize: i16,
    ySubscriptYSize: i16,
    ySubscriptXOffset: i16,
    ySubscriptYOffset: i16,
    ySuperscriptXSize: i16,
    ySuperscriptYSize: i16,
    ySuperscriptXOffset: i16,
    ySuperscriptYOffset: i16,
    yStrikeoutSize: i16,
    yStrikeoutPosition: i16,
    sFamilyClass: i16,
    panose: [10]u8,
    ulUnicodeRange1: u32, //Bits 0–31
    ulUnicodeRange2: u32, //Bits 32–63
    ulUnicodeRange3: u32, //Bits 64–95
    ulUnicodeRange4: u32, //Bits 96–127
    achVendID: u32,
    fsSelection: u16,
    usFirstCharIndex: u16,
    usLastCharIndex: u16,
    sTypoAscender: i16,
    sTypoDescender: i16,
    sTypoLineGap: i16,
    usWinAscent: u16,
    usWinDescent: u16,
    ulCodePageRange1: ?u32 = null,
    ulCodePageRange2: ?u32 = null,
    sxHeight: ?i16 = null,
    sCapHeight: ?i16 = null,
    usDefaultChar: ?u16 = null,
    usBreakChar: ?u16 = null,
    usMaxContext: ?u16 = null,
    usLowerOpticalPointSize: ?u16 = null,
    usUpperOpticalPointSiz: ?u16 = null,
    pub fn format(value: OS2, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer,
            \\ version: {},
            \\ xAvgCharWidth: {},
            \\ usWeightClass: {},
            \\ usWidthClass: {},
            \\ fsType: {},
            \\ ySubscriptXSize: {},
            \\ ySubscriptYSize: {},
            \\ ySubscriptXOffset: {},
            \\ ySubscriptYOffset: {},
            \\ ySuperscriptXSize: {},
            \\ ySuperscriptYSize: {},
            \\ ySuperscriptXOffset: {},
            \\ ySuperscriptYOffset: {},
            \\ yStrikeoutSize: {},
            \\ yStrikeoutPosition: {},
            \\ sFamilyClass: {},
            \\ panose: {},
            \\
        , .{
            value.version,
            value.xAvgCharWidth,
            value.usWeightClass,
            value.usWidthClass,
            value.fsType,
            value.ySubscriptXSize,
            value.ySubscriptYSize,
            value.ySubscriptXOffset,
            value.ySubscriptYOffset,
            value.ySuperscriptXSize,
            value.ySuperscriptYSize,
            value.ySuperscriptXOffset,
            value.ySuperscriptYOffset,
            value.yStrikeoutSize,
            value.yStrikeoutPosition,
            value.sFamilyClass,
            std.fmt.fmtSliceHexUpper(&value.panose),
        });

        try std.fmt.format(writer,
            \\ ulUnicodeRange1: {},
            \\ ulUnicodeRange2: {},
            \\ ulUnicodeRange3: {},
            \\ ulUnicodeRange4: {},
            \\ achVendID: {},
            \\ fsSelection: {},
            \\ usFirstCharIndex: {},
            \\ usLastCharIndex: {},
            \\ sTypoAscender: {},
            \\ sTypoDescender: {},
            \\ sTypoLineGap: {},
            \\ usWinAscent: {},
            \\ usWinDescent: {},
            \\ ulCodePageRange1: {?},
            \\ ulCodePageRange2: {?},
            \\ sxHeight: {?},
            \\ sCapHeight: {?},
            \\ usDefaultChar: {?},
            \\ usBreakChar: {?},
            \\ usMaxContext: {?},
            \\ usLowerOpticalPointSize: {?},
            \\ usUpperOpticalPointSiz: {?},
        , .{
            value.ulUnicodeRange1,
            value.ulUnicodeRange2,
            value.ulUnicodeRange3,
            value.ulUnicodeRange4,
            value.achVendID,
            value.fsSelection,
            value.usFirstCharIndex,
            value.usLastCharIndex,
            value.sTypoAscender,
            value.sTypoDescender,
            value.sTypoLineGap,
            value.usWinAscent,
            value.usWinDescent,
            value.ulCodePageRange1,
            value.ulCodePageRange2,
            value.sxHeight,
            value.sCapHeight,
            value.usDefaultChar,
            value.usBreakChar,
            value.usMaxContext,
            value.usLowerOpticalPointSize,
            value.usUpperOpticalPointSiz,
        });
    }
};

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !OS2 {
    _ = alloc;
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    var os2 = OS2{
        .version = try reader.readIntBig(u16),
        .xAvgCharWidth = try reader.readIntBig(i16),
        .usWeightClass = try reader.readIntBig(u16),
        .usWidthClass = try reader.readIntBig(u16),
        .fsType = try reader.readIntBig(u16),
        .ySubscriptXSize = try reader.readIntBig(i16),
        .ySubscriptYSize = try reader.readIntBig(i16),
        .ySubscriptXOffset = try reader.readIntBig(i16),
        .ySubscriptYOffset = try reader.readIntBig(i16),
        .ySuperscriptXSize = try reader.readIntBig(i16),
        .ySuperscriptYSize = try reader.readIntBig(i16),
        .ySuperscriptXOffset = try reader.readIntBig(i16),
        .ySuperscriptYOffset = try reader.readIntBig(i16),
        .yStrikeoutSize = try reader.readIntBig(i16),
        .yStrikeoutPosition = try reader.readIntBig(i16),
        .sFamilyClass = try reader.readIntBig(i16),
        .panose = [10]u8{
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
        },
        .ulUnicodeRange1 = try reader.readIntBig(u32),
        .ulUnicodeRange2 = try reader.readIntBig(u32),
        .ulUnicodeRange3 = try reader.readIntBig(u32),
        .ulUnicodeRange4 = try reader.readIntBig(u32),
        .achVendID = try reader.readIntBig(u32),
        .fsSelection = try reader.readIntBig(u16),
        .usFirstCharIndex = try reader.readIntBig(u16),
        .usLastCharIndex = try reader.readIntBig(u16),
        .sTypoAscender = try reader.readIntBig(i16),
        .sTypoDescender = try reader.readIntBig(i16),
        .sTypoLineGap = try reader.readIntBig(i16),
        .usWinAscent = try reader.readIntBig(u16),
        .usWinDescent = try reader.readIntBig(u16),
    };
    if (os2.version >= 1) {
        os2.ulCodePageRange1 = try reader.readIntBig(u32);
        os2.ulCodePageRange2 = try reader.readIntBig(u32);
    }

    if (os2.version >= 2) {
        os2.sxHeight = try reader.readIntBig(i16);
        os2.sCapHeight = try reader.readIntBig(i16);
        os2.usDefaultChar = try reader.readIntBig(u16);
        os2.usBreakChar = try reader.readIntBig(u16);
        os2.usMaxContext = try reader.readIntBig(u16);
    }
    if (os2.version >= 5) {
        os2.usLowerOpticalPointSize = try reader.readIntBig(u16);
        os2.usUpperOpticalPointSiz = try reader.readIntBig(u16);
    }
    return os2;
}
