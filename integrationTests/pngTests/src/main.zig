const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const testFolder = "../../image/PNG/PngSuite-2017jul19/";
    var dir = try std.fs.cwd().openDir(testFolder, .{});
    defer dir.close();
    var testDir = try std.fs.cwd().openDir("test", .{});
    defer testDir.close();
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
}
