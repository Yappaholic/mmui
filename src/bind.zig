const std = @import("std");
const fs = std.fs;
var alloc = std.heap.page_allocator;

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

pub fn generate_bindings(bindings: []u8) !void {
    var bindlist = std.ArrayList(Binding).init(alloc);
    defer bindlist.deinit();
    var binditer = std.mem.splitAny(u8, bindings, ";");
    while (binditer.next()) |entry| {
        std.debug.print("{s}\n", .{entry});
    }
}

pub fn search_bindings(config_file: []u8) ![]u8 {
    var file = try fs.openFileAbsolute(config_file, .{ .mode = .read_only });
    var bindings = std.ArrayList(u8).init(alloc);
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const s = std.mem.trimLeft(u8, line, " ");
        if (std.mem.containsAtLeast(u8, s, 1, "bind=") and std.mem.startsWith(u8, s, "#") == false) {
            try bindings.appendSlice(s);
            try bindings.appendSlice(";");
        }
    }
    const result: []u8 = try bindings.toOwnedSlice();
    return result;
}
