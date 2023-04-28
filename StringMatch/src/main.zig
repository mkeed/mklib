const std = @import("std");
const patterns = @import("patterns.zig");
const Regex = @import("Regex.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    var patternsList = try patterns.getPatterns(alloc);
    defer {
        for (patternsList.items) |item| {
            item.deinit();
        }
        patternsList.deinit();
    }

    for (patternsList.items) |item| {
        std.log.info("[{s}] : [{s}]", .{ item.name.items, item.pattern.items });
        var r = try Regex.parse(item.pattern.items, alloc);
        defer r.deinit();
    }
}
