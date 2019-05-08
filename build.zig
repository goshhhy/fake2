const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const server = b.addExecutable("q2-server", null);
    const client = b.addExecutable("q2-client", null);
    const game = b.addSharedLibrary("game", null, b.version(3, 19, 0));
    const ref_gl = b.addSharedLibrary("ref_gl", null, b.version(3, 19, 0));
    const ref_soft = b.addSharedLibrary("ref_soft", null, b.version(3, 19, 0));
    const ref_sdl = b.addSharedLibrary("ref_sdl", null, b.version(3, 19, 0));


    server.setBuildMode(mode);
    client.setBuildMode(mode);
    game.setBuildMode(mode);

    //const run_cmd = exe.run();

    const common_c_sources = [][]const u8 {
        "cmd.o"
    };
    const client_c_sources = [][]const u8 {
        "src/client/cl_cin.c",
        "src/client/cl_ents.c",
        "src/client/cl_fx.c",
        "src/client/cl_input.c",
        "src/client/cl_inv.c",
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
        "src/game/m_flash.c",
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
        "src/platform/linux/cd_linux.c",
        "src/platform/linux/vid_menu.c",
        "src/platform/linux/vid_so.c",
        //"src/linux/snd_linux.c",
        "src/platform/null/snddma_null.c",
        "src/platform/linux/sys_linux.c",
        "src/platform/linux/q_shlinux.c",
        "src/platform/linux/glob.c",
        "src/platform/linux/net_udp.c",
        "src/game/q_shared.c",
        "src/qcommon/pmove.c",
    };
    const server_c_sources = [][]const u8 {

    };
    const gamelib_c_sources = [][]const u8 {
        "src/game/g_ai.c",
        "src/game/p_client.c",
        "src/game/g_cmds.c",
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
        "src/game/q_shared.c",
        "src/game/m_flash.c",
    };
    const ref_gl_c_sources = [][]const u8 {
        "src/ref_gl/gl_draw.c",
        "src/ref_gl/gl_image.c",
        "src/ref_gl/gl_light.c",
        "src/ref_gl/gl_mesh.c",
        "src/ref_gl/gl_model.c",
        "src/ref_gl/gl_rmain.c",
        "src/ref_gl/gl_rmisc.c",
        "src/ref_gl/gl_rsurf.c",
        "src/ref_gl/gl_warp.c",
        "src/platform/linux/qgl_linux.c",
        //"src/linux/gl_fxmesa.c",
        //"src/ref_gl/rw_in_svgalib.c",
        "src/game/q_shared.c",
        "src/platform/linux/q_shlinux.c",
        "src/platform/linux/glob.c"
    };
    const ref_soft_c_sources = [][]const u8 {
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
        "src/game/q_shared.c",
        "src/platform/linux/rw_x11.c",
        "src/platform/linux/q_shlinux.c",
        "src/platform/linux/glob.c",
    };

    const ref_sdl_c_sources = [][]const u8 {
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
        "src/game/q_shared.c",
        "src/platform/linux/q_shlinux.c",
        "src/platform/linux/glob.c",
    };
    const ref_sdl_zig_sources = [][]const u8 {
        "src/platform/zignull/swimp_null.zig"
    };

    for (client_c_sources) |source| {
        client.addCSourceFile(source, [][]const u8{"-std=c99"});
    }
    for (gamelib_c_sources) |source| {
        game.addCSourceFile(source, [][]const u8{"-std=c99"});
    }
    for (ref_gl_c_sources) |source| {
        ref_gl.addCSourceFile(source, [][]const u8{"-std=c99"});
    }
    for (ref_soft_c_sources) |source| {
        ref_soft.addCSourceFile(source, [][]const u8{"-std=c99"});
    }
    for (ref_sdl_c_sources) |source| {
        ref_sdl.addCSourceFile(source, [][]const u8{"-std=c99"});
    }
    for (ref_sdl_zig_sources) |source| {
        const obj = b.addObject(source, source);
        obj.linkSystemLibrary("c");
        obj.addIncludeDir("./src/");
        ref_sdl.addObject(obj);
    }


    client.linkSystemLibrary("c");
    game.linkSystemLibrary("c");
    ref_gl.linkSystemLibrary("c");
    ref_gl.linkSystemLibrary("GL");
    ref_gl.linkSystemLibrary("GLU");
    ref_soft.linkSystemLibrary("c");
    ref_soft.linkSystemLibrary("X11");
    ref_sdl.linkSystemLibrary("c");
    ref_sdl.linkSystemLibrary("X11");
    ref_sdl.linkSystemLibrary("SDL2");

    //const run_step = b.step("run", "Run the app");
    //run_step.dependOn(&run_cmd.step);

    b.default_step.dependOn(&client.step);
    b.default_step.dependOn(&game.step);
    b.default_step.dependOn(&ref_gl.step);
    b.default_step.dependOn(&ref_soft.step);
    b.default_step.dependOn(&ref_sdl.step);
    //b.installArtifact(exe);
}
