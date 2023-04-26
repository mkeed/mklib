const std = @import("std");
const String = @import("../String.zig");
const Render = @import("../Render.zig");
const Face = Render.Face;
const Colour = Render.Colour;

const Pos = Render.Pos;

pub const Cursor = struct {
    pub const home = "\x1b[H";
    pub const hide = "\x1b[?25l";
    pub const show = "\x1b[?25h";

    pub const move = "\x1b[{};{}f"; //line;column
};

pub const Screen = struct {
    pub const clear = "\x1b[2J";
};

pub fn write(screenInfo: Render.RenderInfo, writer: anytype) !void {
    _ = screenInfo;
    _ = writer;
    // try std.fmt.format(writer, "{s}{s}{s}", .{ Screen.clear, Cursor.hide, Cursor.home });

    // try setColour(writer, .{
    //     .fg = .{ .r = 0, .g = 0, .b = 0, .a = 0 },
    //     .bg = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
    // });

    // var lineCount: usize = 0;
    // for (screenInfo.menuItems) |menu| {
    //     lineCount += menu.len + 1;
    //     try std.fmt.format(writer, "{s} ", .{menu});
    // }
    // try writer.writeByteNTimes(' ', @intCast(usize, screenInfo.screenSize.x) - lineCount);
    // try resetColour(writer);

    // for (screenInfo.buffers) |buffer| {
    //     for (buffer.buffer.lines, 0..) |line, idy| {
    //         try std.fmt.format(writer, Cursor.move, .{
    //             buffer.pos.y + @intCast(isize, idy),
    //             buffer.pos.x,
    //         });
    //         try std.fmt.format(writer, "{s}", .{line});
    //     }
    // }

    // try std.fmt.format(writer, Cursor.move, .{ screenInfo.screenSize.y, screenInfo.screenSize.x - @intCast(isize, screenInfo.cmdline.len) });

    // try setColour(writer, .{
    //     .fg = .{ .r = 0, .g = 100, .b = 0, .a = 0 },
    //     .bg = .{ .r = 255, .g = 255, .b = 255, .a = 0 },
    // });

    // try std.fmt.format(writer, "{s}", .{screenInfo.cmdline});
    // try resetColour(writer);

    // try std.fmt.format(writer, Cursor.move ++ Cursor.show, .{ screenInfo.cursorPos.y, screenInfo.cursorPos.x });
}

const CSI = "\x1B[";
const DCS = "\x1BP";
const SetFG = CSI ++ "38;";
const SetBG = CSI ++ "48;";

fn setColour(writer: anytype, face: Face) !void {
    try std.fmt.format(writer, SetFG ++ "2;{};{};{}m" ++ SetBG ++ "2;{};{};{}m", .{
        face.fg.r,
        face.fg.g,
        face.fg.b,
        face.bg.r,
        face.bg.g,
        face.bg.b,
    });
}

pub fn resetColour(writer: anytype) !void {
    try std.fmt.format(writer, CSI ++ "0m", .{});
}
