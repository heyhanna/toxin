const Self = @This();
const toml = @import("toml");
const std = @import("std");

table: *toml.Table,
allocator: std.mem.Allocator,
buffer: []const u8,

pub const Plugin = struct {
    repo: []const u8,
    ref: ?[]const u8,
    submodules: bool,
    path: ?[]const u8,
};

pub fn init(allocator: std.mem.Allocator, c_path: ?[]const u8) !Self {
    var env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    // zig fmt: off
    const config_path = if (c_path) |path| 
        try allocator.dupe(u8, path)
    else if (env.get("TOXIN_CONFIG")) |path|
        try allocator.dupe(u8, path)
    else if (env.get("XDG_CONFIG_HOME")) |path|
        try std.fs.path.join(allocator, &.{ path, "toxin.toml" })
    else if (env.get("HOME")) |path|
        try std.fs.path.join(allocator, &.{ path, ".config", "toxin.toml" })
    else return error.InvalidConfigPath;
    defer allocator.free(config_path);
    // zig fmt: on

    const config_file = if (std.fs.path.isAbsolute(config_path)) blk: {
        std.fs.accessAbsolute(config_path, .{}) catch return error.ConfigNotFound;
        break :blk try std.fs.openFileAbsolute(config_path, .{ .mode = .read_only });
    } else blk: {
        std.fs.cwd().access(config_path, .{}) catch return error.ConfigNotFound;
        break :blk try std.fs.cwd().openFile(config_path, .{ .mode = .read_only });
    };
    defer config_file.close();

    const source = try config_file.readToEndAlloc(allocator, std.math.maxInt(usize));

    return Self{
        .buffer = source,
        .allocator = allocator,
        .table = try toml.parseContents(allocator, source, null),
    };
}

pub fn cache(self: Self) ![]const u8 {
    return if (self.table.keys.get("cache")) |v| v.String else error.CacheNotSet;
}

pub fn plugins(self: Self) !?[]const Plugin {
    var plugin_list = std.ArrayList(Plugin).init(self.allocator);
    defer plugin_list.deinit();

    if (self.table.keys.get("plugin")) |plugin_cfg| {
        const plugin_map = plugin_cfg.ManyTables;
        for (plugin_map.items) |plugin| try plugin_list.append(.{
            .repo = if (plugin.keys.get("repo")) |v| v.String else return error.InvalidPlugin,
            .submodules = if (plugin.keys.get("submodules")) |v| v.Boolean else false,
            .path = if (plugin.keys.get("path")) |v| v.String else null,
            .ref = if (plugin.keys.get("ref")) |v| v.String else null,
        });
    }

    return if (plugin_list.items.len == 0) null else plugin_list.toOwnedSlice();
}

pub fn deinit(self: Self) void {
    self.allocator.free(self.buffer);
    self.table.deinit();
}
