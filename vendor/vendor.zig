const std = @import("std");
const zlib = @import("zig-zlib/zlib.zig");
const libgit2 = @import("zig-libgit2/libgit2.zig");
const libssh2 = @import("zig-libssh2/libssh2.zig");
const mbedtls = @import("zig-mbedtls/mbedtls.zig");

const packages = [_]std.build.Pkg{
    .{ .name = "args", .source = .{ .path = "vendor/zig-args/args.zig" } },
    .{ .name = "toml", .source = .{ .path = "vendor/zig-toml/src/toml.zig" } },
};

pub fn link(
    b: *std.build.Builder,
    exe: *std.build.LibExeObjStep,
    target: std.zig.CrossTarget,
    mode: std.builtin.Mode,
) !void {
    const z = zlib.create(b, target, mode);
    const tls = mbedtls.create(b, target, mode);
    const ssh2 = libssh2.create(b, target, mode);
    const git2 = try libgit2.create(b, target, mode);

    for (packages) |pkg| exe.addPackage(pkg);

    z.link(git2.step, .{});
    ssh2.link(git2.step);
    tls.link(ssh2.step);
    tls.link(git2.step);
    z.link(exe, .{});
    git2.link(exe);
    ssh2.link(exe);
    tls.link(exe);
}
