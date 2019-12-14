const c = @cImport({
    @cInclude("server/server.h");
});

export var ge: ?*c.game_export_t = null;

// called when server is being killed or
// game has been changed
pub export fn SV_ShutdownGameProgs() void {
    if ( ge == null )
        return;
    ge.?.Shutdown.?();
    c.Sys_UnloadGame();
    ge = null;
}