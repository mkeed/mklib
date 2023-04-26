const std = @import("std");
const Display = @import("Display.zig");
const Line = std.ArrayList(u8);

pub const Cursor = struct {
    row: usize,
    col: usize,
};

pub const CursorSet = struct {
    buffer: *Buffer,
    cursors: std.ArrayList(Cursor),
};

pub const Buffer = struct {
    alloc: std.mem.Allocator,
    lines: std.ArrayList(Line),
    topLine: usize,
    cursorSets: std.ArrayList(*CursorSet),
    pub fn init(alloc: std.mem.Allocator) !*Buffer {
        var self = try alloc.create(Buffer);
        errdefer alloc.destroy(self);
        self.* = Buffer{
            .alloc = alloc,
            .lines = std.ArrayList(Line).init(alloc),
            .topLine = 0,
        };

        return self;
    }
    pub fn initFromReader(alloc: std.mem.Allocator, reader: anytype) !*Buffer {
        var self = try Buffer.init(alloc);
        errdefer self.deinit();

        while (try reader.readUntilDelimiterOrEofAlloc(alloc, '\n', std.math.maxInt(usize))) |val| {
            var newLine = Line.fromOwnedSlice(alloc, val);
            errdefer newLine.deinit();
            try self.lines.append(newLine);
        }
        return self;
    }
    pub fn initFromMem(alloc: std.mem.Allocator, data: []const u8) !*Buffer {
        var fbs = std.io.fixedBufferStream(data);
        return try Buffer.initFromReader(alloc, fbs.reader());
    }

    pub fn display(
        self: *Buffer,
        arena: std.mem.Allocator,
        bufferLines: isize,
        bufferWidth: isize,
    ) !Display.BufferDisplay {
        const numLines = std.math.min(self.lines.items.len - self.topLine, bufferLines);
        var lines = try arena.alloc([]const u8, numLines);
        for (lines, 0..) |*l, idx| {
            var lineData = self.lines.items[idx + self.topLine].items;
            const len = std.math.min(lineData.len, bufferWidth);
            const line = try std.fmt.allocPrint(arena, "{s}", .{std.fmt.fmtSliceEscapeLower(lineData[0..len])});
            l.* = line;
        }
        return Display.BufferDisplay{
            .lines = lines,
            .modeLine = "Example ModeLine",
        };
    }

    pub fn deinit(self: *Buffer) void {
        for (self.lines.items) |line| {
            line.deinit();
        }
        self.lines.deinit();
        self.alloc.destroy(self);
    }
};
