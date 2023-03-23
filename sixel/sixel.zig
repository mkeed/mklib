const std = @import("std");

pub const Pixel = struct { r: u8, g: u8, b: u8 };

fn getPixel(pixels: []const u8, width: usize, height: usize, x: usize, y: usize) u8 {
    if (x >= width or y >= height) {
        return 0;
    }
    return pixels[width * y + x];
}

pub fn render(pallete: []const Pixel, pixels: []const u8, width: usize, height: usize, writer: anytype) !void {
    try std.fmt.format(writer, "\x1bPq", .{});
    for (pallete, 0..) |p, idx| {
        try std.fmt.format(writer, "#{};2;{};{};{}", .{ idx, p.r, p.g, p.b });
    }
    var row: usize = 0;
    while (row < height) : (row += 6) {
        for (pallete, 0..) |_, pidx| {
            //
            try std.fmt.format(writer, "#{}", .{pidx});
            for (0..width) |w| {
                var val: u6 = 0;
                for (0..6) |r| {
                    if (getPixel(pixels, width, height, w, row + r) == pidx) {
                        val |= @as(u6, 1) << @truncate(u3, r);
                    }
                }
                try std.fmt.format(writer, "{c}", .{toSixelAscii(val)});
            }
            if (pidx == pallete.len - 1) {
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

    try render(&pallete, img.items, width, height, writer);

    try std.fmt.format(stdout, "\n\n{s}\n\n", .{buffer.items});
}
