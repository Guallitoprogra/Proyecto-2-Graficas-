const Vec3 = @import("vector.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const std = @import("std");

pub const Camera = struct {
    angle: f32 = 0.7,
    elevation: f32 = 0.4,
    distance: f32 = 9,
    target: Vec3 = .{ .x = 0, .y = 1, .z = 0 },

    pub fn position(self: Camera) Vec3 {
        const radius = self.distance * @cos(self.elevation);
        return self.target.add(.{
            .x = radius * @sin(self.angle),
            .y = self.distance * @sin(self.elevation),
            .z = radius * @cos(self.angle),
        });
    }

    pub fn move(self: *Camera, rotation: f32, vertical: f32, zoom: f32, seconds: f32) void {
        self.angle = @mod(self.angle + rotation * seconds, 2 * std.math.pi);
        // Evitamos que la camara entre en la cabana o llegue al polo de la orbita.
        self.elevation = std.math.clamp(self.elevation + vertical * seconds, 0.1, 1.2);
        self.distance = std.math.clamp(self.distance + zoom * 4 * seconds, 5, 18);
    }

    pub fn ray(self: Camera, x: usize, y: usize, width: usize, height: usize) Ray {
        const origin = self.position();
        const forward = self.target.sub(origin).normalized();
        const right = forward.cross(.{ .x = 0, .y = 1, .z = 0 }).normalized();
        const up = right.cross(forward);
        const w: f32 = @floatFromInt(width);
        const h: f32 = @floatFromInt(height);
        // Usamos el centro del pixel para que ambos lados de la imagen sean simetricos.
        const sx = (2 * (@as(f32, @floatFromInt(x)) + 0.5) / w - 1) * (w / h) * 0.5773503;
        const sy = (1 - 2 * (@as(f32, @floatFromInt(y)) + 0.5) / h) * 0.5773503;
        return .{ .origin = origin, .direction = forward.add(right.scale(sx)).add(up.scale(sy)).normalized() };
    }
};

test "la orbita mantiene el centro y el zoom tiene limites" {
    var camera = Camera{};
    camera.move(1, 0, 0, 1);
    const offset = camera.position().sub(camera.target);
    try std.testing.expectApproxEqAbs(camera.distance * camera.distance, offset.dot(offset), 0.0001);
    const center = camera.ray(0, 0, 1, 1);
    try std.testing.expectApproxEqAbs(@as(f32, 1), center.direction.dot(camera.target.sub(center.origin).normalized()), 0.0001);
    camera.move(0, 10, -100, 1);
    try std.testing.expectEqual(@as(f32, 5), camera.distance);
    try std.testing.expectEqual(@as(f32, 1.2), camera.elevation);
    camera.move(0, -10, 100, 1);
    try std.testing.expectEqual(@as(f32, 18), camera.distance);
    try std.testing.expectEqual(@as(f32, 0.1), camera.elevation);
}
