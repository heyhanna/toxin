const std = @import("std");
const args = @import("args");
const help = @import("help.zig");
const use_leaks = @import("options").leaks;
const git = @import("git.zig");

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = if (use_leaks) gpa.allocator() else std.heap.c_allocator;

    // zig fmt: off
    defer if (use_leaks) { _ = gpa.detectLeaks(); _ = gpa.deinit(); };
    // zig fmt: on

    const cli = try args.parseForCurrentProcess(struct {
        pub const shorthands = .{ .h = "help", .v = "version" };
        insecure: bool = false,
        version: bool = false,
        help: bool = false,
    }, allocator, .silent);
    defer cli.deinit();

    git.initialize();
    defer git.deinit();

    if (cli.options.help) try help.print(stdout, .full);
    if (cli.options.version) try help.print(stdout, .version);
    if (cli.positionals.len <= 0) try help.print(stdout, .usage);
    if (cli.options.insecure) git.insecure();
}
