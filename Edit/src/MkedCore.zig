const std = @import("std");
const Log = @import("Log.zig");

const FileInfo = struct {
    isWrite: bool,
    name: std.ArrayList(u8),
    data: std.ArrayList(u8),
    readTime: i128,
    pub fn init(alloc: std.mem.Allocator, isWrite: bool, readTime: i128, name: []const u8) !FileInfo {
        var f = FileInfo{
            .isWrite = isWrite,
            .name = std.ArrayList(u8).init(alloc),
            .data = std.ArrayList(u8).init(alloc),
            .readTime = readTime,
        };

        try f.name.appendSlice(name);
        return f;
    }
    pub fn deinit(self: FileInfo) void {
        self.name.deinit();
        self.data.deinit();
    }
};

pub const MkedCore = struct {
    alloc: std.mem.Allocator,
    projectDir: std.fs.Dir,
    files: std.ArrayList(*FileInfo),
    errorLog: Log.Logger,
    pub fn init(alloc: std.mem.Allocator) MkedCore {
        return MkedCore{
            .projectDir = std.fs.cwd(),
            .files = std.ArrayList(*FileInfo).init(alloc),
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

    pub fn openFileRead(self: *MkedCore, name: []const u8) !*FileInfo {
        var file = self.projectDir.openFile(name, .{}) catch |err| {
            self.errorLog.err("Failed To Open File with error({})", .{err});
            return error.FailedToOpen;
        };
        defer file.close();
        const now = std.time.nanoTimeStamp();
        const meta = file.metadata();
        const perms = meta.permissions();
        var fileInfo = try self.alloc.create(FileInfo);
        fileInfo.* = FileInfo.init(self.alloc, !perms.readOnly(), now, name);
        try fileInfo.data.ensureTotalCapacity(meta.size());
        try file.reader.readAllArrayList(&fileInfo.data, meta.size());
        return fileInfo;
    }
    //pub fn saveFile(
};
