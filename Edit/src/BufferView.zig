const std = @import("std");
const Buffer = @import("Buffer.zig");
const Render = @import("Render.zig");

pub const BufferView = struct {
    buffer: *Buffer.Buffer,
    cursor_set: *Buffer.CursorSet,
    row: usize,
    pub fn init(buffer: *Buffer.Buffer) !BufferView {
        const cursor_set = try buffer.createCursorSet();
        return BufferView{
            .buffer = buffer,
            .cursor_set = cursor_set,
            .line = .{ .Top = 0 },
        };
    }
    pub fn deinit(self: BufferView) void {
        self.buffer.clearCursorSet(self.cursor_set);
    }
    pub fn render(self: BufferView, size: Render.Pos, arena: std.mem.Allocator) !Render.Window {
        const num_lines = std.math.min(self.buffer.numLines() - self.row, size.y);
        for (0..num_lines) |line| {
            const row = self.buffer.getLine(line + self.row) orelse unreachable;
        }
    }
};

// 1----------
// 2
// 3
// 4
// 5
// 6 m
// 7
// 8
// 9
// 10
// 11
// 12_________
// 13
// 14
// 15
// 16
