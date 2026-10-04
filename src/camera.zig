const Vec3 = @import("vector.zig").Vec3;
const Ray = @import("ray.zig").Ray;

pub const Camera = struct {
    position: Vec3 = .{ .x = 5, .y = 3.5, .z = 6 },
    target: Vec3 = .{ .x = 0, .y = 0.5, .z = 0 },

    pub fn ray(self: Camera, x: usize, y: usize, width: usize, height: usize) Ray {
        const forward = self.target.sub(self.position).normalized();
        const right = forward.cross(.{ .x = 0, .y = 1, .z = 0 }).normalized();
        const up = right.cross(forward);
        const w: f32 = @floatFromInt(width);
        const h: f32 = @floatFromInt(height);
        // Usamos el centro del pixel para que ambos lados de la imagen sean simetricos.
        const sx = (2 * (@as(f32, @floatFromInt(x)) + 0.5) / w - 1) * (w / h) * 0.5773503;
        const sy = (1 - 2 * (@as(f32, @floatFromInt(y)) + 0.5) / h) * 0.5773503;
        return .{ .origin = self.position, .direction = forward.add(right.scale(sx)).add(up.scale(sy)).normalized() };
    }
};
