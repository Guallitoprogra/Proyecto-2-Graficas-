const std = @import("std");
const fb = @import("framebuffer.zig");
const Camera = @import("camera.zig").Camera;
const Cube = @import("cube.zig").Cube;
const raytracer = @import("raytracer.zig");

pub const Stats = struct { threads: usize, milliseconds: f64 };
const max_threads = 8;

pub fn defaultThreads() usize {
    return @min(max_threads, std.Thread.getCpuCount() catch 1);
}

pub fn render(buffer: *fb.Framebuffer, camera: Camera, cubes: []const Cube, requested: usize) Stats {
    const io = std.Io.Threaded.global_single_threaded.io();
    const start = std.Io.Clock.awake.now(io);
    const count = std.math.clamp(requested, 1, max_threads);
    var threads: [max_threads - 1]std.Thread = undefined;
    var spawned: usize = 0;
    for (1..count) |index| {
        threads[spawned] = std.Thread.spawn(.{}, renderRows, .{ buffer, camera, cubes, index, count }) catch {
            // Si no se puede crear un hilo, hacemos sus filas aqui para no dejar huecos.
            renderRows(buffer, camera, cubes, index, count);
            continue;
        };
        spawned += 1;
    }
    renderRows(buffer, camera, cubes, 0, count);
    for (threads[0..spawned]) |thread| thread.join();
    const elapsed = start.durationTo(std.Io.Clock.awake.now(io));
    return .{ .threads = spawned + 1, .milliseconds = @as(f64, @floatFromInt(elapsed.toNanoseconds())) / 1000000 };
}

fn renderRows(buffer: *fb.Framebuffer, camera: Camera, cubes: []const Cube, first: usize, step: usize) void {
    // Las filas alternadas reparten la cabana entre los hilos; cada pixel tiene un solo escritor.
    var y = first;
    while (y < fb.screen_height) : (y += step) {
        for (0..fb.screen_width) |x| {
            buffer.point(x, y, raytracer.trace(camera.ray(x, y, fb.screen_width, fb.screen_height), cubes));
        }
    }
}

test "varios hilos producen los mismos pixeles que el render secuencial" {
    const scene = @import("scene.zig");
    var serial: fb.Framebuffer = undefined;
    var parallel: fb.Framebuffer = undefined;
    const cameras = [_]Camera{ Camera{}, .{ .angle = 3.8 } };
    for (cameras, 0..) |camera, index| {
        raytracer.render(&serial, camera, &scene.cubes);
        const stats = render(&parallel, camera, &scene.cubes, if (index == 0) 7 else 2);
        try std.testing.expect(stats.threads > 1);
        try std.testing.expectEqualSlices(fb.Color, &serial.pixels, &parallel.pixels);
    }
    const stats = render(&parallel, Camera{}, &.{}, 0);
    try std.testing.expectEqual(@as(usize, 1), stats.threads);
}
