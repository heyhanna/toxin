const std = @import("std");
const args = @import("args");
const help = @import("help.zig");

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut();
    const allocator = std.heap.c_allocator;

    const cli = try args.parseForCurrentProcess(struct {
        pub const shorthands = .{ .h = "help", .v = "version" };
        version: bool = false,
        help: bool = false,
    }, allocator, .silent);
    defer cli.deinit();

    if (cli.options.help) try help.print(stdout, .full);
    if (cli.options.version) try help.print(stdout, .version);
    if (cli.positionals.len <= 0) try help.print(stdout, .usage);
}
