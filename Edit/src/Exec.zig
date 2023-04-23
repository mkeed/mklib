const std = @import("std");
const String = @import("String.zig").String;

pub const ExecContext = struct {};

pub const Shell = struct {
    command: String,
    pub fn init(command: String) !Shell {
        return Shell{
            .command = try command.clone(),
        };
    }
    pub fn exec(self: Shell) ExecContext {}
};
