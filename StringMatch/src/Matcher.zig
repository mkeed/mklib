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
    lowerBound: ?usize,
    upperBound: ?usize,
    pub const Info = struct {
        idx: usize,
    };
};

pub const String = struct {
    string: []const CodePoint,
    pub const Info = struct {
        idx: usize,
    };
    pub const StringMatch = enum {
        NotMatch,
        Match,
        EndOfString,
    };
    pub fn match(self: String, idx: usize, value: CodePoint) !StringMatch {
        if (self.string.len < idx) return error.CorruptData;
        if (self.string[idx] == value) {
            if (self.string.len == idx + 1) {
                return .EndOfString;
            } else {
                return .Match;
            }
        } else {
            return .NotMatch;
        }
    }
};

pub const Boundary = enum {
    Word,
    //pub fn match(self: Boundary, char: CodePoint) bool {}
};

pub const MatchState = struct {
    pub const MatchOption = union(enum) {
        option: []const usize,
        string: String,
        loop: Loop,
    };
    pub const Result = enum {
        Success,
        NoMatch,
    };
    match: MatchOption,
    next: ?usize,
    pub fn process(
        self: MatchState,
        value: CodePoint,
        state: *Stack,
        run: *MatchRun,
        stateIdx: usize,
    ) !Result {}
    pub fn initBeginState(self: MatchState, stateIdx: usize, begin: usize) ActiveState {
        return .{
            .stateIdx = stateIdx,
            .data = switch (self.match) {
                .option => .option,
                .string => .{ .string = .{ .idx = 0 } },
                .loop => .{ .loop = .{ .idx = 0 } },
            },
            .begin = begin,
        };
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
        option: void,
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
        var stacks = std.ArrayList(*Stack).init(alloc);
        errdefer stacks.deinit();
        return MatchRun{
            .alloc = alloc,
            .engine = engine,
            .stacks = stacks,
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
        std.log.err("Process: [{c}]", .{cpfmt(value)});
        try self.nextState.push(self.engine.matchStates[0].initBeginState(0, self.idx));
        if (try self.engine.matchStates[0].process(value, self.nextState, self, 0) == .Success) {
            self.nextState = try self.createStack();
        }

        for (self.cur.items) |cur| {
            if (cur.topState()) |ts| {
                try self.engine.matchStates[ts.stateIdx].process(value, cur, self, ts.stateIdx);
            } else {
                return error.CorruptState;
            }
        }
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
    pub fn cleanupStack(self: *MatchRun, stack: *Stack) void {
        for (self.stacks.items, 0..) |s, idx| {
            if (s == stack) {
                _ = self.stacks.swapRemove(idx);
                break;
            }
        }
        stack.deinit();
        self.alloc.destroy(stack);
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
    pub fn push(self: *Stack, state: ActiveState) !void {}
};
