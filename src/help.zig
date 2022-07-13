const std = @import("std");
const options = @import("options");

const message =
    \\https://codeberg.org/hanna/toxin
    \\
    \\usage: toxin [options] <arguments>
    \\
    \\-h, --help      Shows this help message
    \\-v, --version   Shows the current version
    \\-c, --config    Specify the config location
    \\--insecure      Disable certificate errors
    \\
    \\The config location can be set with the --config
    \\option or by setting the TOXIN_CONFIG variable,
    \\by default it is in either $HOME/.config/toxin.toml
    \\or $XDG_CONFIG_HOME/toxin.toml, depending if your
    \\system follows the XDG specifications.
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
