const std = @import("std");

const packages = [_]std.build.Pkg{
    .{ .name = "args", .source = .{ .path = "vendor/zig-args/args.zig" } },
};

pub fn link(
    _: *std.build.Builder,
    exe: *std.build.LibExeObjStep,
    _: std.zig.CrossTarget,
    _: std.builtin.Mode,
) void {
    for (packages) |pkg| exe.addPackage(pkg);
}
