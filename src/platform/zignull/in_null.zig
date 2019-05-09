// in_null - stubbed out input driver to aid porting efforts

const c = @cImport(@cInclude("client/client.h"));

export fn IN_Init(hInstance: usize, wndProc: usize) i32 {
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