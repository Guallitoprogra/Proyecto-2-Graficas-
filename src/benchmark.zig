const std = @import("std");
const fb = @import("framebuffer.zig");
const Camera = @import("camera.zig").Camera;
const renderer = @import("renderer.zig");
const scene = @import("scene.zig");

pub fn main() !void {
    var serial: fb.Framebuffer = undefined;
    var parallel: fb.Framebuffer = undefined;
    const threads = renderer.defaultThreads();
    _ = renderer.render(&serial, Camera{}, &scene.cubes, 1);
    _ = renderer.render(&parallel, Camera{}, &scene.cubes, threads);
    var serial_ms: f64 = 0;
    var parallel_ms: f64 = 0;
    const samples = 12;
    for (0..samples) |index| {
        // Alternamos el orden para que el primer modo no tenga siempre la misma ventaja.
        const camera = Camera{ .angle = 0.7 + @as(f32, @floatFromInt(index)) * 0.2 };
        var single: renderer.Stats = undefined;
        var multi: renderer.Stats = undefined;
        if (index % 2 == 0) {
            single = renderer.render(&serial, camera, &scene.cubes, 1);
            multi = renderer.render(&parallel, camera, &scene.cubes, threads);
        } else {
            multi = renderer.render(&parallel, camera, &scene.cubes, threads);
            single = renderer.render(&serial, camera, &scene.cubes, 1);
        }
        if (!std.mem.eql(u8, std.mem.asBytes(&serial.pixels), std.mem.asBytes(&parallel.pixels))) return error.RenderMismatch;
        if (multi.threads != threads) return error.ThreadCreationFailed;
        serial_ms += single.milliseconds;
        parallel_ms += multi.milliseconds;
    }
    serial_ms /= samples;
    parallel_ms /= samples;
    std.debug.print("{d} x {d}, promedio de {d} vistas\nUn hilo: {d:.2} ms\n{d} hilos: {d:.2} ms\nMejora: {d:.2}x\nImagenes identicas pixel por pixel\n", .{ fb.screen_width, fb.screen_height, samples, serial_ms, threads, parallel_ms, serial_ms / parallel_ms });
}
