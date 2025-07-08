const std = @import("std");
const fs = std.fs;
var alloc = std.heap.c_allocator;

pub const Binding = struct {
    keybind: []u8,
    command: []u8,
    group: BindingGroup,
};

pub const BindingGroup = enum {
    Mouse,
    Axis,
    Gesture,
    Default,
};

pub fn remove_prefix(bind_str: *[]u8, entry: []const u8, query: []const u8) !void {
    const size = std.mem.replacementSize(u8, entry, query, "");
    bind_str.* = try alloc.alloc(u8, size);
    _ = std.mem.replace(u8, entry, query, "", bind_str.*);
}
pub fn populate_bind(bind_str: *[]u8, entry: []const u8) !BindingGroup {
    if (std.mem.startsWith(u8, entry, "bind=")) {
        try remove_prefix(bind_str, entry, "bind=");
        std.debug.print("default bind: {s}\n", .{bind_str.*});
        return .Default;
    } else if (std.mem.startsWith(u8, entry, "mousebind=")) {
        try remove_prefix(bind_str, entry, "mousebind=");
        std.debug.print("mousebind: {s}\n", .{bind_str.*});
        return .Mouse;
    } else if (std.mem.startsWith(u8, entry, "axisbind=")) {
        try remove_prefix(bind_str, entry, "axisbind=");
        std.debug.print("axisbind: {s}\n", .{bind_str.*});
        return .Axis;
    } else if (std.mem.startsWith(u8, entry, "gesturebind=")) {
        try remove_prefix(bind_str, entry, "gesturebind=");
        std.debug.print("gesturebind: {s}\n", .{bind_str.*});
        return .Gesture;
    } else unreachable;
}
pub fn generate_bindings(bindings: []u8) !void {
    var bindlist = std.ArrayList(Binding).init(alloc);
    defer bindlist.deinit();
    var binditer = std.mem.splitAny(u8, bindings, ";");
    while (binditer.next()) |entry| {
        var bind_str: []u8 = undefined;
        _ = try populate_bind(&bind_str, entry);
    }
}

pub fn search_bindings(config_file: *[]u8) ![]u8 {
    var file = try fs.openFileAbsolute(config_file.*, .{ .mode = .read_only });
    var bindings = std.ArrayList(u8).init(alloc);
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var s = std.mem.trimLeft(u8, line, " ");
        s = std.mem.trimRight(u8, s, " ");
        if (std.mem.containsAtLeast(u8, s, 1, "bind=") and std.mem.startsWith(u8, s, "#") == false) {
            try bindings.appendSlice(s);
            try bindings.appendSlice(";");
        }
    }
    const result: []u8 = @constCast(std.mem.trimRight(u8, try bindings.toOwnedSlice(), ";"));
    return result;
}
