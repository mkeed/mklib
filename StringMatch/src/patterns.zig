const std = @import("std");

pub const Pattern = struct {
    pattern: std.ArrayList(u8),
    name: std.ArrayList(u8),
    pub fn init(alloc: std.mem.Allocator) Pattern {
        return .{
            .pattern = std.ArrayList(u8).init(alloc),
            .name = std.ArrayList(u8).init(alloc),
        };
    }
    pub fn deinit(self: Pattern) void {
        self.pattern.deinit();
        self.name.deinit();
    }
};

pub fn getPatterns(alloc: std.mem.Allocator) !std.ArrayList(Pattern) {
    const fileName = "src/Zig.tmLanguage.json";
    var file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
    var fileContents = std.ArrayList(u8).init(alloc);
    defer fileContents.deinit();
    try file.reader().readAllArrayList(&fileContents, std.math.maxInt(usize));
    var parser = std.json.Parser.init(alloc, false);
    defer parser.deinit();

    var patterns = std.ArrayList(std.ArrayList(u8)).init(alloc);
    errdefer patterns.deinit();
    errdefer {
        for (patterns.items) |item| {
            item.deinit();
        }
    }
    var valueTree = try parser.parse(fileContents.items);
    defer valueTree.deinit();
    const rep = switch (valueTree.root) {
        .Object => |map| switch (map.get("repository") orelse return patterns) {
            .Object => |obj| obj,
            else => return patterns,
        },
        else => return patterns,
    };
    for (rep.values()) |rep_item| {
        const patternsObj = switch (rep_item) {
            .Object => |repmap| repmap.get("patterns") orelse continue,
            else => continue,
        };
        const arr = switch (patternsObj) {
            .Array => |a| a,
            else => continue,
        };
        for (arr.items) |item| {
            switch (item) {
                .Object => |om| {
                    if (om.get("match")) |match| {
                        switch (match) {
                            .String => |s| {
                                var newString = std.ArrayList(u8).init(alloc);
                                errdefer newString.deinit();
                                try newString.appendSlice(s);
                                try patterns.append(newString);
                            },
                            else => continue,
                        }
                    }
                },
                else => continue,
            }
        }
    }
    return patterns;
}
