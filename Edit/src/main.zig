const std = @import("std");
const el = @import("EventLoop.zig");
const signal = @import("Signal.zig");
const mked = @import("mked.zig");

fn readExample(ctx: *anyopaque, fd: std.os.fd_t) el.HandlerError!el.HandlerResult {
    var data: [512]u8 = undefined;
    const len = std.os.read(fd, data[0..]) catch {
        return el.HandlerResult.Done;
    };

    std.log.info("data:[{s}]", .{data[0..len]});
    _ = ctx;
    return el.HandlerResult.Done;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    std.log.info("Pid:{}", .{std.os.linux.getpid()});

    var eventLoop = el.EventLoop.init(alloc);
    defer eventLoop.deinit();

    var editor = try mked.mked.init(alloc, &eventLoop);
    defer editor.deinit();

    try eventLoop.run();
}
