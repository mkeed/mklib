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
    pub const Info = struct {
        idx: usize,
    };
};

pub const String = struct {
    string: []const u8,
    pub const Info = struct {
        idx: usize,
    };
};

pub const Boundary = enum {
    Word,
    //pub fn match(self: Boundary, char: CodePoint) bool {}
};

pub const MatchState = struct {
    pub const MatchOption = union(enum) {
        option: []const usize,
        string: []const CodePoint,
        loop: Loop,
    };
    match: MatchOption,
    next: ?usize,
    pub fn process(
        self: MatchState,
        value: CodePoint,
        state: ?*Stack,
        run: *MatchRun,
        stateIdx: usize,
    ) !void {
        const stringIdx = run.idx;
        const list = run.next;

        switch (self.match) {
            .string => |str| {
                if (state) |s| {
                    if (s.topState()) |ts| {
                        const string_state = switch (ts.data) {
                            .string => |strState| strState,
                            else => {
                                return error.CorruptedState;
                            },
                        };

                        if (str.len >= string_state.idx) {
                            if (value == str[string_state.idx]) {
                                if (str.len == (string_state.idx + 1)) {
                                    if (s.pop()) |popState| {
                                        _ = popState;
                                        if (s.topState() != null) {
                                            try list.append(s);
                                        } else {
                                            const res = Match{ .start = ts.begin, .len = stringIdx - ts.begin + 1 };
                                            std.log.err("result :[{}]", .{res});
                                            try run.results.append(res);
                                        }
                                    }
                                } else {
                                    try s.replaceTopState(.{
                                        .stateIdx = stateIdx,
                                        .data = .{
                                            .string = .{ .idx = string_state.idx + 1 },
                                        },
                                        .begin = ts.begin,
                                    });
                                    try list.append(s);
                                }
                            }
                        } else {
                            return error.CorrupterState; // this should have already been moved to the nextState
                        }
                    } else {
                        return error.CorruptedState;
                    }
                } else {
                    if (value == str[0]) {
                        if (str.len > 1) {
                            var stack = try run.createStack();
                            try stack.append(.{
                                .stateIdx = stateIdx,
                                .data = .{
                                    .string = .{
                                        .idx = 1,
                                    },
                                },
                                .begin = stringIdx,
                            });
                            try list.append(stack);
                        } else {
                            const res = Match{ .start = stringIdx, .len = 1 };
                            std.log.err("result :[{}]", .{res});
                            try run.results.append(res);
                        }
                    }
                }
            },
            else => unreachable, //TODO
        }
    }
};

pub const Match = struct {
    start: usize,
    len: usize,
    pub fn eql(self: Match, other: Match) bool {
        return self.start == other.start and self.len == other.len;
    }
};

pub const ActiveState = struct {
    stateIdx: usize,
    data: ActiveStateData,
    begin: usize,
    pub const ActiveStateData = union(enum) {
        loop: Loop.Info,
        string: String.Info,
    };
};

pub const MatchEngine = struct {
    matchStates: []const MatchState,

    pub fn createRunner(self: MatchEngine, alloc: std.mem.Allocator) !MatchRun {
        return MatchRun.init(alloc, self);
    }
};

pub const MatchRun = struct {
    alloc: std.mem.Allocator,
    engine: MatchEngine,
    stacks: std.ArrayList(*Stack),
    list1: *std.ArrayList(*Stack),
    list2: *std.ArrayList(*Stack),
    cur: *std.ArrayList(*Stack),
    next: *std.ArrayList(*Stack),
    results: std.ArrayList(Match),
    idx: usize,
    pub fn init(alloc: std.mem.Allocator, engine: MatchEngine) !MatchRun {
        var list1 = try alloc.create(std.ArrayList(*Stack));
        errdefer alloc.destroy(list1);
        list1.* = std.ArrayList(*Stack).init(alloc);
        errdefer list1.deinit();
        var list2 = try alloc.create(std.ArrayList(*Stack));
        errdefer alloc.destroy(list2);
        list2.* = std.ArrayList(*Stack).init(alloc);
        errdefer list2.deinit();

        return MatchRun{
            .alloc = alloc,
            .engine = engine,
            .stacks = std.ArrayList(*Stack).init(alloc),
            .list1 = list1,
            .list2 = list2,
            .cur = list1,
            .next = list2,
            .results = std.ArrayList(Match).init(alloc),
            .idx = 0,
        };
    }
    pub fn deinit(self: MatchRun) void {
        for (self.stacks.items) |stack| {
            stack.deinit();
            self.alloc.destroy(stack);
        }
        self.stacks.deinit();

        self.list1.deinit();
        self.list2.deinit();

        self.alloc.destroy(self.list1);
        self.alloc.destroy(self.list2);
        self.results.deinit();
    }
    pub fn createStack(self: *MatchRun) !*Stack {
        var stack = try self.alloc.create(Stack);
        errdefer self.alloc.destroy(stack);
        stack.* = Stack.init(self.alloc);
        errdefer stack.deinit();
        try self.stacks.append(stack);
        return stack;
    }
    pub fn duplicate(self: *MatchRun, stack: *Stack) !*Stack {
        var newStack = self.alloc.create(Stack);
        errdefer self.alloc.destroy(newStack);
        newStack.* = try stack.duplicate();
        errdefer newStack.deinit();
        try self.stacks.append(stack);
        return newStack;
    }
    pub fn processReader(self: *MatchRun, reader: anytype) !void {
        while (try readerGetCodePoint(reader)) |ch| {
            try self.process(ch);
        }
    }
    pub fn process(self: *MatchRun, value: CodePoint) !void {
        defer {
            var tmp = self.cur;
            self.cur = self.next;
            self.next = tmp;
            self.idx += 1;
        }
        self.next.clearRetainingCapacity();
        try self.engine.matchStates[0].process(value, null, self, 0);

        for (self.cur.items) |cur| {
            if (cur.topState()) |ts| {
                try self.engine.matchStates[ts.stateIdx].process(value, cur, self, ts.stateIdx);
            } else {
                return error.CorruptState;
            }
        }
    }
};

const Stack = struct {
    alloc: std.mem.Allocator,
    stack: std.ArrayList(ActiveState),
    pub fn init(alloc: std.mem.Allocator) Stack {
        return .{
            .alloc = alloc,
            .stack = std.ArrayList(ActiveState).init(alloc),
        };
    }
    pub fn deinit(self: Stack) void {
        self.stack.deinit();
    }
    pub fn topState(self: Stack) ?ActiveState {
        if (self.stack.items.len == 0) return null;
        return self.stack.items[self.stack.items.len - 1];
    }
    pub fn duplciate(self: Stack) !Stack {
        var stack = Stack.init(self.alloc);
        errdefer stack.deinit();
        try stack.stack.appendSlice(self.stack.items);
        return stack;
    }
    pub fn replaceTopState(self: *Stack, state: ActiveState) !void {
        if (self.stack.items.len == 0) return error.CorruptState;
        self.stack.items[self.stack.items.len - 1] = state;
    }
    pub fn append(self: *Stack, state: ActiveState) !void {
        try self.stack.append(state);
    }
    pub fn pop(self: *Stack) ?ActiveState {
        return self.stack.popOrNull();
    }
};

const CodePointInfo = struct {
    len: u8,
    cp: CodePoint,
    pub fn fromSlice(data: []const u8) !CodePointInfo {
        const seq_len = try std.unicode.utf8CodepointSequenceLength(data[0]);
        const cp = try std.unicode.utf8Decode(data[0..seq_len]);
        return CodePointInfo{
            .len = seq_len,
            .cp = cp,
        };
    }
};

fn readerGetCodePoint(reader: anytype) !?CodePoint {
    var first_byte = [1]u8{0};
    const len = try reader.read(&first_byte);
    if (len == 0) return null;
    const seq_len = try std.unicode.utf8CodepointSequenceLength(first_byte[0]);
    var other_bytes = [4]u8{ first_byte[0], 0, 0, 0 };
    if (seq_len > 1) {
        const read_len = try reader.readAll(other_bytes[1..seq_len]);
        if (read_len != seq_len - 1) {
            return null;
        }
    }
    return try std.unicode.utf8Decode(other_bytes[0..seq_len]);
}
