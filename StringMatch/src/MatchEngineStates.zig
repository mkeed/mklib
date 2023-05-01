const std = @import("std");
const me = @import("MatchEngine.zig");

pub const CodePoint = u21;
pub const StateID = usize;
pub const MatchState = struct {
    pub const MatchOption = union(enum) {
        loop: Loop,
        string: String,
        option: Option,
        range: Range,
    };
    match: MatchOption,
    next: ?StateID,

    pub fn match(
        self: MatchState,
        value: CodePoint,
        active_state: *me.ActiveState,
        states: []const MatchState,
    ) !?Result {
        const info = active_state.info;
        const result = switch (self) {
            .string => |s| s.match(value, info),
            .range => |r| r.match(value, info),
            .loop => |l| l.match(value, info, states),
        };
    }
};

pub const MatchInfo = struct {
    start: usize,
    info: Info,
    pub const Info = union(enum) {
        string: String.Info,
        range: void,
        loop: Loop.Info,
        option: void,
    };
};

pub const MatchResult = union(enum) {
    NoMatch: void,
    Match: MatchInfo,
    End: void,
};

pub const Loop = struct {
    state: StateID,
    lower: ?usize,
    upper: ?usize,
};

pub const String = struct {
    string: []const CodePoint,
    pub const Info = struct { idx: usize };
    pub fn match(self: String, value: CodePoint, match_info: MatchInfo) !MatchResult {
        const info = switch (match_info.info) {
            .string => |s| s,
            else => return error.CorruptData,
        };
        if (self.string.len <= info.idx) return error.CorruptData;
        if (value == self.string[info.idx]) {
            if (info.idx + 1 == self.string.len) {
                return MatchResult.End;
            } else {
                return MatchResult{ .Match = .{
                    .start = .match_info.start,
                    .info = .{ .string = .{ .idx = info.idx + 1 } },
                } };
            }
        } else {
            return MatchResult.NoMatch;
        }
    }
};

pub const Range = struct {
    lower: CodePoint,
    upper: CodePoint,
    pub fn match(self: Range, value: CodePoint, match_info: MatchInfo) !MatchResult {
        if (value >= self.lower and value <= self.upper) {
            return MatchResult{
                .Match = .range,
            };
        }
        return MatchResult.NoMatch;
    }
};

pub const Option = struct {
    opt: []const StateID,
};
