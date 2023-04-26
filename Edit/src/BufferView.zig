const std = @import("std");
const Buffer = @import("Buffer.zig");

pub const LinePos = union(enum) {
    Top: usize,
    Middle: usize,
    Bottom: usize,
};

pub const BufferView = struct {
    buffer: *Buffer.Buffer,
    cursorSet: *Buffer.CursorSet,
    line: LinePos,
    pub fn init(buffer: *Buffer.Buffer) !BufferView {
        const cursorSet = try buffer.createCursorSet();
        return BufferView{
            .buffer = buffer,
            .cursorSet = cursorSet,
            .line = .{ .Top = 0 },
        };
    }
};
