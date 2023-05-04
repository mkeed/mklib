const std = @import("std");

pub fn WeightedLayout(comptime T: type) type {
    return struct {
        const Self = @This();
        items: []const T,
        pub const Iterator = struct {
            totalWeight: usize,
            totalSize: usize,
            currentIdx: usize,
            currentPos: usize,
            padding: usize,
            items: []const T,
            pub const Result = struct {
                pos: usize,
                size: usize,
                item: T,
            };
            pub fn next(self: *Iterator) ?Result {
                if (self.currentIdx >= self.items.len) return null;
                defer self.currentIdx += 1;

                const pos = self.currentPos;
                const cur = self.items[self.currentIdx];
                const move = (self.totalSize * cur.weight) / self.totalWeight;
                defer self.currentPos += (move + self.padding);
                return Result{
                    .pos = pos,
                    .size = move,
                    .item = cur,
                };
            }
        };

        pub fn iter(self: Self, totalSize: usize, padding: usize) Iterator {
            var totalWeight: usize = 0;
            for (self.items) |item| {
                totalWeight += item.weight;
            }
            return .{
                .totalWeight = totalWeight - (self.items.len - 1) * padding,
                .totalSize = totalSize,
                .currentIdx = 0,
                .currentPos = 0,
                .padding = padding,
                .items = self.items,
            };
        }
    };
}

const testStruct = struct {
    weight: usize,
    expPos: usize,
};

test {
    const tests = [_]testStruct{
        .{ .weight = 25, .expPos = 0 },
        .{ .weight = 25, .expPos = 25 },
        .{ .weight = 25, .expPos = 50 },
        .{ .weight = 25, .expPos = 75 },
    };
    const layout = WeightedLayout(testStruct){
        .items = &tests,
    };
    var iter = layout.iter(100);
    while (iter.next()) |p| {
        try std.testing.expectEqual(p.item.expPos, p.pos);
    }
}
