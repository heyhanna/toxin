const std = @import("std");
const bind = @import("bind/git2.zig");
const os_tag = @import("builtin").target.os.tag;

const Head = struct { oid: [bind.GIT_OID_HEXSZ]u8, name: []const u8 };
const State = struct { allocator: std.mem.Allocator, base_path: []const u8 };
const Options = struct { ref: ?[]const u8 = null, recurse: bool = false };

// zig fmt: off
pub fn initialize() void { _ = bind.git_libgit2_init(); }
pub fn deinit() void { _ = bind.git_libgit2_shutdown(); }
// zig fmt: on

pub const Error =
    std.mem.Allocator.Error ||
    std.fs.Dir.DeleteTreeError ||
    error{ Clone, Ref, Submodule };

pub fn clone(
    allocator: std.mem.Allocator,
    url: []const u8,
    path: []const u8,
    opts: Options,
) Error!void {
    const url_z = try allocator.dupeZ(u8, url);
    defer allocator.free(url_z);

    const path_z = try allocator.dupeZ(u8, path);
    defer allocator.free(path_z);

    var repo: ?*bind.git_repository = null;
    var options: bind.git_clone_options = undefined;
    _ = bind.git_clone_init_options(&options, bind.GIT_CLONE_OPTIONS_VERSION);
    if (bind.git_clone(&repo, url_z, path_z, &options) != 0) return Error.Clone;

    var err: i32 = 0;
    if (opts.ref) |rid| {
        const commit_z = try allocator.dupeZ(u8, rid);
        defer allocator.free(commit_z);

        var oid: bind.git_oid = undefined;
        err = bind.git_oid_fromstr(&oid, commit_z);
        if (err != 0) return Error.Ref;
        var obj: ?*bind.git_object = undefined;
        err = bind.git_object_lookup(&obj, repo, &oid, bind.GIT_OBJECT_ANY);
        if (err != 0) return Error.Ref;
        var checkout_opts: bind.git_checkout_options = undefined;
        _ = bind.git_checkout_options_init(&checkout_opts, bind.GIT_CHECKOUT_OPTIONS_VERSION);
        err = bind.git_checkout_tree(repo, obj, &checkout_opts);
        if (err != 0) return Error.Ref;
    }

    if (opts.recurse) {
        var state = State{ .allocator = allocator, .base_path = path };
        err = bind.git_submodule_foreach(repo, submoduleCb, &state);
        if (err != 0) return Error.Submodule;
    }

    if (os_tag != .windows) {
        const dot_dir = try std.fs.path.join(allocator, &.{ path, ".git" });
        defer allocator.free(dot_dir);
        try std.fs.cwd().deleteTree(dot_dir);
    }
}

pub fn ref(allocator: std.mem.Allocator, url: []const u8, rid: []const u8) Error![]const u8 {
    const url_z = try allocator.dupeZ(u8, url);
    defer allocator.free(url_z);

    const rid_z = try allocator.dupeZ(u8, rid);
    defer allocator.free(rid_z);

    if (rid_z.len == bind.GIT_OID_HEXSZ) for (rid) |char| {
        if (!std.ascii.isXDigit(char)) break;
    } else return allocator.dupe(u8, rid);

    var remote: ?*bind.git_remote = null;
    var err = bind.git_remote_create_anonymous(&remote, null, url_z);
    if (err != 0) return Error.Ref;
    defer bind.git_remote_free(remote);

    var cb: bind.git_remote_callbacks = undefined;
    err = bind.git_remote_init_callbacks(&cb, bind.GIT_REMOTE_CALLBACKS_VERSION);
    if (err != 0) return Error.Ref;

    err = bind.git_remote_connect(remote, bind.GIT_DIRECTION_FETCH, &cb, null, null);
    if (err != 0) return Error.Ref;

    var refs_len: usize = 0;
    var refs_ptr: [*c][*c]bind.git_remote_head = undefined;
    err = bind.git_remote_ls(&refs_ptr, &refs_len, remote);
    if (err != 0) return Error.Ref;

    var refs = std.ArrayList(Head).init(allocator);

    defer {
        for (refs.items) |entry| allocator.free(entry.name);
        refs.deinit();
    }

    var index: usize = 0;
    while (index < refs_len) : (index += 1) {
        const len = std.mem.len(refs_ptr[index].*.name);
        try refs.append(.{
            .oid = undefined,
            .name = try allocator.dupeZ(u8, refs_ptr[index].*.name[0..len]),
        });
        _ = bind.git_oid_fmt(
            &refs.items[refs.items.len - 1].oid,
            &refs_ptr[index].*.oid,
        );
    }

    inline for (&[_][]const u8{ "refs/tags/", "refs/heads/" }) |prefix| {
        for (refs.items) |entry| if (std.mem.startsWith(u8, entry.name, prefix) and
            std.mem.eql(u8, entry.name[prefix.len..], rid_z))
            return allocator.dupe(u8, &entry.oid);
    }

    return Error.Ref;
}

fn submoduleCb(
    sm: ?*bind.git_submodule,
    sm_name: [*c]const u8,
    payload: ?*anyopaque,
) callconv(.C) c_int {
    return if (submoduleImpl(sm, sm_name, payload)) 0 else |err| blk: {
        std.log.err("{s}", .{@errorName(err)});
        break :blk -1;
    };
}

fn submoduleImpl(sm: ?*bind.git_submodule, sm_name: [*c]const u8, payload: ?*anyopaque) Error!void {
    const parent_state = @ptrCast(*State, @alignCast(@alignOf(*State), payload));
    const allocator = parent_state.allocator;

    if (sm == null) return;
    const sub_name = if (sm_name != null) std.mem.span(sm_name) else return;
    const sub_path = try std.mem.replaceOwned(u8, allocator, sub_name, "/", std.fs.path.sep_str);
    defer allocator.free(sub_path);

    const base_path = try std.fs.path.join(allocator, &.{ parent_state.base_path, sub_path });
    defer allocator.free(base_path);

    const oid = try allocator.alloc(u8, bind.GIT_OID_HEXSZ);
    _ = bind.git_oid_fmt(oid.ptr, bind.git_submodule_head_id(sm));
    defer allocator.free(oid);

    var options: bind.git_submodule_update_options = undefined;
    _ = bind.git_submodule_update_init_options(&options, bind.GIT_SUBMODULE_UPDATE_OPTIONS_VERSION);
    var err = bind.git_submodule_update(sm, 1, &options);
    if (err != 0) return Error.Submodule;

    var repo: ?*bind.git_repository = null;
    err = bind.git_submodule_open(&repo, sm);
    if (err != 0) return Error.Submodule;

    var state = State{ .allocator = allocator, .base_path = base_path };
    err = bind.git_submodule_foreach(repo, submoduleCb, &state);
    if (err != 0) return Error.Submodule;

    if (os_tag != .windows) {
        const dot_dir = try std.fs.path.join(allocator, &.{ base_path, ".git" });
        defer allocator.free(dot_dir);

        try std.fs.cwd().deleteTree(dot_dir);
    }
}
