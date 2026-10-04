const std = @import("std");

pub fn build(b: *std.Build) void {
    const module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .link_libc = true,
    });
    module.linkSystemLibrary("user32", .{});
    module.linkSystemLibrary("gdi32", .{});
    module.linkSystemLibrary("kernel32", .{});
    const exe = b.addExecutable(.{ .name = "diorama", .root_module = module });
    b.installArtifact(exe);
    const run = b.addRunArtifact(exe);
    run.step.dependOn(b.getInstallStep());
    b.step("run", "Abre el diorama").dependOn(&run.step);
    const tests = b.addTest(.{ .root_module = module });
    const run_tests = b.addRunArtifact(tests);
    b.step("test", "Comprueba los calculos de rayos").dependOn(&run_tests.step);
}
