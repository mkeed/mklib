const std = @import("std");
const EventLoop = @import("EventLoop.zig");

fn readExample(ctx: *anyopaque, fd: std.os.fd_t) EventLoop.HandlerError!EventLoop.HandlerResult {
    var data: [512]u8 = undefined;
    const len = std.os.read(fd, data[0..]) catch {
        return EventLoop.HandlerResult.Done;
    };

    std.log.info("data:[{s}]", .{data[0..len]});
    _ = ctx;
    return EventLoop.HandlerResult.Done;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var eventLoop = EventLoop.EventLoop.init(alloc);
    defer eventLoop.deinit();
    var in = std.io.getStdIn();
    try eventLoop.addHandler(.{
        .fd = in.handle,
        .ctx = &gpa,
        .read = &readExample,
    });
    //
    try eventLoop.run();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
