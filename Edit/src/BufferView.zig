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
            .row = 1,
        };
    }
    pub fn deinit(self: BufferView) void {
        self.buffer.clearCursorSet(self.cursor_set);
    }

    pub fn dupe(self: BufferView) !BufferView {
        return BufferView{
            .buffer = self.buffer,
            .cursor_set = try self.cursor_set.dupe(),
            .row = self.row,
        };
    }

    pub fn render(self: BufferView, size: Render.Pos, arena: std.mem.Allocator) !Render.Window {
        const num_lines = std.math.min(self.buffer.numLines() - (self.row - 1), size.y);
        var lines = try arena.alloc(Render.RenderLine, num_lines);
        for (0..num_lines) |line| {
            const row = self.buffer.getLine(line + self.row) orelse unreachable;
            var lineData = try arena.alloc(Render.Text, 1);
            lineData[0] = .{ .face = "default", .data = row };
            lines[line] = .{
                .line_num = line + self.row,
                .data = lineData,
            };
        }
        return .{
            .mode_line = .{
                .mode_info = &.{
                    .{
                        .pos = 0,
                        .val = .{ .face = "default", .data = "Modeline" },
                    },
                },
            },
            .lines = lines,
        };
    }
};
