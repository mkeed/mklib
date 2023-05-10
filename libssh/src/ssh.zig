const std = @import("std");
const ssh2 = @cImport({
    @cInclude("libssh2.h");
});

pub const SSHOpts = struct {
    address: std.net.Address,
    hostname: []const u8,
};

const AllocInfo = struct {
    allocr: std.mem.Allocator,
    buffers: std.ArrayList(Buffer),
    const Buffer = struct {
        used: bool,
        data: std.ArrayList(u8),
    };
    pub fn deinit(self: *AllocInfo) void {
        for (self.buffers.items) |item| {
            item.data.deinit();
        }
        self.buffers.deinit();
    }
    pub fn alloc(self: *AllocInfo, count: usize) ?*anyopaque {
        if (count == 0) return null;
        for (self.buffers.items) |*item| {
            if (item.used == false) {
                item.used = true;
                item.data.clearRetainingCapacity();
                item.data.appendNTimes(0, count) catch {
                    item.used = false;
                    return null;
                };
                return item.data.items.ptr;
            }
        }
        var b = Buffer{ .used = true, .data = std.ArrayList(u8).init(self.allocr) };

        b.data.appendNTimes(0, count) catch {
            b.data.deinit();
            return null;
        };
        for (b.data.items) |*v| v.* = 0;
        self.buffers.append(b) catch {
            b.data.deinit();
            return null;
        };
        return b.data.items.ptr;
    }
    pub fn realloc(self: *AllocInfo, count: usize, data: ?*anyopaque) ?*anyopaque {
        if (data) |d| {
            if (count == 0) {
                self.free(data);
            }
            for (self.buffers.items) |*item| {
                if (@ptrToInt(item.data.items.ptr) == @ptrToInt(d)) {
                    if (item.data.items.len > count) {
                        item.data.shrinkRetainingCapacity(count);
                    } else {
                        item.data.appendNTimes(0, count - item.data.items.len) catch return null;
                    }
                    return item.data.items.ptr;
                }
            }
            return null;
        } else return self.alloc(count);
    }
    pub fn free(self: *AllocInfo, data: ?*anyopaque) void {
        if (data) |d| {
            for (self.buffers.items) |*item| {
                if (@ptrToInt(item.data.items.ptr) == @ptrToInt(d)) {
                    for (item.data.items) |*v| v.* = 0;
                    item.used = false;
                }
            }
        }
    }
};

fn allocFunc(count: usize, ctx: [*c]?*anyopaque) callconv(.C) ?*anyopaque {
    var self = @ptrCast(**AllocInfo, ctx);
    return self.*.alloc(count);
}

fn freeFunc(ptr: ?*anyopaque, ctx: [*c]?*anyopaque) callconv(.C) void {
    var self = @ptrCast(**AllocInfo, ctx);
    return self.*.free(ptr);
}

fn reallocFunc(ptr: ?*anyopaque, count: usize, ctx: [*c]?*anyopaque) callconv(.C) ?*anyopaque {
    var self = @ptrCast(**AllocInfo, ctx);
    return self.*.realloc(count, ptr);
}

pub fn init(alloc: std.mem.Allocator, dir: std.fs.Dir, opts: SSHOpts) !SSH {
    var info = try alloc.create(AllocInfo);
    errdefer alloc.destroy(info);
    info.* = .{ .allocr = alloc, .buffers = std.ArrayList(AllocInfo.Buffer).init(alloc) };
    errdefer info.deinit();
    var stream = try std.net.tcpConnectToAddress(opts.address);
    errdefer stream.close();

    if (ssh2.libssh2_init(0) != 0) return error.FailedToInitssh2;

    var session = ssh2.libssh2_session_init_ex(
        &allocFunc,
        &freeFunc,
        &reallocFunc,
        info,
    );
    if (session == null) return error.FaileToCreateSShSession;
    errdefer _ = ssh2.libssh2_session_free(session);
    ssh2.libssh2_session_set_blocking(session, 0);

    while (true) {
        var rc = ssh2.libssh2_session_handshake(session, stream.handle);
        if (rc == ssh2.LIBSSH2_ERROR_EAGAIN) continue;
        if (rc != 0) {
            return error.FailedHandShake;
        }
        break;
    }
    {
        var nh = ssh2.libssh2_knownhost_init(session);
        if (nh != null) {
            return error.KnownHostsInitError;
        }
        defer ssh2.libssh2_knownhost_free(nh);
        _ = ssh2.libssh2_knownhost_readfile(nh, "known_hosts", ssh2.LIBSSH2_KNOWNHOST_FILE_OPENSSH); //TODO
        _ = ssh2.libssh2_knownhost_writefile(nh, "dummpfile", ssh2.LIBSSH2_KNOWNHOST_FILE_OPENSSH); //TODO

        var len: usize = 0;
        var fingerprint_type: c_int = 0;
        var fingerprint = ssh2.libssh2_session_hostkey(
            session,
            @ptrCast([*c]usize, &len),
            @ptrCast([*c]c_int, &fingerprint_type),
        );
        if (fingerprint == 0) return error.FailedFingerPrint;
        var host: ?*ssh2.libssh2_knownhost = null;
        var check = ssh2.libssh2_knownhost_checkp(
            nh,
            @ptrCast([*c]const u8, &opts.hostname),
            opts.address.getPort(),
            fingerprint,
            len,
            ssh2.LIBSSH2_KNOWNHOST_TYPE_PLAIN | ssh2.LIBSSH2_KNOWNHOST_KEYENC_RAW,
            &host,
        );
        _ = check;
        //TODO: complete check
    }
    while (true) {
        var pub_key = try dir.readFileAlloc(alloc, "~/.ssh/id_rsa.pub", 65535);
        defer alloc.free(pub_key);
        var priv_key = try dir.readFileAlloc(alloc, "~/.ssh/id_rsa", 65535);
        defer alloc.free(priv_key);
        const userName = "mitchk";
        const rc = ssh2.libssh2_userauth_publickey_frommemory(
            session,
            userName.ptr,
            userName.len,
            pub_key.ptr,
            pub_key.len,
            priv_key.ptr,
            priv_key.len,
            "",
        );
        if (rc == ssh2.LIBSSH2_ERROR_EAGAIN) continue;
        if (rc != 0) return error.FailedAuth;
        break;
    }
    return SSH{
        .stream = stream,
        .session = session,
        .alloc = alloc,
        .info = info,
    };
}

pub const SSH = struct {
    stream: std.net.Stream,
    session: ?*ssh2.LIBSSH2_SESSION,
    alloc: std.mem.Allocator,
    info: *AllocInfo,
    pub fn deinit(self: SSH) void {
        self.stream.close();
        _ = ssh2.libssh2_session_free(self.session);
        self.info.deinit();
        self.alloc.destroy(self.info);
    }
};
