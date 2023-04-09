const std = @import("std");
const pngTests = @import("PngTests.zig");
const png = @import("png");
const sixel = @import("sixel");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const testDir = "src/PngSuite-2017jul19/";
    const dir = try std.fs.cwd().openDir(testDir, .{});
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // defer bw.flush() catch {};
    // const stdout = bw.writer();
    var dataBuffer = std.ArrayList(u8).init(alloc);
    defer dataBuffer.deinit();
    for (pngTests.tests) |t| {
        if (t.testCase) |tc| {
            std.log.info("{s}", .{t.name});
            dataBuffer.clearRetainingCapacity();
            const file = try dir.openFile(t.name, .{});
            defer file.close();
            try file.reader().readAllArrayList(&dataBuffer, std.math.maxInt(usize));
            var fbs = std.io.fixedBufferStream(dataBuffer.items);
            const fbs_reader = fbs.reader();
            const img = png.decodeImage(fbs_reader, alloc) catch |err| {
                std.log.info("{s} => error {}", .{ t.name, err });
                return err;
            };
            defer img.deinit();
            for (0..tc.width) |w| {
                for (0..tc.height) |h| {
                    const p_exp = tc.getPixel(w, h);
                    const p_act = img.getPixel(w, h) orelse unreachable;
                    if (p_exp.r != p_act.r or
                        p_exp.g != p_act.g or
                        p_exp.b != p_act.b or
                        (p_exp.a != null and p_exp.a != p_act.a))
                    {
                        std.log.err("{}x{}", .{ tc.width, tc.height });
                        //std.log.err("{}", .{img.header});
                        std.log.err("[{s}][{},{}] {} != {}", .{ t.name, w, h, p_exp, p_act });
                        return error.Invalid;
                    }
                }
            }
        }
    }
}
