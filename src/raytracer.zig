const std = @import("std");
const fb = @import("framebuffer.zig");
const Vec3 = @import("vector.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const cube_file = @import("cube.zig");
const Cube = cube_file.Cube;
const Camera = @import("camera.zig").Camera;
const optics = @import("optics.zig");
const skybox = @import("skybox.zig");

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
    return toColor(traceBounce(ray, cubes, 0));
}

fn secondaryRay(point: Vec3, normal: Vec3, direction: Vec3) Ray {
    const side: f32 = if (direction.dot(normal) >= 0) 1 else -1;
    return .{ .origin = point.add(normal.scale(surface_offset * side)), .direction = direction };
}

fn traceBounce(ray: Ray, cubes: []const Cube, depth: u8) Vec3 {
    const nearest = nearestHit(ray, cubes) orelse return skybox.sample(ray.direction);
    const local = surfaceColor(ray, cubes, nearest);
    if (depth >= 6) return local;
    const cube = cubes[nearest.cube_index];
    const material = cube.material.properties();
    const point = ray.at(nearest.hit.distance);
    const outward = nearest.hit.normal;
    const entering = ray.direction.dot(outward) < 0;
    const normal = if (entering) outward else outward.scale(-1);
    var reflection = material.reflectivity;
    var transmission: f32 = 0;
    var refracted: ?Vec3 = null;
    if (material.transparency > 0) {
        // Al salir del vidrio intercambiamos los indices de aire y vidrio.
        const ratio = if (entering) 1 / material.refractive_index else material.refractive_index;
        refracted = optics.refract(ray.direction, normal, ratio);
        if (refracted != null) {
            reflection += (1 - reflection) * optics.fresnel(-ray.direction.dot(normal), material.refractive_index);
            transmission = material.transparency * (1 - reflection);
        } else {
            reflection = 1;
        }
    }
    var color = local.scale(@max(0, 1 - reflection - transmission));
    if (reflection > 0) {
        const reflected = secondaryRay(point, outward, optics.reflect(ray.direction, normal));
        color = color.add(traceBounce(reflected, cubes, depth + 1).scale(reflection));
    }
    if (refracted) |direction| {
        const transmitted = traceBounce(secondaryRay(point, outward, direction), cubes, depth + 1);
        // Un tinte suave conserva la textura del vidrio sin tapar lo que tiene detras.
        const uv = cube.textureCoordinates(point, outward);
        const texture = material.texture.sample(uv[0], uv[1]);
        const tint = Vec3{
            .x = 0.85 + 0.15 * @as(f32, @floatFromInt(texture.r)) / 255 * material.albedo.x,
            .y = 0.85 + 0.15 * @as(f32, @floatFromInt(texture.g)) / 255 * material.albedo.y,
            .z = 0.85 + 0.15 * @as(f32, @floatFromInt(texture.b)) / 255 * material.albedo.z,
        };
        color = color.add((Vec3{ .x = transmitted.x * tint.x, .y = transmitted.y * tint.y, .z = transmitted.z * tint.z }).scale(transmission));
    }
    return color;
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

test "el metal refleja el objeto fuera del rayo de la camara" {
    const mirror = Cube{ .min = .{ .x = -1, .y = -0.3, .z = -1 }, .max = .{ .x = 1, .y = 0, .z = 1 }, .material = .metal };
    const red = Cube{ .min = .{ .x = 0.3, .y = 0.7, .z = -0.3 }, .max = .{ .x = 0.8, .y = 1.3, .z = 0.3 }, .material = .stone, .color = .{ .r = 255, .g = 0, .b = 0 } };
    var blue = red;
    blue.color = .{ .r = 0, .g = 0, .b = 255 };
    const ray = Ray{ .origin = .{ .x = -0.5, .y = 1, .z = 0 }, .direction = (Vec3{ .x = 0.5, .y = -1, .z = 0 }).normalized() };
    try std.testing.expectEqual(@as(usize, 0), nearestHit(ray, &.{ mirror, red }).?.cube_index);
    const red_reflection = trace(ray, &.{ mirror, red });
    const blue_reflection = trace(ray, &.{ mirror, blue });
    try std.testing.expect(red_reflection.r > blue_reflection.r);
    try std.testing.expect(blue_reflection.b > red_reflection.b);
}

test "el vidrio desvia el rayo al entrar y salir hasta otro objeto" {
    const glass = Cube{ .min = .{ .x = -1, .y = -1, .z = 0 }, .max = .{ .x = 1, .y = 1, .z = 0.5 }, .material = .glass };
    const target = Cube{ .min = .{ .x = 0.5, .y = -0.3, .z = -1.1 }, .max = .{ .x = 0.65, .y = 0.3, .z = -1 }, .material = .grass, .color = .{ .r = 0, .g = 255, .b = 0 } };
    const ray = Ray{ .origin = .{ .x = -2.25, .y = 0, .z = 3 }, .direction = .{ .x = 0.6, .y = 0, .z = -0.8 } };
    try std.testing.expect(nearestHit(ray, &.{target}) == null);
    const through_glass = trace(ray, &.{ glass, target });
    try std.testing.expect(through_glass.g > through_glass.b and through_glass.g > through_glass.r);
}
