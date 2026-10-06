const fb = @import("framebuffer.zig");
const win = @import("window.zig");
const Camera = @import("camera.zig").Camera;
const scene = @import("scene.zig");
const raytracer = @import("raytracer.zig");

pub fn main() !void {
    var buffer: fb.Framebuffer = undefined;
    var camera = Camera{};
    raytracer.render(&buffer, camera, &scene.cubes);
    var window = try win.Window.open("Diorama | A/D girar | W/S altura | Q/E zoom | R reiniciar");
    var previous = win.nowMilliseconds();
    while (window.isOpen()) {
        if (win.isKeyDown(0x1B)) break;
        const now = win.nowMilliseconds();
        const seconds = @min(@as(f32, @floatFromInt(now - previous)) / 1000, 0.05);
        previous = now;
        const rotation = key('D') - key('A');
        const vertical = key('W') - key('S');
        const zoom = key('E') - key('Q');
        if (rotation != 0 or vertical != 0 or zoom != 0 or win.isKeyDown('R')) {
            camera.move(rotation, vertical, zoom, seconds);
            if (win.isKeyDown('R')) camera = Camera{};
            // Si la vista no cambia, conservamos la imagen en vez de renderizar otra vez.
            raytracer.render(&buffer, camera, &scene.cubes);
        }
        window.draw(&buffer);
        win.waitMilliseconds(16);
    }
}

fn key(code: i32) f32 {
    return if (win.isKeyDown(code)) 1 else 0;
}

test {
    @import("std").testing.refAllDecls(@This());
}
