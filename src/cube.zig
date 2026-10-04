const std = @import("std");
const Vec3 = @import("vector.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const Color = @import("framebuffer.zig").Color;

pub const Hit = struct {
    distance: f32,
    normal: Vec3,
};

pub const Cube = struct {
    min: Vec3,
    max: Vec3,
    color: Color,

    pub fn intersect(self: Cube, ray: Ray) ?Hit {
        const origins = [3]f32{ ray.origin.x, ray.origin.y, ray.origin.z };
        const directions = [3]f32{ ray.direction.x, ray.direction.y, ray.direction.z };
        const lower = [3]f32{ self.min.x, self.min.y, self.min.z };
        const upper = [3]f32{ self.max.x, self.max.y, self.max.z };
        const axes = [3]Vec3{ .{ .x = 1, .y = 0, .z = 0 }, .{ .x = 0, .y = 1, .z = 0 }, .{ .x = 0, .y = 0, .z = 1 } };
        var enter: f32 = -std.math.inf(f32);
        var leave: f32 = std.math.inf(f32);
        var enter_normal = axes[0];
        var leave_normal = axes[0];
        for (0..3) |axis| {
            // Un rayo paralelo solo puede cruzar la caja si ya esta entre esas dos caras.
            if (directions[axis] == 0) {
                if (origins[axis] < lower[axis] or origins[axis] > upper[axis]) return null;
                continue;
            }
            const a = (lower[axis] - origins[axis]) / directions[axis];
            const b = (upper[axis] - origins[axis]) / directions[axis];
            const near = @min(a, b);
            const far = @max(a, b);
            const normal = axes[axis].scale(if (directions[axis] > 0) -1 else 1);
            if (near > enter) {
                enter = near;
                enter_normal = normal;
            }
            if (far < leave) {
                leave = far;
                leave_normal = normal.scale(-1);
            }
            if (enter > leave) return null;
        }
        if (leave < 0.001) return null;
        // Desde dentro de la caja necesitamos la cara de salida, no la de entrada.
        return if (enter >= 0.001)
            .{ .distance = enter, .normal = enter_normal }
        else
            .{ .distance = leave, .normal = leave_normal };
    }
};

test "intersecciones desde fuera, dentro, paralelas y detras del rayo" {
    const box = Cube{ .min = .{ .x = -1, .y = -1, .z = -1 }, .max = .{ .x = 1, .y = 1, .z = 1 }, .color = .{ .r = 255, .g = 255, .b = 255 } };
    const forward = Vec3{ .x = 0, .y = 0, .z = -1 };
    const outside = box.intersect(.{ .origin = .{ .x = 0, .y = 0, .z = 3 }, .direction = forward }).?;
    try std.testing.expectEqual(@as(f32, 2), outside.distance);
    try std.testing.expectEqual(@as(f32, 1), outside.normal.z);
    const inside = box.intersect(.{ .origin = .{ .x = 0, .y = 0, .z = 0 }, .direction = forward }).?;
    try std.testing.expectEqual(@as(f32, 1), inside.distance);
    try std.testing.expectEqual(@as(f32, -1), inside.normal.z);
    try std.testing.expect(box.intersect(.{ .origin = .{ .x = 2, .y = 0, .z = 3 }, .direction = forward }) == null);
    try std.testing.expect(box.intersect(.{ .origin = .{ .x = 0, .y = 0, .z = -3 }, .direction = forward }) == null);
}
