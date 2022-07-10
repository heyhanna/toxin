const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const exe = b.addExecutable("toxin", "src/main.zig");
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.install();
}
