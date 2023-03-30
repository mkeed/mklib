const std = @import("std");

pub const Pixel = struct {
    r: u16,
    g: u16,
    b: u16,
    a: u16,
};

pub const Image = struct {
    width: usize,
    height: usize,
    bitDepth: usize,
    imageType: imgType,
    pixels: std.ArrayList(Pixel),
    pub fn init(alloc: std.mem.Allocator, width: usize, height: usize, bitDepth: usize, imageType: imgType) !Image {
        var pixels = std.ArrayList(Pixel).init(alloc);
        try pixels.appendNTimes(.{ .r = 0, .g = 0, .b = 0, .a = 0 }, width * height);
        return Image{
            .width = width,
            .height = height,
            .bitDepth = bitDepth,
            .imageType = imageType,
            .pixels = pixels,
        };
    }
    pub fn deinit(self: Image) void {
        self.pixels.deinit();
    }
    pub fn setPixel(self: Image, x: usize, y: usize, r: u16, g: u16, b: u16, a: u16) void {
        if (x < self.width and y < self.height) {
            const idx = x + y * self.width;
            self.pixels.items[idx] = Pixel{
                .r = r,
                .g = g,
                .b = b,
                .a = a,
            };
        }
    }
    pub fn format(self: Image, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer,
            \\impl.TestCase{{
            \\    .width = {},
            \\    .height = {},
            \\    .bitDepth = {},
            \\    .imageType = .{s},
            \\    .pixels = &.{{
        , .{ self.width, self.height, self.bitDepth, self.imageType.toString() });

        for (self.pixels.items, 0..) |pixel, idx| {
            if (self.imageType.isAlpha()) {
                try std.fmt.format(writer, ".{{.r = {},.g = {},.b = {},.a ={}}},", .{
                    pixel.r,
                    pixel.g,
                    pixel.b,
                    pixel.a,
                });
            } else {
                try std.fmt.format(writer, ".{{.r = {},.g = {},.b = {},}},", .{
                    pixel.r,
                    pixel.g,
                    pixel.b,
                });
            }
            if ((idx % self.width) == 0) try std.fmt.format(writer, "\n", .{});
        }
        try std.fmt.format(writer, "}}\n}}", .{});
    }
};

const imgType = enum {
    RGB,
    RGBA,
    Gray,
    LinearGray,
    LinearGrayA,
    SRGB,
    SRGBA,
    pub fn toString(self: imgType) []const u8 {
        return switch (self) {
            .RGB => "RGB",
            .RGBA => "RGBA",
            .Gray => "Gray",
            .LinearGray => "LinearGray",
            .LinearGrayA => "LinearGrayA",
            .SRGB => "SRGB",
            .SRGBA => "SRGBA",
        };
    }
    pub fn fromText(text: []const u8) !imgType {
        if (std.mem.eql(u8, "lineargray", text)) return imgType.LinearGray;
        if (std.mem.eql(u8, "lineargraya", text)) return imgType.LinearGrayA;
        if (std.mem.eql(u8, "rgb", text)) return imgType.RGB;
        if (std.mem.eql(u8, "rgba", text)) return imgType.RGBA;
        if (std.mem.eql(u8, "gray", text)) return imgType.Gray;
        if (std.mem.eql(u8, "srgb", text)) return imgType.SRGB;
        if (std.mem.eql(u8, "srgba", text)) return imgType.SRGBA;
        std.log.err("{s}", .{text});
        return error.InvalidType;
    }
    pub fn isAlpha(self: imgType) bool {
        return switch (self) {
            .RGB, .Gray, .SRGB, .LinearGray => false,
            .LinearGrayA, .SRGBA, .RGBA => true,
        };
    }
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
    const imageType = try imgType.fromText(valSplit.rest());

    var img = try Image.init(alloc, width, height, bitDepth, imageType);
    errdefer img.deinit();
    while (true) {
        reader.readUntilDelimiterArrayList(&readBuffer, '\n', 100000) catch |err| {
            switch (err) {
                error.EndOfStream => break,
                else => return err,
            }
        };
        const line = try parseLine(readBuffer.items, imageType);
        img.setPixel(line.x, line.y, line.r, line.g, line.b, line.a);
    }
    return img;
}

const LineInfo = struct {
    x: usize,
    y: usize,
    r: u16,
    g: u16,
    b: u16,
    a: u16,
};

fn parseLine(line: []const u8, imageType: imgType) !LineInfo {
    var token = std.mem.tokenize(u8, line, ",:()");
    const x = try std.fmt.parseInt(usize, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10);
    const y = try std.fmt.parseInt(usize, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10);
    _ = token.next() orelse return error.InvalidLine;

    const r = try std.fmt.parseInt(u16, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10);
    const g = try std.fmt.parseInt(u16, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10);
    const b = try std.fmt.parseInt(u16, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10);

    const isAlpha = imageType.isAlpha();

    const a = if (isAlpha) try std.fmt.parseInt(u16, std.mem.trim(u8, token.next() orelse return error.InvalidLine, &std.ascii.whitespace), 10) else 0;
    return LineInfo{ .x = x, .y = y, .r = r, .g = g, .b = b, .a = a };
}

test {
    const alloc = std.testing.allocator;
    var genFile = try std.fs.cwd().createFile("PngTests.zig", .{});
    defer genFile.close();
    var writer = genFile.writer();
    try std.fmt.format(writer, "const impl = @import(\"PngTestsImpl.zig\");\n", .{});
    try std.fmt.format(writer, "const rgb = impl.rgb;\n", .{});
    try std.fmt.format(writer, "const rgba = impl.rgba;\n", .{});
    var dir = try std.fs.cwd().openIterableDir("PngSuite-2017jul19", .{});
    defer dir.close();
    var iter = dir.iterate();

    var list = std.ArrayList(u8).init(alloc);
    defer list.deinit();

    try std.fmt.format(list.writer(), "pub const tests = [_]impl.TestInfo{{", .{});

    while (try iter.next()) |entry| {
        if (std.mem.indexOf(u8, entry.name, ".png")) |pos| {
            if (pos != entry.name.len - 4) continue;
            if (entry.name[0] != 'x') {
                var txtBuf = std.mem.zeroes([512]u8);
                const txtFile = try std.fmt.bufPrint(&txtBuf, "{s}.txt", .{entry.name[0..pos]});

                var defFile = dir.dir.openFile(txtFile, .{}) catch |err| {
                    std.log.err("{s}", .{txtFile});
                    return err;
                };
                defer defFile.close();
                var stream = std.io.BufferedReader(512, std.fs.File.Reader){ .unbuffered_reader = defFile.reader() };
                const img = try parse(stream.reader(), alloc);
                defer img.deinit();
                try std.fmt.format(writer, "const {s} = {};\n\n", .{ entry.name[0..pos], img });

                try std.fmt.format(list.writer(),
                    \\impl.TestInfo{{
                    \\    .name = "{s}",
                    \\    .testCase = {s},
                    \\    .enabled = false
                    \\}},
                , .{
                    entry.name,
                    entry.name[0..pos],
                });
            } else {
                try std.fmt.format(list.writer(),
                    \\impl.TestInfo{{
                    \\    .name = "{s}",
                    \\    .testCase = null,
                    \\    .enabled = false
                    \\}},
                , .{
                    entry.name,
                });
            }
            //std.log.err("{}", .{img});
        }
    }
    try std.fmt.format(list.writer(), "}};", .{});
    try std.fmt.format(writer, "{s}", .{list.items});
}
