const std = @import("std");

const LogItem = struct {
    level: std.log.Level,
    info: std.ArrayList(u8),
    pub fn init(alloc: std.mem.Allocator, level: std.log.Level) LogItem {
        return .{
            .level = level,
            .info = std.ArrayList(u8).init(alloc),
        };
    }
    pub fn deinit(self: LogItem) void {
        self.info.deinit();
    }
};

pub const Logger = struct {
    pub const LoggerOpts = struct {
        maxDepth: usize = 100,
    };
    alloc: std.mem.Allocator,
    logs: std.ArrayList(LogItem),
    opts: LoggerOpts,
    pub fn init(alloc: std.mem.Allocator, opts: LoggerOpts) Logger {
        return .{
            .alloc = alloc,
            .logs = std.ArrayList(LogItem).init(alloc),
            .opts = opts,
        };
    }
    pub fn deinit(self: Logger) void {
        for (self.logs.items) |item| {
            item.deinit();
        }
        self.logs.deinit();
    }
    pub fn err(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.errImpl(fmt, args);
    }
    fn errImpl(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
        var line = LogItem.init(self.alloc, .err);
        errdefer line.deinit();
        try std.fmt.format(line.info.writer(), fmt, args);
        try self.logs.append(line);
    }
};
