const std = @import("std");
const b_target = @import("builtin").target;

const _target = std.zig.CrossTarget{
    .abi = if (b_target.os.tag == .linux) .musl else .gnu,
    .cpu_model = .{ .explicit = b_target.cpu.model },
    .cpu_arch = b_target.cpu.arch,
    .os_tag = b_target.os.tag,
};

pub fn build(b: *std.build.Builder) void {
    const exe = b.addExecutable("toxin", "src/main.zig");
    const target = b.standardTargetOptions(.{ .default_target = _target });
    const mode = b.standardReleaseOptions();
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.install();
}
