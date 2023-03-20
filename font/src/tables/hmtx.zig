const std = @import("std");

const longHorMetric = struct {
    advanceWidth: u16,
    lsb: i16,
};

const HMTX = struct {
    metrics: std.ArrayList(longHorMetric),

    pub fn init(alloc: std.mem.Allocator) HMTX {
        return HMTX{
            .metrics = std.ArrayList(longHorMetric).init(alloc),
        };
    }

    pub fn deinit(self: HMTX) void {
        self.metrics.deinit();
    }
};

pub fn parse(data: []const u8, alloc: std.mem.Allocator, numMetrics: u16) !HMTX {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();

    var hmtx = HMTX.init(alloc);
    errdefer hmtx.deinit();
}
