const std = @import("std");
const Vec3 = @import("vector.zig").Vec3;
const Texture = @import("texture.zig").Texture;

const faces = [_]Texture{
    Texture.read(@embedFile("textures/sky/right.ppm")),
    Texture.read(@embedFile("textures/sky/left.ppm")),
    Texture.read(@embedFile("textures/sky/top.ppm")),
    Texture.read(@embedFile("textures/sky/bottom.ppm")),
    Texture.read(@embedFile("textures/sky/front.ppm")),
    Texture.read(@embedFile("textures/sky/back.ppm")),
};

const FacePoint = struct { face: usize, u: f32, v: f32 };

fn coordinates(direction: Vec3) FacePoint {
    const x = @abs(direction.x);
    const y = @abs(direction.y);
    const z = @abs(direction.z);
    if (x == 0 and y == 0 and z == 0) return .{ .face = 2, .u = 0, .v = 0 };
    // La componente mas grande indica cual de las seis caras cruza el rayo.
    if (x >= y and x >= z) {
        return if (direction.x > 0)
            .{ .face = 0, .u = -direction.z / x, .v = -direction.y / x }
        else
            .{ .face = 1, .u = direction.z / x, .v = -direction.y / x };
    }
    if (y >= z) {
        return if (direction.y > 0)
            .{ .face = 2, .u = direction.x / y, .v = direction.z / y }
        else
            .{ .face = 3, .u = direction.x / y, .v = -direction.z / y };
    }
    return if (direction.z > 0)
        .{ .face = 4, .u = direction.x / z, .v = -direction.y / z }
    else
        .{ .face = 5, .u = -direction.x / z, .v = -direction.y / z };
}

pub fn sample(direction: Vec3) Vec3 {
    const point = coordinates(direction);
    const color = faces[point.face].sampleClamped((point.u + 1) * 0.5, (point.v + 1) * 0.5);
    return .{ .x = @floatFromInt(color.r), .y = @floatFromInt(color.g), .z = @floatFromInt(color.b) };
}

test "los seis ejes apuntan al centro de su cara del skybox" {
    const axes = [_]Vec3{ .{ .x = 1, .y = 0, .z = 0 }, .{ .x = -1, .y = 0, .z = 0 }, .{ .x = 0, .y = 1, .z = 0 }, .{ .x = 0, .y = -1, .z = 0 }, .{ .x = 0, .y = 0, .z = 1 }, .{ .x = 0, .y = 0, .z = -1 } };
    for (axes, 0..) |axis, index| {
        const point = coordinates(axis);
        try std.testing.expectEqual(index, point.face);
        try std.testing.expectEqual(@as(f32, 0), point.u);
        try std.testing.expectEqual(@as(f32, 0), point.v);
    }
    const edge = coordinates(.{ .x = 1, .y = -1, .z = -1 });
    try std.testing.expectEqual(faces[0].pixels[1023], faces[0].sampleClamped((edge.u + 1) * 0.5, (edge.v + 1) * 0.5));
}
