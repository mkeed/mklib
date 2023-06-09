const png = @import("png.zig");

pub const AutoTest = struct {
    filename: []const u8,
    width: usize,
    height: usize,
    depth: usize,
    colour: png.IHDR.ColourType,
    interlace: png.IHDR.Interlace,
    bytesPerPixel: usize,
    data: []const u8,
};

pub const FailingTest = struct {
    fileName: []const u8, //TODO workout a way to catch the correct errors
};

pub const TestCase = union(enum) {
    todoTest: []const u8,
    auto: AutoTest,
    failingTest: FailingTest,
    endTest: void,
};

pub fn todoFile(comptime filename: []const u8) TestCase {
    return TestCase{
        .todoTest = filename,
    };
}

pub const tests = [_]TestCase{
    .{ .todoTest = "s01n3p01.png" },
    .{ .todoTest = "s01i3p01.png" },
    .{ .todoTest = "s02i3p01.png" },
    .{ .todoTest = "s02n3p01.png" },
    .{ .todoTest = "s03i3p01.png" },
    .{ .todoTest = "s03n3p01.png" },
    .{ .todoTest = "s04i3p01.png" },
    .{ .todoTest = "s04n3p01.png" },
    .{ .todoTest = "s05i3p02.png" },
    .{ .todoTest = "s05n3p02.png" },
    .{ .todoTest = "s06i3p02.png" },
    .{ .todoTest = "s06n3p02.png" },
    .{ .todoTest = "s07i3p02.png" },
    .{ .todoTest = "s07n3p02.png" },
    .{ .todoTest = "s08i3p02.png" },
    .{ .todoTest = "s08n3p02.png" },
    .{ .todoTest = "s09i3p02.png" },
    .{ .todoTest = "s09n3p02.png" },
    .{ .todoTest = "s32i3p04.png" },
    .{ .todoTest = "s32n3p04.png" },
    .{ .todoTest = "s33i3p04.png" },
    .{ .todoTest = "s33n3p04.png" },
    .{ .todoTest = "s34i3p04.png" },
    .{ .todoTest = "s34n3p04.png" },
    .{ .todoTest = "s35i3p04.png" },
    .{ .todoTest = "s35n3p04.png" },
    .{ .todoTest = "s36i3p04.png" },
    .{ .todoTest = "s36n3p04.png" },
    .{ .todoTest = "s37i3p04.png" },
    .{ .todoTest = "s37n3p04.png" },
    .{ .todoTest = "s38i3p04.png" },
    .{ .todoTest = "s38n3p04.png" },
    .{ .todoTest = "s39i3p04.png" },
    .{ .todoTest = "s39n3p04.png" },
    .{ .todoTest = "s40i3p04.png" },
    .{ .todoTest = "s40n3p04.png" },
    //.endTest,
    // .{ .auto = .{ .filename = "basi0g01.png", .width = 32, .height = 32, .depth = 1, .colour = .GrayScale, .interlace = .Adam7, .bytesPerPixel = 1, .data = @import("testCases/basi0g01.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi0g02.png", .width = 32, .height = 32, .depth = 2, .colour = .GrayScale, .interlace = .Adam7, .bytesPerPixel = 1, .data = @import("testCases/basi0g02.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi0g04.png", .width = 32, .height = 32, .depth = 4, .colour = .GrayScale, .interlace = .Adam7, .bytesPerPixel = 1, .data = @import("testCases/basi0g04.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi0g08.png", .width = 32, .height = 32, .depth = 8, .colour = .GrayScale, .interlace = .Adam7, .bytesPerPixel = 1, .data = @import("testCases/basi0g08.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi0g16.png", .width = 32, .height = 32, .depth = 16, .colour = .GrayScale, .interlace = .Adam7, .bytesPerPixel = 2, .data = @import("testCases/basi0g16.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi2c16.png", .width = 32, .height = 32, .depth = 16, .colour = .RGB, .interlace = .Adam7, .bytesPerPixel = 6, .data = @import("testCases/basi2c16.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi3p01.png", .width = 32, .height = 32, .depth = 1, .colour = .Palette, .interlace = .Adam7, .bytesPerPixel = 1, .data = @import("testCases/basi3p01.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi3p02.png", .width = 32, .height = 32, .depth = 2, .colour = .Palette, .interlace = .Adam7, .bytesPerPixel = 1, .data = @import("testCases/basi3p02.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi3p04.png", .width = 32, .height = 32, .depth = 4, .colour = .Palette, .interlace = .Adam7, .bytesPerPixel = 1, .data = @import("testCases/basi3p04.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi3p08.png", .width = 32, .height = 32, .depth = 8, .colour = .Palette, .interlace = .Adam7, .bytesPerPixel = 1, .data = @import("testCases/basi3p08.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi4a08.png", .width = 32, .height = 32, .depth = 8, .colour = .AlphaGrayScale, .interlace = .Adam7, .bytesPerPixel = 2, .data = @import("testCases/basi4a08.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi4a16.png", .width = 32, .height = 32, .depth = 16, .colour = .AlphaGrayScale, .interlace = .Adam7, .bytesPerPixel = 4, .data = @import("testCases/basi4a16.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi6a16.png", .width = 32, .height = 32, .depth = 16, .colour = .AlphaRGB, .interlace = .Adam7, .bytesPerPixel = 8, .data = @import("testCases/basi6a16.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basi6a08.png", .width = 32, .height = 32, .depth = 8, .colour = .AlphaRGB, .interlace = .Adam7, .bytesPerPixel = 4, .data = @import("testCases/basi6a08.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basn0g01.png", .width = 32, .height = 32, .depth = 1, .colour = .GrayScale, .interlace = .None, .bytesPerPixel = 1, .data = @import("testCases/basn0g01.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basn0g02.png", .width = 32, .height = 32, .depth = 2, .colour = .GrayScale, .interlace = .None, .bytesPerPixel = 1, .data = @import("testCases/basn0g02.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basn0g04.png", .width = 32, .height = 32, .depth = 4, .colour = .GrayScale, .interlace = .None, .bytesPerPixel = 1, .data = @import("testCases/basn0g04.zig").data[0..] } },
    // .{ .auto = .{ .filename = "basn0g08.png", .width = 32, .height = 32, .depth = 8, .colour = .GrayScale, .interlace = .None, .bytesPerPixel = 1, .data = @import("testCases/basn0g08.zig").data[0..] } },
    .{ .todoTest = "basn0g16.png" },
    .{ .todoTest = "basn2c08.png" },
    .{ .todoTest = "basn2c16.png" },
    .{ .todoTest = "basn3p01.png" },
    .{ .todoTest = "basn3p02.png" },
    .{ .todoTest = "basn3p04.png" },
    .{ .todoTest = "basn3p08.png" },
    .{ .todoTest = "basn4a08.png" },
    //.endTest,
    .{ .todoTest = "basn4a16.png" },
    .{ .todoTest = "basn6a08.png" },
    .{ .todoTest = "basn6a16.png" },
    .{ .todoTest = "bgai4a08.png" },
    .{ .todoTest = "bgai4a16.png" },
    .{ .todoTest = "bgan6a08.png" },
    .{ .todoTest = "bgan6a16.png" },
    .{ .todoTest = "bgbn4a08.png" },
    .{ .todoTest = "bggn4a16.png" },
    .{ .todoTest = "bgwn6a08.png" },
    .{ .todoTest = "bgyn6a16.png" },
    .{ .todoTest = "ccwn2c08.png" },
    .{ .todoTest = "ccwn3p08.png" },
    .{ .todoTest = "cdfn2c08.png" },
    .{ .todoTest = "cdhn2c08.png" },
    .{ .todoTest = "cdsn2c08.png" },
    .{ .todoTest = "cdun2c08.png" },
    .{ .todoTest = "ch1n3p04.png" },
    .{ .todoTest = "ch2n3p08.png" },
    .{ .todoTest = "cm0n0g04.png" },
    .{ .todoTest = "cm7n0g04.png" },
    .{ .todoTest = "cm9n0g04.png" },
    .{ .todoTest = "cs3n2c16.png" },
    .{ .todoTest = "cs3n3p08.png" },
    .{ .todoTest = "cs5n2c08.png" },
    .{ .todoTest = "cs5n3p08.png" },
    .{ .todoTest = "cs8n2c08.png" },
    .{ .todoTest = "cs8n3p08.png" },
    .{ .todoTest = "ct0n0g04.png" },
    .{ .todoTest = "ct1n0g04.png" },
    .{ .todoTest = "cten0g04.png" },
    .{ .todoTest = "ctfn0g04.png" },
    .{ .todoTest = "ctgn0g04.png" },
    .{ .todoTest = "cthn0g04.png" },
    .{ .todoTest = "ctjn0g04.png" },
    .{ .todoTest = "ctzn0g04.png" },
    .{ .todoTest = "exif2c08.png" },
    .{ .todoTest = "f00n0g08.png" },
    .{ .todoTest = "f00n2c08.png" },
    .{ .todoTest = "f01n0g08.png" },
    .{ .todoTest = "f01n2c08.png" },
    .{ .todoTest = "f02n0g08.png" },
    .{ .todoTest = "f02n2c08.png" },
    .{ .todoTest = "f03n0g08.png" },
    .{ .todoTest = "f03n2c08.png" },
    .{ .todoTest = "f04n0g08.png" },
    .{ .todoTest = "f04n2c08.png" },
    .{ .todoTest = "f99n0g04.png" },
    .{ .todoTest = "g03n0g16.png" },
    .{ .todoTest = "g03n2c08.png" },
    .{ .todoTest = "g03n3p04.png" },
    .{ .todoTest = "g04n0g16.png" },
    .{ .todoTest = "g04n2c08.png" },
    .{ .todoTest = "g04n3p04.png" },
    .{ .todoTest = "g05n0g16.png" },
    .{ .todoTest = "g05n2c08.png" },
    .{ .todoTest = "g05n3p04.png" },
    .{ .todoTest = "g07n0g16.png" },
    .{ .todoTest = "g07n2c08.png" },
    .{ .todoTest = "g07n3p04.png" },
    .{ .todoTest = "g10n0g16.png" },
    .{ .todoTest = "g10n2c08.png" },
    .{ .todoTest = "g10n3p04.png" },
    .{ .todoTest = "g25n0g16.png" },
    .{ .todoTest = "g25n2c08.png" },
    .{ .todoTest = "g25n3p04.png" },
    // .{ .todoTest = "oi1n0g16.png" },
    // .{ .todoTest = "oi1n2c16.png" },
    // .{ .todoTest = "oi2n0g16.png" },
    // .{ .todoTest = "oi2n2c16.png" },
    // .{ .todoTest = "oi4n0g16.png" },
    // .{ .todoTest = "oi4n2c16.png" },
    // .{ .todoTest = "oi9n0g16.png" },
    // .{ .todoTest = "oi9n2c16.png" },
    .{ .todoTest = "pp0n2c16.png" },
    .{ .todoTest = "pp0n6a08.png" },
    .{ .todoTest = "ps1n0g08.png" },
    .{ .todoTest = "ps1n2c16.png" },
    .{ .todoTest = "ps2n0g08.png" },
    .{ .todoTest = "ps2n2c16.png" },
    .{ .todoTest = "s01i3p01.png" },
    .{ .todoTest = "s01n3p01.png" },
    .{ .todoTest = "s02i3p01.png" },
    .{ .todoTest = "s02n3p01.png" },
    .{ .todoTest = "s03i3p01.png" },
    .{ .todoTest = "s03n3p01.png" },
    .{ .todoTest = "s04i3p01.png" },
    .{ .todoTest = "s04n3p01.png" },
    .{ .todoTest = "s05i3p02.png" },
    .{ .todoTest = "s05n3p02.png" },
    .{ .todoTest = "s06i3p02.png" },
    .{ .todoTest = "s06n3p02.png" },
    .{ .todoTest = "s07i3p02.png" },
    .{ .todoTest = "s07n3p02.png" },
    .{ .todoTest = "s08i3p02.png" },
    .{ .todoTest = "s08n3p02.png" },
    .{ .todoTest = "s09i3p02.png" },
    .{ .todoTest = "s09n3p02.png" },
    .{ .todoTest = "s32i3p04.png" },
    .{ .todoTest = "s32n3p04.png" },
    .{ .todoTest = "s33i3p04.png" },
    .{ .todoTest = "s33n3p04.png" },
    .{ .todoTest = "s34i3p04.png" },
    .{ .todoTest = "s34n3p04.png" },
    .{ .todoTest = "s35i3p04.png" },
    .{ .todoTest = "s35n3p04.png" },
    .{ .todoTest = "s36i3p04.png" },
    .{ .todoTest = "s36n3p04.png" },
    .{ .todoTest = "s37i3p04.png" },
    .{ .todoTest = "s37n3p04.png" },
    .{ .todoTest = "s38i3p04.png" },
    .{ .todoTest = "s38n3p04.png" },
    .{ .todoTest = "s39i3p04.png" },
    .{ .todoTest = "s39n3p04.png" },
    .{ .todoTest = "s40i3p04.png" },
    .{ .todoTest = "s40n3p04.png" },
    .{ .todoTest = "tbbn0g04.png" },
    .{ .todoTest = "tbbn2c16.png" },
    .{ .todoTest = "tbbn3p08.png" },
    .{ .todoTest = "tbgn2c16.png" },
    .{ .todoTest = "tbgn3p08.png" },
    .{ .todoTest = "tbrn2c08.png" },
    .{ .todoTest = "tbwn0g16.png" },
    .{ .todoTest = "tbwn3p08.png" },
    .{ .todoTest = "tbyn3p08.png" },
    .{ .todoTest = "tm3n3p02.png" },
    .{ .todoTest = "tp0n0g08.png" },
    .{ .todoTest = "tp0n2c08.png" },
    .{ .todoTest = "tp0n3p08.png" },
    .{ .todoTest = "tp1n3p08.png" },
    .{ .failingTest = .{ .fileName = "xc1n0g08.png" } },
    .{ .failingTest = .{ .fileName = "xc9n2c08.png" } },
    .{ .failingTest = .{ .fileName = "xcrn0g04.png" } },
    .{ .failingTest = .{ .fileName = "xcsn0g01.png" } },
    .{ .failingTest = .{ .fileName = "xd0n2c08.png" } },
    .{ .failingTest = .{ .fileName = "xd3n2c08.png" } },
    .{ .failingTest = .{ .fileName = "xd9n2c08.png" } },
    .{ .failingTest = .{ .fileName = "xdtn0g01.png" } },
    .{ .failingTest = .{ .fileName = "xhdn0g08.png" } },
    .{ .failingTest = .{ .fileName = "xlfn0g04.png" } },
    .{ .failingTest = .{ .fileName = "xs1n0g01.png" } },
    .{ .failingTest = .{ .fileName = "xs2n0g01.png" } },
    .{ .failingTest = .{ .fileName = "xs4n0g01.png" } },
    .{ .failingTest = .{ .fileName = "xs7n0g01.png" } },
    .{ .todoTest = "z00n2c08.png" },
    .{ .todoTest = "z03n2c08.png" },
    .{ .todoTest = "z06n2c08.png" },
    .{ .todoTest = "z09n2c08.png" },
};
