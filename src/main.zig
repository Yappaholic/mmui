const std = @import("std");
const bind = @import("./bind.zig");
const dvui = @import("dvui");

var alloc = std.heap.c_allocator;
const RaylibBackend = dvui.backend;

comptime {
    std.debug.assert(@hasDecl(RaylibBackend, "RaylibBackend"));
}

const vsync = true;
pub const c = RaylibBackend.c;

const VERSION = "0.1.2";

pub fn detect_config(config: *[]u8, cmd_arg: ?[]u8) !void {
    var config_file: []u8 = undefined;
    if (cmd_arg != null) {
        config.* = cmd_arg.?;
        return;
    }
    const config_home = std.posix.getenv("XDG_CONFIG_HOME");
    if (config_home == null) {
        const home = std.posix.getenv("HOME");
        config_file = try std.fmt.allocPrint(alloc, "{s}/.config/maomao/config.conf", .{home.?});
    } else {
        config_file = try std.fmt.allocPrint(alloc, "{s}/.config/maomao/config.conf", .{config_home.?});
    }
    config.* = try alloc.dupe(u8, config_file);
    alloc.free(config_file);
    return;
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
        try detect_config(config, config_path);
    } else {
        std.debug.print("No config path provided", .{});
        return 1;
    }
    return 0;
}
pub fn main() !void {
    var backend = try RaylibBackend.initWindow(.{
        .gpa = alloc,
        .size = .{ .w = 800.0, .h = 600.0 },
        .vsync = vsync,
        .title = "mmui",
    });
    defer backend.deinit();

    var win = try dvui.Window.init(@src(), alloc, backend.backend(), .{});
    defer win.deinit();

    const argv = std.os.argv;
    var config: []u8 = undefined;
    config = try alloc.alloc(u8, 2048);
    defer alloc.free(config);
    if (argv.len > 1) {
        const code: i8 = try parse_flags(&config, argv);
        switch (code) {
            1 => return,
            0 => {},
            else => unreachable,
        }
    } else try detect_config(&config, null);
    const bindings = try bind.search_bindings(&config);
    _ = try bind.generate_bindings(bindings);

    main_loop: while (true) {
        c.BeginDrawing();

        const nstime = win.beginWait(true);
        try win.begin(nstime);

        const quit = try backend.addAllEvents(&win);
        if (quit) break :main_loop;

        backend.clear();
        const end_micros = try win.end(.{});

        backend.setCursor(win.cursorRequested());

        const wait_event_micros = win.waitTime(end_micros, null);
        backend.EndDrawingWaitEventTimeout(wait_event_micros);
    }
}
