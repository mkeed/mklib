const std = @import("std");
const Log = @import("Log.zig");

pub const FileHandle = struct {};

const FileInfo = struct {
    pub fn deinit(self: FileInfo) void {
        _ = self;
    }
};

pub const MkedCore = struct {
    projectDir: std.fs.Dir,
    files: std.ArrayList(?FileInfo),
    errorLog: Log.Logger,
    pub fn init(alloc: std.mem.Allocator) MkedCore {
        return MkedCore{
            .projectDir = std.fs.cwd(),
            .files = std.ArrayList(?FileInfo).init(alloc),
            .errorLog = Log.Logger.init(alloc),
        };
    }
    pub fn deinit(self: *MkedCore) void {
        for (self.files) |file| {
            if (file) |f| {
                f.deinit();
            }
        }
        self.files.deinit();
        self.errorLog.deinit();
    }

    pub fn openFileRead(self: *MkedCore, name: []const u8) !FileHandle {
        var file = self.projectDir.openFile(name, .{}) catch |err| {
            self.errorLog.err("Failed To Open File with error({})", .{err});
            return error.FailedToOpen;
        };
    }
};
