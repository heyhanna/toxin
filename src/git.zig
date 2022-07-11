const bind = @import("bind/git2.zig");

// zig fmt: off
pub fn initialize() void { _ = bind.git_libgit2_init(); }
pub fn deinit() void { _ = bind.git_libgit2_shutdown(); }
// zig fmt: on

extern fn git_mbedtls__insecure() void;
pub const insecure = git_mbedtls__insecure;
