const std = @import("std");
const ssh = @import("ssh.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 15 }){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var session = try ssh.init(alloc, std.fs.cwd(), .{
        .address = std.net.Address.parseIp("127.0.0.1", 22) catch unreachable,
        .hostname = "127.0.0.1",
    });
    defer session.deinit();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
