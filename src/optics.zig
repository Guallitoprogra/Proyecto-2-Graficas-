const std = @import("std");
const Vec3 = @import("vector.zig").Vec3;

pub fn reflect(direction: Vec3, normal: Vec3) Vec3 {
    return direction.sub(normal.scale(2 * direction.dot(normal))).normalized();
}

pub fn refract(direction: Vec3, normal: Vec3, ratio: f32) ?Vec3 {
    const cosine = std.math.clamp(-direction.dot(normal), 0, 1);
    const sine_squared = ratio * ratio * (1 - cosine * cosine);
    // Si el angulo de salida es demasiado grande, toda la luz se refleja dentro del vidrio.
    if (sine_squared > 1) return null;
    return direction.scale(ratio).add(normal.scale(ratio * cosine - @sqrt(1 - sine_squared))).normalized();
}

pub fn fresnel(cosine: f32, index: f32) f32 {
    const r = (1 - index) / (1 + index);
    const base = r * r;
    const grazing = 1 - std.math.clamp(cosine, 0, 1);
    return base + (1 - base) * grazing * grazing * grazing * grazing * grazing;
}

test "reflexion conserva el angulo y refraccion sigue la ley de Snell" {
    const direction = Vec3{ .x = 0.6, .y = -0.8, .z = 0 };
    const normal = Vec3{ .x = 0, .y = 1, .z = 0 };
    const reflected = reflect(direction, normal);
    try std.testing.expectApproxEqAbs(@as(f32, 0.6), reflected.x, 0.0001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.8), reflected.y, 0.0001);
    const transmitted = refract(direction, normal, 1.0 / 1.5).?;
    try std.testing.expectApproxEqAbs(@as(f32, 0.4), transmitted.x, 0.0001);
    try std.testing.expectApproxEqAbs(@as(f32, 1), transmitted.dot(transmitted), 0.0001);
    const normal_ray = refract(.{ .x = 0, .y = -1, .z = 0 }, normal, 1.0 / 1.5).?;
    try std.testing.expectApproxEqAbs(@as(f32, -1), normal_ray.y, 0.0001);
    try std.testing.expect(refract(.{ .x = 0.8, .y = -0.6, .z = 0 }, normal, 1.5) == null);
    try std.testing.expect(fresnel(0, 1.5) > fresnel(1, 1.5));
}
