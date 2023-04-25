const std = @import("std");
const arg = @import("ArgParse");
const Terminal = @import("Terminal.zig").Terminal;
const el = @import("EventLoop.zig");
const Display = @import("Display.zig");
const MkedCore = @import("MkedCore.zig").MkedCore;
const App = @import("App.zig");
const Buffer = @import("Buffer.zig").Buffer;

const RunInfo = struct {
    fileList: std.ArrayList(std.ArrayList(u8)),

    pub fn init(alloc: std.mem.Allocator) RunInfo {
        return RunInfo{
            .fileList = std.ArrayList(std.ArrayList(u8)).init(alloc),
        };
    }
    pub fn deinit(self: RunInfo) void {
        for (self.fileList.items) |item| {
            item.deinit();
        }
        self.fileList.deinit();
    }
};

const ArgDef = arg.ProcInfo{
    .args = &.{
        .{
            .longName = "files",
            .short = 'f',
            .fieldName = "fileList",
            .docs = "File List to edit",
        },
    },
    .defaultList = "fileList",
    .docs = "test",
};

pub const alice = @embedFile("alice.txt");
pub const frankenstein = @embedFile("Frankenstein.txt");

pub const mked = struct {
    alloc: std.mem.Allocator,
    core: *MkedCore,
    terminal: *Terminal,
    event: *el.EventLoop,
    cursorPos: Display.Pos,
    inputMessage: std.ArrayList(u8),
    buffers: std.ArrayList(*Buffer),
    pub fn init(alloc: std.mem.Allocator, event: *el.EventLoop) !*mked {
        var self = try alloc.create(mked);
        errdefer alloc.destroy(self);

        var core = try alloc.create(MkedCore);
        errdefer alloc.destroy(core);
        core.* = MkedCore.init(alloc, self);
        errdefer core.deinit();
        var terminal = try Terminal.init(alloc, event, core);
        self.* = mked{
            .alloc = alloc,
            .core = core,
            .terminal = terminal,
            .event = event,
            .cursorPos = .{
                .x = 1,
                .y = 1,
            },
            .inputMessage = std.ArrayList(u8).init(alloc),
            .buffers = std.ArrayList(*Buffer).init(alloc),
        };

        try self.buffers.append(try Buffer.initFromMem(alloc, frankenstein));
        try self.buffers.append(try Buffer.initFromMem(alloc, alice));

        try event.addPreHandler(.{ .ctx = self, .func = &preEventHandler });

        return self;
    }

    pub fn preEventImpl(self: *mked) !void {
        while (self.terminal.input.inputQueue.readItem()) |item| {
            switch (item) {
                .keyboard => |key| {
                    if (key.key == .F12) {
                        self.core.close();
                    }
                    for (App.Input.inputs) |input| {
                        switch (input.input) {
                            .keyboard => |k| {
                                if (k.equal(key)) {
                                    switch (input.command) {
                                        .movement => |m| {
                                            switch (m) {
                                                .Char => |c| {
                                                    self.cursorPos.x += c;
                                                },
                                                .Line => |l| {
                                                    self.cursorPos.y += l;
                                                },
                                                .Word => |w| {
                                                    self.cursorPos.x += w;
                                                },
                                            }
                                        },
                                    }
                                }
                            },
                            else => {},
                        }
                    }
                    self.inputMessage.clearRetainingCapacity();
                    const writer = self.inputMessage.writer();
                    try std.fmt.format(writer, "{}", .{key});
                },
                .mouse => |m| {
                    self.inputMessage.clearRetainingCapacity();
                    const writer = self.inputMessage.writer();
                    var mods = [2]u8{ ' ', ' ' };

                    if (m.ctrl) mods[0] = 'c';
                    if (m.meta) mods[1] = 'm';

                    try std.fmt.format(writer, "{?} @ {}x{}[{s}]", .{ m.button, m.x, m.y, mods });
                    if (m.button) |button| {
                        if (button == .Left) self.cursorPos = .{
                            .x = m.x,
                            .y = m.y,
                        };
                    }
                },
            }
        }
        var arena = std.heap.ArenaAllocator.init(self.alloc);
        defer arena.deinit();
        const aalloc = arena.allocator();
        const bufferWidth: isize = 100;
        var buffers = try aalloc.alloc(Display.BufferInfo, self.buffers.items.len);
        for (self.buffers.items, 0..) |buf, idx| {
            const pos = @intCast(isize, idx * bufferWidth);
            const len = std.math.min(
                bufferWidth,
                self.terminal.output.terminalSize.x - pos,
            );
            buffers[idx] = .{
                .pos = .{ .x = pos, .y = 1 },
                .buffer = try buf.display(aalloc, self.terminal.output.terminalSize.y, len),
            };
        }

        try self.terminal.output.draw(.{
            .screenSize = self.terminal.output.terminalSize,
            .cursorPos = self.cursorPos,
            .menuItems = &.{ "File", "Edit", "Options", "Buffers" },
            .cmdline = self.inputMessage.items,
            .buffers = buffers,
        });
    }

    fn preEventHandler(ctx: *anyopaque) void {
        const self = el.ctxTo(mked, ctx);
        self.preEventImpl() catch {};
    }

    pub fn deinit(self: *mked) void {
        self.core.deinit();
        self.terminal.deinit();
        self.inputMessage.deinit();
        for (self.buffers.items) |buffer| {
            buffer.deinit();
        }
        self.buffers.deinit();
        self.alloc.destroy(self);
    }
};
