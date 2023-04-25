const App = @import("../App.zig");

pub const InputMap = struct {
    input: App.InputEvent,
    command: App.Command,
};

pub const inputs = [_]InputMap{
    .{ .input = .{ .keyboard = .{ .keyCode = .Up } }, .command = .{ .movement = .{ .Line = -1 } } },
    .{ .input = .{ .keyboard = .{ .keyCode = .Down } }, .command = .{ .movement = .{ .Line = 1 } } },
    .{ .input = .{ .keyboard = .{ .keyCode = .Left } }, .command = .{ .movement = .{ .Char = -1 } } },
    .{ .input = .{ .keyboard = .{ .keyCode = .Right } }, .command = .{ .movement = .{ .Char = 1 } } },
    .{ .input = .{ .keyboard = .{ .alt = true, .keyCode = .Left } }, .command = .{ .movement = .{ .Word = -1 } } },
    .{ .input = .{ .keyboard = .{ .alt = true, .keyCode = .Right } }, .command = .{ .movement = .{ .Word = 1 } } },
};
