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

    var file = try std.fs.cwd().createFile("ErrorFile.txt", .{ .truncate = false });
    defer file.close();

    var eventLoop = el.EventLoop.init(alloc, file);
    defer eventLoop.deinit();

    var editor = try mked.mked.init(alloc, &eventLoop);
    defer editor.deinit();
    try eventLoop.run();
}
