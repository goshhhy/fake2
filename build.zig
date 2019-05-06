const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const server = b.addExecutable("q2-server", null);
    const client = b.addExecutable("q2-client", null);
    const game = b.addSharedLibrary("game", null, b.version(0, 3, 18));
    
    server.setBuildMode(mode);
    client.setBuildMode(mode);
    game.setBuildMode(mode);

    //const run_cmd = exe.run();

    const common_sources = [][]const u8 {
        "cmd.o"
    };
    const client_sources = [][]const u8 {
        ""
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

    for (gamelib_sources) |source| {
        game.addCSourceFile(source, [][]const u8{"-std=c99"});
    }
    game.linkSystemLibrary("c");

    //const run_step = b.step("run", "Run the app");
    //run_step.dependOn(&run_cmd.step);

    b.default_step.dependOn(&game.step);
    //b.installArtifact(exe);
}
