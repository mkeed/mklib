const std = @import("std");

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

pub const String = struct {
    data: std.ArrayList(u8),
    pub fn alloc(allocator: std.mem.Allocator) String {
        return String{
            .data = std.ArrayList(u8).init(allocator),
        };
    }
    pub fn append(self: *String, data: []const u8) !void {
        try self.data.appendSlice(data);
    }

    pub fn clone(self: String) !String {
        return String{
            .data = try self.data.clone(),
        };
    }

    pub fn codePointIter(self: String) CodePointIter {
        return CodePointIter{
            .data = self.data.items,
            .idx = 0,
        };
    }
    pub const CodePointIter = struct {
        data: []const u8,
        idx: usize,
        pub fn next(self: *CodePointIter) ?CodePoint {
            if (self.idx >= self.data.len) return null;
            const len = std.unicode.utf8ByteSequenceLength(self.data[self.idx]) catch {
                self.idx += 1;
                return std.unicode.replacement_character;
            };

            defer self.idx += len;

            if (self.idx + len >= self.data.len) return null;

            const cp = std.unicode.utf8Decode(self.data[self.idx..][0..len]) catch {
                return std.unicode.replacement_character;
            };
            return cp;
        }
    };
};
