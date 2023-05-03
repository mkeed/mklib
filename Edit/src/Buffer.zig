const std = @import("std");
const Line = std.ArrayList(u8);

pub const Cursor = struct {
    row: usize,
    col: usize,
};

pub const CursorSet = struct {
    buffer: *Buffer,
    cursors: std.ArrayList(Cursor),
    pub fn init(alloc: std.mem.Allocator, buffer: *Buffer) !CursorSet {
        var cursors = std.ArrayList(Cursor).init(alloc);
        try cursors.append(.{ .row = 0, .col = 0 });
        return .{
            .buffer = buffer,
            .cursors = cursors,
        };
    }
    pub fn dupe(self: CursorSet) !*CursorSet {
        var new = try self.buffer.createCursorSet();
        try new.cursors.appendSlice(self.cursors.items);
        return new;
    }
    pub fn deinit(self: CursorSet) void {
        self.cursors.deinit();
    }
};

pub const Buffer = struct {
    alloc: std.mem.Allocator,
    lines: std.ArrayList(Line),
    top_line: usize,
    cursor_sets: std.ArrayList(*CursorSet),
    pub fn init(alloc: std.mem.Allocator) !*Buffer {
        var self = try alloc.create(Buffer);
        errdefer alloc.destroy(self);
        self.* = Buffer{
            .alloc = alloc,
            .lines = std.ArrayList(Line).init(alloc),
            .top_line = 0,
            .cursor_sets = std.ArrayList(*CursorSet).init(alloc),
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

    pub fn createInitBuffer(alloc: std.mem.Allocator) !*Buffer {
        const welcomeMessage =
            \\Welcome to mked
            \\Open a file to begin
        ;
        return Buffer.initFromMem(alloc, welcomeMessage);
    }
    pub fn numLines(self: *Buffer) usize {
        return self.lines.items.len;
    }
    pub fn getLine(self: *Buffer, line: usize) ?[]const u8 {
        if (line > self.lines.items.len) return null;
        return self.lines.items[line - 1].items;
    }
    pub fn createCursorSet(self: *Buffer) !*CursorSet {
        var set = try self.alloc.create(CursorSet);
        errdefer self.alloc.destroy(set);
        set.* = try CursorSet.init(self.alloc, self);
        errdefer set.deinit();
        try self.cursor_sets.append(set);
        return set;
    }
    pub fn clearCursorSet(self: *Buffer, set: *CursorSet) void {
        for (self.cursor_sets.items, 0..) |item, idx| {
            if (item == set) {
                _ = self.cursor_sets.swapRemove(idx);
                break;
            }
        }
        set.deinit();
        self.alloc.destroy(set);
    }
    pub fn deinit(self: *Buffer) void {
        for (self.lines.items) |line| {
            line.deinit();
        }
        self.lines.deinit();
        for (self.cursor_sets.items) |item| {
            item.deinit();
            self.alloc.destroy(item);
        }
        self.cursor_sets.deinit();
        self.alloc.destroy(self);
    }
};
