
// cl_null.c -- this file can stub out the entire client system
// for pure dedicated servers

const c = @cImport({
    @cInclude("../qcommon/qcommon.h");
    @cInclude("SDL2/SDL.h");
});

fn Key_Bind_Null_f() void {
}

fn CL_Init () void {
}

fn CL_Drop () void {
}

fn CL_Shutdown () void {
}

fn CL_Frame (int msec) void {
}

fn Con_Print (char *text) void {
}

fn Cmd_ForwardToServer () void
{
	char *cmd;

	cmd = Cmd_Argv(0);
	Com_Printf ("Unknown command \"%s\"\n", cmd);
}

fn SCR_DebugGraph (float value, int color) void {
}

fn SCR_BeginLoadingPlaque () void {
}

fn SCR_EndLoadingPlaque () void {
}

fn Key_Init () void {
	c.Cmd_AddCommand (c"bind", Key_Bind_Null_f);
}

