const Cube = @import("cube.zig").Cube;
const Material = @import("material.zig").Material;

fn block(x: f32, y: f32, z: f32, width: f32, height: f32, depth: f32, material: Material) Cube {
    return .{ .min = .{ .x = x, .y = y, .z = z }, .max = .{ .x = x + width, .y = y + height, .z = z + depth }, .material = material };
}

pub const cubes = [_]Cube{
    block(-3, -0.5, -3, 6, 0.5, 6, .grass),
    block(-1.65, 0, -1.35, 3.3, 0.25, 2.7, .stone),
    block(-1.5, 0.25, -1.2, 3, 0.15, 2.4, .wood),
    // Las paredes dejan huecos reales para la puerta y las ventanas.
    block(-1.5, 0.4, -1.2, 3, 1.9, 0.15, .wood),
    block(-1.5, 0.4, -1.05, 0.15, 1.9, 2.1, .wood),
    block(1.35, 0.4, -1.05, 0.15, 0.6, 2.1, .wood),
    block(1.35, 1.9, -1.05, 0.15, 0.4, 2.1, .wood),
    block(1.35, 1, -1.05, 0.15, 0.9, 0.55, .wood),
    block(1.35, 1, 0.5, 0.15, 0.9, 0.55, .wood),
    block(1.4, 1, -0.5, 0.05, 0.9, 1, .glass),
    block(-1.5, 0.4, 1.05, 1.6, 0.6, 0.15, .wood),
    block(-1.5, 1.9, 1.05, 3, 0.4, 0.15, .wood),
    block(-1.5, 1, 1.05, 0.25, 0.9, 0.15, .wood),
    block(-0.35, 1, 1.05, 0.45, 0.9, 0.15, .wood),
    block(0.95, 0.4, 1.05, 0.55, 1.5, 0.15, .wood),
    block(-1.25, 1, 1.1, 0.9, 0.9, 0.05, .glass),
    block(-0.83, 1, 1.16, 0.06, 0.9, 0.08, .wood),
    block(-1.25, 1.42, 1.16, 0.9, 0.06, 0.08, .wood),
    block(0.14, 0.4, 1.07, 0.77, 1.45, 0.1, .wood),
    block(0.75, 1.05, 1.17, 0.08, 0.08, 0.06, .metal),
    // El techo escalonado mantiene el estilo de cubos del diorama.
    block(-1.8, 2.3, -1.5, 3.6, 0.22, 3, .wood),
    block(-1.4, 2.52, -1.5, 2.8, 0.22, 3, .wood),
    block(-1, 2.74, -1.5, 2, 0.22, 3, .wood),
    block(-0.6, 2.96, -1.5, 1.2, 0.22, 3, .wood),
    block(-0.2, 3.18, -1.5, 0.4, 0.22, 3, .wood),
    block(0.8, 2.5, -0.8, 0.4, 1, 0.4, .stone),
    block(0.75, 3.5, -0.85, 0.5, 0.12, 0.5, .metal),
    block(0, 0, 1.35, 1.05, 0.12, 0.9, .stone),
    block(0, 0.12, 1.35, 1.05, 0.12, 0.6, .stone),
    block(0, 0.24, 1.35, 1.05, 0.12, 0.3, .stone),
    block(1.9, 0, 1.35, 0.55, 0.65, 0.55, .metal),
    block(-2.3, 0, 1.7, 0.65, 0.4, 0.65, .stone),
    block(-2.2, 0.4, 1.8, 0.45, 0.55, 0.45, .glass),
    block(-1, 0.4, -0.65, 0.7, 0.55, 0.65, .stone),
};
