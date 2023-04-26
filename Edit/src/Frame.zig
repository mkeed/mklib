const std = @import("std");
const Display = @import("Display.zig");
const Layout = @import("Layout.zig");
const LayoutError = error{} || std.mem.Allocator.Error;

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
    display: *BufferView,
    pub fn deinit(self: Display) void {
        switch (self) {
            .horizontal, .vertical => |d| {
                d.deinit();
            },
        }
    }
    pub fn layout(self: Display, size: Pos, pos: Pos, list: *std.ArrayList(Frame.BufferLayout)) LayoutError!void {
        switch (self) {
            .display => |d| {
                try list.append(.{
                    .pos = pos,
                    .size = size,
                    .buffer = d,
                });
            },
            .vertical => |v| {
                const layout = Layout.WeightedLayout(SplitFrame.SplitDisplay){
                    .items = v.displays.items,
                };
                //var iter = layout.iter
            },
            .horizontal => |h| {},
        }
    }
};

pub const Frame = struct {
    alloc: std.mem.Allocator,
    displays: std.ArrayList(*Display),
    topLevel: *Display,
    pub fn init(alloc: std.mem.Allocator, buffer: *BufferView) !Frame {
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
    pub fn layout(self: Frame, windowSize: *Display.Pos, arena: std.mem.Allocator) []BufferLayout {
        var list = std.ArrayList(BufferLayout).init(arena);
    }
};

const disp = Display{
    .vertical = .{
        .splits = &.{
            .{ .weight = 50, .display = disp2 },
            .{ .weight = 50, .display = disp3 },
        },
    },
};

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
