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
    pub fn deinit(self: CursorSet) void {
        self.cursors.deinit();
    }
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
            .cursorSets = std.ArrayList(*CursorSet).init(alloc),
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

    pub fn createCursorSet(self: *Buffer) !*CursorSet {
        var set = try self.alloc.create(CursorSet);
        errdefer self.alloc.destroy(set);
        set.* = try CursorSet.init(self.alloc, self);
        errdefer set.deinit();
        try self.cursorSets.append(set);
        return set;
    }
    pub fn deinit(self: *Buffer) void {
        for (self.lines.items) |line| {
            line.deinit();
        }
        self.lines.deinit();
        for (self.cursorSets.items) |item| {
            item.deinit();
        }
        self.cursorSets.deinit();
        self.alloc.destroy(self);
    }
};
