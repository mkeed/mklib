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
    implemented: bool = true,
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
        .pattern = .{ .regex = "(abcd)(1234)" },
        .states = &.{
            .{ .match = .{ .string = .{ .string = &.{ 'a', 'b', 'c', 'd' } } }, .next = 1 },
            .{ .match = .{ .string = .{ .string = &.{ '1', '2', '3', '4' } } }, .next = null },
        },
        .cases = &.{
            .{
                .haystack = "abcd1234 abcd124 abcd1234",
                .results = &.{
                    .{ .start = 0, .len = 8 },
                    .{ .start = 17, .len = 8 },
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
        .implemented = false,
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
            runner.processReader(fbs.reader()) catch |err| {
                switch (err) {
                    error.NotImplementedYet => {
                        if (patternTest.implemented == false) continue else return err;
                    },
                    else => {
                        return err;
                    },
                }
            };
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
