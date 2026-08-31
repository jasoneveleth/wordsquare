const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    // Native binary for testing
    const native_target = b.standardTargetOptions(.{});
    const native_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = native_target,
        .optimize = optimize,
    });
    const native = b.addExecutable(.{ .name = "wordsquare", .root_module = native_mod });
    b.installArtifact(native);

    // WASM module
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });
    const wasm_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = wasm_target,
        .optimize = optimize,
    });
    const wasm = b.addExecutable(.{ .name = "wordsquare", .root_module = wasm_mod });
    wasm.entry = .disabled;
    wasm.rdynamic = true;

    const wasm_install = b.addInstallArtifact(wasm, .{ .dest_dir = .{ .override = .{ .custom = "wasm" } } });
    const wasm_step = b.step("wasm", "Build WASM module");
    wasm_step.dependOn(&wasm_install.step);

    // HTTP server
    const server_mod = b.createModule(.{
        .root_source_file = b.path("src/server.zig"),
        .target = native_target,
        .optimize = optimize,
    });
    const server = b.addExecutable(.{ .name = "wordsquare-server", .root_module = server_mod });
    b.installArtifact(server);
}
