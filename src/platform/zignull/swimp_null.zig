// swimp_null - stubbed out driver to aid porting efforts

const c = @cImport({
    @cInclude("ref_soft/r_local.h");
});

const std = @import("std");
extern var vid: c.viddef_t;
const allocator = std.heap.c_allocator;

export fn SWimp_BeginFrame(camera_separation: f32) void {
    _ = camera_separation;
}

export fn SWimp_EndFrame() void {

}

export fn SWimp_Init(hInstance: usize, wndProc: usize) i32 {
    _ = hInstance;
    _ = wndProc;
    return 1;
}

export fn SWimp_SetPalette( opt_pal: ?*[1024]u8 ) void {
    _ = opt_pal;
}

export fn SWimp_InitGraphics( fullscreen: bool ) bool {
    _ = fullscreen;
    return false;
}

export fn SWimp_Shutdown() void {

}

export fn SWimp_SetMode( pwidth: *i32, pheight: *i32, mode: i32, fullscreen: bool ) c.rserr_t {
    _ = pwidth;
    _ = pheight;
    _ = mode;
    _ = fullscreen;
    
    return c.rserr_unknown;
}

export fn SWimp_AppActivate( active: bool ) void {
    _ = active;
}
