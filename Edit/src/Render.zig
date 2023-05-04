const std = @import("std");
pub const Colour = @import("Colour.zig").Colour;
pub const Face = @import("Face.zig").Face;
pub const Text = struct {
    face: []const u8,
    data: []const u8,
};

pub const Pos = struct {
    x: isize,
    y: isize,
    pub fn sub(self: Pos, other: Pos) Pos {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }
};

pub const Menu = struct {
    name: []const u8,
};

pub const RenderObject = struct {};

pub const ModeLine = struct {
    pub const ModeInfo = struct { pos: usize, val: Text };
    mode_info: []const ModeInfo,
};
pub const RenderLine = struct {
    line_num: usize,
    data: []const Text,
};
pub const Window = struct {
    mode_line: ModeLine,
    lines: []const RenderLine,
};

pub const WindowInfo = struct {
    pos: Pos,
    size: Pos,
    window: Window,
};

pub const RenderInfo = struct {
    title: []const u8,
    menus: []const Menu,
    buffer: []const WindowInfo,
    screenSize: Pos,
};
