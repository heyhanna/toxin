const Self = @This();
const std = @import("std");

handle: std.fs.Dir,
allocator: std.mem.Allocator,
path: []const u8,

pub fn init(allocator: std.mem.Allocator, path: []const u8) !Self {
    const resolved = try std.fs.path.resolve(allocator, &.{path});
    std.fs.makeDirAbsolute(resolved) catch |err| switch (err) {
        std.os.MakeDirError.PathAlreadyExists => {},
        else => return err,
    };

    return Self{
        .handle = try std.fs.openDirAbsolute(resolved, .{ .iterate = true }),
        .allocator = allocator,
        .path = resolved,
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.path);
    self.handle.close();
}
