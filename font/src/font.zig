const std = @import("std");

pub const Font = struct {
    pub fn deinit(self: Font) void {
        _ = self;
    }
};

pub const Fixed = struct {
    whole: i16,
    decimal: u16,
    pub fn initFromReader(reader: anytype) !Fixed {
        return Fixed{
            .whole = try reader.readIntBig(i16),
            .decimal = try reader.readIntBig(u16),
        };
    }
};

//const cmap = @import("tables/cmap.zig");
const head = @import("tables/head.zig");
const hhea = @import("tables/hhea.zig");
//const hmtx = @import("tables/hmtx.zig");
const maxp = @import("tables/maxp.zig");
const name = @import("tables/name.zig");
const os2 = @import("tables/os2.zig");
//const post = @import("tables/post.zig");

const Table = struct {
    data: []const u8,
    pub fn verify(self: Table) !void {
        const numTables = std.mem.readIntSliceBig(u16, self.data[4..8]);
        for (0..numTables) |idx| {
            const pos = 12 + idx * 16;

            const tag = self.data[pos .. pos + 4];
            const isHead = std.mem.eql(u8, "head", tag[0..]);
            const checkSum = std.mem.readIntSliceBig(u32, self.data[pos + 4 ..]);
            const offset = std.mem.readIntSliceBig(u32, self.data[pos + 8 ..]);
            const length = std.mem.readIntSliceBig(u32, self.data[pos + 12 ..]);
            if (offset + length > self.data.len) return error.InvalidTagLength;
            const data = self.data[offset .. offset + length];
            const calcCheckSum = calculateCheckSum(data, isHead);
            if (checkSum != calcCheckSum) {
                std.log.err("tag:[{s}] calc[{x}] != checksum[{x}]", .{
                    tag,
                    calcCheckSum,
                    checkSum,
                });
                return error.InvalidCheckSum;
            }
        }
    }
    fn calculateCheckSum(data: []const u8, isHead: bool) u32 {
        var sum: u32 = 0;
        var idx: usize = 0;
        while (idx < data.len) : (idx += 4) {
            var zero = std.mem.zeroes([4]u8);
            if (isHead and idx == 8) {
                // assume checkSumAdjustMent is zero
            } else if (data[idx..].len >= 4) {
                std.mem.copy(u8, &zero, data[idx .. idx + 4]);
            } else {
                std.mem.copy(u8, &zero, data[idx..]);
            }
            sum +%= std.mem.readIntBig(u32, &zero);
        }
        return sum;
    }
    pub fn get(self: Table, table: []const u8) ?[]const u8 {
        if (table.len != 4) return null;
        const numTables = std.mem.readIntSliceBig(u16, self.data[4..8]);
        for (0..numTables) |idx| {
            const pos = 12 + idx * 16;
            if (std.mem.eql(u8, self.data[pos .. pos + 4], table[0..])) {
                const offset = std.mem.readIntSliceBig(u32, self.data[pos + 8 ..]);
                const length = std.mem.readIntSliceBig(u32, self.data[pos + 12 ..]);
                return self.data[offset .. offset + length];
            }
        }
        return null;
    }
};

pub fn parseFont(data: []const u8, alloc: std.mem.Allocator) !Font {
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();

    const version = try reader.readIntBig(u32);
    if (version != 0x00010000 and version != 0x4F54544F) {
        std.log.err("Expected 0x00010000 or 0X4F54544F got [{x}]", .{version});
        return error.InvalidFileMagicNumber;
    }

    const tbl = Table{
        .data = data,
    };
    try tbl.verify();

    const HEAD = try head.parse(tbl.get("head") orelse return error.Missing_head, alloc);
    std.log.info("Head:{}", .{HEAD});
    const HHEA = try hhea.parse(tbl.get("hhea") orelse return error.Missing_hhea, alloc);
    std.log.info("HHEA:{}", .{HHEA});

    const MAXP = try maxp.parse(tbl.get("maxp") orelse return error.Missing_hmtx, alloc);
    std.log.info("MAXP:{}", .{MAXP});

    const NAME = try name.parse(tbl.get("name") orelse return error.Missing_name, alloc);
    defer NAME.deinit();

    const OS2 = try os2.parse(tbl.get("OS/2") orelse return error.Missing_Os2, alloc);
    std.log.info("OS2:{}", .{OS2});
    //const HMTX = try hmtx.parse(tbl.get("hmtx") orelse return error.Missing_hmtx, alloc, HHEA.numberOfHMetrics);
    return Font{};
}
