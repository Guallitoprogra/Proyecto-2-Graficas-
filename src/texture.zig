const std = @import("std");
const Color = @import("framebuffer.zig").Color;

pub const Texture = struct {
    pixels: [32 * 32]Color,

    pub fn read(comptime source: []const u8) Texture {
        @setEvalBranchQuota(1000000);
        var words = std.mem.tokenizeAny(u8, source, " \r\n\t");
        if (!std.mem.eql(u8, words.next().?, "P3")) @compileError("La textura debe ser PPM P3");
        if (!std.mem.eql(u8, words.next().?, "32") or !std.mem.eql(u8, words.next().?, "32")) @compileError("La textura debe medir 32 x 32");
        if (!std.mem.eql(u8, words.next().?, "255")) @compileError("La textura debe usar canales de 0 a 255");
        var texture: Texture = undefined;
        for (&texture.pixels) |*pixel| {
            pixel.* = .{
                .r = std.fmt.parseInt(u8, words.next().?, 10) catch unreachable,
                .g = std.fmt.parseInt(u8, words.next().?, 10) catch unreachable,
                .b = std.fmt.parseInt(u8, words.next().?, 10) catch unreachable,
            };
        }
        if (words.next() != null) @compileError("Hay pixeles de mas en la textura");
        return texture;
    }

    pub fn sample(self: *const Texture, u: f32, v: f32) Color {
        // Repetimos la textura por cada unidad del mundo, incluso en coordenadas negativas.
        const x: usize = @intFromFloat((u - @floor(u)) * 32);
        const y: usize = @intFromFloat((v - @floor(v)) * 32);
        const row: usize = @min(y, 31);
        const column: usize = @min(x, 31);
        return self.pixels[row * 32 + column];
    }
};

test "la textura se repite a ambos lados del origen" {
    const texture = comptime Texture.read(@embedFile("textures/wood.ppm"));
    try std.testing.expectEqual(texture.sample(0.75, 0.25), texture.sample(-0.25, 1.25));
}
