const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --- Library module declarations (for inter-file @import) ---
    const message_mod = b.createModule(.{
        .root_source_file = b.path("src/message.zig"),
        .target = target,
        .optimize = optimize,
    });

    const transport_mod = b.createModule(.{
        .root_source_file = b.path("src/transport.zig"),
        .target = target,
        .optimize = optimize,
    });
    transport_mod.addImport("message", message_mod);

    const membership_mod = b.createModule(.{
        .root_source_file = b.path("src/membership.zig"),
        .target = target,
        .optimize = optimize,
    });
    membership_mod.addImport("message", message_mod);

    const gossip_mod = b.createModule(.{
        .root_source_file = b.path("src/gossip.zig"),
        .target = target,
        .optimize = optimize,
    });
    gossip_mod.addImport("message", message_mod);
    gossip_mod.addImport("transport", transport_mod);
    gossip_mod.addImport("membership", membership_mod);

    // --- Executable ---
    const exe = b.addExecutable(.{
        .name = "gossip",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("message", message_mod);
    exe.root_module.addImport("transport", transport_mod);
    exe.root_module.addImport("membership", membership_mod);
    exe.root_module.addImport("gossip", gossip_mod);

    b.installArtifact(exe);

    // --- Run step ---
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the gossip node");
    run_step.dependOn(&run_cmd.step);

    // --- Tests ---
    const test_files = [_][]const u8{
        "src/message.zig",
        "src/transport.zig",
        "src/membership.zig",
        "src/gossip.zig",
        "src/main.zig",
    };

    const test_step = b.step("test", "Run unit tests");

    for (test_files) |file| {
        const t = b.addTest(.{
            .root_source_file = b.path(file),
            .target = target,
            .optimize = optimize,
        });
        t.root_module.addImport("message", message_mod);
        t.root_module.addImport("transport", transport_mod);
        t.root_module.addImport("membership", membership_mod);
        t.root_module.addImport("gossip", gossip_mod);

        const run_t = b.addRunArtifact(t);
        test_step.dependOn(&run_t.step);
    }
}
