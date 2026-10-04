const fb = @import("framebuffer.zig");
const win = @import("window.zig");
const Camera = @import("camera.zig").Camera;
const scene = @import("scene.zig");
const raytracer = @import("raytracer.zig");

pub fn main() !void {
    var buffer: fb.Framebuffer = undefined;
    raytracer.render(&buffer, Camera{}, &scene.cubes);
    var window = try win.Window.open("Proyecto 2 - Diorama");
    while (window.isOpen()) {
        if (win.isKeyDown(0x1B)) break;
        window.draw(&buffer);
        win.waitMilliseconds(16);
    }
}

test {
    @import("std").testing.refAllDecls(@This());
}
