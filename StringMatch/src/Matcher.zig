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
    pub const MatchOption = union(enum) {
        option: []const usize,
        string: []const u8,
        loop: Loop,
    };
    match: MatchOption,
    next: ?usize,
    pub fn match(self: MatchState, value: CodePoint, state: ?ActiveState, list: *std.ArrayList, run: *MatchRun) !void {
        switch (self.match) {
            .option => |opt| {},
        }
    }
};

pub const Match = struct {
    start: usize,
    len: usize,
};

pub const ActiveState = struct {
    idx: usize,
    data: ActiveStateData,
    pub const ActiveStateData = union(enum) {
        loop: Loop.Info,
        string: String.Info,
    };
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

pub const MatchRun = struct {
    alloc: std.mem.Allocator,
    engine: MatchEngine,
    stacks: std.ArrayList(*Stack),
    list1: *std.ArrayList(*Stack),
    list2: *std.ArrayList(*Stack),
    cur: *std.ArrayList(*Stack),
    next: *std.ArrayList(*Stack),
    results: std.ArrayList(MatchState),
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
            .stacks = std.ArrayList(*Stack),
            .list1 = list1,
            .list2 = list2,
            .cur = list1,
            .next = list2,
            .idx = 0,
        };
    }
    pub fn newStack(self: MatchRun) !*Stack {
        var stack = try alloc.create(Stack);
        errdefer self.alloc.destroy(stack);
        stack.* = Stack.init(alloc);
        errdefer stack.deinit();
        try self.stacks.append(stack);
        return stack;
    }
    pub fn duplicate(self: MatchRun, stack: *Stack) !*Stack {
        var newStack = self.alloc.create(Stack);
        errdefer self.alloc.destroy(newStack);
        newStack.* = try stack.duplicate();
        errdefer newStack.deinit();
        try self.stacks.append(stack);
        return newStack;
    }
    pub fn process(self: *MatcRun, value: CodePoint) !void {
        defer {
            var tmp = self.cur;
            self.cur = self.next;
            self.next = tmp;
        }
        self.next.clearRetainingCapacity();
        try self.engine.matchStates[0].match(value, null, self.next, &self);

        for (self.cur.items) |cur| {
            //try cur.match(value,
        }
    }
    pub fn deinit(self: MatchRun) void {
        for (self.stacks) |stack| {
            stack.deinit();
            self.alloc.destroy(stack);
        }
        self.stacks.deinit();

        self.list1.deinit();
        self.list2.deinit();

        self.alloc.destroy(self.list1);
        self.alloc.destroy(self.list2);
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
    pub fn duplciate(self: Stack) !Stack {
        var stack = Stack.init(self.alloc);
        errdefer stack.deinit();
        try stack.stack.appendSlice(self.stack.items);
        return stack;
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

const ActiveState = struct {
    prev: ?*ActiveState,
    children: usize,
};
