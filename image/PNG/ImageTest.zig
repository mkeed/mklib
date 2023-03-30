const std = @import("std");
const sixel = @import("sixel");
const png = @import("png");
const testCases = @import("img/src/png_tests.zig");
const Image = @import("img/src/Image.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const testFolder = "img/src/PNG/PngSuite-2017jul19/";
    var dir = try std.fs.cwd().openDir(testFolder, .{});

    defer dir.close();
    //var buf: [4096]u8 = undefined;
    var testDir = try std.fs.cwd().openDir("test", .{});
    defer testDir.close();
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    if (false) {
        var bufres = [8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 };

        const input = [1]u8{0xDF};
        const a = [1]u8{0x4};
        const b = [1]u8{0x0};
        const c = [1]u8{0x0};
        const result = png.paethPredictorBuf(
            bufres[0..],
            4,
            input[0..],
            a[0..],
            b[0..],
            c[0..],
        );

        std.log.err("result:{}", .{std.fmt.fmtSliceHexUpper(result)});
        return;
    }
    var contents = std.ArrayList(u8).init(alloc);
    defer contents.deinit();
    for (testCases.tests) |tc| {
        const fileName = switch (tc) {
            .todoTest => |tt| tt,
            .auto => |at| at.filename,
            .endTest => {
                break;
            },
            .failingTest => {
                continue;
            },
        };
        std.log.info("Reading: {s}", .{fileName});
        contents.clearRetainingCapacity();

        var file = try dir.openFile(fileName, .{});
        defer file.close();
        try file.reader().readAllArrayList(&contents, std.math.maxInt(u32));
        var img = try png.decodeImage(contents.items, alloc);
        defer img.deinit();

        switch (tc) {
            .auto => |at| {
                errdefer {
                    printData(alloc, img, fileName) catch {};
                }
                var imgView = Image.ImageView{ .data = at.data, .width = at.width, .height = at.height, .bytesPerPixel = at.bytesPerPixel };
                var y: usize = 0;
                try std.testing.expectEqual(at.interlace, img.header.interlace);
                try std.testing.expectEqual(at.width, img.img.width);
                try std.testing.expectEqual(at.height, img.img.height);
                try std.testing.expectEqual(at.depth, img.header.depth);
                try std.testing.expectEqual(at.colour, img.header.colourType);
                while (y < img.img.height) : (y += 1) {
                    var x: usize = 0;
                    while (x < img.img.width) : (x += 1) {
                        const pix = img.img.getPixelIfSet(x, y) orelse return error.PixelMissing;
                        const pixexp = imgView.getPixel(x, y) orelse return error.PixelMissing;

                        std.testing.expectEqualSlices(u8, pixexp, pix) catch |err| {
                            std.log.err("At pixel({},{}) expected({}), found({})", .{
                                x,                                y,
                                std.fmt.fmtSliceHexUpper(pixexp), std.fmt.fmtSliceHexUpper(pix),
                            });
                            return err;
                        };
                    }
                }
            },
            .todoTest => {
                try printData(alloc, img, fileName);
                const writeOutputData = true;
                if (writeOutputData) {
                    const partName = fileName[0..(std.mem.indexOf(u8, fileName, ".") orelse unreachable)];
                    var buf: [256]u8 = undefined;
                    const outfileName = try std.fmt.bufPrint(buf[0..], "{s}.zig", .{partName});

                    var outputFile = try testDir.createFile(outfileName, .{
                        .truncate = true,
                    });
                    defer outputFile.close();
                    var outwriter = outputFile.writer();
                    const testValues = [_][2]u8{};

                    for (testValues) |val| {
                        const pix = img.img.getPixelIfSet(val[0], val[1]) orelse return error.PixelMissing;
                        std.log.err("pix:[{},{}] => [{}]", .{ val[0], val[1], std.fmt.fmtSliceHexUpper(pix) });
                    }

                    try std.fmt.format(outwriter, "pub const data = [_]u8{{//\n", .{});
                    var y: usize = 0;
                    while (y < img.img.height) : (y += 1) {
                        var x: usize = 0;
                        while (x < img.img.width) : (x += 1) {
                            const pix = if (img.img.getPixelIfSet(x, y)) |p| p else {
                                std.log.err("[{},{}]", .{ x, y });
                                return error.PixelMissing;
                            };
                            for (pix) |pval| {
                                try std.fmt.format(outwriter, "0x{x:0>2}, ", .{pval});
                            }
                        }
                        try std.fmt.format(outwriter, "// \n ", .{});
                    }
                    try std.fmt.format(outwriter, "\n}};\n", .{});
                }
            },
            else => {},
        }
    }

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.

    try stdout.print("Run `zig build test` to run the tests.\n", .{});
}

fn printData(alloc: std.mem.Allocator, img: png.PNG, name: []const u8) !void {
    std.log.info("printing:{s}", .{name});
    var pixels = try alloc.alloc(tr.Pixel, img.img.width * img.img.height);
    defer alloc.free(pixels);
    var y: usize = 0;
    var idx: usize = 0;
    while (y < img.img.height) : (y += 1) {
        var x: usize = 0;
        while (x < img.img.width) : (x += 1) {
            defer idx += 1;
            const redPixel = [4]u8{ 255, 0, 0, 255 };
            const pix = img.img.getPixelIfSet(x, y);
            //std.log.err("x:{} y:{}",.{x,y});
            const scaledData = if (pix) |p| try img.header.convertToRGB(p) else redPixel;
            pixels[idx] = .{
                .red = scaledData[0],
                .green = scaledData[1],
                .blue = scaledData[2],
                .alpha = scaledData[3],
            };
        }
    }
    try tr.render(.{ .pixel = pixels, .width = img.img.width, .height = img.img.height });
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
