const std = @import("std");

pub const FileHandle = struct {};

const FileInfo = struct {
    pub fn deinit(self: FileInfo) void {
        _ = self;
    }
};

pub const MkedCore = struct {
    projectDir: std.fs.Dir,
    files: std.ArrayList(?FileInfo),
    pub fn init(alloc: std.mem.Allocator) MkedCore {
        return MkedCore{
            .projectDir = std.fs.cwd(),
            .files = std.ArrayList(?FileInfo).init(alloc),
        };
    }
    pub fn deinit(self: *MkedCore) void {
        for (self.files) |file| {
            if (file) |f| {
                f.deinit();
            }
        }
        self.files.deinit();
    }
};
