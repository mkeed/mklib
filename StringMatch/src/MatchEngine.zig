const std = @import("std");
pub const States = @import("MatchEngineStates.zig");
pub const StateID = States.StateID;
pub const MatchEngine = struct {
    states: []const States.MatchState,
    startStates: []const StateID,
};

pub fn match(engine: MatchEngine, options: MatchOptions, alloc: std.mem.Allocator, reader: anytype) !std.ArrayList(Result) {
    var stateList1 = std.ArrayList(State).init(alloc);
    defer stateList1.deinit();
    var stateList2 = std.ArrayList(State).init(alloc);
    defer stateList2.deinit();

    var cur = &stateList1;
    var next = &stateList2;

    while (try readerGetCodePoint(reader)) |value| {
        for (engine.startStates) |idx| {
            if (idx > engine.states.len) return error.InvalidSetup;
            const state = engine.states[idx];
            if (state.match(value)) {
                //
            }
        }
    }
}

pub const ActiveState = struct {
    parent: *ActiveState,
    children: std.ArrayList(*ActiveState),
    info: MatchInfo,
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

fn cpfmt(value: CodePoint) std.fmt.Formatter(fmtCodePoint) {
    return .{
        .data = value,
    };
}

fn fmtCodePoint(value: CodePoint, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = options;
    _ = fmt;
    var buf: [4]u8 = undefined;
    var len = std.unicode.utf8Encode(value, buf[0..]) catch 0;
    if (len == 0) {
        buf[0] = 0xFF;
        buf[1] = 0xFD;
        len = 2;
    }
    try std.fmt.format(writer, "{s}", .{buf[0..len]});
}
