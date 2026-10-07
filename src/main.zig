const fb = @import("framebuffer.zig");
const win = @import("window.zig");
const Camera = @import("camera.zig").Camera;
const scene = @import("scene.zig");
const renderer = @import("renderer.zig");
const std = @import("std");

pub fn main() !void {
    var buffer: fb.Framebuffer = undefined;
    var camera = Camera{};
    var thread_count = renderer.defaultThreads();
    var stats = renderer.render(&buffer, camera, &scene.cubes, thread_count);
    var window = try win.Window.open("Diorama");
    updateTitle(&window, stats);
    var previous = win.nowMilliseconds();
    while (window.isOpen()) {
        if (win.isKeyDown(0x1B)) break;
        const now = win.nowMilliseconds();
        const seconds = @min(@as(f32, @floatFromInt(now - previous)) / 1000, 0.05);
        previous = now;
        const rotation = key('D') - key('A');
        const vertical = key('W') - key('S');
        const zoom = key('E') - key('Q');
        const old_count = thread_count;
        if (win.isKeyDown('1')) thread_count = 1;
        if (win.isKeyDown('2')) thread_count = renderer.defaultThreads();
        if (rotation != 0 or vertical != 0 or zoom != 0 or win.isKeyDown('R') or old_count != thread_count) {
            camera.move(rotation, vertical, zoom, seconds);
            if (win.isKeyDown('R')) camera = Camera{};
            // Si la vista no cambia, conservamos la imagen en vez de renderizar otra vez.
            stats = renderer.render(&buffer, camera, &scene.cubes, thread_count);
            updateTitle(&window, stats);
        }
        window.draw(&buffer);
        win.waitMilliseconds(16);
    }
}

fn updateTitle(window: *win.Window, stats: renderer.Stats) void {
    var text: [200]u8 = undefined;
    const title = std.fmt.bufPrintZ(&text, "Diorama | {d} hilos | {d:.1} ms | A/D giro | W/S altura | Q/E zoom | R reset | 1/2 hilos", .{ stats.threads, stats.milliseconds }) catch return;
    window.setTitle(title);
}

fn key(code: i32) f32 {
    return if (win.isKeyDown(code)) 1 else 0;
}

test {
    @import("std").testing.refAllDecls(@This());
}
