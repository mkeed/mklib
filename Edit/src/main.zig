const std = @import("std");
const el = @import("EventLoop.zig");
const signal = @import("Signal.zig");

fn readExample(ctx: *anyopaque, fd: std.os.fd_t) el.HandlerError!el.HandlerResult {
    var data: [512]u8 = undefined;
    const len = std.os.read(fd, data[0..]) catch {
        return el.HandlerResult.Done;
    };

    std.log.info("data:[{s}]", .{data[0..len]});
    _ = ctx;
    return el.HandlerResult.Done;
}

fn sigWinch(ctx: *anyopaque, sig: u32) el.HandlerError!el.HandlerResult {
    _ = ctx;
    _ = sig;
    return el.HandlerResult.Done;
}
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var eventLoop = el.EventLoop.init(alloc);
    defer eventLoop.deinit();

    var sig = signal.Signal.init();
    sig.addHandler(std.os.SIG.WINCH, &sigWinch);
    const sfd = try sig.createSignalFd(alloc);
    defer sfd.deinit();

    const handler = sfd.getEventHandler();
    try eventLoop.addHandler(handler);

    try eventLoop.run();
}
