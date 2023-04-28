const std = @import("std");
const patterns = @import("patterns.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    var patternsList = try patterns.getPatterns(alloc);
    errdefer {
        for (patternsList.items) |item| {
            item.deinit();
        }
        patternsList.deinit();
    }

    for (patternsList.items) |item| {
        std.log.info("Pattern: [{s}]", .{item.items});
    }
}
