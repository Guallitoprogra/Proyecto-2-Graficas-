const fb = @import("framebuffer.zig");
const win = @import("window.zig");

pub fn main() !void {
    var buffer: fb.Framebuffer = undefined;
    for (0..fb.screen_height) |y| {
        for (0..fb.screen_width) |x| {
            const shade: u8 = @intCast(y / 3);
            buffer.point(x, y, .{ .r = 40 + shade, .g = 80 + shade, .b = 130 + shade });
        }
    }
    var window = try win.Window.open("Proyecto 2 - Diorama");
    while (window.isOpen()) {
        if (win.isKeyDown(0x1B)) break;
        window.draw(&buffer);
        win.waitMilliseconds(16);
    }
}
