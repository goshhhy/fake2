
// cl_null.c -- this file can stub out the entire client system
// for pure dedicated servers

const c = @cImport({
    @cInclude("qcommon/qcommon.h");
});

export fn Key_Bind_Null_f() void {
}

export fn CL_Init () void {
}

export fn CL_Drop () void {
}

export fn CL_Shutdown () void {
}

export fn CL_Frame (msec: c_int) void {
}

export fn Con_Print (text: [*]const u8 ) void {
}

export fn Cmd_ForwardToServer () void
{
    var cmd: [*]u8 = c.Cmd_Argv( 0 );
    c.Com_Printf( "Unknown command \"%s\"\n", cmd );
}

export fn SCR_DebugGraph (value: f32, color: c_int) void {
}

export fn SCR_BeginLoadingPlaque () void {
}

export fn SCR_EndLoadingPlaque () void {
}

export fn Key_Init () void {
    c.Cmd_AddCommand ("bind", Key_Bind_Null_f);
}

