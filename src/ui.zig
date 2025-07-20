const std = @import("std");
const dvui = @import("dvui");
const bind = @import("./bind.zig");
const alloc = std.heap.c_allocator;

// zig fmt: off
const label_opts: dvui.Options = .{ 
    .color_text = .fromHex("#00FF00"), 
    .font_style = .heading, 
    .font = .{ .size = 24, .name = "" } 
};

const box_opts: dvui.Options = .{ 
    .expand = .both, 
    .background = true, 
    .color_fill = .fromHex("#181818"),
    .min_size_content = .{.w = 120, .h = 0}
};

// zig fmt: on
pub fn draw_hello(bindings: bind.Bindings) !void {
    dvui.TextLayoutWidget.defaults.min_size_content = .{ .w = 120, .h = 0 };
    var box = dvui.box(@src(), .vertical, box_opts);
    box.install();
    dvui.label(@src(), "Keybinds\n", .{}, label_opts);

    var tl_default = dvui.textLayout(@src(), .{}, .{ .expand = .vertical, .background = true, .color_fill = .fromHex("#181818") });
    //dvui.label(@src(), "Default\n", .{}, label_opts);
    for (bindings.Default) |binding| {
        const keybind = try std.fmt.allocPrint(alloc, "{s} --> {s}\n", .{ binding.keybind, binding.command });
        tl_default.addText(keybind, .{ .color_text = .fromHex("#00FF00") });
    }

    var tl_mouse = dvui.textLayout(@src(), .{}, .{ .expand = .vertical, .background = true, .color_fill = .fromHex("#181818") });
    //dvui.label(@src(), "Mouse\n", .{}, label_opts);
    for (bindings.Mouse) |binding| {
        const keybind = try std.fmt.allocPrint(alloc, "{s} --> {s}\n", .{ binding.keybind, binding.command });
        tl_mouse.addText(keybind, .{ .color_text = .fromHex("#00FF00") });
    }

    var tl_axis = dvui.textLayout(@src(), .{}, .{ .expand = .vertical, .background = true, .color_fill = .fromHex("#181818") });
    //dvui.label(@src(), "Axis\n", .{}, label_opts);
    for (bindings.Axis) |binding| {
        const keybind = try std.fmt.allocPrint(alloc, "{s} --> {s}\n", .{ binding.keybind, binding.command });
        tl_axis.addText(keybind, .{ .color_text = .fromHex("#00FF00") });
    }

    var tl_gesture = dvui.textLayout(@src(), .{}, .{ .expand = .vertical, .background = true, .color_fill = .fromHex("#181818") });
    //dvui.label(@src(), "Gesture\n", .{}, label_opts);
    for (bindings.Gesture) |binding| {
        const keybind = try std.fmt.allocPrint(alloc, "{s} --> {s}\n", .{ binding.keybind, binding.command });
        tl_gesture.addText(keybind, .{ .color_text = .fromHex("#00FF00") });
    }

    tl_gesture.deinit();
    tl_axis.deinit();
    tl_mouse.deinit();
    tl_default.deinit();

    box.deinit();
}
