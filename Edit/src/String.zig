const std = @import("std");
pub const String = struct {
    text: []const u8,
    pub fn len(self: String) usize {
        return self.text.len;
        //TODO make this work with utf-8
    }
};

pub const CodePoint = u21;
pub const CodePointFormatter = struct {
    cp: CodePoint,
    pub fn format(
        value: CodePointFormatter,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        var buf: [4]u8 = undefined;
        const len = std.unicode.utf8Encode(value.cp, &buf) catch
            std.unicode.utf8Encode(std.unicode.replacement_character, &buf) catch unreachable;

        try std.fmt.format(writer, "{s}", .{buf[0..len]});
    }
};
pub fn CPFmt(cp: CodePoint) CodePointFormatter {
    return .{
        .cp = cp,
    };
}
