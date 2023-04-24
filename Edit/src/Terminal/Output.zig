const std = @import("std");
const String = @import("../String.zig");

pub const Pos = struct {
    x: isize,
    y: isize,
};

pub const ScreenInfo = struct {
    screenSize: Pos,
    cursorPos: Pos,
    menuItems: []const []const u8,
};

pub const Cursor = struct {
    pub const home = "\x1b[H";
    pub const hide = "\x1b[?25l";
    pub const show = "\x1b[?25h";

    pub const move = "\x1b[{};{}H"; //line;column
};

pub const Screen = struct {
    pub const clear = "\x1b[2J";
};

pub fn write(screenInfo: ScreenInfo, writer: anytype) !void {
    try std.fmt.format(writer, "{s}{s}{s}", .{ Screen.clear, Cursor.hide, Cursor.home });

    for (screenInfo.menuItems) |menu| {
        try std.fmt.format(writer, "{s} ", .{menu});
    }

    try std.fmt.format(writer, Cursor.move ++ Cursor.show, .{ screenInfo.cursorPos.y, screenInfo.cursorPos.x });
}
