const std = @import("std");
const CodePoint = u21;

pub const Class = enum {
    Word,
    NotWord,
    WordBoundary,
    NotWordBoundary,
};

const StateId = usize;

pub const Range = struct {
    // An inclusive range
    lower: CodePoint,
    upper: CodePoint,
    pub fn match(self: Range, char: CodePoint) bool {
        return char >= self.lower and char <= self.upper;
    }
};

pub const List = struct {
    data: [10]CodePoint,
    len: u8,
    pub fn match(self: List, char: CodePoint) bool {
        for (self.data[0..self.len]) |cp| {
            if (char == cp) return true;
        }
        return false;
    }
};

pub const Loop = struct {
    idx: StateId,
    upperBound: ?usize,
    lowerBound: ?usize,
};

pub const Boundary = enum {
    Word,
    pub fn match(self: Boundary, char: CodePoint) bool {}
};

pub const MatchState = struct {
    //
};

pub const Match = struct {
    start: usize,
    len: usize,
};

pub const MatchEngine = struct {
    matchStates: []const MatchState,

    pub fn find(self: Match, reader: anytype, alloc: std.mem.Allocator) std.ArrayList(Match) {
        var stack_1 = std.ArrayList(ActiveState).init(alloc);
        defer stack_1.deinit();

        var stack_2 = std.ArrayList(ActiveState).init(alloc);
        defer stack_2.deinit();

        var cur = &stack_1;
        var next = &stack_2;

        var matches = std.ArrayList(Match).init(alloc);
        errdefer matches.deinit();

        while (try readerGetCodePoint(reader)) |codePoint| {
            defer {
                var tmp = cur;
                cur = next;
                next = tmp;
            }
            next.clearRetainingCapacity();
            if (self.matchStates[0].match(codePoint, &matches)) |state| {
                try next.append(state);
            }
            for (cur.items) |item| {
                if (item.match(codePoint, &matches)) |state| {
                    try next.append(state);
                }
            }
        }
    }
};

fn readerGetCodePoint(reader: anytype) !?CodePoint {
    var first_byte = [1]u8{0};
    const len = try reader.read(&first_byte);
    if (len == 0) return null;
    const seq_len = try std.unicode.utf8SequenceLength(first_byte[0]);
    var other_bytes = [4]u8{ first_byte[0], 0, 0, 0 };
    if (seqlen > 1) {
        const read_len = try reader.readAll(other_bytes[1..seq_len]);
        if (read_len != sel_len - 1) {
            return null;
        }
    }
    return try std.unicode.utf8Decode(other_bytes[0..seq_len]);
}
