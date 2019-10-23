// in_null - stubbed out input driver to aid porting efforts

const c = @cImport({
    @cInclude("client/client.h");
    @cInclude("ref_soft/r_local.h");
    @cInclude("client/keys.h");
});

export var in_joystick: [*c]c.cvar_t = undefined;

fn KBD_Init() void {

}

export fn IN_Init(hInstance: usize, wndProc: usize) i32 {
    in_joystick = c.Cvar_Get(c"in_joystick", c"0", c.CVAR_ARCHIVE);
    return 1;
}

export fn IN_Shutdown() void {

}

export fn IN_Commands() void {

}

export fn IN_Frame() void {

}

export fn IN_Move(cmd: [*c]c.usercmd_t) void {

}

export fn IN_Activate(active: bool) void {

}

export fn IN_ActivateMouse() void {

}

export fn IN_DeactivateMouse() void {

}