const std = @import("std");

pub const Pixel = struct { r: u8, g: u8, b: u8 };

pub fn render(pallete: []const Pixel, pixels: []const u8, width: usize, height: usize, writer: anytype) !void {
    //
}

//const sixelValues =

//<ESC>Pq
//#0;2;0;0;0#1;2;100;100;0#2;2;0;100;0
//#1~~@@vv@@~~@@~~$
//#2??}}GG}}??}}??-
//#1!14@
//<ESC>\
