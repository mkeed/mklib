const std = @import("std");
const Regex = @import("Regex.zig");
const Token = Regex.Token;

const TestCase = struct {
    pattern: []const u8,
    tokens: []const Token,
};

const Tc = [_]TestCase{
    .{ .pattern = "\\b!\\b", .tokens = &.{ .{ .anchor = .WordBoundary }, .{ .char = '!' }, .{ .anchor = .WordBoundary } } },
    .{ .pattern = "(==|(?:!|>|<)=?)", .tokens = &.{
        .{ .control = .GroupStart },
        .{ .char = '=' },
        .{ .char = '=' },
        .{ .control = .GroupOr },
        .{ .control = .PassiveGroupStart },
        .{ .char = '!' },
        .{ .control = .GroupOr },
        .{ .char = '>' },
        .{ .control = .GroupOr },
        .{ .char = '<' },
        .{ .control = .GroupEnd },
        .{ .char = '=' },
        .{ .quantifier = .ZeroOrOne },
        .{ .control = .GroupEnd },
    } },
    .{ .pattern = "((?:(?:\\+|-|\\*)\\%?|/|%|<<|>>|&|\\|(?=[^\\|])|\\^)?=)", .tokens = &.{
        .{ .control = .GroupStart },
        .{ .control = .PassiveGroupStart },
        .{ .control = .PassiveGroupStart },
        .{ .char = '+' },
        .{ .control = .GroupOr },
        .{ .char = '-' },
        .{ .control = .GroupOr },
        .{ .char = '*' },
        .{ .control = .GroupEnd },
        .{ .char = '%' },
        .{ .quantifier = .ZeroOrOne },
        .{ .control = .GroupOr },
        .{ .char = '/' },
        .{ .control = .GroupOr },
        .{ .char = '%' },
        .{ .control = .GroupOr },
        .{ .char = '<' },
        .{ .char = '<' },
        .{ .control = .GroupOr },
        .{ .char = '>' },
        .{ .char = '>' },
        .{ .control = .GroupOr },
        .{ .char = '&' },
        .{ .control = .GroupOr },
        .{ .char = '|' },
        .{ .look = .PositiveLookAhead },
        .{ .control = .RangeNotStart },
        .{ .char = '|' },
        .{ .control = .RangeEnd },
        .{ .control = .GroupEnd },
        .{ .control = .GroupOr },
        .{ .char = '^' },
        .{ .control = .GroupEnd },
        .{ .quantifier = .ZeroOrOne },
        .{ .char = '=' },
        .{ .control = .GroupEnd },
    } },
};

test {
    const alloc = std.testing.allocator;
    for (Tc) |test_item| {
        var tokens = try Regex.tokenize(test_item.pattern, alloc);
        defer tokens.deinit();
        try std.testing.expectEqual(tokens.items.len, test_item.tokens.len);
        for (tokens.items, 0..) |t, idx| {
            errdefer {
                std.log.err("At idx[{}] Expected [{}] found [{}]", .{ idx, test_item.tokens[idx], t.token });
            }
            try std.testing.expectEqual(test_item.tokens[idx], t.token);
        }
    }
}
