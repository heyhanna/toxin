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

    const v_opt = b.option([]const u8, "version", "Specify a manual version string");
    const v_str = if (v_opt) |v| try std.fmt.allocPrint(b.allocator, "{s}\n", .{v}) else ref;
    options.addOption([]const u8, "revision", v_str);
    exe.addOptions("options", options);

    try vendor.link(b, exe, target, mode);
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.linkLibC();
    exe.install();
}
