const std = @import("std");

pub const Regex = struct {
    alloc: std.mem.Allocator,
    pub fn init(alloc: std.mem.Allocator) Regex {
        return .{
            .alloc = alloc,
        };
    }
    pub fn deinit(self: Regex) void {
        _ = self;
    }
};

const Class = enum { Control, WhiteSpace, NotWhiteSpace, Digit, NotDigit, Word, NotWord, Hexadecimal, Octal };

const Anchor = enum { StartLine, StartString, EndLine, EndString, WordBoundary, NotWordBoundary, StartOfWord, EndOfWord };

const Posix = enum { Upper, Lower, Alpha, Alnum, Digit, XDigit, Punct, Blank, Space, Cntrl, Graph, Print, Word };

const Special = enum { NewLine, CarriageReturn, Tab, VerticalTab, FormFeed };

const Control = enum { GroupStart, PassiveGroupStart, GroupEnd, GroupOr, RangeStart, RangeEnd, RangeNotStart };

const Quantifier = enum { ZeroOrMore, OneOrMore, ZeroOrOne };

const Look = enum { PositiveLookAhead, NegativeLookAhead, PositiveLookBehind, NegativeLookBehind };

const Token = union(enum) {
    anchor: Anchor,
    class: Class,
    posix: Posix,
    special: Special,
    control: Control,
    quantifier: Quantifier,
    look: Look,
    char: u8,
    escape: u8,
    pub fn format(self: Token, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            .anchor => |a| {
                try std.fmt.format(writer, "Anchor:{}", .{a});
            },
            .class => |a| {
                try std.fmt.format(writer, "Class:{}", .{a});
            },
            .posix => |a| {
                try std.fmt.format(writer, "Posix:{}", .{a});
            },
            .special => |a| {
                try std.fmt.format(writer, "Special:{}", .{a});
            },
            .char, .escape => |a| {
                try std.fmt.format(writer, "Char:{c}", .{a});
            },
            .look => |a| {
                try std.fmt.format(writer, "Look:{}", .{a});
            },
            .control => |a| {
                try std.fmt.format(writer, "Control:{}", .{a});
            },
            .quantifier => |a| {
                try std.fmt.format(writer, "Quantifier:{}", .{a});
            },
        }
    }
};

const TokenInfo = struct {
    token: Token,
    val: []const u8,
};

const Matcher = union(enum) {
    static: []const u8,

    pub fn match(self: Matcher, text: []const u8) ?usize {
        switch (self) {
            .static => |s| {
                if (text.len >= s.len) {
                    if (std.mem.eql(u8, text[0..s.len], s)) return s.len;
                }
                return null;
            },
        }
    }
};

const TokenMatch = struct {
    match: Matcher,
    token: Token,
};
fn strMatch(str: []const u8, token: Token) TokenMatch {
    return .{
        .match = .{ .static = str },
        .token = token,
    };
}
const Matches = [_]TokenMatch{
    strMatch("^", .{ .anchor = .StartLine }),
    strMatch("\\A", .{ .anchor = .StartString }),
    strMatch("$", .{ .anchor = .EndLine }),
    strMatch("\\Z", .{ .anchor = .EndString }),
    strMatch("\\b", .{ .anchor = .WordBoundary }),
    strMatch("\\B", .{ .anchor = .NotWordBoundary }),
    strMatch("\\<", .{ .anchor = .StartOfWord }),
    strMatch("\\>", .{ .anchor = .EndOfWord }),

    strMatch("\\c", .{ .class = .Control }),
    strMatch("\\s", .{ .class = .WhiteSpace }),
    strMatch("\\S", .{ .class = .NotWhiteSpace }),
    strMatch("\\d", .{ .class = .Digit }),
    strMatch("\\D", .{ .class = .NotDigit }),
    strMatch("\\w", .{ .class = .Word }),
    strMatch("\\W", .{ .class = .NotWord }),
    strMatch("\\x", .{ .class = .Hexadecimal }),
    strMatch("\\O", .{ .class = .Octal }),

    strMatch("[:upper:]", .{ .posix = .Upper }),
    strMatch("[:lower:]", .{ .posix = .Lower }),
    strMatch("[:alpha:]", .{ .posix = .Alpha }),
    strMatch("[:alnum:]", .{ .posix = .Alnum }),
    strMatch("[:digit:]", .{ .posix = .Digit }),
    strMatch("[:xdigit:]", .{ .posix = .XDigit }),
    strMatch("[:punct:]", .{ .posix = .Punct }),
    strMatch("[:blank:]", .{ .posix = .Blank }),
    strMatch("[:space:]", .{ .posix = .Space }),
    strMatch("[:cntrl:]", .{ .posix = .Cntrl }),
    strMatch("[:graph:]", .{ .posix = .Graph }),
    strMatch("[:print:]", .{ .posix = .Print }),
    strMatch("[:word:]", .{ .posix = .Word }),

    strMatch("\\n", .{ .special = .NewLine }),
    strMatch("\\r", .{ .special = .CarriageReturn }),
    strMatch("\\t", .{ .special = .Tab }),
    strMatch("\\v", .{ .special = .VerticalTab }),
    strMatch("\\f", .{ .special = .FormFeed }),
    strMatch("(", .{ .control = .GroupStart }),
    strMatch("(?:", .{ .control = .PassiveGroupStart }),
    strMatch(")", .{ .control = .GroupEnd }),
    strMatch("|", .{ .control = .GroupOr }),

    strMatch("[", .{ .control = .RangeStart }),
    strMatch("]", .{ .control = .RangeEnd }),
    strMatch("[^", .{ .control = .RangeNotStart }),

    strMatch("*", .{ .quantifier = .ZeroOrMore }),
    strMatch("+", .{ .quantifier = .OneOrMore }),
    strMatch("?", .{ .quantifier = .ZeroOrOne }),

    strMatch("(?=", .{ .look = .PositiveLookAhead }),
    strMatch("(?!", .{ .look = .NegativeLookAhead }),
    strMatch("(?<=", .{ .look = .PositiveLookBehind }),
    strMatch("(?<!", .{ .look = .NegativeLookBehind }),
};

pub fn parse(pattern: []const u8, alloc: std.mem.Allocator) !Regex {
    var reg = Regex.init(alloc);
    errdefer reg.deinit();

    var tokens = std.ArrayList(TokenInfo).init(alloc);
    defer tokens.deinit();

    var idx: usize = 0;
    while (idx < pattern.len) {
        var maxLen: usize = 0;
        var token: ?Token = null;
        for (Matches) |m| {
            if (m.match.match(pattern[idx..])) |len| {
                if (len > maxLen) {
                    maxLen = len;
                    token = m.token;
                }
            }
        }
        if (token) |t| {
            try tokens.append(.{ .token = t, .val = pattern[idx..][0..maxLen] });
            idx += maxLen;
        } else {
            if (pattern[idx] == '\\') {
                try tokens.append(.{ .token = .{ .char = pattern[idx + 1] }, .val = pattern[idx..][0..2] });
                idx += 2;
            } else {
                try tokens.append(.{ .token = .{ .char = pattern[idx] }, .val = pattern[idx..][0..1] });
                idx += 1;
            }
        }
    }

    for (tokens.items) |token| {
        std.log.info("Token:[{}]:[{s}]", .{ token.token, token.val });
    }

    return reg;
}
