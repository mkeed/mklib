const std = @import("std");
const MKGUI = @import("MKGUI");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var mkgui = try MKGUI.init(alloc, .{});
    defer mkgui.deinit();
    var screen = mkgui.addScreen();
    var split = try screen.split(.vertical, &.{
        .{ .flow = .all },
        .{ .flow = .{ .constant = 1 } },
        .{ .flow = .{ .constant = 3 } },
    });

    var scrollback = try split[0].addComponent(.{
        .scrollable = .{},
    });

    var cmdline = try split[1].addComponent(.{
        .textField = .{},
    });

    var bitspace = try split[2].split(.horizontal,
        &.{
        .{.flow = .{.constant = 16},
    });

    try mkgui.run();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
// ----------------------------------------------------------------
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// |                                                              |
// ----------------------------------------------------------------
// |                                                              |
// ----------------------------------------------------------------
// |63 62 61 60 59 58 57 56 55 54 53 52 51 50 49 48               |
// |47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32               |
// |31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16               |
// |15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0               |
// ----------------------------------------------------------------
