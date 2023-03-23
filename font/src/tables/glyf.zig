const std = @import("std");

const Point = struct { x: i16, y: i16 };
const StraightLine = struct {
    start: Point,
    end: Point,
};

const CurvedLine = struct {
    start: Point,
    control: Point,
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

const CompositeGlyph = struct {
    pub fn init(alloc: std.mem.Allocator) CompositeGlyph {
        return .{
            .subGlyphs = std.ArrayList(SubGlyph).init(alloc),
        };
    }
    pub fn deinit(self: CompositeGlyph) void {
        self.subGlyphs.deinit();
    }
    pub const SubGlyph = struct {
        glyphIdx: usize,
        x: i16,
        y: i16,
    };
    subGlyphs: std.ArrayList(SubGlyph),
};

const RegularGlyph = struct {
    alloc: std.mem.Allocator,
    contours: std.ArrayList(Contour),
    pub fn init(alloc: std.mem.Allocator) RegularGlyph {
        return RegularGlyph{
            .alloc = alloc,
            .contours = std.ArrayList(Contour).init(alloc),
        };
    }
    pub fn deinit(self: RegularGlyph) void {
        for (self.contours.items) |item| {
            item.deinit();
        }
        self.contours.deinit();
    }
    pub fn addSegment(self: RegularGyph, line: Line) !void {
        if (self.contours.items.len == 0) {
            try self.newContour();
        }
        try self.contours.items[self.contours.items.len - 1].points.append(line);
    }
    pub fn newContour(self: RegularGlyph) !void {
        var c = Contour.init(alloc);
        errdefer c.deinit();
        try self.contours.append(c);
    }
};

const Glyph = struct {
    pub fn deinit(self: Glyph) void {
        switch (self.info) {
            inline else => |val| val.deinit(),
        }
    }
    xMin: i16,
    yMin: i16,
    xMax: i16,
    yMax: i16,
    info: GlyphInfo,
    pub const GlyphInfo = union(enum) {
        glyph: RegularGlyph,
        composite: CompositeGlyph,
    };
};

const CompositeGlyfFlag = packed struct(u16) {
    AreWords: u1,
    AreXY: u1,
    RoundToGrid: u1,
    WeHaveAScale: u1,

    Reserved: u1,
    MoreComponents: u1,
    HaveXandYScale: u1,
    Have2x2: u1,

    HaveInstructions: u1,
    UseMyMetrics: u1,
    OverlapCompund: u1,
    ScaledComponentOffset: u1,

    UnscaledComponentOffset: u1,
    Reserved2: u3,
};

const GLYF = struct {
    glyphs: std.ArrayList(Glyph),
    pub fn init(alloc: std.mem.Allocator) GLYF {
        return GLYF{
            .glyphs = std.ArrayList(Glyph).init(alloc),
        };
    }
    pub fn deinit(self: GLYF) void {
        for (self.glyphs.items) |item| {
            item.deinit();
        }
        self.glyphs.deinit();
    }
};

pub fn parse(data: []const u8, alloc: std.mem.Allocator, numGlyfs: usize) !GLYF {
    var returnVal = GLYF.init(alloc);
    errdefer returnVal.deinit();
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    //std.log.info("data:[{}]enddata", .{std.fmt.fmtSliceHexUpper(data[)});
    var xPointBuffer = std.ArrayList(i16).init(alloc);
    defer xPointBuffer.deinit();
    var yPointBuffer = std.ArrayList(i16).init(alloc);
    defer yPointBuffer.deinit();
    var isCurveBuffer = std.ArrayList(bool).init(alloc);
    defer isCurveBuffer.deinit();
    var pointsBuffer = std.ArrayList(u16).init(alloc);
    defer pointsBuffer.deinit();
    for (0..numGlyfs) |glyfIdx| {
        //std.log.info("{}[{}:{x}]------------------------------------------------------------", .{ glyfIdx, fbs.pos, fbs.pos });
        xPointBuffer.clearRetainingCapacity();
        yPointBuffer.clearRetainingCapacity();
        isCurveBuffer.clearRetainingCapacity();
        pointsBuffer.clearRetainingCapacity();
        const numberOfContours = try reader.readIntBig(i16);

        const xMin = try reader.readIntBig(i16);
        const yMin = try reader.readIntBig(i16);
        const xMax = try reader.readIntBig(i16);
        const yMax = try reader.readIntBig(i16);

        if (numberOfContours < 0) {
            var composite = CompositeGlyph.init(alloc);
            errdefer composite.deinit();
            std.log.err("glyf:{} data:[{}]", .{ glyfIdx, std.fmt.fmtSliceHexUpper(data[fbs.pos .. fbs.pos + 20]) });
            var more = true;
            while (more) {
                const flags = try reader.readIntBig(u16);
                const flagSet = @ptrCast(*const CompositeGlyfFlag, &flags);
                std.log.err("Flags:{}", .{flagSet});
                more = ((flags & 0x0020) != 0);
                const index = try reader.readIntBig(u16);
                const arg1 = if ((flags & 0x0001) != 0) try reader.readIntBig(u16) else try reader.readIntBig(u8);
                const arg2 = if ((flags & 0x0001) != 0) try reader.readIntBig(u16) else try reader.readIntBig(u8);
                try composite.subGlyphs.append(.{
                    .glyphIdx = index,
                    .x = @bitCast(i16, arg1),
                    .y = @bitCast(i16, arg2),
                });
                std.log.info("composite {}: {}@[{}x{}]", .{ flags, index, arg1, arg2 });
                if (flags & 0x0008 != 0) {
                    const scale = try reader.readIntBig(u16);
                    std.log.info("{}.{}", .{
                        @truncate(u2, scale >> 14),
                        @truncate(u14, scale),
                    });
                }
                if (flags & 0x0040 != 0) {
                    const scale2 = try reader.readIntBig(u16);
                    std.log.info("{}.{}", .{
                        @truncate(u2, scale2 >> 14),
                        @truncate(u14, scale2),
                    });
                }
                if (flags & ~@as(u16, 0x01 | 0x02 | 0x04 | 0x20 | 0x200 | 0x800 | 0x400) != 0) {
                    std.log.err("flags:{x}:", .{flags});
                    std.log.err("data:[{}]:", .{std.fmt.fmtSliceHexUpper(data[fbs.pos .. fbs.pos + 20])});
                    composite.deinit();
                    return returnVal;
                    //return error.CompositeNotImplemented;
                }
            }
            try returnVal.glyphs.append(.{
                .xMin = xMin,
                .yMin = yMin,
                .xMax = xMax,
                .yMax = yMax,
                .info = .{
                    .composite = composite,
                },
            });
            continue;
        }
        var regular = RegularGlyph.init(alloc);

        const num = @intCast(u16, numberOfContours);
        var last: usize = 0;
        for (0..num) |_| {
            const endPoint = try reader.readIntBig(u16);
            try pointsBuffer.append(endPoint);
            last = endPoint;
        }
        const instructionLength = try reader.readIntBig(u16);
        for (0..instructionLength) |_| {
            const instruction = try reader.readIntBig(u8);
            _ = instruction;
        }
        var flags = std.ArrayList(Flag).init(alloc);
        defer flags.deinit();
        var flagcount: usize = 0;
        while (flagcount < (last + 1)) : (flagcount += 1) {
            const flagVal = try reader.readIntBig(u8);
            const flag = @ptrCast(*const Flag, &flagVal);
            try flags.append(flag.*);
            if (flag.repeat == 1) {
                const times = try reader.readIntBig(u8);
                flagcount += times;
                try flags.appendNTimes(flag.*, times);
            }
        }
        var curPoint: i16 = 0;
        for (flags.items) |f| {
            const val = if (f.xShort == 1)
                @intCast(i16, try reader.readIntBig(u8)) * if (f.xSame == 1) @as(i16, 1) else @as(i16, -1)
            else if (f.xSame == 1) @as(i16, 0) else try reader.readIntBig(i16);
            curPoint += val;
            try xPointBuffer.append(curPoint);
            try isCurveBuffer.append(f.onCurve == 1);
        }
        curPoint = 0;
        for (flags.items) |f| {
            const val = if (f.yShort == 1)
                @intCast(i16, try reader.readIntBig(u8)) * if (f.ySame == 1) @as(i16, 1) else @as(i16, -1)
            else if (f.ySame == 1) @as(i16, 0) else try reader.readIntBig(i16);
            curPoint += val;
            try yPointBuffer.append(curPoint);
        }
        if (yPointBuffer.items.len != xPointBuffer.items.len) return error.InvalidNumberOfPoints;
        var lastX: u16 = xPointBuffer.items[0];
        var lastY: u16 = yPointBuffer.items[0];
        var lastCurve: bool = true;
        for (xPointBuffer.items[1..], yPointBuffer.items[1..], isCurveBuffer.items[1..], 1..) |x, y, curve, idx| {
            const lastX = xPointsBuffer.items[idx - 1];
            const lastY = yPointsBuffer.items[idx - 1];
            const lastCurve = isCurveBuffer.items[idx - 1];
            defer {
                lastX = x;
                lastY = y;
                lastCurve = curve;
            }
            if (curve and lastCurve) {
                try regular.addSegment(.{
                    .straight = .{
                        .start = .{ .x = lastX, .y = lastY },
                        .end = .{ .x = y, .y = y },
                    },
                });
            }
            const c: u8 = if (curve) 'p' else 'c';
            std.log.info("[{},{}][{c}]", .{ x, y, c });
            if (std.mem.indexOf(u16, pointsBuffer.items, &.{@truncate(u16, idx)}) != null) {
                std.log.info("end of contour", .{});
            }
        }

        //if (glyfIdx > 4) break;
    }

    return returnVal;
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
