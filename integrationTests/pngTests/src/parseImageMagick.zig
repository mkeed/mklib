const std = @import("std");

pub const Pixel = struct {
    r: u16,
    g: u16,
    b: u16,
};

pub const Image = struct {
    width: usize,
    height: usize,
    bitDepth: usize,
    pixels: std.ArrayList(Pixel),
    pub fn init(alloc: std.mem.Allocator, width: usize, height: usize, bitDepth: usize) !Image {
        var pixels = std.ArrayList(Pixel).init(alloc);
        try pixels.appendNTimes(.{ .r = 0, .g = 0, .b = 0 }, width * height);
        return Image{
            .width = width,
            .height = height,
            .bitDepth = bitDepth,
            .pixels = pixels,
        };
    }
    pub fn deinit(self: Image) void {
        self.pixels.deinit();
    }
    pub fn setPixel(self: Image, x: usize, y: usize, r: u16, g: u16, b: u16) void {
        if (x < self.width and y < self.height) {
            const idx = x + y * self.width;
            self.pixels.items[idx] = Pixel{
                .r = r,
                .g = g,
                .b = b,
            };
        }
    }
};

const imgType = enum {
    RGB,
    RGBA,
    GRAY,
    linearGray,
    linearyGrayA,
    srgb,
};

pub fn parse(reader: anytype, alloc: std.mem.Allocator) !Image {
    var readBuffer = std.ArrayList(u8).init(alloc);
    defer readBuffer.deinit();
    try reader.readUntilDelimiterArrayList(&readBuffer, '\n', 100000);

    var split = std.mem.split(u8, readBuffer.items, ":");
    _ = split.first();
    const vals = split.next() orelse return error.Invalid;
    var valSplit = std.mem.split(u8, vals, ",");
    const width = try std.fmt.parseInt(usize, std.mem.trim(u8, valSplit.next() orelse return error.InvalidWidth, &std.ascii.whitespace), 10);
    const height = try std.fmt.parseInt(usize, std.mem.trim(u8, valSplit.next() orelse return error.InvalidWidth, &std.ascii.whitespace), 10);
    const bitDepth = try std.fmt.parseInt(usize, std.mem.trim(u8, valSplit.next() orelse return error.InvalidWidth, &std.ascii.whitespace), 10);
    const imageType = valSplit.rest();

    var img = try Image.init(alloc, width, height, bitDepth);
    errdefer img.deinit();
    while (true) {
        reader.readUntilDelimiterArrayList(&readBuffer, '\n', 100000) catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        const line = try parseLine(readBuffer.items);
        img.setPixel(line.x, line.y, line.r, line.g, line.b);
    }
    return img;
}

const LineInfo = struct {
    x: usize,
    y: usize,
    r: u16,
    g: u16,
    b: u16,
};

fn parseLine(line: []const u8) !LineInfo {
    var token = std.mem.tokenize(u8, line, ",:()");
    const x = try std.fmt.parseInt(usize, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10);
    const y = try std.fmt.parseInt(usize, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10);
    _ = token.next() orelse return error.InvalidLine;

    const r = try std.fmt.parseInt(u16, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10);
    const g = try std.fmt.parseInt(u16, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10);
    const b = try std.fmt.parseInt(u16, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10);
    return LineInfo{ .x = x, .y = y, .r = r, .g = g, .b = b };
}

test {
    const alloc = std.testing.allocator;
    const file = @embedFile("PngSuite-2017jul19/basi0g01.txt");
    var stream = std.io.fixedBufferStream(file);
    const img = try parse(stream.reader(), alloc);
    defer img.deinit();
}
