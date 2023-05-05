const std = @import("std");

pub const MKGUIOptions = struct {};

pub fn init(alloc: std.mem.Allocator, opts: MKGUIOptions) !MKGUI {}

pub const MKGUI = struct {
    pub fn init(alloc: std.mem.Allocator) MKGUI {
        _ = alloc;
        return .{};
    }
    pub fn deinit(self: MKGUI) void {
        _ = self;
    }

    pub fn run(self: MKGUI) !void {
        _ = self;
    }
};
