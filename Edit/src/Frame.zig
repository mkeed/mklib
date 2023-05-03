const std = @import("std");
const Layout = @import("Layout.zig");
const LayoutError = error{} || std.mem.Allocator.Error;
const Render = @import("Render.zig");
const BufferView = @import("BufferView.zig").BufferView;
const SplitFrame = struct {
    pub fn init(alloc: std.mem.Allocator) SplitFrame {
        return .{
            .displays = std.ArrayList(SplitDisplay).init(alloc),
        };
    }
    pub fn deinit(self: SplitFrame) void {
        self.displays.deinit();
    }
    displays: std.ArrayList(SplitDisplay),
    pub const SplitDisplay = struct {
        weight: usize,
        display: *Display,
    };
};

const Display = union(enum) {
    vertical: SplitFrame,
    horizontal: SplitFrame,
    display: BufferView,
    pub fn deinit(self: Display) void {
        switch (self) {
            .horizontal, .vertical => |d| {
                d.deinit();
            },
            else => {},
        }
    }
    pub fn layout(self: Display, size: Render.Pos, pos: Render.Pos, list: *std.ArrayList(Frame.BufferLayout)) LayoutError!void {
        switch (self) {
            .display => |d| {
                try list.append(.{
                    .pos = pos,
                    .size = size,
                    .buffer = d,
                });
            },
            .vertical => |v| {
                const layoutComp = Layout.WeightedLayout(SplitFrame.SplitDisplay){
                    .items = v.displays.items,
                };

                var iter = layoutComp.iter(@intCast(usize, size.x));
                while (iter.next()) |val| {
                    try val.item.display.layout(
                        .{ .x = @bitCast(isize, val.size), .y = size.y },
                        .{ .x = @bitCast(isize, val.pos), .y = pos.y },
                        list,
                    );
                }
            },
            .horizontal => |h| {
                const layoutComp = Layout.WeightedLayout(SplitFrame.SplitDisplay){
                    .items = h.displays.items,
                };

                var iter = layoutComp.iter(@intCast(usize, size.x));
                while (iter.next()) |val| {
                    try val.item.display.layout(
                        .{ .x = size.x, .y = @bitCast(isize, val.size) },
                        .{ .x = pos.x, .y = @bitCast(isize, val.pos) },
                        list,
                    );
                }
            },
        }
    }
};

pub const Frame = struct {
    alloc: std.mem.Allocator,
    displays: std.ArrayList(*Display),
    top_level: *Display,
    current_selection: *Display,
    pub fn init(alloc: std.mem.Allocator, buffer: BufferView) !Frame {
        var top_level = try alloc.create(Display);
        errdefer alloc.destroy(top_level);
        top_level.* = .{
            .display = buffer,
        };
        var displays = std.ArrayList(*Display).init(alloc);
        errdefer displays.deinit();
        try displays.append(top_level);
        return .{
            .alloc = alloc,
            .displays = displays,
            .top_level = top_level,
            .current_selection = top_level,
        };
    }
    pub fn deinit(self: Frame) void {
        for (self.displays.items) |d| {
            d.deinit();
            self.alloc.destroy(d);
        }
        self.displays.deinit();
    }
    pub const Direction = enum { Vertical, Horizontal };
    pub fn split(self: *Frame, direction: Direction, count: usize) !void {
        switch (self.current_selection.*) {
            .display => |d| {
                var split_frame = SplitFrame.init(self.alloc);
                errdefer split_frame.deinit();
                for (0..count) |_| {
                    var new_display = try self.alloc.create(Display);
                    errdefer self.alloc.destroy(new_display);
                    new_display.* = .{ .display = try d.dupe() };
                    try self.displays.append(new_display);
                    try split_frame.displays.append(.{
                        .weight = 100,
                        .display = new_display,
                    });
                }
                self.current_selection.* = switch (direction) {
                    .Vertical => .{
                        .vertical = split_frame,
                    },
                    .Horizontal => .{
                        .horizontal = split_frame,
                    },
                };
            },
            else => unreachable,
        }
    }
    pub const BufferLayout = struct {
        pos: Render.Pos,
        size: Render.Pos,
        buffer: BufferView,
    };
    pub fn render(self: Frame, windowSize: Render.Pos, arena: std.mem.Allocator) !Render.RenderInfo {
        const title = try std.fmt.allocPrint(arena, "Frame:{}", .{123});
        const menus = [_]Render.Menu{
            .{ .name = "File" },
            .{ .name = "Edit" },
            .{ .name = "Options" },
            .{ .name = "Buffers" },
        };
        var layouts = std.ArrayList(BufferLayout).init(arena);
        try self.top_level.layout(.{ .x = windowSize.x, .y = windowSize.y - 1 }, .{ .x = 0, .y = 1 }, &layouts);
        var bufferRender = try arena.alloc(Render.WindowInfo, layouts.items.len);
        for (layouts.items, 0..) |layout, idx| {
            bufferRender[idx] = .{
                .pos = layout.pos,
                .size = layout.size,
                .window = try layout.buffer.render(layout.size, arena),
            };
        }

        return Render.RenderInfo{
            .title = title,
            .menus = &menus,
            .buffer = bufferRender,
            .screenSize = windowSize,
        };
    }
};

//const disp = Display{
//    .vertical = .{
//        .splits = &.{
//            .{ .weight = 50, .display = disp2 },
//            .{ .weight = 50, .display = disp3 },
//        },
//    },
//};

// --------------------------------------------------------------------------------
// |                                    |                                          |
// |                                    |                                          |
// |                                    |                                          |
// |                                    |                                          |
// |                                    |                                          |
// |                                    |                                          |
// |                                    |------------------------------------------|
// |                                    |                                          |
// |                                    |                                          |
// |                                    |                                          |
// |                                    |                                          |
// |                                    |                                          |
// |                                    |                                          |
// --------------------------------------------------------------------------------
