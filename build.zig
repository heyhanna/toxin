const std = @import("std");
const b_target = @import("builtin").target;
const vendor = @import("vendor/vendor.zig");

const _target = std.zig.CrossTarget{
    .abi = if (b_target.os.tag == .linux) .musl else .gnu,
    .cpu_model = .{ .explicit = b_target.cpu.model },
    .cpu_arch = b_target.cpu.arch,
    .os_tag = b_target.os.tag,
};

pub fn build(b: *std.build.Builder) anyerror!void {
    const exe = b.addExecutable("toxin", "src/main.zig");
    const target = b.standardTargetOptions(.{ .default_target = _target });
    const mode = b.standardReleaseOptions();

    const options = b.addOptions();
    const ref = try b.exec(&.{ "git", "rev-parse", "--short", "HEAD" });
    const leaks = b.option(bool, "leaks", "Enable the use of leak detection");
    options.addOption(bool, "leaks", leaks orelse false);
    options.addOption([]const u8, "revision", ref);
    exe.addOptions("options", options);

    try vendor.link(b, exe, target, mode);
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.linkLibC();
    exe.install();
}
