const std = @import("std");

pub const ArgInfo = struct {
    longName: []const u8,
    short: ?u8 = null,
    docs: []const u8,

    fieldName: []const u8,
    pub const ArgType = enum {
        Flag,
        List,
        Value,
    };
    pub fn match(self: ArgInfo, arg: []const u8) bool {
        if (arg.len == 2) {
            if (self.short) |short| {
                if (arg[0] == '-' and arg[1] == short) return true;
            }
        } else if (arg.len > 2) {
            if (arg[0] == '-' and arg[1] == '-' and std.mem.eql(u8, arg[2..], self.longName)) return true;
        }
        return false;
    }
    pub fn argType(comptime self: ArgInfo, comptime T: type) ArgType {
        const tinfo = @typeInfo(T).Struct;
        inline for (tinfo.fields) |field| {
            if (std.mem.eql(u8, field.name, self.fieldName)) {
                if (field.type == std.ArrayList(std.ArrayList(u8))) {
                    return .List;
                }
                switch (@typeInfo(field.type)) {
                    .Bool => {
                        return .Flag;
                    },
                    .Int => {
                        return .Value;
                    },
                    else => @compileError("Invalid Type"),
                }
            }
        }
        return .Flag;
    }
};

pub const ProcInfo = struct {
    args: []const ArgInfo,
    defaultList: []const u8,
    docs: []const u8,
    nextArgs: ?[]const u8 = null,
};

pub fn printHelp(comptime T: type, comptime info: ProcInfo) !void {
    _ = T;
    _ = info;
}

pub fn parseArgs(comptime T: type, alloc: std.mem.Allocator, comptime info: ProcInfo) !?T {
    return parseArgsImpl(T, alloc, info, BetterArgIter);
}

pub fn parseArgsImpl(
    comptime T: type,
    alloc: std.mem.Allocator,
    comptime info: ProcInfo,
    comptime IterImpl: type,
) !?T {
    var args = try IterImpl.init(alloc);
    defer args.deinit();

    var result = T.init(alloc);
    errdefer result.deinit();
    _ = args.next();
    var curList = &@field(result, info.defaultList);
    argLoop: while (args.next()) |arg| {
        if (std.mem.eql(u8, "-h", arg) or std.mem.eql(u8, arg, "--help")) {
            printHelp(T, info);
            result.deinit();
            return null;
        }
        if (info.hasNextArgs) |nextFieldName| {
            if (std.mem.eql(u8, "--", arg)) {
                while (args.next()) |nextArgs| {
                    var newString = std.ArrayList(u8).init(alloc);
                    errdefer newString.deinit();
                    try newString.appendSlice(nextArgs);
                    try @field(result, nextFieldName).append(newString);
                }
            }
        }
        inline for (info.args) |i| {
            if (i.match(arg)) {
                const at = comptime i.argType(T);
                comptime if (at == .List) {
                    curList = &@field(result, i.fieldName);
                };
                comptime if (at == .Flag) {
                    @field(result, i.fieldName) = true;
                };
                comptime if (at == .Value) {};

                continue :argLoop;
            }
        }
        {
            var newString = std.ArrayList(u8).init(alloc);
            errdefer newString.deinit();
            try newString.appendSlice(arg);
            try curList.append(newString);
        }
    }

    return result;
}

const TestStruct = struct {
    pub fn init(alloc: std.mem.Allocator) TestStruct {
        return .{
            .alloc = alloc,
            .testField = 1234,
            .otherField = false,
            .exampleList = std.ArrayList(std.ArrayList(u8)).init(alloc),
        };
    }
    pub fn deinit(self: TestStruct) void {
        for (self.exampleList.items) |item| {
            item.deinit();
        }
        self.exampleList.deinit();
    }
    alloc: std.mem.Allocator,
    testField: u32,
    otherField: bool,
    exampleList: std.ArrayList(std.ArrayList(u8)),
};

test {
    const alloc = std.testing.allocator;
    const args = ProcInfo{
        .args = &.{
            .{
                .longName = "test",
                .short = 't',
                .docs = "test",
                .fieldName = "testField",
            },
            .{
                .longName = "field",
                .short = 'f',
                .docs = "test",
                .fieldName = "otherField",
            },
        },
        .defaultList = "exampleList",
        .docs = "example",
    };

    var v = try parseArgs(TestStruct, alloc, args);
    defer v.deinit();
}

pub const BetterArgIter = struct {
    args: std.process.ArgIterator,
    cur: ?[]const u8 = null,
    curIdx: usize = 0,
    buf: [2]u8 = [2]u8{ 0, 0 },
    pub fn init(alloc: std.mem.Allocator) !BetterArgIter {
        var args = try std.process.argsWithAllocator(alloc);
        return BetterArgIter{
            .args = args,
        };
    }
    pub fn next(self: *BetterArgIter) ?[]const u8 {
        if (self.cur) |c| {
            if (self.curIdx < c.len) {
                self.buf[0] = '-';
                self.buf[1] = c[self.curIdx];
                self.curIdx += 1;
                return self.buf[0..];
            } else {
                self.cur = null;
            }
        }
        const result = self.args.next();
        if (result) |res| {
            if (res.len >= 1 and res[0] == '-') {
                if (res.len >= 2 and res[1] != '-') {
                    self.curIdx = 2;
                    self.cur = res;
                    self.buf[0] = '-';
                    self.buf[1] = res[2];
                    return self.buf[0..];
                }
            }
            return res;
        } else {
            return null;
        }
    }
    pub fn skip(self: *BetterArgIter) ?[:0]bool {
        return self.next() != null;
    }
    pub fn deinit(self: *BetterArgIter) void {
        defer self.args.deinit();
    }
};
