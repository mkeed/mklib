const std = @import("std");
const ssh2 = @cImport({
    @cInclude("libssh2.h");
});

pub const SSHOpts = struct {
    address: std.net.Address,
    hostname: []const u8,
};

pub fn init(alloc: std.mem.Allocator, opts: SSHOpts) !SSH {
    var stream = try std.net.tcpConnectToAddress(opts.address);
    errdefer stream.close();

    var session = ssh2.libssh2_session_init();
    if (session == null) return error.FaileToCreateSShSession;
    errdefer ssh2.libssh2_session_free(session);
    ssh2.libssh2_session_set_blocking(session, 0);

    while (true) {
        var rc = ssh2.libssh2_session_handshake(session, stream, stream.handle);
        if (rc == ssh2.LIBSSH2_ERROR_EAGAIN) continue;
        if (rc != 0) {
            return error.FailedHandShake;
        }
        break;
    }
    {
        var nh = ssh2.libssh2_knowhhost_init(session);
        if (nh != 0) {
            return error.KnownHostsInitError;
        }
        defer ssh2.libssh2_knownhost_free(nh);
        ssh2.libssh2_knownhost_readfile(nh, "known_hosts", ssh2.LIBSSH2_KNOWNHOST_FILE_OPENSSH);
        ssh2.libssh2_knownhost_writefile(nh, "dummpfile", ssh2.LIBSSH2_KNOWNHOST_FILE_OPENSSH);

        var len: c_int = 0;
        var fingerprint_type: c_int = 0;
        var fingerprint = ssh2.libssh2_session_hostkey(session, &len, &fingerprint_type);
        if (fingerprint == 0) return error.FailedFingerPrint;
        var host: ?*ssh2.libssh2_knownhost = null;
        var check = ssh2.libssh2_knownhost_checkp(nh, opts.hostname, len, ssh2.LIBSSH2_KNOWNHOST_TYPE_PLAIN | ssh2.LIBSSH2_KNOWNHOST_KEYENC_RAW, &host);
    }
}

pub const SSH = struct {
    stream: std.net.Stream,
    session: ?*ssh2.LIBSSH2_SESSION,
};
