const std = @import("std");

pub const DataReader = struct {
    data: []const u8,
    idx: usize,
    byteOrder: std.builtin.Endian,

    pub fn init(data: []const u8, endian: std.builtin.Endian) DataReader {
        return .{
            .data = data,
            .idx = 0,
            .byteOrder = endian,
        };
    }

    pub fn read(self: *DataReader, comptime T: type) !T {
        if (self.idx + @sizeOf(T) > self.data.len) {
            return error.TooLong;
        }
        defer self.idx += @sizeOf(T);
        return std.mem.readIntSlice(T, self.data[self.idx..], self.byteOrder);
    }
    pub fn readArray(self: *DataReader, comptime len: usize) ![len]u8 {
        if (self.idx + len > self.data.len) {
            return error.TooLong;
        }
        defer self.idx += len;
        var result = [1]u8{0} ** len;
        for (result[0..], 0..) |*val, i| val.* = self.data[self.idx + i];
        return result;
    }

    pub fn readSlice(self: *DataReader, len: usize) ![]const u8 {
        if (self.idx + len > self.data.len) {
            return error.TooLong;
        }
        defer self.idx += len;
        return self.data[self.idx .. self.idx + len];
    }
    pub fn readReader(self: *DataReader, len: usize) !DataReader {
        return DataReader{
            .data = try self.readSlice(len),
            .idx = 0,
            .byteOrder = self.byteOrder,
        };
    }
    pub fn rest(self: DataReader) []const u8 {
        return self.data[self.idx..];
    }

    pub fn dataAvailable(self: DataReader) bool {
        return self.idx < self.data.len;
    }
};

pub const BitReader = struct {
    data: []const u8,
    idx: usize = 0,
    byteOrder: std.builtin.Endian = .Big,
    pub fn readu8(self: *BitReader) !u8 {
        const byteIdx = self.idx / 8;
        if (byteIdx >= self.data.len) return error.TooLong;
        defer self.idx += 8;
        return self.data[byteIdx];
    }

    pub fn readu16(self: *BitReader) !u16 {
        const byteIdx = self.idx / 8;
        if (byteIdx > self.data.len) return error.TooLong;
        defer self.idx += 16;
        return std.mem.readIntSlice(u16, self.data[byteIdx..], self.byteOrder);
    }

    pub fn read(self: *BitReader, comptime T: type) !T {
        const byteIdx = self.idx / 8;
        const bitIdx = 7 - @truncate(u3, self.idx % 8) - (@bitSizeOf(T) - 1);
        //std.log.err("byte:{} bit:{}", .{ byteIdx, bitIdx });
        if (byteIdx > self.data.len) return error.TooLong;
        defer self.idx += @bitSizeOf(T);
        const val = @truncate(T, self.data[byteIdx] >> bitIdx);
        //std.log.err("val:{b}  {b:0>8}", .{ val, self.data[byteIdx] });
        return val;
    }
};

test {
    const val = [_]u8{ 0x1B, 0x1B };
    var br = BitReader{ .data = val[0..], .idx = 0 };
    try std.testing.expectEqual(@as(u2, 0), try br.read(u2));
    try std.testing.expectEqual(@as(u2, 1), try br.read(u2));
    try std.testing.expectEqual(@as(u2, 2), try br.read(u2));
    try std.testing.expectEqual(@as(u2, 3), try br.read(u2));
    try std.testing.expectEqual(@as(u2, 0), try br.read(u2));
    try std.testing.expectEqual(@as(u2, 1), try br.read(u2));
    try std.testing.expectEqual(@as(u2, 2), try br.read(u2));
    try std.testing.expectEqual(@as(u2, 3), try br.read(u2));
}
