const std = @import("std");
const fb = @import("framebuffer.zig");
const Vec3 = @import("vector.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const cube_file = @import("cube.zig");
const Cube = cube_file.Cube;
const Camera = @import("camera.zig").Camera;

const light_direction = (Vec3{ .x = -0.5, .y = 1, .z = 0.7 }).normalized();
const surface_offset = 0.002;

const SceneHit = struct {
    cube_index: usize,
    hit: cube_file.Hit,
};

fn nearestHit(ray: Ray, cubes: []const Cube) ?SceneHit {
    var nearest: f32 = std.math.inf(f32);
    var result: ?SceneHit = null;
    for (cubes, 0..) |cube, index| {
        if (cube.intersect(ray)) |hit| {
            if (hit.distance >= nearest) continue;
            nearest = hit.distance;
            result = .{ .cube_index = index, .hit = hit };
        }
    }
    return result;
}

fn shadowVisibility(point: Vec3, normal: Vec3, cubes: []const Cube) f32 {
    // Movemos el origen para que la superficie no se haga sombra a si misma.
    const ray = Ray{ .origin = point.add(normal.scale(surface_offset)), .direction = light_direction };
    var visibility: f32 = 1;
    for (cubes) |cube| {
        if (cube.intersect(ray) != null) {
            visibility *= cube.material.properties().transparency;
            if (visibility == 0) return 0;
        }
    }
    return visibility;
}

fn surfaceColor(ray: Ray, cubes: []const Cube, nearest: SceneHit) Vec3 {
    const cube = cubes[nearest.cube_index];
    const hit = nearest.hit;
    const point = ray.at(hit.distance);
    const material = cube.material.properties();
    const uv = cube.textureCoordinates(point, hit.normal);
    const texture = material.texture.sample(uv[0], uv[1]);
    const base = Vec3{
        .x = @as(f32, @floatFromInt(texture.r)) * @as(f32, @floatFromInt(cube.color.r)) / 255 * material.albedo.x,
        .y = @as(f32, @floatFromInt(texture.g)) * @as(f32, @floatFromInt(cube.color.g)) / 255 * material.albedo.y,
        .z = @as(f32, @floatFromInt(texture.b)) * @as(f32, @floatFromInt(cube.color.b)) / 255 * material.albedo.z,
    };
    const diffuse = @max(0, hit.normal.dot(light_direction));
    const visibility = if (diffuse > 0) shadowVisibility(point, hit.normal, cubes) else 0;
    const halfway = light_direction.sub(ray.direction).normalized();
    const specular = if (diffuse > 0)
        material.specular * std.math.pow(f32, @max(0, hit.normal.dot(halfway)), material.shininess) * visibility
    else
        0;
    // La luz ambiente permite reconocer los detalles que quedan en sombra.
    return base.scale(0.2 + 0.8 * diffuse * visibility).add((Vec3{ .x = 255, .y = 245, .z = 225 }).scale(specular));
}

pub fn trace(ray: Ray, cubes: []const Cube) fb.Color {
    const hit = nearestHit(ray, cubes) orelse return .{ .r = 100, .g = 155, .b = 210 };
    return toColor(surfaceColor(ray, cubes, hit));
}

fn toColor(color: Vec3) fb.Color {
    return .{
        .r = @intFromFloat(std.math.clamp(color.x, 0, 255)),
        .g = @intFromFloat(std.math.clamp(color.y, 0, 255)),
        .b = @intFromFloat(std.math.clamp(color.z, 0, 255)),
    };
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
    try std.testing.expect(first.r > first.g);
}

test "un objeto entre la superficie y la luz reduce su iluminacion" {
    const floor = Cube{ .min = .{ .x = -2, .y = -1, .z = -2 }, .max = .{ .x = 2, .y = 0, .z = 2 }, .material = .stone };
    const blocker = Cube{ .min = .{ .x = -0.6, .y = 0.5, .z = 0.1 }, .max = .{ .x = -0.1, .y = 1, .z = 0.8 }, .material = .wood };
    const ray = Ray{ .origin = .{ .x = 0, .y = 2, .z = 0 }, .direction = .{ .x = 0, .y = -1, .z = 0 } };
    const lit = trace(ray, &.{floor});
    const shaded = trace(ray, &.{ floor, blocker });
    try std.testing.expect(shaded.r < lit.r and shaded.g < lit.g and shaded.b < lit.b);
    const point = Vec3{ .x = 0, .y = 0, .z = 0 };
    const normal = Vec3{ .x = 0, .y = 1, .z = 0 };
    try std.testing.expectEqual(@as(f32, 1), shadowVisibility(point, normal, &.{floor}));
    var glass = blocker;
    glass.material = .glass;
    const transmission = shadowVisibility(point, normal, &.{ floor, glass });
    try std.testing.expect(transmission > 0 and transmission < 1);
}
