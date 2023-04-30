const std = @import("std");
const Matcher = @import("Matcher.zig");

const MatchState = Matcher.MatchState;

const Pattern = union(enum) {
    regex: []const u8,
};

const TestCase = struct {
    pattern: Pattern,
    states: []const MatchState,
    cases: TestString,
};

const TestString = struct { haystack: []const u8, results: []Matcher.Result };

const Tc = [_]TestCase{
    .{
        .pattern = .{ .regex = "(bat|asd|bbb)" },
        .states = &.{
            .{ .match = .{ .option = &.{ 1, 2, 3 } }, .next = null },
            .{ .match = .{ .string = "bat" }, .next = null },
            .{ .match = .{ .string = "asd" }, .next = null },
            .{ .match = .{ .string = "bbb" }, .next = null },
        },
        .cases = &.{
            .{ .haystack = "bat bat bbb asd", .results = &.{
                .{ .start = 0, .len = 3 },
                .{ .start = 4, .len = 3 },
                .{ .start = 8, .len = 3 },
                .{ .start = 12, .len = 3 },
            } },
        },
    },

    .{
        .pattern = .{ .regex = "(abcd|1234){1,3}" },
        .states = &.{
            .{
                .match = .{ .loop = .{ .min = 1, .max = 3, .state = 1 } },
                .next = null,
            },
            .{
                .match = .{ .option = &.{ 2, 3 } },
                .next = null,
            },
            .{
                .match = .{ .string = "abcd" },
                .next = null,
            },
            .{
                .match = .{ .string = "1234" },
                .next = null,
            },
        },
    },
};
