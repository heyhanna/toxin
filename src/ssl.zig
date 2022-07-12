const std = @import("std");
const builtin = @import("builtin");

extern fn git_mbedtls__set_cert_location(path: ?[*:0]const u8, file: ?[*:0]const u8) c_int;

extern fn git_mbedtls__insecure() void;
pub const insecure = git_mbedtls__insecure;

const locations: []const [:0]const u8 = &.{
    "/etc/ssl/certs/ca-certificates.crt",
    "/etc/pki/tls/certs/ca-bundle.crt",
    "/etc/ssl/ca-bundle.pem",
    "/etc/pki/tls/cacert.pem",
    "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem",
    "/etc/ssl/cert.pem",
    "/etc/certs/ca-certificates.crt",
    "/etc/ssl/certs/ca-certificates.crt",
    "/etc/ssl/cacert.pem",
    "/var/ssl/certs/ca-bundle.crt",
    "/usr/local/share/certs/ca-root-nss.crt",
    "/etc/openssl/certs/ca-certificates.crt",
    "/usr/local/etc/ssl/cert.pem",
    "/etc/ssl/cert.pem",
    "/sys/lib/tls/ca.pem",
};

pub const Error = std.mem.Allocator.Error || std.process.GetEnvVarOwnedError;

pub fn load(allocator: std.mem.Allocator) Error!void {
    switch (builtin.target.os.tag) {
        .windows, .macos => {},
        else => std.log.warn("certificates for {s} not implemented", .{builtin.target.os.tag}),
        .linux, .aix, .dragonfly, .netbsd, .freebsd, .openbsd, .plan9, .solaris => {
            const env_var = try std.process.hasEnvVar(allocator, "SSL_CERT_FILE");
            const files: []const [:0]const u8 = if (!env_var) locations else blk: {
                const path = try std.process.getEnvVarOwned(allocator, "SSL_CERT_FILE");
                defer allocator.free(path);
                break :blk &.{try allocator.dupeZ(u8, path)};
            };
            defer if (env_var) allocator.free(files[0]);
            for (files) |path| if (git_mbedtls__set_cert_location(path, null) == 0) return;
        },
    }
}
