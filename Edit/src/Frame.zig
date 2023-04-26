const std = @import("std");

pub const SplitFrame = struct {
    pub fn init(alloc: std.mem.Allocator) SplitFrame {
        return .{
            .displays = std.ArrayList(*Display).init(alloc),
        };
    }
    pub fn deinit(self: SplitFrame) void {
        self.displays.deinit();
    }
    displays: std.ArrayList(*Display),
};

const Display = union(enum) {
    vertical: SplitFrame,
    horizontal: SplitFrame,
    display: *BufferView,
    pub fn deinit(self: Display) void {
        switch (self) {
            .display => |d| {
                d.deinit();
            },
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
