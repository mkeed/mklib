const std = @import("std");

pub const MKGUIOptions = struct {};

pub fn init(alloc: std.mem.Allocator, opts: MKGUIOptions) !*MKGUI {}

pub const MKGUI = struct {
    alloc: std.mem.Allocator,
    screens: std.ArrayList(Screen),
    pub fn init(alloc: std.mem.Allocator) MKGUI {
        return .{
            .alloc = alloc,
            .screens = std.ArrayList(Screen).init(alloc),
        };
    }
    pub fn deinit(self: MKGUI) void {
        for (self.
    }

    pub fn run(self: MKGUI) !void {
        _ = self;
    }
    pub fn addScreen(self: MKGUI) !Screen {
        //
    }
};

pub const Screen = struct {
    alloc: std.mem.Allocator,
    core: MKGUI,
    pub fn init(alloc: std.mem.Allocator, core: MKGUI) Screen {
        return .{ .alloc = alloc, .core = core };
    }
    pub fn deinit(self: Screen) void {
        _ = self;
    }
};
