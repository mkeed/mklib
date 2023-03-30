const std = @import("std");

const ImageType = enum {
    RGB,
    RGBA,
    Gray,
    LinearGray,
    LinearGrayA,
    SRGB,
    SRGBA,
};

pub const Pixel = struct {
    r: u16,
    g: u16,
    b: u16,
    a: ?u16 = null,
};

pub const TestCase = struct {
    width: usize,
    height: usize,
    bitDepth: usize,
    imageType: ImageType,
    pixels: []const Pixel,
    pub fn getPixel(self: TestCase, x: usize, y: usize) Pixel {
        if (x > self.width or y > self.width) return .{ .r = 0, .g = 0, .b = 0 };
        return self.pixels[x + y * self.width];
    }
};

pub const TestInfo = struct {
    name: []const u8,
    testCase: ?TestCase,
    enabled: bool,
};

pub fn rgb(r: u16, g: u16, b: u16) Pixel {
    @setEvalBranchQuota(100000);

    return .{
        .r = r,
        .g = g,
        .b = b,
        .a = 0,
    };
}

pub fn rgba(r: u16, g: u16, b: u16, a: u16) Pixel {
    @setEvalBranchQuota(100000);

    return .{
        .r = r,
        .g = g,
        .b = b,
        .a = a,
    };
}
