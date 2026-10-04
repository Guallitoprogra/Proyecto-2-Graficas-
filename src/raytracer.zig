const std = @import("std");
const fb = @import("framebuffer.zig");
const Vec3 = @import("vector.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const Cube = @import("cube.zig").Cube;
const Camera = @import("camera.zig").Camera;

pub fn trace(ray: Ray, cubes: []const Cube) fb.Color {
    var nearest: f32 = std.math.inf(f32);
    var color = fb.Color{ .r = 100, .g = 155, .b = 210 };
    const light = (Vec3{ .x = -0.5, .y = 1, .z = 0.7 }).normalized();
    for (cubes) |cube| {
        if (cube.intersect(ray)) |hit| {
            if (hit.distance >= nearest) continue;
            nearest = hit.distance;
            // El sombreado inicial permite distinguir las caras; todavia no hay sombras.
            const intensity = 0.25 + 0.75 * @max(0, hit.normal.dot(light));
            color = .{
                .r = @intFromFloat(@as(f32, @floatFromInt(cube.color.r)) * intensity),
                .g = @intFromFloat(@as(f32, @floatFromInt(cube.color.g)) * intensity),
                .b = @intFromFloat(@as(f32, @floatFromInt(cube.color.b)) * intensity),
            };
        }
    }
    return color;
}

pub fn render(buffer: *fb.Framebuffer, camera: Camera, cubes: []const Cube) void {
    for (0..fb.screen_height) |y| {
        for (0..fb.screen_width) |x| {
            buffer.point(x, y, trace(camera.ray(x, y, fb.screen_width, fb.screen_height), cubes));
        }
    }
}

test "el cubo cercano tapa al lejano sin depender del orden" {
    const near = Cube{ .min = .{ .x = -1, .y = -1, .z = 1 }, .max = .{ .x = 1, .y = 1, .z = 2 }, .color = .{ .r = 255, .g = 0, .b = 0 } };
    const far = Cube{ .min = .{ .x = -1, .y = -1, .z = -2 }, .max = .{ .x = 1, .y = 1, .z = -1 }, .color = .{ .r = 0, .g = 255, .b = 0 } };
    const ray = Ray{ .origin = .{ .x = 0, .y = 0, .z = 5 }, .direction = .{ .x = 0, .y = 0, .z = -1 } };
    const first = trace(ray, &.{ near, far });
    const second = trace(ray, &.{ far, near });
    try std.testing.expectEqual(first, second);
    try std.testing.expect(first.r > 0 and first.g == 0);
}
