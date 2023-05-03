const std = @import("std");
pub const Colour = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const Face = struct {
    fg: Colour,
    bg: Colour,
};

pub const Pos = struct {
    x: isize,
    y: isize,
};

pub const Menu = struct {
    name: []const u8,
};

pub const RenderObject = struct {};

pub const ModeLine = struct {};
pub const RenderLine = struct {};
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
};
