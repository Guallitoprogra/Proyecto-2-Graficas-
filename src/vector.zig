const std = @import("std");

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn add(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x + b.x, .y = a.y + b.y, .z = a.z + b.z };
    }

    pub fn sub(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }

    pub fn scale(a: Vec3, amount: f32) Vec3 {
        return .{ .x = a.x * amount, .y = a.y * amount, .z = a.z * amount };
    }

    pub fn dot(a: Vec3, b: Vec3) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    pub fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.y * b.z - a.z * b.y, .y = a.z * b.x - a.x * b.z, .z = a.x * b.y - a.y * b.x };
    }

    pub fn normalized(a: Vec3) Vec3 {
        const length = @sqrt(a.dot(a));
        if (length == 0) return a;
        return a.scale(1.0 / length);
    }
};

test "normalizar conserva la direccion y produce longitud uno" {
    const v = (Vec3{ .x = 3, .y = 4, .z = 0 }).normalized();
    try std.testing.expectApproxEqAbs(@as(f32, 1), v.dot(v), 0.0001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.6), v.x, 0.0001);
}
