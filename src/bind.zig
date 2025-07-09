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

pub const BindingError = error{
    InvalidKeybinding,
};

pub fn remove_prefix(bind_str: *[]u8, entry: []const u8, query: []const u8) !void {
    const size = std.mem.replacementSize(u8, entry, query, "");
    bind_str.* = try alloc.alloc(u8, size);
    _ = std.mem.replace(u8, entry, query, "", bind_str.*);
}

pub fn populate_bind(bind_str: *[]u8, entry: []const u8) !Binding {
    var keybind: [2][]u8 = .{ "", "" };
    var result_keybind: []u8 = undefined;
    var command: []u8 = undefined;
    var arr_list = std.ArrayList([]u8).init(alloc);
    var group: BindingGroup = undefined;

    if (std.mem.startsWith(u8, entry, "bind=")) {
        try remove_prefix(bind_str, entry, "bind=");
        group = .Default;
    } else if (std.mem.startsWith(u8, entry, "mousebind=")) {
        try remove_prefix(bind_str, entry, "mousebind=");
        group = .Mouse;
    } else if (std.mem.startsWith(u8, entry, "axisbind=")) {
        try remove_prefix(bind_str, entry, "axisbind=");
        group = .Axis;
    } else if (std.mem.startsWith(u8, entry, "gesturebind=")) {
        try remove_prefix(bind_str, entry, "gesturebind=");
        group = .Gesture;
    } else unreachable;

    var bind_iter = std.mem.splitAny(u8, bind_str.*, ",");

    while (bind_iter.next()) |item| {
        try arr_list.append(@constCast(item));
    }

    std.debug.print("keybind length is: {d}\n", .{arr_list.items.len});

    switch (arr_list.items.len) {
        0...2 => {
            std.debug.print("invalid keybinding: {s}\n", .{bind_str.*});
            return BindingError.InvalidKeybinding;
        },
        3 => {
            command = arr_list.items[2];
        },
        4...5 => {
            if (group != .Gesture) {
                command = try std.mem.join(alloc, " ", arr_list.items[2..]);
            } else {
                command = try std.mem.join(alloc, " ", arr_list.items[3..]);
            }
        },
        else => {
            std.debug.print("invalid keybinding: {s}\n", .{bind_str.*});
            return BindingError.InvalidKeybinding;
        },
    }

    if (arr_list.items.len >= 4 and group == .Gesture) {
        result_keybind = try std.mem.join(alloc, " | ", arr_list.items[1..3]);
    } else {
        keybind = .{ arr_list.items[0], arr_list.items[1] };
        result_keybind = try std.mem.join(alloc, " | ", &keybind);
    }

    return Binding{
        .keybind = result_keybind,
        .command = command,
        .group = group,
    };
}
pub fn generate_bindings(bindings: []u8) !void {
    var bindlist = std.ArrayList(Binding).init(alloc);
    defer bindlist.deinit();
    var binditer = std.mem.splitAny(u8, bindings, ";");
    while (binditer.next()) |entry| {
        var bind_str: []u8 = undefined;
        const bind = try populate_bind(&bind_str, entry);
        try bindlist.append(bind);
    }

    for (bindlist.items) |bind| {
        std.debug.print("{s} : {s} : {any}\n", .{ bind.keybind, bind.command, bind.group });
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
