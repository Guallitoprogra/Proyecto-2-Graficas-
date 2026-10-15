const std = @import("std");
const fb = @import("framebuffer.zig");
const Camera = @import("camera.zig").Camera;
const renderer = @import("renderer.zig");
const scene = @import("scene.zig");

pub fn main() !void {
    const io = std.Io.Threaded.global_single_threaded.io();
    const frames = try std.Io.Dir.cwd().createFile(io, ".zig-cache/demo.bgra", .{});
    defer frames.close(io);
    const timings = try std.Io.Dir.cwd().createFile(io, ".zig-cache/demo-times.txt", .{});
    defer timings.close(io);
    var buffer: fb.Framebuffer = undefined;
    // 480 cuadros a 15 por segundo: vuelta completa, zoom, altura y comparacion de hilos.
    for (0..480) |index| {
        var camera = Camera{};
        if (index < 180) {
            camera.angle += 2 * std.math.pi * @as(f32, @floatFromInt(index)) / 180;
        } else if (index < 270) {
            const t = @as(f32, @floatFromInt(index - 180)) / 89;
            camera.distance -= 2.5 * @sin(std.math.pi * t);
        } else if (index < 360) {
            const t = @as(f32, @floatFromInt(index - 270)) / 89;
            camera.elevation += 0.6 * @sin(std.math.pi * t);
        } else {
            camera.distance = 6.5;
        }
        const threads = if (index < 420) renderer.defaultThreads() else 1;
        const stats = renderer.render(&buffer, camera, &scene.cubes, threads);
        try frames.writeStreamingAll(io, std.mem.asBytes(&buffer.pixels));
        var line: [80]u8 = undefined;
        try timings.writeStreamingAll(io, try std.fmt.bufPrint(&line, "{d} {d} {d:.2}\n", .{ index, stats.threads, stats.milliseconds }));
        if (index % 60 == 0) std.debug.print("Demo: {d}/480 cuadros\n", .{index});
    }
    std.debug.print("Demo lista en .zig-cache/demo.bgra (320 x 240, BGRA, 15 fps)\n", .{});
}
