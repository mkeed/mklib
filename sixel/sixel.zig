const std = @import("std");

pub const Pixel = struct { r: u8, g: u8, b: u8 };

fn getPixel(pixels: []const u8, width: usize, height: usize, x: usize, y: usize) u8 {
    if (x >= width or y >= height) {
        return 0;
    }
    return pixels[width * y + x];
}

const imgRender = struct {
    pallete: []const Pixel,
    pixels: []const u8,
    width: usize,
    height: usize,
    pub fn getHeight(self: imgRender) usize {
        return self.height;
    }
    pub fn getWidth(self: imgRender) usize {
        return self.width;
    }
    pub fn getPallete(self: imgRender, idx: usize) ?Pixel {
        if (idx < self.pallete.len) return self.pallete[idx];
        return null;
    }
    pub fn getPixel(self: imgRender, x: usize, y: usize) u8 {
        if (x >= self.width or y >= self.height) {
            return 0;
        }
        return self.pixels[self.width * y + x];
    }
};

pub fn render(
    img: anytype,
    writer: anytype,
) !void {
    try std.fmt.format(writer, "\x1bPq", .{});
    var numPallete: usize = 0;
    while (img.getPallete(numPallete)) |p| {
        defer numPallete += 1;
        try std.fmt.format(writer, "#{};2;{};{};{}", .{ numPallete, p.r, p.g, p.b });
    }
    var row: usize = 0;
    while (row < img.getHeight()) : (row += 6) {
        for (0..numPallete) |pidx| {
            //
            try std.fmt.format(writer, "#{}", .{pidx});
            for (0..img.getWidth()) |w| {
                var val: u6 = 0;
                for (0..6) |r| {
                    if (img.getPixel(w, row + r) == pidx) {
                        val |= @as(u6, 1) << @truncate(u3, r);
                    }
                }
                try std.fmt.format(writer, "{c}", .{toSixelAscii(val)});
            }
            if (pidx == numPallete - 1) {
                try std.fmt.format(writer, "-\n", .{});
            } else {
                try std.fmt.format(writer, "$\n", .{});
            }
        }
    }

    try std.fmt.format(writer, "\x1b\x5c", .{});
}

//const sixelValues =

//<ESC>Pq
//#0;2;0;0;0#1;2;100;100;0#2;2;0;100;0
//#1~~@@vv@@~~@@~~$
//#2??}}GG}}??}}??-
//#1!14@
//<ESC>\
//~~@@vv@@~~@@~~
//##############
//##  ##  ##  ##
//##  ##  ##  ##
//##      ##  ##
//##  ##  ##  ##
//##  ##  ##  ##

//##############

fn toSixelAscii(val: u6) u8 {
    const res = '?' + @intCast(u8, val);
    return res;
}

test {
    const alloc = std.testing.allocator;
    var buffer = std.ArrayList(u8).init(alloc);
    defer buffer.deinit();
    const writer = buffer.writer();
    const stdout = std.io.getStdOut().writer();

    const pallete = [_]Pixel{
        .{ .r = 0, .g = 0, .b = 0 },
        .{ .r = 100, .g = 100, .b = 0 },
        .{ .r = 0, .g = 100, .b = 0 },
    };
    const width: usize = 100;
    const height: usize = 60;

    var img = std.ArrayList(u8).init(alloc);
    defer img.deinit();

    for (0..height) |_| {
        for (0..width) |w| {
            try img.append(if ((w / 2) % 2 != 0) 1 else 2);
        }
    }

    try render(imgRender{
        .pallete = &pallete,
        .pixels = img.items,
        .width = width,
        .height = height,
    }, writer);

    try std.fmt.format(stdout, "\n\n{s}\n\n", .{buffer.items});
}
