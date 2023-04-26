const std = @import("std");
const Layout = @import("Layout.zig");
const LayoutError = error{} || std.mem.Allocator.Error;
const Render = @import("Render.zig");
const BufferView = @import("BufferView.zig").BufferView;
const SplitFrame = struct {
    pub fn init(alloc: std.mem.Allocator) SplitFrame {
        return .{
            .displays = std.ArrayList(*Display).init(alloc),
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
                _ = layoutComp;
                //var iter = layoutComp.iter
            },
            .horizontal => |h| {
                _ = h;
            },
        }
    }
};

pub const Frame = struct {
    alloc: std.mem.Allocator,
    displays: std.ArrayList(*Display),
    topLevel: *Display,
    pub fn init(alloc: std.mem.Allocator, buffer: BufferView) !Frame {
        var topLevel = try alloc.create(Display);
        errdefer alloc.destroy(topLevel);
        topLevel.* = .{
            .display = buffer,
        };
        var displays = std.ArrayList(*Display).init(alloc);
        errdefer displays.deinit();
        try displays.append(topLevel);
        return .{
            .alloc = alloc,
            .displays = displays,
            .topLevel = topLevel,
        };
    }
    pub fn deinit(self: Frame) void {
        for (self.displays.items) |d| {
            d.deinit();
            self.alloc.destroy(d);
        }
        self.displays.deinit();
    }
    pub const BufferLayout = struct {
        pos: Display.Pos,
        size: Display.Pos,
        buffer: *BufferView,
    };
    pub fn layout(self: Frame, windowSize: Display.Pos, arena: std.mem.Allocator) []BufferLayout {
        _ = self;
        _ = windowSize;
        var list = std.ArrayList(BufferLayout).init(arena);
        return list.item;
    }

    pub fn render(self: Frame, windowSize: Render.Pos, arena: std.mem.Allocator) RenderInfo {
        const title = try std.fmt.allocPrint(arena, "Frame:{}", .{123});
        const menus = &.{ "File", "Edit", "Options", "Buffers" };
        //var layouts =
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
