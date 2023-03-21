const std = @import("std");

const GLYF = struct {};

pub fn parse(data: []const u8, alloc: std.mem.Allocator, numGlyfs: usize) !GLYF {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    std.log.info("data:[{}]", .{std.fmt.fmtSliceHexUpper(data[0..100])});
    for (0..numGlyfs) |glyfIdx| {
        const numberOfContours = try reader.readIntBig(i16);
        if (numberOfContours < 0) return error.CompositeNotImplemented;
        const num = @intCast(u16, numberOfContours);
        const xMin = try reader.readIntBig(i16);
        const yMin = try reader.readIntBig(i16);
        const xMax = try reader.readIntBig(i16);
        const yMax = try reader.readIntBig(i16);
        var last: usize = 0;
        std.log.info("Contours:{} [{}:{} => {}:{}] ", .{ numberOfContours, xMin, yMin, xMax, yMax });
        for (0..num) |_| {
            const endPoint = try reader.readIntBig(u16);
            last = endPoint;
            std.log.info("point:{}", .{endPoint});
        }
        const instructionLength = try reader.readIntBig(u16);
        std.log.info("instructionLength:{}", .{instructionLength});
        for (0..instructionLength) |_| {
            const instruction = try reader.readIntBig(u8);
            _ = instruction;
            //std.log.info("Instruction:{}", .{instruction});
        }
        var flags = std.ArrayList(Flag).init(alloc);
        defer flags.deinit();
        for (0..(last + 1)) |_| {
            const flagVal = try reader.readIntBig(u8);
            const flag = @ptrCast(*const Flag, &flagVal);
            try flags.append(flag.*);
        }
        var curPoint: isize = 0;
        std.log.info("vals:{}", .{std.fmt.fmtSliceHexUpper(data[fbs.pos .. fbs.pos + 20])});
        for (flags.items) |f| {
            std.log.info("flags:{}", .{f});
            const val = if (f.xShort == 1)
                @intCast(i16, try reader.readIntBig(u8)) * if (f.xSame == 1) @as(i16, 1) else @as(i16, -1)
            else if (f.xSame == 1) @as(i16, 0) else try reader.readIntBig(i16);
            curPoint += val;
            std.log.info("val:{} x:{}", .{ val, curPoint });
        }
        curPoint = 0;
        std.log.info("vals:{}", .{std.fmt.fmtSliceHexUpper(data[fbs.pos .. fbs.pos + 20])});
        for (flags.items) |f| {
            std.log.info("flags:{}", .{f});
            const val = if (f.yShort == 1)
                @intCast(i16, try reader.readIntBig(u8)) * if (f.ySame == 1) @as(i16, 1) else @as(i16, -1)
            else if (f.ySame == 1) @as(i16, 0) else try reader.readIntBig(i16);
            curPoint += val;
            std.log.info("val:{} y:{}", .{ val, curPoint });
        }
        if (glyfIdx > 2) break;
    }

    return GLYF{};
}

const Flag = packed struct(u8) {
    onCurve: u1,
    xShort: u1,
    yShort: u1,
    repeat: u1,
    xSame: u1,
    ySame: u1,
    overLap: u1,
    reserved: u1,
};
