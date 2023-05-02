const std = @import("std");
const el = @import("EventLoop.zig");
const signal = @import("Signal.zig");
const mked = @import("mked.zig");

pub const std_options = struct {
    pub const log_level = .info;

    pub const logFn = fileLogFn;
};

pub fn fileLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    var buffer: [4096]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    const now = std.time.milliTimestamp();

    const diff = now - start;
    const seconds = @intCast(usize, @divFloor(diff, std.time.ms_per_s));
    const millis = @intCast(usize, @mod(diff, std.time.ms_per_s));

    std.fmt.format(fbs.writer(), "[{:>5}.{:0>3}]({}|{})", .{ seconds, millis, level, scope }) catch return;
    std.fmt.format(fbs.writer(), format, args) catch return;

    std.fmt.format(file.writer(), "{s}", .{buffer[0..fbs.pos]}) catch return;
}

var file: std.fs.File = undefined;
var start: i64 = 0;
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
    start = std.time.milliTimestamp();
    file = try std.fs.cwd().createFile("ErrorFile.txt", .{ .truncate = true });
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 10 }){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var eventLoop = el.EventLoop.init(alloc);
    defer eventLoop.deinit();

    var editor = try mked.mked.init(alloc, &eventLoop);
    defer editor.deinit();
    try eventLoop.run();
}
