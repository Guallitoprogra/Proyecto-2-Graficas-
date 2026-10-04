const Cube = @import("cube.zig").Cube;

// Estos bloques son una escena de prueba; la cabana se construye en el siguiente avance.
pub const cubes = [_]Cube{
    .{ .min = .{ .x = -2.5, .y = -0.5, .z = -2.5 }, .max = .{ .x = 2.5, .y = 0, .z = 2.5 }, .color = .{ .r = 85, .g = 130, .b = 65 } },
    .{ .min = .{ .x = -1, .y = 0, .z = -1 }, .max = .{ .x = 0, .y = 1, .z = 0 }, .color = .{ .r = 155, .g = 100, .b = 55 } },
    .{ .min = .{ .x = 0.3, .y = 0, .z = 0.2 }, .max = .{ .x = 1.3, .y = 1, .z = 1.2 }, .color = .{ .r = 140, .g = 145, .b = 150 } },
    .{ .min = .{ .x = -1, .y = 1, .z = -1 }, .max = .{ .x = 0, .y = 2, .z = 0 }, .color = .{ .r = 180, .g = 115, .b = 60 } },
};
