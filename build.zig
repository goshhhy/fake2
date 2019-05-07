const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const server = b.addExecutable("q2-server", null);
    const client = b.addExecutable("q2-client", null);
    const game = b.addSharedLibrary("game", null, b.version(3, 19, 0));
    const ref_gl = b.addSharedLibrary("ref_gl", null, b.version(3, 19, 0));

    server.setBuildMode(mode);
    client.setBuildMode(mode);
    game.setBuildMode(mode);

    //const run_cmd = exe.run();

    const common_sources = [][]const u8 {
        "cmd.o"
    };
    const client_sources = [][]const u8 {
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
    const server_sources = [][]const u8 {

    };
    const gamelib_sources = [][]const u8 {
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
    const ref_gl_sources = [][]const u8 {
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
    for (client_sources) |source| {
        client.addCSourceFile(source, [][]const u8{"-std=c99"});
    }
    for (gamelib_sources) |source| {
        game.addCSourceFile(source, [][]const u8{"-std=c99"});
    }
    for (ref_gl_sources) |source| {
        ref_gl.addCSourceFile(source, [][]const u8{"-std=c99"});
    }
    client.linkSystemLibrary("c");
    game.linkSystemLibrary("c");
    ref_gl.linkSystemLibrary("c");
    ref_gl.linkSystemLibrary("GL");
    ref_gl.linkSystemLibrary("GLU");

    //const run_step = b.step("run", "Run the app");
    //run_step.dependOn(&run_cmd.step);

    b.default_step.dependOn(&client.step);
    b.default_step.dependOn(&game.step);
    b.default_step.dependOn(&ref_gl.step);
    //b.installArtifact(exe);
}
