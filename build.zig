const Builder = @import("std").build.Builder;
const Package = @import("std").build.Pkg;
const std = @import("std");
const builtin = @import("builtin");

const ZigSource = struct {
    name: []const u8,
    path: []const u8,
};

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const client = b.addExecutable("ztech2-client", null);
    const server = b.addExecutable("ztech2-server", null);

    //const target = std.zig.CrossTarget{ .cpu_arch = .aarch64, .os_tag = .macos };
    //client.setTarget(target);

    if ( builtin.os.tag == .macos ) {
        client.addFrameworkDir("/Library/Frameworks");
        client.addIncludePath("/Library/Frameworks/SDL2.framework/Headers");
        client.linkFramework("SDL2");
    } else if ( builtin.os.tag == .linux ) {
        client.linkSystemLibrary("x11");
        client.linkSystemLibrary("wayland-client");
        client.linkSystemLibrary("SDL2");
    } else if ( builtin.os.tag == .windows ) {
        client.linkSystemLibrary("SDL2");
    } else {
        client.linkSystemLibrary("x11");
        client.linkSystemLibrary("SDL2");
    }

    client.addPackagePath("qcommon", "src/qcommon/qcommon.zig");
    server.addPackagePath("qcommon", "src/qcommon/qcommon.zig");
    //const game = b.addSharedLibrary("game", null, b.version(3, 19, 0));

    client.setOutputDir("./");
    server.setOutputDir("./");
    //game.setOutputDir("./");
    
    //client.setDisableGenH(true);
    //server.setDisableGenH(true);

    client.setBuildMode(mode);
    server.setBuildMode(mode);
    //game.setBuildMode(mode);

    const run_cmd = client.run();

    const client_c_sources = [_][]const u8 {
        "src/client/cl_cin.c",
        "src/client/cl_ents.c",
        "src/client/cl_fx.c",
        "src/client/cl_input.c",
        "src/client/cl_main.c",
        "src/client/cl_newfx.c",
        "src/client/cl_parse.c",
        "src/client/cl_pred.c",
        "src/client/cl_tent.c",
        "src/client/cl_scrn.c",
        "src/client/cl_view.c",
        "src/client/console.c",
        "src/client/keys.c",
        "src/client/menu.c",
        "src/client/snd_dma.c",
        "src/client/snd_mem.c",
        "src/client/snd_mix.c",
        "src/client/qmenu.c",
    };

    const shared_c_sources = [_][]const u8 {
        "src/qcommon/cmd.c",
        "src/qcommon/cmodel.c",
        "src/qcommon/common.c",
        "src/qcommon/crc.c",
        "src/qcommon/cvar.c",
        "src/qcommon/files.c",
        "src/qcommon/md4.c",
        "src/qcommon/net_chan.c",
        "src/server/sv_ccmds.c",
        "src/server/sv_ents.c",
        "src/server/sv_game.c",
        "src/server/sv_init.c",
        "src/server/sv_main.c",
        "src/server/sv_send.c",
        "src/server/sv_user.c",
        "src/server/sv_world.c",
        "src/platform/linux/q_shlinux.c",
        "src/platform/linux/glob.c",
        "src/platform/linux/net_udp.c",
        "src/platform/zigsdl/sys_legacy.c",
        "src/game/q_shared.c",
        "src/qcommon/pmove.c",
        "src/game/m_flash.c",
    };
    const client_zig_sources = [_]ZigSource {
        ZigSource { .name = "in", .path = "src/platform/zigsdl/in_sdl.zig" },
        ZigSource { .name = "cd", .path = "src/platform/zignull/cd_null.zig" },
        ZigSource { .name = "snd", .path = "src/platform/zigsdl/snddma_sdl.zig" },
        ZigSource { .name = "swimp", .path = "src/platform/zigsdl/swimp_sdl.zig" },
        ZigSource { .name = "sys", .path = "src/platform/zigsdl/sys_sdl.zig" },

        ZigSource { .name = "cl_inven", .path = "src/client/inven.zig" },
        //ZigSource { .name = "vid", .path = "src/platform/zignull/vid_null.zig" },
    };
    const server_zig_sources = [_]ZigSource {
        ZigSource { .name = "in", .path = "src/platform/zignull/in_null.zig" },
        ZigSource { .name = "cd", .path = "src/platform/zignull/cd_null.zig" },
        ZigSource { .name = "snd", .path = "src/platform/zignull/snddma_null.zig" },
        ZigSource { .name = "swimp_null", .path = "src/platform/zignull/swimp_null.zig" },
        ZigSource { .name = "vid", .path = "src/platform/zignull/vid_null.zig" },
        ZigSource { .name = "vidmenu", .path = "src/platform/zignull/vidmenu_null.zig" },
        ZigSource { .name = "sys", .path = "src/platform/zignull/sys_null.zig" },
        ZigSource { .name = "client", .path = "src/platform/zignull/cl_null.zig" },
    };
    const shared_zig_sources = [_]ZigSource {
        ZigSource { .name = "sv_main", .path = "src/server/sv_main.zig" },
        ZigSource { .name = "sv_game", .path = "src/server/sv_game.zig" },
        //ZigSource { .name = "md4", .path = "src/qcommon/md4.zig" },
    };
    const gamelib_c_sources = [_][]const u8 {
        "src/game/g_ai.c",
        "src/game/p_client.c",
        "src/game/g_cmds.c",
        "src/game/g_chase.c",
        "src/game/g_svcmds.c",
        "src/game/g_combat.c",
        "src/game/g_func.c",
        "src/game/g_items.c",
        "src/game/g_main.c",
        "src/game/g_misc.c",
        "src/game/g_monster.c",
        "src/game/g_phys.c",
        "src/game/g_save.c",
        "src/game/g_spawn.c",
        "src/game/g_target.c",
        "src/game/g_trigger.c",
        "src/game/g_turret.c",
        "src/game/g_utils.c",
        "src/game/g_weapon.c",
        "src/game/m_actor.c",
        "src/game/m_berserk.c",
        "src/game/m_boss2.c",
        "src/game/m_boss3.c",
        "src/game/m_boss31.c",
        "src/game/m_boss32.c",
        "src/game/m_brain.c",
        "src/game/m_chick.c",
        "src/game/m_flipper.c",
        "src/game/m_float.c",
        "src/game/m_flyer.c",
        "src/game/m_gladiator.c",
        "src/game/m_gunner.c",
        "src/game/m_hover.c",
        "src/game/m_infantry.c",
        "src/game/m_insane.c",
        "src/game/m_medic.c",
        "src/game/m_move.c",
        "src/game/m_mutant.c",
        "src/game/m_parasite.c",
        "src/game/m_soldier.c",
        "src/game/m_supertank.c",
        "src/game/m_tank.c",
        "src/game/p_hud.c",
        "src/game/p_trail.c",
        "src/game/p_view.c",
        "src/game/p_weapon.c",
        //"src/game/q_shared.c",
        //"src/game/m_flash.c",
    };
    const ref_sdl_c_sources = [_][]const u8 {
        "src/ref_soft/r_aclip.c",
        "src/ref_soft/r_alias.c",
        "src/ref_soft/r_bsp.c",
        "src/ref_soft/r_draw.c",
        "src/ref_soft/r_edge.c",
        "src/ref_soft/r_image.c",
        "src/ref_soft/r_light.c",
        "src/ref_soft/r_main.c",
        "src/ref_soft/r_misc.c",
        "src/ref_soft/r_model.c",
        "src/ref_soft/r_part.c",
        "src/ref_soft/r_poly.c",
        "src/ref_soft/r_polyse.c",
        "src/ref_soft/r_rast.c",
        "src/ref_soft/r_scan.c",
        "src/ref_soft/r_sprite.c",
        "src/ref_soft/r_surf.c",
    };

    for (client_c_sources) |source| {
        client.addCSourceFile(source, &[_][]const u8 {"-std=c99", "-g", "-Og", "-fno-sanitize=undefined", "-fno-sanitize-trap=undefined"});
    }
    for (shared_c_sources) |source| {
        client.addCSourceFile(source, &[_][]const u8{"-std=c99", "-g", "-Og", "-fno-sanitize=undefined", "-fno-sanitize-trap=undefined"});
        server.addCSourceFile(source, &[_][]const u8{"-std=c99", "-g", "-Og", "-DDEDICATED_ONLY", "-fno-sanitize=undefined", "-fno-sanitize-trap=undefined"});
    }
    for (gamelib_c_sources) |source| {
        client.addCSourceFile(source, &[_][]const u8{"-std=c99", "-g", "-Og", "-DGAME_HARD_LINKED", "-fno-sanitize=undefined", "-fno-sanitize-trap=undefined"});
        server.addCSourceFile(source, &[_][]const u8{"-std=c99", "-g", "-Og", "-DGAME_HARD_LINKED", "-DDEDICATED_ONLY", "-fno-sanitize=undefined", "-fno-sanitize-trap=undefined"});
        //game.addCSourceFile(source, &[_][]const u8{"-std=c99", "-g"});
    }
    for (ref_sdl_c_sources) |source| {
        client.addCSourceFile(source, &[_][]const u8{"-std=c99", "-g", "-Og", "-DREF_HARD_LINKED", "-fno-sanitize=undefined", "-fno-sanitize-trap=undefined"});
        //ref_sdl.addCSourceFile(source, &[_][]const u8{"-std=c99", "-g"});
    }

    // add zig sources for client
    for (client_zig_sources) |source| {
        const obj = b.addObject(source.name, source.path);
        obj.linkLibC();

        obj.addPackagePath("qcommon", "src/qcommon/qcommon.zig");

        if ( builtin.os.tag == .macos ) {
            obj.addFrameworkDir("/Library/Frameworks");
            obj.addIncludePath("/Library/Frameworks/SDL2.framework/Headers");
            obj.linkFramework("SDL2");
        } else if ( builtin.os.tag == .linux ) {
            obj.linkSystemLibrary("wayland-client");
            obj.linkSystemLibrary("SDL2");
        }

        obj.addIncludePath("./src/");
        //obj.setDisableGenH(true);
        client.addObject(obj);
    }

    for (server_zig_sources) |source| {
        const obj = b.addObject(source.name, source.path);
        obj.linkLibC();
        obj.addIncludePath("./src/");

        obj.addPackagePath("qcommon", "src/qcommon/qcommon.zig");
        //obj.setDisableGenH(true);
        server.addObject(obj);
    }

    for (shared_zig_sources) |source| {
        const obj = b.addObject(source.name, source.path);
        obj.linkLibC();
        obj.addIncludePath("./src/");
        //obj.setDisableGenH(true);

        obj.addPackagePath("qcommon", "src/qcommon/qcommon.zig");

        client.addObject(obj);
        server.addObject(obj);
    }

    client.linkLibC();
    server.linkLibC();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    b.default_step.dependOn(&client.step);
    b.default_step.dependOn(&server.step);
    //b.default_step.dependOn(&game.step);
    //b.installArtifact(exe);
}
