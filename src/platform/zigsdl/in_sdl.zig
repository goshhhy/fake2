// in_null - stubbed out input driver to aid porting efforts

const c = @cImport({
    @cInclude("client/client.h");
    @cInclude("SDL.h");
});

export var in_joystick: [*c]c.cvar_t = undefined;
extern var sensitivity: *c.cvar_t;

var mouse_active: bool = false;

export fn IN_Init(hInstance: usize, wndProc: usize) i32 {
    in_joystick = c.Cvar_Get("in_joystick", "0", c.CVAR_ARCHIVE);
    IN_Activate(true);
    return 1;
}

export fn IN_Shutdown() void {
    IN_Activate(false);
}

export fn IN_Commands() void {

}

export fn IN_Frame() void {

}

export fn IN_Move(cmd: [*c]c.usercmd_t) void {
    var mx: i32 = 0;
    var my: i32 = 0;
    var buttons: u32 = c.SDL_GetRelativeMouseState( &mx, &my );

    mx = mx * @floatToInt(i32, sensitivity.value);
    my = my * @floatToInt(i32, sensitivity.value);

    c.cl.viewangles[c.YAW] -= c.m_yaw.*.value * @intToFloat(f32, mx);
    c.cl.viewangles[c.PITCH] += c.m_pitch.*.value * @intToFloat(f32, my);

    if ( ( buttons & c.SDL_BUTTON_LMASK ) != 0 ) {
        
    }
}

export fn IN_Activate(active: bool) void {
    mouse_active = active;
    if ( active ) {
        IN_ActivateMouse();
    } else {
        IN_DeactivateMouse();
    }
}

export fn IN_ActivateMouse() void {
    _ = c.SDL_SetRelativeMouseMode(@intToEnum( c.SDL_bool, c.SDL_TRUE ));
}

export fn IN_DeactivateMouse() void {
    _ = c.SDL_SetRelativeMouseMode(@intToEnum( c.SDL_bool, c.SDL_FALSE ));
}
