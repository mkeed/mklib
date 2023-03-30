const std = @import("std");

pub const ImageView = struct {
    data: []const u8,
    width: usize,
    height: usize,
    bytesPerPixel: usize,
    pub fn getPixel(self: ImageView, x: usize, y: usize) ?[]const u8 {
        if (x > self.width or y > self.height) return null;

        const idx = (self.bytesPerPixel) * (self.width * y + x);

        return self.data[idx .. idx + self.bytesPerPixel];
    }
};

pub const Image = struct {
    alloc: std.mem.Allocator,
    data: []u8,
    width: usize,
    height: usize,
    bytesPerPixel: usize,
    pub fn init(alloc: std.mem.Allocator, width: usize, height: usize, bytesPerPixel: usize) !Image {
        var i = Image{
            .alloc = alloc,
            .data = try alloc.alloc(u8, width * height * (bytesPerPixel + 1)),
            .width = width,
            .height = height,
            .bytesPerPixel = bytesPerPixel,
        };
        for (i.data) |*val| {
            val.* = 0;
        }
        return i;
    }
    pub fn deinit(self: Image) void {
        self.alloc.free(self.data);
    }
    pub fn setPixel(self: Image, x: usize, y: usize, pixel: []const u8) void {
        //std.log.err("sp:[{}:{}] => [{}]",.{x,y,std.fmt.fmtSliceHexUpper(pixel)});
        if (x >= self.width or y >= self.height) return;
        const idx = (self.bytesPerPixel + 1) * (self.width * y + x);

        self.data[idx] = 1;

        for (pixel[0..self.bytesPerPixel], 0..) |p, i| self.data[1 + idx + i] = p;
    }

    pub fn getPixel(self: Image, x: usize, y: usize) ?[]const u8 {
        if (x > self.width or y > self.height) return null;

        const idx = (self.bytesPerPixel + 1) * (self.width * y + x);

        return self.data[idx + 1 .. idx + 1 + self.bytesPerPixel];
    }

    pub fn getPixelIfSet(self: Image, x: usize, y: usize) ?[]const u8 {
        if (x > self.width or y > self.height) return null;

        const idx = (self.bytesPerPixel + 1) * (self.width * y + x);
        if (self.data[idx] != 0) {
            return self.data[idx + 1 .. idx + 1 + self.bytesPerPixel];
        } else {
            return null;
        }
    }

    pub fn write(self: Image, writer: anytype) !void {
        _ = self;
        _ = writer;
        // try std.fmt.format(writer, "ConstImage{{", .{});

        // var first: bool = true;
        // try std.fmt.format(writer, "    .data = &.{{", .{});
        // for (self.data) |val| {
        //     if (!first) {
        //         try std.fmt.format(writer, ", ", .{});
        //     }
        //     first = false;
        //     try val.print(writer);
        // }

        // try std.fmt.format(writer, "}},", .{});
        // try std.fmt.format(writer, "    .width = {},", .{self.width});
        // try std.fmt.format(writer, "    .height = {},", .{self.height});
        // try std.fmt.format(writer, "}}", .{});
    }
};
