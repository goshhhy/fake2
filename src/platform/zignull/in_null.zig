// in_null - stubbed out input driver to aid porting efforts

const c = @cImport(@cInclude("client/client.h"));

export var in_joystick: [*c]c.cvar_t = undefined;

export fn IN_Init(hInstance: usize, wndProc: usize) i32 {
    _ = hInstance;
    _ = wndProc;

    in_joystick = c.Cvar_Get("in_joystick", "0", c.CVAR_ARCHIVE);
    return 1;
}

export fn IN_Shutdown() void {

}

export fn IN_Commands() void {

}

export fn IN_Frame() void {

}

export fn IN_Move(cmd: [*c]c.usercmd_t) void {
    _ = cmd;
}

export fn IN_Activate(active: bool) void {
    _ = active;
}

export fn IN_ActivateMouse() void {

}

export fn IN_DeactivateMouse() void {

}