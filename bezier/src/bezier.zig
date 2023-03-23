const std = @import("std");
pub const Point = struct {
    x: isize,
    y: isize,
};

const LerpTest = struct {
    start: Point,
    end: Point,
    expectedPoints: []const Point,
};

fn pt(x: isize, y: isize) Point {
    return Point{ .x = x, .y = y };
}
test "lerp test" {
    const tests = [_]LerpTest{
        .{
            .start = .{ .x = 0, .y = 0 },
            .end = .{ .x = 10, .y = 10 },
            .expectedPoints = &.{
                pt(0, 0),
                pt(1, 1),
                pt(2, 2),
                pt(3, 3),
                pt(4, 4),
                pt(5, 5),
                pt(6, 6),
                pt(7, 7),
                pt(8, 8),
                pt(9, 9),
                pt(10, 10),
            },
        },
    };
    for (tests) |t| {
        for (t.expectedPoints, 0..) |ep, i| {
            const val = lerp(t.start, t.end, @intCast(isize, t.expectedPoints.len), @intCast(isize, i));
            try std.testing.expectEqual(val, ep);
        }
    }
}

pub fn lerp(start: Point, end: Point, steps: isize, current: isize) Point {
    const x = start.x + @divTrunc((end.x - start.x) * current, (steps - 1));
    const y = start.y + @divTrunc((end.y - start.y) * current, (steps - 1));
    return Point{
        .x = x,
        .y = y,
    };
}

pub fn quadratic(start: Point, control: Point, end: Point, points: []Point) void {
    for (points, 0..) |*p, idx| {
        const p1 = lerp(start, control, @intCast(isize, points.len), @intCast(isize, idx));
        const p2 = lerp(control, end, @intCast(isize, points.len), @intCast(isize, idx));
        p.* = lerp(p1, p2, @intCast(isize, points.len), @intCast(isize, idx));
    }
}

pub fn cubic(start: Point, control1: Point, control2: Point, end: Point, points: []Point) void {
    for (points, 0..) |*p, idx| {
        const p1 = lerp(start, control1, @intCast(isize, points.len), @intCast(isize, idx));
        const p2 = lerp(control2, end, @intCast(isize, points.len), @intCast(isize, idx));
        p.* = lerp(p1, p2, @intCast(isize, points.len), @intCast(isize, idx));
    }
}

test "bezier" {
    const start = Point{ .x = 0, .y = 0 };
    const end = Point{ .x = 100, .y = 100 };
    const control1 = Point{ .x = 0, .y = 100 };
    const control2 = Point{ .x = 50, .y = 50 };

    var points: [10]Point = undefined;
    quadratic(start, control1, end, &points);
    for (points) |p| std.log.err("{}", .{p});
    cubic(start, control1, control2, end, &points);
    for (points) |p| std.log.err("{}", .{p});
}
