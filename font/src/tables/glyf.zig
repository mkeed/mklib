const std = @import("std");

const Point = struct { x: i16, y: i16 };
const StraightLine = struct {
    start: Point,
    end: Point,
};

const CurvedLine = struct {
    start: Point,
    control1: Point,
    Control2: Point,
    end: Point,
};

const Line = union(enum) {
    straight: StraightLine,
    curve: CurvedLine,
};
const Contour = struct {
    points: std.ArrayList(Line),
    pub fn init(alloc: std.mem.Allocator) Contour {
        return Contour{
            .points = std.ArrayList(Line).init(alloc),
        };
    }
    pub fn deinit(self: Contour) void {
        self.points.deinit();
    }
};

const Glyph = struct {
    alloc: std.mem.Allocator,
    contours: std.ArrayList(Contour),
    pub fn init(alloc: std.mem.Allocator) Glyph {
        return Glyph{
            .alloc = alloc,
            .contours = std.ArrayList(Contour).init(alloc),
        };
    }
};

const GLYF = struct {};

pub fn parse(data: []const u8, alloc: std.mem.Allocator, numGlyfs: usize) !GLYF {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    std.log.info("data:[{}]", .{std.fmt.fmtSliceHexUpper(data[0..100])});
    var xPointBuffer = std.ArrayList(i16).init(alloc);
    defer xPointBuffer.deinit();
    var yPointBuffer = std.ArrayList(i16).init(alloc);
    defer yPointBuffer.deinit();
    var isCurveBuffer = std.ArrayList(bool).init(alloc);
    defer isCurveBuffer.deinit();
    for (0..numGlyfs) |glyfIdx| {
        xPointBuffer.clearRetainingCapacity();
        yPointBuffer.clearRetainingCapacity();
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
            //std.log.info("point:{}", .{endPoint});
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
        var curPoint: i16 = 0;
        //std.log.info("vals:{}", .{std.fmt.fmtSliceHexUpper(data[fbs.pos .. fbs.pos + 20])});
        for (flags.items) |f| {
            //std.log.info("flags:{}", .{f});
            const val = if (f.xShort == 1)
                @intCast(i16, try reader.readIntBig(u8)) * if (f.xSame == 1) @as(i16, 1) else @as(i16, -1)
            else if (f.xSame == 1) @as(i16, 0) else try reader.readIntBig(i16);

            curPoint += val;
            try xPointBuffer.append(curPoint);
            std.log.info("val:{} x:{}", .{ val, curPoint });
        }
        curPoint = 0;
        //std.log.info("vals:{}", .{std.fmt.fmtSliceHexUpper(data[fbs.pos .. fbs.pos + 20])});
        for (flags.items) |f| {
            //std.log.info("flags:{}", .{f});
            const val = if (f.yShort == 1)
                @intCast(i16, try reader.readIntBig(u8)) * if (f.ySame == 1) @as(i16, 1) else @as(i16, -1)
            else if (f.ySame == 1) @as(i16, 0) else try reader.readIntBig(i16);
            curPoint += val;
            try yPointBuffer.append(curPoint);
            //std.log.info("val:{} y:{}", .{ val, curPoint });
        }
        for (xPointBuffer.items, yPointBuffer.items) |x, y| {
            std.log.info("point:[{}:{}]", .{ x, y });
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
