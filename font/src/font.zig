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

const cmap = @import("tables/cmap.zig");
const head = @import("tables/head.zig");
const hhea = @import("tables/hhea.zig");
//const hmtx = @import("tables/hmtx.zig");
const maxp = @import("tables/maxp.zig");
const name = @import("tables/name.zig");
const os2 = @import("tables/os2.zig");
const post = @import("tables/post.zig");
const glyf = @import("tables/glyf.zig");

pub const Table = struct {
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
            std.log.info("tag:[{s}]", .{tag});
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
    pub fn listTables(self: Table, res: *std.ArrayList([4]u8)) !void {
        const numTables = std.mem.readIntSliceBig(u16, self.data[4..8]);
        for (0..numTables) |idx| {
            const pos = 12 + idx * 16;

            const tag = [4]u8{
                self.data[pos],
                self.data[pos + 1],
                self.data[pos + 2],
                self.data[pos + 3],
            };
            try res.append(tag);
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

    const CMAP = try cmap.parse(tbl.get("cmap") orelse return error.Missing_cmap, alloc);
    std.log.info("CMAP:{}", .{CMAP});

    const GLYF = try glyf.parse(tbl.get("glyf") orelse return error.Missing_glyf, alloc, MAXP.numGlyphs);
    defer GLYF.deinit();
    std.log.info("GLYF:{}", .{GLYF});

    //const POST = try post.parse(tbl.get("post") orelse return error.Missing_post, alloc);
    //_ = POST;
    //const HMTX = try hmtx.parse(tbl.get("hmtx") orelse return error.Missing_hmtx, alloc, HHEA.numberOfHMetrics);
    return Font{};
}

pub fn listFonts(alloc: std.mem.Allocator) !std.ArrayList(std.ArrayList(u8)) {
    var fonts = std.ArrayList(std.ArrayList(u8)).init(alloc);
    errdefer {
        for (fonts.items) |item| {
            item.deinit();
        }
        fonts.deinit();
    }
    const searchFolders = [_][]const u8{ "/usr/share/fonts/truetype", "/usr/share/fonts/opentype", "/usr/share/fonts" };

    for (searchFolders) |folderName| {
        var dir = try std.fs.cwd().openIterableDir(folderName, .{});
        defer dir.close();
        var dirIter = dir.iterate();
        while (try dirIter.next()) |item| {
            switch (item.kind) {
                .Directory => {
                    var fontDir = try dir.dir.openIterableDir(item.name, .{});
                    defer fontDir.close();
                    var fontIter = fontDir.iterate();
                    while (try fontIter.next()) |fontFile| {
                        switch (fontFile.kind) {
                            .File => {
                                var split = std.mem.splitBackwards(u8, fontFile.name, ".");
                                if (split.next()) |n| {
                                    if (std.mem.eql(u8, "ttf", n) or std.mem.eql(u8, "otf", n)) {
                                        var filename = std.ArrayList(u8).init(alloc);
                                        errdefer filename.deinit();
                                        try std.fmt.format(filename.writer, "{s}/{s}/{s}", .{
                                            folderName,
                                            item.name,
                                            fontFile.name,
                                        });
                                        try fonts.append(filename);
                                    }
                                }
                            },
                            else => continue,
                        }
                    }
                },
                else => continue,
            }
        }
    }
    return fonts;
}

test {
    const alloc = std.testing.allocator;
    var fonts = try listFonts(alloc);
    defer {
        for (fonts.items) |f| {
            f.deinit();
        }
        fonts.deinit();
    }
    for (fonts.items) |f| {
        std.log.err("{s}", .{f.items});
    }
}
