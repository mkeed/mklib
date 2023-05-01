const std = @import("std");

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

    pub fn match(self: MatchState, value: CodePoint, info: MatchInfo) !?Result {
        return switch (self) {
            inline else => |val| val.match(value),
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
};

pub const Loop = struct {
    state: StateID,
    lower: ?usize,
    upper: ?usize,
};

pub const String = struct {
    string: []const CodePoint,
    pub const Info = struct { idx: usize };
    pub fn match(self: String, value: CodePoint, info: Info) ?MatchResult {}
};

pub const Range = struct {
    lower: CodePoint,
    upper: CodePoint,
};

pub const Option = struct {
    opt: []const StateID,
};
