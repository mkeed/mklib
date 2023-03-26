const std = @import("std");

pub fn parse(data: []const u8, alloc: std.mem.Allocator) !GSUB {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    const majorVersion = try reader.readIntBig(u16);
    if (majorVersion != 1) return error.InvalidVersion;
    const minorVersion = try reader.readIntBig(u16);
    if (minorVersion != 0 or minorVersion != 1) return error.InvalidVersion;

    try parseScriptList(data[try reader.readIntBig(u16)..], alloc);
    try parseFeatureList(data[try reader.readIntBig(u16)..], alloc);
    try parseLookupList(data[try reader.readIntBig(u16)..], alloc);

    if (minorVersion == 1) {
        try parseFeatureVariationsList(data[try reader.readIntBig(u32)..], alloc);
    }
}

fn parseScriptList(data: []const u8, alloc: std.mem.Allocator) !void {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    const count = try reader.readIntBig(u16);
    for (0..count) |script| {
        const tag = [4]u8{
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
        };
        const offset = try reader.readIntBig(u16);
    }

    //
}

fn parseSciptTable(data: []const u8, alloc: std.mem.Allocator) !void {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    const defaultLangSysOffset = try reader.readIntBig(u16);
    const count = try reader.readIntBig(u16);
    for (0..count) |_| {
        const tag = [4]u8{
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
            try reader.readIntBig(u8),
        };
        const offset = try reader.readIntBig(u16);
    }
}

fn parseFeatureList(data: []const u8, alloc: std.mem.Allocator) !void {
    //
}

fn parseLookupList(data: []const u8, alloc: std.mem.Allocator) !void {
    //
}

fn parseFeatureVarationsList(data: []const u8, alloc: std.mem.Allocator) !void {
    //
}
