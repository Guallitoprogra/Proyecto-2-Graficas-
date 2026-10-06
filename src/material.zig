const Texture = @import("texture.zig").Texture;
const Vec3 = @import("vector.zig").Vec3;

const grass_texture = Texture.read(@embedFile("textures/grass.ppm"));
const wood_texture = Texture.read(@embedFile("textures/wood.ppm"));
const stone_texture = Texture.read(@embedFile("textures/stone.ppm"));
const glass_texture = Texture.read(@embedFile("textures/glass.ppm"));
const metal_texture = Texture.read(@embedFile("textures/metal.ppm"));

pub const Properties = struct {
    texture: *const Texture,
    albedo: Vec3,
    specular: f32,
    shininess: f32,
    transparency: f32,
    reflectivity: f32,
    refractive_index: f32 = 1,
};

pub const Material = enum {
    grass,
    wood,
    stone,
    glass,
    metal,

    pub fn properties(self: Material) Properties {
        return switch (self) {
            .grass => .{ .texture = &grass_texture, .albedo = .{ .x = 0.85, .y = 1, .z = 0.8 }, .specular = 0.02, .shininess = 4, .transparency = 0, .reflectivity = 0 },
            .wood => .{ .texture = &wood_texture, .albedo = .{ .x = 1, .y = 0.9, .z = 0.8 }, .specular = 0.12, .shininess = 16, .transparency = 0, .reflectivity = 0.03 },
            .stone => .{ .texture = &stone_texture, .albedo = .{ .x = 0.9, .y = 0.92, .z = 1 }, .specular = 0.08, .shininess = 8, .transparency = 0, .reflectivity = 0.01 },
            .glass => .{ .texture = &glass_texture, .albedo = .{ .x = 0.75, .y = 0.94, .z = 1 }, .specular = 0.9, .shininess = 96, .transparency = 0.85, .reflectivity = 0.1, .refractive_index = 1.5 },
            .metal => .{ .texture = &metal_texture, .albedo = .{ .x = 0.92, .y = 0.95, .z = 1 }, .specular = 0.8, .shininess = 64, .transparency = 0, .reflectivity = 0.75 },
        };
    }
};
