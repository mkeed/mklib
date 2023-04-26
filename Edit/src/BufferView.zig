const std = @import("std");
const Buffer = @import("Buffer.zig");

pub const BufferView = struct {
    buffer: *Buffer.Buffer,
    cursorSet: *Buffer.CursorSet,
    pub fn init(buffer: *Buffer) !BufferView {
        const cursorSet = try buffer.createCursorSet();
        return BufferView{
            .buffer = buffer,
            .cursorSet = cursorSet,
        };
    }
};
