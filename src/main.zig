const std = @import("std");
const bind = @import("./bind.zig");
const alloc = std.heap.page_allocator;
const print = std.fmt.comptimePrint;

const VERSION = "0.1.0";

pub fn detect_config(cmd_arg: ?[]u8) ![]u8 {
    var config_file: []u8 = undefined;
    if (cmd_arg != null) {
        config_file = cmd_arg.?;
        return config_file;
    }
    const config_home = std.posix.getenv("XDG_CONFIG_HOME");
    if (config_home == null) {
        const home = std.posix.getenv("HOME");
        config_file = try std.fmt.allocPrint(alloc, "{s}/.config/maomao/config.conf", .{home.?});
    } else {
        config_file = try std.fmt.allocPrint(alloc, "{s}/.config/maomao/config.conf", .{config_home.?});
    }
    return config_file;
}

pub fn parse_flags(config: *[]u8, argv: [][*:0]u8) !i8 {
    const flag = std.mem.span(argv[1]);
    if (argv.len > 2) {
        std.debug.print("Too many arguments...", .{});
        return 1;
    }
    if (!std.mem.eql(u8, flag, "-c") and !std.mem.eql(u8, flag, "-v")) {
        std.debug.print("Unknown flag: {s}\n", .{flag});
        return 1;
    }
    if (std.mem.eql(u8, flag, "-v")) {
        std.debug.print("mmui version {s}\n", .{VERSION});
        return 1;
    }
    if (std.mem.eql(u8, flag, "-c") and argv.len == 2) {
        const config_path: []u8 = std.mem.span(argv[2]);
        config.* = try detect_config(config_path);
    } else {
        std.debug.print("No config path provided", .{});
        return 1;
    }
    return 0;
}
pub fn main() !void {
    const argv = std.os.argv;
    var config: []u8 = undefined;
    if (argv.len > 1) {
        const code: i8 = try parse_flags(&config, argv);
        switch (code) {
            1 => return,
            0 => {},
            else => unreachable,
        }
    } else config = try detect_config(null);
    const bindings = try bind.search_bindings(config);
    _ = try bind.generate_bindings(bindings);
}
