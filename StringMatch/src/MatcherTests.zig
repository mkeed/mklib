const std = @import("std");
const Matcher = @import("Matcher.zig");

const MatchState = Matcher.MatchState;

const Pattern = union(enum) {
    regex: []const u8,
};

const TestCase = struct {
    pattern: Pattern,
    states: []const MatchState,
    cases: []const TestString,
};

const TestString = struct { haystack: []const u8, results: []const Matcher.Match };

const Tc = [_]TestCase{
    .{
        .pattern = .{ .regex = "abcd" },
        .states = &.{
            .{ .match = .{ .string = .{ .string = &.{ 'a', 'b', 'c', 'd' } } }, .next = null },
        },
        .cases = &.{
            .{
                .haystack = "abcd abcd aaa abc ",
                .results = &.{
                    .{ .start = 0, .len = 4 },
                    .{ .start = 5, .len = 4 },
                },
            },
        },
    },
    .{
        .pattern = .{ .regex = "a{3,5}" },
        .states = &.{
            .{ .match = .{ .loop = .{ .idx = 1, .lowerBound = 3, .upperBound = 5 } }, .next = null },
            .{ .match = .{ .string = .{ .string = &.{'a'} } }, .next = null },
        },
        .cases = &.{
            .{
                .haystack = "aaa aaaa ",
                .results = &.{
                    .{ .start = 0, .len = 4 },
                    .{ .start = 5, .len = 4 },
                },
            },
        },
    },
};

test {
    const alloc = std.testing.allocator;
    for (Tc) |patternTest| {
        const match = Matcher.MatchEngine{
            .matchStates = patternTest.states,
        };
        for (patternTest.cases) |testCase| {
            var runner = try match.createRunner(alloc);
            defer runner.deinit();
            var fbs = std.io.fixedBufferStream(testCase.haystack);
            try runner.processReader(fbs.reader());
            try std.testing.expectEqual(testCase.results.len, runner.results.items.len);
            tc_loop: for (testCase.results) |expRes| {
                errdefer std.log.err("Didn't find {}", .{expRes});
                for (runner.results.items) |result| {
                    if (expRes.eql(result)) {
                        continue :tc_loop;
                    }
                }
                try std.testing.expect(false);
            }
        }
    }
}
