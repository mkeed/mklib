const std = @import("std");
const Colour = @import("Colour.zig");

pub const Face = struct {
    fg: Colour.Colour,
    bg: Colour.Colour,
};

pub const FaceInfo = struct {
    fg: []const u8,
    bg: []const u8,
};

pub const FaceList = struct {
    name: []const u8,
    face: FaceInfo,
};

pub const Default = Face{ .fg = Colour.white, .bg = Colour.black };

pub fn getFace(name: []const u8) ?Face {
    for (faces) |f| {
        if (std.mem.eql(u8, name, f.name)) {
            const fg = Colour.getColour(f.face.fg) orelse Colour.white;
            const bg = Colour.getColour(f.face.bg) orelse Colour.black;
            return Face{ .fg = fg, .bg = bg };
        }
    }
    return null;
}

pub fn getFaceOrDefault(name: []const u8) Face {
    return getFace(name) orelse Default;
}
pub const faces = [_]FaceList{
    .{ .name = "default", .face = .{ .fg = "white", .bg = "gray19" } },
};
