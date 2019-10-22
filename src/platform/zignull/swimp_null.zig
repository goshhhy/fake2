// swimp_null - stubbed out driver to aid porting efforts

const c = @cImport({
    @cInclude("ref_soft/r_local.h");
});

const std = @import("std");
extern var vid: c.viddef_t;
const allocator = std.heap.c_allocator;

export fn SWimp_BeginFrame(camera_separation: f32) void {

}

export fn SWimp_EndFrame() void {

}

export fn SWimp_Init(hInstance: usize, wndProc: usize) i32 {
    return 1;
}

export fn SWimp_SetPalette( opt_pal: ?*[1024]u8 ) void {

}

export fn SWimp_InitGraphics( fullscreen: bool ) bool {
    return false;
}

export fn SWimp_Shutdown() void {

}

export fn SWimp_SetMode( pwidth: *i32, pheight: *i32, mode: i32, fullscreen: bool ) c.rserr_t {
    return c.rserr_t.rserr_unknown;
}

export fn SWimp_AppActivate( active: bool ) void {

}
