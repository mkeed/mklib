const std = @import("std");
const DataReader = @import("dataReader.zig").DataReader;
const BitReader = @import("dataReader.zig").BitReader;
const Image = @import("Image.zig").Image;

const Filter = enum { None, Sub, Up, Average, Paeth };

pub const RenPixel = struct {
    r: u16,
    g: u16,
    b: u16,
    a: u16,
};

pub const Point = struct {
    x: usize,
    y: usize,
};

pub const DataIter = struct {
    data: []const u8,
    buf: [8]u8,
    idx: usize = 0,
    bytesPerPixel: usize,
    pub fn init(data: []const u8, bytesPerPixel: usize) !DataIter {
        return DataIter{
            .data = data,
            .buf = [8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 },
            .bytesPerPixel = bytesPerPixel,
        };
    }
    pub fn nextOrZero(self: *DataIter) []const u8 {
        if (self.next()) |val| return val;
        for (self.buf) |*v| v.* = 0;
        return self.buf[0..];
    }
    pub fn next(self: *DataIter) ?[]const u8 {
        if (((self.idx + 1) * self.bytesPerPixel) > self.data.len) return null;
        defer self.idx += 1;
        return self.data[(self.idx * self.bytesPerPixel)..((self.idx + 1) * self.bytesPerPixel)];
    }
};

pub const PImage = struct {
    img: Image,
    depth: u8,
    channels: u8,
    interlace: IHDR.Interlace,

    pub fn init(interlace: IHDR.Interlace, depth: u8, channels: u8, img: Image) PImage {
        return .{
            .interlace = interlace,
            .depth = depth,
            .channels = channels,
            .img = img,
        };
    }

    pub fn mapPoint(self: PImage, x: usize, y: usize) Point {
        switch (self.interlace) {
            .None => {
                return .{ .x = x, .y = y };
            },
            .Adam7 => {
                const blocks = std.math.divCeil(usize, self.img.height, 8) catch unreachable;
                return if (y < blocks) .{
                    .x = x * 8,
                    .y = y * 8,
                } else if (y < blocks * 2) .{
                    .x = (x * 8) + 4,
                    .y = (y - blocks) * 8,
                } else if (y < blocks * 3) .{
                    .x = (x * 4),
                    .y = ((y - (blocks * 2)) * 8) + 4,
                } else if (y < (blocks * 5)) .{
                    .x = (x * 4) + 2,
                    .y = (y - (blocks * 3)) * 4,
                } else if (y < (blocks * 7)) .{
                    .x = x * 2,
                    .y = ((y - (blocks * 5)) * 4) + 2,
                } else if (y < (blocks * 11)) .{
                    .x = (x * 2) + 1,
                    .y = (y - (blocks * 7)) * 2,
                } else .{
                    .x = x,
                    .y = ((y - (blocks * 11)) * 2) + 1,
                };
            },
        }
    }

    pub fn isStartOfBlock(self: PImage, y: usize) bool {
        switch (self.interlace) {
            .None => {
                return y == 0;
            },
            .Adam7 => {
                const blocks = std.math.divCeil(usize, self.img.height, 8) catch unreachable;

                return (y == 0 or y == blocks or y == blocks * 2 or y == blocks * 3 or y == blocks * 5 or y == blocks * 7 or y == blocks * 11);
            },
        }
    }
    const subByteIter = struct {
        data: []const u8,
        idx: usize = 0,
        bits: u8,
        pub fn next(self: *subByteIter, buf: []u8) ?[]u8 {
            if (((self.idx + 1) * self.bits) > self.data.len * 8) return null;
            defer self.idx += 1;
            const byteIdx = (self.idx * self.bits) / 8;
            switch (self.bits) {
                1 => {
                    const bitIdx = 7 - @truncate(u3, self.idx % 8);
                    const val = @intCast(u8, @truncate(u1, self.data[byteIdx] >> bitIdx));
                    buf[0] = val;
                    buf[1] = 0;
                    return buf[0..1];
                },
                2 => {
                    const bitIdx = 7 - @truncate(u3, (2 * self.idx) % 8) - 1;
                    const val = @intCast(u8, @truncate(u2, self.data[byteIdx] >> bitIdx));
                    buf[0] = val;
                    buf[1] = 0;
                    return buf[0..1];
                },
                4 => {
                    const bitIdx = 7 - @truncate(u3, (4 * self.idx) % 8) - 3;
                    const val = @intCast(u8, @truncate(u4, self.data[byteIdx] >> bitIdx));
                    buf[0] = val;
                    buf[1] = 0;
                    return buf[0..1];
                },
                8 => {
                    buf[0] = self.data[byteIdx];
                    buf[1] = 0;
                    return buf[0..1];
                },
                16 => {
                    buf[0] = self.data[byteIdx];
                    buf[1] = self.data[byteIdx + 1];
                    return buf[0..2];
                },
                else => return null,
            }
        }
    };
    const multiChannelIter = struct {
        iter: subByteIter,
        channels: u8,
        pub fn next(self: *multiChannelIter, buf: []u8) ?[]const u8 {
            var channel: usize = 0;
            var idx: usize = 0;
            while (channel < self.channels) : (channel += 1) {
                if (self.iter.next(buf[idx..])) |val| {
                    idx += val.len;
                } else {
                    return null;
                }
            }
            return buf[0..idx];
        }
    };

    pub fn readRow(self: PImage, data: []const u8, y: usize, iter: *interlaceIter) void {
        var mci = multiChannelIter{
            .iter = subByteIter{
                .data = data,
                .bits = self.depth,
            },
            .channels = self.channels,
        };
        var buf: [8]u8 = [8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 };
        while (iter.nextX()) |x| {
            const pixdata = mci.next(buf[0..]) orelse return;
            self.img.setPixel(x, y, pixdata);
        }
    }
};

var exitEarly = false;

pub const PLTE = struct {
    alloc: std.mem.Allocator,
    data: []const u8,
    pub fn init(data: []const u8, alloc: std.mem.Allocator) !PLTE {
        if (data.len % 3 != 0) return error.InvaldPLTE;

        var savedData = try alloc.alloc(u8, data.len);
        for (data, 0..) |v, i| savedData[i] = v;
        errdefer alloc.free(savedData);
        return PLTE{
            .alloc = alloc,
            .data = savedData,
        };
    }
    pub fn get(self: PLTE, idx: usize) ?[]const u8 {
        if (idx > self.data.len / 3) return null;
        return self.data[idx * 3 .. (idx + 1) * 3];
    }
    pub fn deinit(self: PLTE) void {
        self.alloc.free(self.data);
    }
};

pub const interlaceIter = struct {
    pub fn init(interlace: IHDR.Interlace, height: usize, width: usize) interlaceIter {
        return .{
            .interlace = interlace,
            .curPass = 0,
            .yPos = 0,
            .xPos = 0,
            .height = height,
            .width = width,
        };
    }
    pub fn nextY(self: *interlaceIter, prevRow: []u8) ?usize {
        defer {}
        self.xPos = xoffset[self.curPass];
        //std.log.info("nextY", .{});
        switch (self.interlace) {
            .None => {
                if (self.yPos < self.height) {
                    defer self.yPos += 1;
                    //std.log.info("nextY(None) => {}", .{self.yPos});
                    return self.yPos;
                } else {
                    return null;
                }
            },
            .Adam7 => {
                if (self.curPass != 0) {
                    if (self.yPos + ysteps[self.curPass] < self.height) {
                        self.yPos += ysteps[self.curPass];
                        //std.log.info("nextY(Adam7)[{}] => {}", .{ self.curPass, self.yPos });
                        return self.yPos;
                    } else {
                        while (self.curPass < 7) {
                            self.curPass += 1;
                            for (prevRow) |*v| v.* = 0;
                            self.xPos = xoffset[self.curPass];
                            self.yPos = yoffset[self.curPass];
                            //std.log.info("possiblenextY(Adam7)[{}] => {}", .{ self.curPass, self.yPos });
                            if (self.yPos < self.height and self.xPos < self.width) {
                                //std.log.info("nextY(Adam7)[{}] => {}", .{ self.curPass, self.yPos });
                                return self.yPos;
                            } else continue;
                        }
                        return null;
                    }
                } else {
                    self.curPass = 1;
                    self.yPos = yoffset[self.curPass];
                    self.xPos = xoffset[self.curPass];
                    //std.log.info("nextY[i](Adam7) => {}", .{self.yPos});
                    return self.yPos;
                }
            },
        }
    }

    pub fn numX(self: interlaceIter) !usize {
        switch (self.interlace) {
            .None => {
                //std.log.info("numX(None)=>{}", .{self.width});
                return self.width;
            },
            .Adam7 => {
                if (self.curPass == 0) return error.InvalidData;
                var x = xoffset[self.curPass];
                var count: usize = 0;
                while (x < self.width) : (x += xsteps[self.curPass]) {
                    count += 1;
                }
                //std.log.info("numX([{}]Adam7)=>{}", .{ self.curPass, count });
                return count;
            },
        }
    }

    pub fn nextX(self: *interlaceIter) ?usize {
        switch (self.interlace) {
            .None => {
                if (self.xPos < self.width) {
                    defer self.xPos += 1;
                    //std.log.info("nextX1(None)=>{}", .{self.xPos});
                    return self.xPos;
                } else {
                    //std.log.info("nextX0(None)=>{}", .{self.xPos});
                    return null;
                }
            },
            .Adam7 => {
                if (self.curPass == 0) {
                    return null;
                } else {
                    if (self.xPos < self.width) {
                        defer self.xPos += xsteps[self.curPass];

                        return self.xPos;
                    } else {
                        return null;
                    }
                }
            },
        }
    }

    const ysteps = [_]usize{ 0, 8, 8, 8, 4, 4, 2, 2 };
    const yoffset = [_]usize{ 0, 0, 0, 4, 0, 2, 0, 1 };
    const xsteps = [_]usize{ 0, 8, 8, 4, 4, 2, 2, 1 };
    const xoffset = [_]usize{ 0, 0, 4, 0, 2, 0, 1, 0 };
    //1 6 4 6 2 6 4 6
    //7 7 7 7 7 7 7 7
    //5 6 5 6 5 6 5 6
    //7 7 7 7 7 7 7 7
    //3 6 4 6 3 6 4 6
    //7 7 7 7 7 7 7 7
    //5 6 5 6 5 6 5 6
    //7 7 7 7 7 7 7 7

    interlace: IHDR.Interlace,
    curPass: u8,
    xPos: usize,
    yPos: usize,
    height: usize,
    width: usize,
};

pub fn parseIDAT(data: []const u8, alloc: std.mem.Allocator, header: IHDR, img: Image) !void {
    var fbStream = std.io.fixedBufferStream(data);
    var reader = fbStream.reader();
    var decomp = try std.compress.zlib.zlibStream(alloc, reader);
    defer decomp.deinit();
    var output = try decomp.reader().readAllAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(output);
    //std.log.err("data =>{}", .{std.fmt.fmtSliceHexUpper(output)});
    //std.log.err("bytes:{}", .{header.bytesPerRow(0)});
    var dr = DataReader.init(output, .Big);

    var pimg = PImage.init(header.interlace, header.depth, header.numChannels(), img);

    var prevRow = try alloc.alloc(u8, header.bytesPerPixel() * header.width);
    defer alloc.free(prevRow);
    for (prevRow) |*v| v.* = 0;
    var curRow = try alloc.alloc(u8, header.bytesPerPixel() * header.width);
    defer alloc.free(curRow);
    for (curRow) |*v| v.* = 0;

    var iter = interlaceIter.init(header.interlace, header.height, header.width);

    while (iter.nextY(prevRow)) |scanLine| {
        var rowData = try dr.readSlice(((7 + try iter.numX() * header.bitsPerPixel()) / 8) + 1);
        //std.log.err("Row:[{}]", .{std.fmt.fmtSliceHexUpper(rowData)});
        try parseLine(rowData, curRow, prevRow, header.bytesPerPixel());

        pimg.readRow(curRow[0 .. rowData.len - 1], scanLine, &iter);
        for (curRow, 0..) |*v, i| {
            prevRow[i] = v.*;
            v.* = 0;
        }
        if (exitEarly) {
            exitEarly = false;
            return;
        }
    }
}
pub fn avgArray(output: []u8, raw: []const u8, a: []const u8, b: []const u8) []const u8 {
    // std.log.err("avgarray({},{},{}) => ()", .{
    //     std.fmt.fmtSliceHexUpper(raw),
    //     std.fmt.fmtSliceHexUpper(a),
    //     std.fmt.fmtSliceHexUpper(b),
    // });
    for (raw, 0..) |val, idx| {
        output[idx] = @truncate(u8, @intCast(u16, val) +% (std.math.divFloor(u16, (@intCast(u16, a[idx]) + @intCast(u16, b[idx])), 2) catch unreachable));
    }
    return output[0..raw.len];
}
pub fn subArray(output: []u8, a: []const u8, b: []const u8) []const u8 {
    if (b.len == 0) {
        for (a, 0..) |val, idx| {
            output[idx] = val;
        }

        return output[0..a.len];
    } else {
        for (a, 0..) |val, idx| {
            output[idx] = val +% b[idx];
        }
        return output[0..a.len];
    }
}

pub fn paethPredictor(a: u8, b: u8, c: u8) u8 {
    const p: i16 = @intCast(i16, a) +% @intCast(i16, b) -% @intCast(i16, c);
    const pa = std.math.absCast(p - @intCast(i16, a));
    const pb = std.math.absCast(p - @intCast(i16, b));
    const pc = std.math.absCast(p - @intCast(i16, c));
    return if (pa <= pb and pa <= pc) a else if (pb <= pc) b else c;
}

pub fn paethPredictorBuf(buf: []u8, input: []const u8, a: []const u8, b: []const u8, c: []const u8) []const u8 {
    // std.log.info("in:[{}] a:[{}] b:[{}] c:[{}]", .{
    //     std.fmt.fmtSliceHexUpper(input),
    //     std.fmt.fmtSliceHexUpper(a),
    //     std.fmt.fmtSliceHexUpper(b),
    //     std.fmt.fmtSliceHexUpper(c),
    // });
    for (input, 0..) |val, idx| {
        const pp = paethPredictor(a[idx], b[idx], c[idx]);
        buf[idx] = val +% pp;
    }
    return buf[0..input.len];
}

pub fn parseLine(rowData: []const u8, outRow: []u8, prevRow: []const u8, bytesPerPixel: u8) !void {
    //std.log.info("rowData:[{}] prevRow:[{}]", .{ std.fmt.fmtSliceHexUpper(rowData), std.fmt.fmtSliceHexUpper(prevRow) });
    const filter = try std.meta.intToEnum(Filter, rowData[0]);
    var iter = try DataIter.init(rowData[1..], bytesPerPixel);
    var filteredBuf = [8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 };
    const zeroBuf = [8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 };
    var idx: usize = 0;
    while (iter.next()) |data| {
        const colidx = bytesPerPixel * idx;
        const prevIdx = if (idx != 0) bytesPerPixel * (idx - 1) else 0;
        defer idx += 1;
        const pixel = switch (filter) {
            .None => data,
            .Sub => subArray(
                filteredBuf[0..],
                data,
                if (idx == 0) zeroBuf[0..bytesPerPixel] else outRow[prevIdx .. prevIdx + bytesPerPixel],
            ),
            .Up => subArray(
                filteredBuf[0..],
                data,
                prevRow[colidx .. colidx + bytesPerPixel],
            ),
            .Average => avgArray(
                filteredBuf[0..],
                data,
                prevRow[colidx .. colidx + bytesPerPixel],
                if (idx == 0) zeroBuf[0..bytesPerPixel] else outRow[prevIdx .. prevIdx + bytesPerPixel],
            ),

            .Paeth => paethPredictorBuf(
                filteredBuf[0..],
                data,
                if (idx == 0) zeroBuf[0..bytesPerPixel] else outRow[prevIdx .. prevIdx + bytesPerPixel],
                prevRow[colidx .. colidx + bytesPerPixel],
                if (idx == 0) zeroBuf[0..bytesPerPixel] else prevRow[prevIdx .. prevIdx + bytesPerPixel],
            ),
        };

        for (pixel, 0..) |v, pidx| {
            outRow[colidx + pidx] = v;
        }
    }
}

pub const IHDR = struct {
    pub const ColourType = enum(u8) {
        GrayScale = 0,
        RGB = 2,
        Palette = 3,
        AlphaGrayScale = 4,
        AlphaRGB = 6,
    };
    pub fn scaleDepth(comptime T: type, val: u16, depth: u16) T {
        if (val >= std.math.pow(u32, 2, depth)) return std.math.maxInt(T);
        return (std.math.maxInt(T) / @truncate(T, std.math.pow(u32, 2, @truncate(T, depth)) - 1)) * @truncate(T, val);
    }
    pub fn convertToRGB(self: IHDR, data: []const u8) !RenPixel {
        switch (self.colourType) {
            .GrayScale => {
                if (self.depth == 16) {
                    return RenPixel{
                        .r = std.mem.readIntSliceBig(u16, data[0..]),
                        .g = std.mem.readIntSliceBig(u16, data[0..]),
                        .b = std.mem.readIntSliceBig(u16, data[0..]),
                        .a = std.math.maxInt(u16),
                    };
                } else {
                    const val = scaleDepth(u8, data[0], self.depth);

                    return RenPixel{
                        .r = val,
                        .g = val,
                        .b = val,
                        .a = val,
                    };
                }
            },
            .RGB => {
                if (self.depth == 16) {
                    return RenPixel{
                        .r = std.mem.readIntSliceBig(u16, data[0..]),
                        .g = std.mem.readIntSliceBig(u16, data[2..]),
                        .b = std.mem.readIntSliceBig(u16, data[4..]),
                        .a = std.math.maxInt(u16),
                    };
                } else {
                    return RenPixel{
                        .r = data[0],
                        .g = data[1],
                        .b = data[2],
                        .a = std.math.maxInt(u8),
                    };
                }
            },
            .Palette => {
                if (self.palette) |p| {
                    if (p.get(data[0])) |val| {
                        return RenPixel{
                            .r = val[0],
                            .g = val[1],
                            .b = val[2],
                            .a = std.math.maxInt(u8),
                        };
                    } else {
                        return error.PaletteTooSmall;
                    }
                } else {
                    return error.PaletteNotSet;
                }
            },
            .AlphaGrayScale => {
                if (self.depth == 16) {
                    const val = std.mem.readIntSliceBig(u16, data[0..]);
                    const alpha = std.mem.readIntSliceBig(u16, data[2..]);
                    return RenPixel{
                        .r = val,
                        .g = val,
                        .b = val,
                        .a = alpha,
                    };
                } else {
                    const val = data[0]; // I think this is right. GOing from u16 to u8 just measn throwing away lower 8 bits
                    const alpha = data[1];
                    return RenPixel{
                        .r = val,
                        .g = val,
                        .b = val,
                        .a = alpha,
                    };
                }
            },
            .AlphaRGB => {
                if (self.depth == 16) {
                    return RenPixel{
                        .r = std.mem.readIntSliceBig(u16, data[0..]),
                        .g = std.mem.readIntSliceBig(u16, data[2..]),
                        .b = std.mem.readIntSliceBig(u16, data[4..]),
                        .a = std.mem.readIntSliceBig(u16, data[6..]),
                    };
                } else {
                    return RenPixel{
                        .r = data[0],
                        .g = data[1],
                        .b = data[2],
                        .a = data[3],
                    };
                }
            },
        }
    }

    pub const Interlace = enum(u8) {
        None = 0,
        Adam7 = 1,
    };

    width: u32,
    height: u32,
    depth: u8,
    colourType: ColourType,
    filter: u8,
    interlace: Interlace,
    palette: ?PLTE = null,
    gama: ?u32 = null,
    sbit: ?[4]u8 = null,
    pub fn parse(data: []const u8) !IHDR {
        var dr = DataReader.init(data, .Big);
        const width = try dr.read(u32);
        const height = try dr.read(u32);
        const depth = try dr.read(u8);
        const colourType = std.meta.intToEnum(ColourType, try dr.read(u8)) catch return error.INvalidColourType;
        switch (colourType) {
            .GrayScale => {
                switch (depth) {
                    1, 2, 4, 8, 16 => {},
                    else => return error.InvalidColour,
                }
            },
            .RGB, .AlphaGrayScale, .AlphaRGB => {
                switch (depth) {
                    8, 16 => {},
                    else => return error.InvalidColour,
                }
            },
            .Palette => {
                switch (depth) {
                    1, 2, 4, 8 => {},
                    else => return error.InvalidColour,
                }
            },
        }

        const compression = try dr.read(u8);
        if (compression != 0) return error.InvalidCompression;
        const filter = try dr.read(u8);
        if (filter != 0) return error.InvalidFilter;
        const interlace = std.meta.intToEnum(Interlace, try dr.read(u8)) catch return error.InvalidInterlace;
        return IHDR{
            .width = width,
            .height = height,
            .depth = depth,
            .colourType = colourType,
            .filter = filter,
            .interlace = interlace,
        };
    }

    pub fn scanLineLen(self: IHDR, row: usize) usize {
        switch (self.interlace) {
            .Adam7 => {
                const blocks = std.math.divCeil(usize, self.height, 8) catch unreachable;
                const pixelsInBlock = if (row < blocks * 2) self.width / 8 //
                else if (row < (blocks * 5)) self.width / 4 //
                else if (row < (blocks * 11)) self.width / 2 //
                else self.width;
                return pixelsInBlock;
            },
            .None => {
                return self.width;
            },
        }
    }

    pub fn bytesPerPixel(self: IHDR) u8 {
        switch (self.colourType) {
            .GrayScale => {
                switch (self.depth) {
                    1, 2, 4, 8 => return 1,
                    16 => return 2,
                    else => unreachable,
                }
            },
            .RGB => {
                return if (self.depth == 8) 3 else 6;
            },
            .Palette => {
                return 1;
            },
            .AlphaGrayScale => {
                return if (self.depth == 8) 2 else 4;
            },
            .AlphaRGB => {
                return if (self.depth == 8) 4 else 8;
            },
        }
    }
    pub fn numChannels(self: IHDR) u8 {
        switch (self.colourType) {
            .Palette, .GrayScale => {
                return 1;
            },
            .RGB => {
                return 3;
            },
            .AlphaGrayScale => {
                return 2;
            },
            .AlphaRGB => {
                return 4;
            },
        }
    }
    pub fn bitsPerPixel(self: IHDR) u8 {
        return self.numChannels() * self.depth;
    }
    pub fn numScanLines(self: IHDR) usize {
        switch (self.interlace) {
            .None => {
                return self.height;
            },
            .Adam7 => {
                switch (self.height) {
                    1 => return 1,
                    2 => return 4,
                    3 => return 3,
                    else => {},
                }
                const blocks = std.math.divCeil(usize, self.height, 8) catch unreachable;
                const scansPer8 = @as(usize, 13);
                return (blocks) * scansPer8 + 8;
            },
        }
    }
    pub fn bytesPerRow(self: IHDR, row: usize) usize {
        switch (self.interlace) {
            .None => {
                const bitsPerRow = 7 + self.width * self.bitsPerPixel();
                return bitsPerRow / 8;
            },
            .Adam7 => {
                const blocks = std.math.divCeil(usize, self.height, 8) catch unreachable;
                const pixelsInBlock = if (row < blocks * 2) 7 + self.width / 8 //
                else if (row < (blocks * 5)) 3 + self.width / 4 //
                else if (row < (blocks * 11)) 1 + self.width / 2 //
                else self.width;
                //std.log.err("pixelsInblock:[{}] row:[{}] blocks:[{}]", .{ pixelsInBlock, row, blocks });

                const bitsPerRow = pixelsInBlock * self.bitsPerPixel();
                return std.math.divCeil(usize, bitsPerRow, 8) catch unreachable;
            },
        }
    }
    pub fn deinit(self: IHDR) void {
        if (self.palette) |p| {
            p.deinit();
        }
    }
};

pub fn table() [256]u32 {
    @setEvalBranchQuota(256 * 8 * 10);
    var crc_table = [1]u32{0} ** 256;
    for (crc_table[0..], 0..) |*val, idx| {
        var c = @truncate(u32, idx);
        var k: usize = 0;
        while (k < 8) : (k += 1) {
            if ((c & 1) != 0) {
                c = 0xedb88320 ^ (c >> 1);
            } else {
                c = c >> 1;
            }
        }
        val.* = c;
    }

    return crc_table;
}
const CRC_table = table();

fn computeCrc(data: []const u8) u32 {
    var crc: u32 = 0xFFFFFFFF;
    for (data) |val| {
        crc = CRC_table[@truncate(u8, crc ^ val)] ^ (crc >> 8);
    }
    return ~crc;
}

const startbytes = [8]u8{ 137, 80, 78, 71, 13, 10, 26, 10 };
pub const PNG = struct {
    img: Image,
    header: IHDR,
    pub fn deinit(self: PNG) void {
        self.img.deinit();
        self.header.deinit();
    }
    pub fn getPixel(self: PNG, x: usize, y: usize) ?RenPixel {
        if (self.img.getPixel(x, y)) |data| {
            return self.header.convertToRGB(data) catch return null;
        }
        return null;
    }
};

pub fn decoder(Reader: anytype) type {
    return struct {
        const Self = @this();
        pub fn init(reader: Reader) Self {}
    };
}

pub fn decodeImage(data: []const u8, alloc: std.mem.Allocator) !PNG {
    var dr = DataReader.init(data, .Big);
    const start = try dr.readSlice(startbytes.len);
    var header: ?IHDR = null;
    errdefer {
        if (header) |hdr| {
            hdr.deinit();
        }
    }
    var img: ?Image = null;
    errdefer {
        if (img) |i| {
            i.deinit();
        }
    }
    if (std.mem.eql(u8, start, startbytes[0..]) == false) {
        return error.InvalidBytes;
    }
    while (dr.dataAvailable()) {
        const length = try dr.read(u32);
        var chunkData = try dr.readReader(length + 4);
        const name = try chunkData.readArray(4);
        const crc = try dr.read(u32);
        const calcCRC = computeCrc(chunkData.data);
        if (crc != calcCRC) return error.InvalidCRC;
        if (std.mem.eql(u8, name[0..], "IHDR")) {
            header = try IHDR.parse(chunkData.rest());
            img = try Image.init(
                alloc,
                header.?.width,
                header.?.height,
                header.?.bytesPerPixel(),
            );
            //std.log.err("{any}", .{header});
        } else if (std.mem.eql(u8, name[0..], "IDAT")) {
            try parseIDAT(
                chunkData.rest(),
                alloc,
                header.?,
                img.?,
            );
            //std.log.err("IDAT", .{});
        } else if (std.mem.eql(u8, name[0..], "IEND")) {
            return PNG{
                .img = img.?,
                .header = header.?,
            };
        } else if (std.mem.eql(u8, name[0..], "PLTE")) {
            header.?.palette = try PLTE.init(chunkData.rest(), alloc);
            //std.log.err("PLTE", .{});
        } else if (std.mem.eql(u8, name[0..], "bKGD")) { // Background colour
            //try parseBKGD(chunkData.rest(), header.?.colourType);
            //std.log.err("bKGD", .{});
            //return error.NotImplemented;
        } else if (std.mem.eql(u8, name[0..], "cHRM")) { // Primary chromaticities and white point
            //std.log.err("cHRM", .{});
            //return error.NotImplemented;
        } else if (std.mem.eql(u8, name[0..], "gAMA")) { // Image gamma
            header.?.gama = try chunkData.read(u32);
        } else if (std.mem.eql(u8, name[0..], "hIST")) { // Image histogram
            if (header) |hdr| {
                if (hdr.palette) |plte| {
                    _ = plte;
                    //std.log.err("plte:{}", .{std.fmt.fmtSliceHexUpper(plte.data)});
                }
            }
            //std.log.err("hIST:{}", .{std.fmt.fmtSliceHexUpper(chunkData.rest())});
        } else if (std.mem.eql(u8, name[0..], "pHYs")) { // Physical pixel dimensions
            const xphys = try chunkData.read(u32);
            const yphys = try chunkData.read(u32);
            const unit = try chunkData.read(u8);
            //_ = xphys;
            //_ = yphys;
            //_ = unit;
            //try parsePHYS(chunkData.rest());
            std.log.info("pHYs:{}x{}:{}", .{ xphys, yphys, unit });
        } else if (std.mem.eql(u8, name[0..], "sBIT")) { // Significant bits
            var sbitdata = [4]u8{ 0, 0, 0, 0 };
            const rest = chunkData.rest();
            for (rest, 0..) |v, i| sbitdata[i] = v;
            header.?.sbit = sbitdata;
        } else if (std.mem.eql(u8, name[0..], "tEXt")) { // Textual data
            const cd = chunkData.rest();
            var idx: usize = 0;
            while (cd[idx] != 0) : (idx += 1) {}

            //std.log.err("tEXt:{s} => {s}", .{ cd[0..idx], cd[idx + 1 ..] });
        } else if (std.mem.eql(u8, name[0..], "tIME")) { // Image last-modification time
            const y = try chunkData.read(u16);
            const m = try chunkData.read(u8);
            const d = try chunkData.read(u8);
            const h = try chunkData.read(u8);
            const min = try chunkData.read(u8);
            const s = try chunkData.read(u8);
            _ = y;
            _ = m;
            _ = d;
            _ = h;
            _ = min;
            _ = s;
            //std.log.err("tIME {}-{}-{} {}:{}:{}", .{ y, m, d, h, min, s });
        } else if (std.mem.eql(u8, name[0..], "tRNS")) { // Transparency
            std.log.err("tRNS", .{});
            //return error.NotImplemented;
        } else if (std.mem.eql(u8, name[0..], "zTXt")) { // Compressed textual data

            const cd = chunkData.rest();
            var idx: usize = 0;
            while (cd[idx] != 0) : (idx += 1) {}
            //TODO decompress
            //std.log.err("zTXt :{s}", .{cd[0..idx]});
        }
    }
    return error.MissingIEND;
}
