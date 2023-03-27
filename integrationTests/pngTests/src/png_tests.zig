pub const TestCase = struct {
    fileName: []const u8,
    fileData: []const u8,
    expectedData: ?ImageData = null,
};

pub const tests = [_]TestCase{
    .{
        .fileName = "basi0g01.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi0g01.png"),
    },
    .{
        .fileName = "basi0g02.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi0g02.png"),
    },
    .{
        .fileName = "basi0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi0g04.png"),
    },
    .{
        .fileName = "basi0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi0g08.png"),
    },
    .{
        .fileName = "basi0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi0g16.png"),
    },
    .{
        .fileName = "basi2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi2c08.png"),
    },
    .{
        .fileName = "basi2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi2c16.png"),
    },
    .{
        .fileName = "basi3p01.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi3p01.png"),
    },
    .{
        .fileName = "basi3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi3p02.png"),
    },
    .{
        .fileName = "basi3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi3p04.png"),
    },
    .{
        .fileName = "basi3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi3p08.png"),
    },
    .{
        .fileName = "basi4a08.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi4a08.png"),
    },
    .{
        .fileName = "basi4a16.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi4a16.png"),
    },
    .{
        .fileName = "basi6a08.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi6a08.png"),
    },
    .{
        .fileName = "basi6a16.png",
        .fileData = @embedFile("PngSuite-2017jul19/basi6a16.png"),
    },
    .{
        .fileName = "basn0g01.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn0g01.png"),
    },
    .{
        .fileName = "basn0g02.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn0g02.png"),
    },
    .{
        .fileName = "basn0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn0g04.png"),
    },
    .{
        .fileName = "basn0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn0g08.png"),
    },
    .{
        .fileName = "basn0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn0g16.png"),
    },
    .{
        .fileName = "basn2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn2c08.png"),
    },
    .{
        .fileName = "basn2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn2c16.png"),
    },
    .{
        .fileName = "basn3p01.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn3p01.png"),
    },
    .{
        .fileName = "basn3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn3p02.png"),
    },
    .{
        .fileName = "basn3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn3p04.png"),
    },
    .{
        .fileName = "basn3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn3p08.png"),
    },
    .{
        .fileName = "basn4a08.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn4a08.png"),
    },
    .{
        .fileName = "basn4a16.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn4a16.png"),
    },
    .{
        .fileName = "basn6a08.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn6a08.png"),
    },
    .{
        .fileName = "basn6a16.png",
        .fileData = @embedFile("PngSuite-2017jul19/basn6a16.png"),
    },
    .{
        .fileName = "bgai4a08.png",
        .fileData = @embedFile("PngSuite-2017jul19/bgai4a08.png"),
    },
    .{
        .fileName = "bgai4a16.png",
        .fileData = @embedFile("PngSuite-2017jul19/bgai4a16.png"),
    },
    .{
        .fileName = "bgan6a08.png",
        .fileData = @embedFile("PngSuite-2017jul19/bgan6a08.png"),
    },
    .{
        .fileName = "bgan6a16.png",
        .fileData = @embedFile("PngSuite-2017jul19/bgan6a16.png"),
    },
    .{
        .fileName = "bgbn4a08.png",
        .fileData = @embedFile("PngSuite-2017jul19/bgbn4a08.png"),
    },
    .{
        .fileName = "bggn4a16.png",
        .fileData = @embedFile("PngSuite-2017jul19/bggn4a16.png"),
    },
    .{
        .fileName = "bgwn6a08.png",
        .fileData = @embedFile("PngSuite-2017jul19/bgwn6a08.png"),
    },
    .{
        .fileName = "bgyn6a16.png",
        .fileData = @embedFile("PngSuite-2017jul19/bgyn6a16.png"),
    },
    .{
        .fileName = "ccwn2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/ccwn2c08.png"),
    },
    .{
        .fileName = "ccwn3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/ccwn3p08.png"),
    },
    .{
        .fileName = "cdfn2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/cdfn2c08.png"),
    },
    .{
        .fileName = "cdhn2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/cdhn2c08.png"),
    },
    .{
        .fileName = "cdsn2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/cdsn2c08.png"),
    },
    .{
        .fileName = "cdun2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/cdun2c08.png"),
    },
    .{
        .fileName = "ch1n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/ch1n3p04.png"),
    },
    .{
        .fileName = "ch2n3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/ch2n3p08.png"),
    },
    .{
        .fileName = "cm0n0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/cm0n0g04.png"),
    },
    .{
        .fileName = "cm7n0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/cm7n0g04.png"),
    },
    .{
        .fileName = "cm9n0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/cm9n0g04.png"),
    },
    .{
        .fileName = "cs3n2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/cs3n2c16.png"),
    },
    .{
        .fileName = "cs3n3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/cs3n3p08.png"),
    },
    .{
        .fileName = "cs5n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/cs5n2c08.png"),
    },
    .{
        .fileName = "cs5n3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/cs5n3p08.png"),
    },
    .{
        .fileName = "cs8n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/cs8n2c08.png"),
    },
    .{
        .fileName = "cs8n3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/cs8n3p08.png"),
    },
    .{
        .fileName = "ct0n0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/ct0n0g04.png"),
    },
    .{
        .fileName = "ct1n0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/ct1n0g04.png"),
    },
    .{
        .fileName = "cten0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/cten0g04.png"),
    },
    .{
        .fileName = "ctfn0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/ctfn0g04.png"),
    },
    .{
        .fileName = "ctgn0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/ctgn0g04.png"),
    },
    .{
        .fileName = "cthn0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/cthn0g04.png"),
    },
    .{
        .fileName = "ctjn0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/ctjn0g04.png"),
    },
    .{
        .fileName = "ctzn0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/ctzn0g04.png"),
    },
    .{
        .fileName = "exif2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/exif2c08.png"),
    },
    .{
        .fileName = "f00n0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/f00n0g08.png"),
    },
    .{
        .fileName = "f00n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/f00n2c08.png"),
    },
    .{
        .fileName = "f01n0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/f01n0g08.png"),
    },
    .{
        .fileName = "f01n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/f01n2c08.png"),
    },
    .{
        .fileName = "f02n0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/f02n0g08.png"),
    },
    .{
        .fileName = "f02n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/f02n2c08.png"),
    },
    .{
        .fileName = "f03n0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/f03n0g08.png"),
    },
    .{
        .fileName = "f03n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/f03n2c08.png"),
    },
    .{
        .fileName = "f04n0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/f04n0g08.png"),
    },
    .{
        .fileName = "f04n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/f04n2c08.png"),
    },
    .{
        .fileName = "f99n0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/f99n0g04.png"),
    },
    .{
        .fileName = "g03n0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/g03n0g16.png"),
    },
    .{
        .fileName = "g03n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/g03n2c08.png"),
    },
    .{
        .fileName = "g03n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/g03n3p04.png"),
    },
    .{
        .fileName = "g04n0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/g04n0g16.png"),
    },
    .{
        .fileName = "g04n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/g04n2c08.png"),
    },
    .{
        .fileName = "g04n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/g04n3p04.png"),
    },
    .{
        .fileName = "g05n0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/g05n0g16.png"),
    },
    .{
        .fileName = "g05n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/g05n2c08.png"),
    },
    .{
        .fileName = "g05n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/g05n3p04.png"),
    },
    .{
        .fileName = "g07n0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/g07n0g16.png"),
    },
    .{
        .fileName = "g07n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/g07n2c08.png"),
    },
    .{
        .fileName = "g07n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/g07n3p04.png"),
    },
    .{
        .fileName = "g10n0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/g10n0g16.png"),
    },
    .{
        .fileName = "g10n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/g10n2c08.png"),
    },
    .{
        .fileName = "g10n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/g10n3p04.png"),
    },
    .{
        .fileName = "g25n0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/g25n0g16.png"),
    },
    .{
        .fileName = "g25n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/g25n2c08.png"),
    },
    .{
        .fileName = "g25n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/g25n3p04.png"),
    },
    .{
        .fileName = "oi1n0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/oi1n0g16.png"),
    },
    .{
        .fileName = "oi1n2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/oi1n2c16.png"),
    },
    .{
        .fileName = "oi2n0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/oi2n0g16.png"),
    },
    .{
        .fileName = "oi2n2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/oi2n2c16.png"),
    },
    .{
        .fileName = "oi4n0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/oi4n0g16.png"),
    },
    .{
        .fileName = "oi4n2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/oi4n2c16.png"),
    },
    .{
        .fileName = "oi9n0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/oi9n0g16.png"),
    },
    .{
        .fileName = "oi9n2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/oi9n2c16.png"),
    },
    .{
        .fileName = "pp0n2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/pp0n2c16.png"),
    },
    .{
        .fileName = "pp0n6a08.png",
        .fileData = @embedFile("PngSuite-2017jul19/pp0n6a08.png"),
    },
    .{
        .fileName = "ps1n0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/ps1n0g08.png"),
    },
    .{
        .fileName = "ps1n2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/ps1n2c16.png"),
    },
    .{
        .fileName = "ps2n0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/ps2n0g08.png"),
    },
    .{
        .fileName = "ps2n2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/ps2n2c16.png"),
    },
    .{
        .fileName = "s01i3p01.png",
        .fileData = @embedFile("PngSuite-2017jul19/s01i3p01.png"),
    },
    .{
        .fileName = "s01n3p01.png",
        .fileData = @embedFile("PngSuite-2017jul19/s01n3p01.png"),
    },
    .{
        .fileName = "s02i3p01.png",
        .fileData = @embedFile("PngSuite-2017jul19/s02i3p01.png"),
    },
    .{
        .fileName = "s02n3p01.png",
        .fileData = @embedFile("PngSuite-2017jul19/s02n3p01.png"),
    },
    .{
        .fileName = "s03i3p01.png",
        .fileData = @embedFile("PngSuite-2017jul19/s03i3p01.png"),
    },
    .{
        .fileName = "s03n3p01.png",
        .fileData = @embedFile("PngSuite-2017jul19/s03n3p01.png"),
    },
    .{
        .fileName = "s04i3p01.png",
        .fileData = @embedFile("PngSuite-2017jul19/s04i3p01.png"),
    },
    .{
        .fileName = "s04n3p01.png",
        .fileData = @embedFile("PngSuite-2017jul19/s04n3p01.png"),
    },
    .{
        .fileName = "s05i3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/s05i3p02.png"),
    },
    .{
        .fileName = "s05n3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/s05n3p02.png"),
    },
    .{
        .fileName = "s06i3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/s06i3p02.png"),
    },
    .{
        .fileName = "s06n3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/s06n3p02.png"),
    },
    .{
        .fileName = "s07i3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/s07i3p02.png"),
    },
    .{
        .fileName = "s07n3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/s07n3p02.png"),
    },
    .{
        .fileName = "s08i3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/s08i3p02.png"),
    },
    .{
        .fileName = "s08n3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/s08n3p02.png"),
    },
    .{
        .fileName = "s09i3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/s09i3p02.png"),
    },
    .{
        .fileName = "s09n3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/s09n3p02.png"),
    },
    .{
        .fileName = "s32i3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s32i3p04.png"),
    },
    .{
        .fileName = "s32n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s32n3p04.png"),
    },
    .{
        .fileName = "s33i3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s33i3p04.png"),
    },
    .{
        .fileName = "s33n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s33n3p04.png"),
    },
    .{
        .fileName = "s34i3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s34i3p04.png"),
    },
    .{
        .fileName = "s34n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s34n3p04.png"),
    },
    .{
        .fileName = "s35i3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s35i3p04.png"),
    },
    .{
        .fileName = "s35n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s35n3p04.png"),
    },
    .{
        .fileName = "s36i3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s36i3p04.png"),
    },
    .{
        .fileName = "s36n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s36n3p04.png"),
    },
    .{
        .fileName = "s37i3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s37i3p04.png"),
    },
    .{
        .fileName = "s37n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s37n3p04.png"),
    },
    .{
        .fileName = "s38i3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s38i3p04.png"),
    },
    .{
        .fileName = "s38n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s38n3p04.png"),
    },
    .{
        .fileName = "s39i3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s39i3p04.png"),
    },
    .{
        .fileName = "s39n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s39n3p04.png"),
    },
    .{
        .fileName = "s40i3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s40i3p04.png"),
    },
    .{
        .fileName = "s40n3p04.png",
        .fileData = @embedFile("PngSuite-2017jul19/s40n3p04.png"),
    },
    .{
        .fileName = "tbbn0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/tbbn0g04.png"),
    },
    .{
        .fileName = "tbbn2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/tbbn2c16.png"),
    },
    .{
        .fileName = "tbbn3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/tbbn3p08.png"),
    },
    .{
        .fileName = "tbgn2c16.png",
        .fileData = @embedFile("PngSuite-2017jul19/tbgn2c16.png"),
    },
    .{
        .fileName = "tbgn3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/tbgn3p08.png"),
    },
    .{
        .fileName = "tbrn2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/tbrn2c08.png"),
    },
    .{
        .fileName = "tbwn0g16.png",
        .fileData = @embedFile("PngSuite-2017jul19/tbwn0g16.png"),
    },
    .{
        .fileName = "tbwn3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/tbwn3p08.png"),
    },
    .{
        .fileName = "tbyn3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/tbyn3p08.png"),
    },
    .{
        .fileName = "tm3n3p02.png",
        .fileData = @embedFile("PngSuite-2017jul19/tm3n3p02.png"),
    },
    .{
        .fileName = "tp0n0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/tp0n0g08.png"),
    },
    .{
        .fileName = "tp0n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/tp0n2c08.png"),
    },
    .{
        .fileName = "tp0n3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/tp0n3p08.png"),
    },
    .{
        .fileName = "tp1n3p08.png",
        .fileData = @embedFile("PngSuite-2017jul19/tp1n3p08.png"),
    },
    .{
        .fileName = "xc1n0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/xc1n0g08.png"),
    },
    .{
        .fileName = "xc9n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/xc9n2c08.png"),
    },
    .{
        .fileName = "xcrn0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/xcrn0g04.png"),
    },
    .{
        .fileName = "xcsn0g01.png",
        .fileData = @embedFile("PngSuite-2017jul19/xcsn0g01.png"),
    },
    .{
        .fileName = "xd0n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/xd0n2c08.png"),
    },
    .{
        .fileName = "xd3n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/xd3n2c08.png"),
    },
    .{
        .fileName = "xd9n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/xd9n2c08.png"),
    },
    .{
        .fileName = "xdtn0g01.png",
        .fileData = @embedFile("PngSuite-2017jul19/xdtn0g01.png"),
    },
    .{
        .fileName = "xhdn0g08.png",
        .fileData = @embedFile("PngSuite-2017jul19/xhdn0g08.png"),
    },
    .{
        .fileName = "xlfn0g04.png",
        .fileData = @embedFile("PngSuite-2017jul19/xlfn0g04.png"),
    },
    .{
        .fileName = "xs1n0g01.png",
        .fileData = @embedFile("PngSuite-2017jul19/xs1n0g01.png"),
    },
    .{
        .fileName = "xs2n0g01.png",
        .fileData = @embedFile("PngSuite-2017jul19/xs2n0g01.png"),
    },
    .{
        .fileName = "xs4n0g01.png",
        .fileData = @embedFile("PngSuite-2017jul19/xs4n0g01.png"),
    },
    .{
        .fileName = "xs7n0g01.png",
        .fileData = @embedFile("PngSuite-2017jul19/xs7n0g01.png"),
    },
    .{
        .fileName = "z00n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/z00n2c08.png"),
    },
    .{
        .fileName = "z03n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/z03n2c08.png"),
    },
    .{
        .fileName = "z06n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/z06n2c08.png"),
    },
    .{
        .fileName = "z09n2c08.png",
        .fileData = @embedFile("PngSuite-2017jul19/z09n2c08.png"),
    },
};
