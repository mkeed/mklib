const std = @import("std");

const MAXP = struct {
    numGlyphs: u16,
    maxPoints: ?u16 = null,
    maxContours: ?u16 = null,
    maxCompositePoints: ?u16 = null,
    maxCompositeContours: ?u16 = null,
    maxZones: ?u16 = null,
    maxTwilightPoints: ?u16 = null,
    maxStorage: ?u16 = null,
    maxFunctionDefs: ?u16 = null,
    maxInstructionDefs: ?u16 = null,
    maxStackElements: ?u16 = null,
    maxSizeOfInstructions: ?u16 = null,
    maxComponentElements: ?u16 = null,
    maxComponentDepth: ?u16 = null,
};

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !MAXP {
    _ = alloc;
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    const version = try reader.readIntBig(u32);
    var maxp = MAXP{ .numGlyphs = try reader.readIntBig(u16) };
    if (version == 0x0005000) {
        return maxp;
    }
    if (version != 0x00010000) return error.InvalidVersion;

    maxp.maxPoints = try reader.readIntBig(u16);
    maxp.maxContours = try reader.readIntBig(u16);
    maxp.maxCompositePoints = try reader.readIntBig(u16);
    maxp.maxCompositeContours = try reader.readIntBig(u16);
    maxp.maxZones = try reader.readIntBig(u16);
    maxp.maxTwilightPoints = try reader.readIntBig(u16);
    maxp.maxStorage = try reader.readIntBig(u16);
    maxp.maxFunctionDefs = try reader.readIntBig(u16);
    maxp.maxInstructionDefs = try reader.readIntBig(u16);
    maxp.maxStackElements = try reader.readIntBig(u16);
    maxp.maxSizeOfInstructions = try reader.readIntBig(u16);
    maxp.maxComponentElements = try reader.readIntBig(u16);
    maxp.maxComponentDepth = try reader.readIntBig(u16);
    return maxp;
}
