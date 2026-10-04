const Vec3 = @import("vector.zig").Vec3;

pub const Ray = struct {
    origin: Vec3,
    direction: Vec3,

    pub fn at(self: Ray, distance: f32) Vec3 {
        return self.origin.add(self.direction.scale(distance));
    }
};
