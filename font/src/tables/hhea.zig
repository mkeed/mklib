const std = @import("std");

pub const HHEA = struct {
    ascender: i16,
    descender: i16,
    lineGap: i16,
    advanceWidthMax: u16,
    minLeftSideBearing: i16,
    minRightSideBearing: i16,
    xMaxExtent: i16,
    caretSlopeRise: i16,
    caretSlopeRun: i16,
    caretOffset: i16,
    metricDataFormat: u16,
    numberOfHMetrics: u16,
};

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !HHEA {
    _ = alloc;
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    const majorVersion = try reader.readIntBig(u16);
    if (majorVersion != 1) return error.InvalidHeadVersion;
    const minorVersion = try reader.readIntBig(u16);
    if (minorVersion != 0) return error.InvalidHeadVersion;

    const ascender = try reader.readIntBig(i16);
    const descender = try reader.readIntBig(i16);

    const lineGap = try reader.readIntBig(i16);

    const advanceWidthMax = try reader.readIntBig(u16);
    const minLeftSideBearing = try reader.readIntBig(i16);
    const minRightSideBearing = try reader.readIntBig(i16);
    const xMaxExtent = try reader.readIntBig(i16);
    const caretSlopeRise = try reader.readIntBig(i16);
    const caretSlopeRun = try reader.readIntBig(i16);
    const caretOffset = try reader.readIntBig(i16);
    _ = try reader.readIntBig(u16);
    _ = try reader.readIntBig(u16);
    _ = try reader.readIntBig(u16);
    _ = try reader.readIntBig(u16);

    const metricDataFormat = try reader.readIntBig(u16);

    const numberOfHMetrics = try reader.readIntBig(u16);
    return HHEA{
        .ascender = ascender,
        .descender = descender,
        .lineGap = lineGap,
        .advanceWidthMax = advanceWidthMax,
        .minLeftSideBearing = minLeftSideBearing,
        .minRightSideBearing = minRightSideBearing,
        .xMaxExtent = xMaxExtent,
        .caretSlopeRise = caretSlopeRise,
        .caretSlopeRun = caretSlopeRun,
        .caretOffset = caretOffset,
        .metricDataFormat = metricDataFormat,
        .numberOfHMetrics = numberOfHMetrics,
    };
}
