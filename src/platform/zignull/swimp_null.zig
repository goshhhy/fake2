// swimp_null - stubbed out driver to aid porting efforts

const c = @cImport(@cInclude("ref_soft/r_local.h"));

export fn SWimp_BeginFrame(camera_separation: f32) void {

}

export fn SWimp_EndFrame() void {

}

export fn SWimp_Init(hInstance: usize, wndProc: usize) i32 {
    return 1;
}

export fn SWimp_SetPalette( pal: [256]u8 ) void {

}

export fn SWimp_Shutdown() void {

}

export fn SWimp_SetMode( pwidth: *i32, pheight: *i32, mode: i32, fullscreen: bool ) c.rserr_t {
    return c.rserr_t.rserr_ok;
}

export fn SWimp_AppActivate( active: bool ) void {

}
