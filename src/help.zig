const std = @import("std");
const options = @import("options");

const message =
    \\https://codeberg.org/hanna/toxin
    \\
    \\usage: toxin [options] <arguments>
    \\
    \\-h, --help      Shows this help message
    \\-v, --version   Shows the current version
    \\--insecure      Disable certificate errors
    \\
;

const HelpLevel = enum { usage, version, full };

pub fn print(stdout: std.fs.File, level: HelpLevel) std.os.WriteError!void {
    const version = "toxin version " ++ options.revision;
    defer std.process.exit(0);

    try switch (level) {
        .usage => stdout.writeAll(message[34..69]),
        .full => stdout.writeAll(version ++ message),
        .version => stdout.writeAll(version),
    };
}
