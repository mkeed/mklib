const std = @import("std");
const sixel = @import("sixel");
const bezier = @import("bezier");

fn setPoints(data: []u8, width: usize, points: []bezier.Point, val: u8) void {
    for (points) |p| {
        const thickness: usize = 2;
        const x_usize = @intCast(usize, p.x);
        const y_usize = @intCast(usize, p.y);
        const startX: usize = x_usize - thickness;
        const startY: usize = y_usize - thickness;
        const endX: usize = x_usize + thickness;
        const endY: usize = y_usize + thickness;
        for (startY..endY) |y| {
            for (startX..endX) |x| {
                data[y * width + x] = val;
            }
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var points: [100]bezier.Point = undefined;

    const width: usize = 250;
    const height: usize = 250;

    var img = std.ArrayList(u8).init(alloc);
    defer img.deinit();
    try img.appendNTimes(1, width * height);

    bezier.quadratic(.{ .x = 50, .y = 50 }, .{ .x = 200, .y = 50 }, .{ .x = 200, .y = 200 }, &points);
    setPoints(img.items, width, &points, 2);

    const pallete = [_]sixel.Pixel{
        .{ .r = 0, .g = 0, .b = 0 },
        .{ .r = 100, .g = 100, .b = 0 },
        .{ .r = 0, .g = 100, .b = 0 },
        .{ .r = 0, .g = 0, .b = 100 },
    };

    var buffer = std.ArrayList(u8).init(alloc);
    defer buffer.deinit();
    const writer = buffer.writer();
    const stdout = std.io.getStdOut().writer();

    try sixel.render(&pallete, img.items, width, height, writer);

    try std.fmt.format(stdout, "\n\n{s}\n\n", .{buffer.items});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
