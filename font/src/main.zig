const std = @import("std");
const font = @import("font.zig");

pub const ProcessInfo = struct {
    files: std.ArrayList(std.ArrayList(u8)),
    dumpTables: bool = false,
    addAllSystemFonts: bool = false,
    pub fn init(alloc: std.mem.Allocator) !ProcessInfo {
        var args = try std.process.argsWithAllocator(alloc);
        defer args.deinit();
        _ = args.skip(); // don't need processName
        var self = ProcessInfo{
            .files = std.ArrayList(std.ArrayList(u8)).init(alloc),
        };
        errdefer self.deinit();
        while (args.next()) |val| {
            if (val.len == 0) {
                continue;
            }
            if (val.len == '-') {
                if (std.mem.eql(u8, val, "--dumpTables")) {
                    self.dumpTables = true;
                }
                if (std.mem.eql(u8, val, "--addAllSystemFonts")) {
                    self.addAllSystemFonts = true;
                }
                //is option
            } else {
                var name = std.ArrayList(u8).init(alloc);
                errdefer name.deinit();
                try name.appendSlice(val);
                try self.files.append(name);
            }
        }
        return self;
    }

    pub fn deinit(self: ProcessInfo) void {
        for (self.files.items) |file| {
            file.deinit();
        }
        self.files.deinit();
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var procInfo = try ProcessInfo.init(alloc);
    defer procInfo.deinit();

    if (procInfo.addAllSystemFonts) {
        var fonts = font.listFonts(alloc);
        defer {
            for (fonts.items) |item| {
                item.deinit();
            }
            fonts.deinit();
        }
        while (fonts.popOrNull()) |item| {
            try procInfo.files.append(item);
        }
    }
    var fileBuffer = std.ArrayList(u8).init(alloc);
    defer fileBuffer.deinit();
    var errorFiles = std.ArrayList(std.ArrayList(u8)).init(alloc);
    defer {
        errorFiles.deinit();
    }
    for (procInfo.files.items) |item| {
        fileBuffer.clearRetainingCapacity();
        var file = try std.fs.cwd().openFile(item.items, .{});
        defer file.close();
        try file.reader().readAllArrayList(&fileBuffer, 100000000);
        var f = font.parseFont(fileBuffer.items, alloc) catch |err| {
            std.log.err("FileName:{s}", .{item.items});
            switch (err) {
                error.InvalidVersion => {
                    errorFiles.append(item) catch {};
                    continue;
                },
                else => return err,
            }
        };
        defer f.deinit();
    }
    for (errorFiles.items) |item| {
        std.log.info("fileError:{s}", .{item.items});
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
