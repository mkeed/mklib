const std = @import("std");
const Buffer = @import("Buffer.zig");
const Render = @import("Render.zig");

pub const LinePos = union(enum) {
    Top: usize,
    Middle: usize,
    Bottom: usize,
};

pub const BufferView = struct {
    buffer: *Buffer.Buffer,
    cursor_set: *Buffer.CursorSet,
    line: LinePos,
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
    pub fn render(self: BufferView, size: Render.Pos, arena: std.mem.Allocator) !Render.Window {}
};
