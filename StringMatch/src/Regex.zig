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

const Token = union(enum) {
    anchor: Anchor,
    class: Class,
    posix: Posix,
    special: Special,
    char: u8,
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
};

pub fn parse(pattern: []const u8, alloc: std.mem.Allocator) !Regex {
    var reg = Regex.init(alloc);
    errdefer reg.deinit();

    var tokens = std.ArrayList(Token).init(alloc);
    defer tokens.deinit();

    var idx: usize = 0;
    outerLoop: while (idx < pattern.len) {
        for (Matches) |m| {
            if (m.match.match(pattern[idx..])) |len| {
                try tokens.append(m.token);
                idx += len;
                continue :outerLoop;
            }
        }
        try tokens.append(.{ .char = pattern[idx] });
        idx += 1;
    }

    for (tokens.items) |token| {
        std.log.info("Token:[{}]", .{token});
    }

    return reg;
}
