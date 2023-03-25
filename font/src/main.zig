const std = @import("std");
const font = @import("font.zig");

pub const ProcessInfo = struct {
    files: std.ArrayList(std.ArrayList(u8)),
    dumpTables: bool = false,
    perTableDump: bool = false,
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
            if (val[0] == '-') {
                if (std.mem.eql(u8, val, "--dumpTables")) {
                    self.dumpTables = true;
                }
                if (std.mem.eql(u8, val, "--addAllSystemFonts")) {
                    self.addAllSystemFonts = true;
                }
                if (std.mem.eql(u8, val, "--perTableDump")) {
                    self.perTableDump = true;
                }
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

const sortCtx = struct {
    table: std.AutoArrayHashMap([4]u8, usize),
    pub fn lessThan(ctx: sortCtx, a_index: usize, b_index: usize) bool {
        const a = ctx.table.values()[a_index];
        const b = ctx.table.values()[b_index];
        return a < b;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var procInfo = try ProcessInfo.init(alloc);
    defer procInfo.deinit();

    if (procInfo.addAllSystemFonts) {
        var fonts = try font.listFonts(alloc);
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
    var writer = std.io.getStdOut().writer();
    var fileBuffer = std.ArrayList(u8).init(alloc);
    defer fileBuffer.deinit();
    var errorFiles = std.ArrayList(std.ArrayList(u8)).init(alloc);
    defer {
        errorFiles.deinit();
    }
    var tableNames = std.ArrayList([4]u8).init(alloc);
    defer tableNames.deinit();
    var tableCount = std.AutoArrayHashMap([4]u8, usize).init(alloc);
    defer tableCount.deinit();
    for (procInfo.files.items) |item| {
        fileBuffer.clearRetainingCapacity();
        var file = try std.fs.cwd().openFile(item.items, .{});
        defer file.close();

        if (procInfo.dumpTables) {
            var buf = std.mem.zeroes([4096]u8);
            const len = try file.read(buf[0..]);
            var table = font.Table{ .data = buf[0..len] };
            tableNames.clearRetainingCapacity();
            try table.listTables(&tableNames);
            if (procInfo.perTableDump) {
                try std.fmt.format(writer, "{s}\n[", .{item.items});
            }
            for (tableNames.items) |tn| {
                if (procInfo.perTableDump) {
                    try std.fmt.format(writer, "{s} ", .{tn});
                }
                if (tableCount.getPtr(tn)) |val| {
                    val.* += 1;
                } else {
                    try tableCount.put(tn, 1);
                }
            }
            if (procInfo.perTableDump) {
                try std.fmt.format(writer, "]\n", .{});
            }
            continue;
        }

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
    if (procInfo.dumpTables) {
        var ctx = sortCtx{ .table = tableCount };
        tableCount.sort(ctx);
        var iter = tableCount.iterator();
        while (iter.next()) |entry| {
            try std.fmt.format(writer, "[{s}] => {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
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
