const App = @import("../App.zig");

pub const InputMap = struct {
    input: App.InputEvent,
    command: App.Command,
};

pub const inputs = [_]InputMap{
    .{ .input = .{ .keyboard = .{ .key = .Up } }, .command = .{ .movement = .{ .Line = -1 } } },
    .{ .input = .{ .keyboard = .{ .key = .Down } }, .command = .{ .movement = .{ .Line = 1 } } },
    .{ .input = .{ .keyboard = .{ .key = .Left } }, .command = .{ .movement = .{ .Char = -1 } } },
    .{ .input = .{ .keyboard = .{ .key = .Right } }, .command = .{ .movement = .{ .Char = 1 } } },
    .{ .input = .{ .keyboard = .{ .alt = true, .key = .Left } }, .command = .{ .movement = .{ .Word = -1 } } },
    .{ .input = .{ .keyboard = .{ .alt = true, .key = .Right } }, .command = .{ .movement = .{ .Word = 1 } } },
};
