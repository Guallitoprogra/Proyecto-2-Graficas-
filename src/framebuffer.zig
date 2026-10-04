pub const screen_width = 320;
pub const screen_height = 240;

pub const Color = packed struct(u32) {
    b: u8,
    g: u8,
    r: u8,
    a: u8 = 255,
};

pub const Framebuffer = struct {
    pixels: [screen_width * screen_height]Color,

    pub fn point(self: *Framebuffer, x: usize, y: usize, color: Color) void {
        if (x >= screen_width or y >= screen_height) return;
        self.pixels[y * screen_width + x] = color;
    }
};
