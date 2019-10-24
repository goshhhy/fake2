// vid_null -- null video driver to aid porting efforts
// this assumes that one of the refs is statically linked to the executable

const c = @cImport(@cInclude("client/client.h"));
const std = @import("std");

export var viddef: c.viddef_t = undefined;
export var re: c.refexport_t = undefined;

extern fn GetRefAPI (rimp: c.refimport_t) c.refexport_t;

export fn VID_NewWindow (width: c_int, height: c_int) void {
        viddef.width = @intCast( c_uint, width );
        viddef.height = @intCast( c_uint, height );
}

const VidMode = struct {
    desc: []const u8,
    width: i32,
    height: i32,
    mode: i32,
};

const vid_modes = [_]VidMode {
    VidMode { .desc = "Mode 0: 320x240 [4:3]",      .width =  320, .height =  240, .mode =  0 },
    VidMode { .desc = "Mode 1: 400x300 [4:3]",      .width =  400, .height =  300, .mode =  1 },
    VidMode { .desc = "Mode 2: 512x384 [4:3]",      .width =  512, .height =  384, .mode =  2 },
    VidMode { .desc = "Mode 3: 640x480 [4:3]",      .width =  640, .height =  480, .mode =  3 },
    VidMode { .desc = "Mode 4: 800x600 [4:3]",      .width =  800, .height =  600, .mode =  4 },
    VidMode { .desc = "Mode 6: 1024x768 [4:3]",     .width = 1024, .height =  768, .mode =  6 },
    VidMode { .desc = "Mode 8: 1280x960 [4:3]",     .width = 1280, .height =  960, .mode =  8 },
    VidMode { .desc = "Mode 9: 1600x1200 [4:3]",    .width = 1600, .height = 1200, .mode =  9 },
    VidMode { .desc = "Mode 10: 1280x800 [16:10]",  .width = 1280, .height =  800, .mode = 10 },
    VidMode { .desc = "Mode 11: 1440x900 [16:10]",  .width = 1440, .height =  900, .mode = 11 },
    VidMode { .desc = "Mode 12: 1680x1050 [16:10]", .width = 1680, .height = 1050, .mode = 12 },
    VidMode { .desc = "Mode 13: 1920x1200 [16:10]", .width = 1920, .height = 1200, .mode = 13 },
    VidMode { .desc = "Mode 14: 1280x720 [16:9]",   .width = 1280, .height =  720, .mode = 14 },
    VidMode { .desc = "Mode 15: 1366x768 [16:9]",   .width = 1366, .height =  768, .mode = 15 },
    VidMode { .desc = "Mode 16: 1920x1080 [16:9]",  .width = 1920, .height = 1080, .mode = 16 },
};

pub export fn VID_GetModeInfo( width: [*c]c_int, height: [*c]c_int, mode: c_int ) c.qboolean {
    if ( mode < 0 or mode >= 16 ) {
        return false;
    }

    width.* = vid_modes[@intCast(usize, mode)].width;
    height.* = vid_modes[@intCast(usize,mode)].height;

    return true;
}

export fn VID_Shutdown() void {
    if (re.Shutdown) |reShutdown| {
        reShutdown();
    }
}

export fn VID_CheckChanges() void {
}

//export fn VID_MenuInit() void {
//}

//export fn VID_MenuDraw() void {
//}

//export fn VID_MenuKey(k: i32) ?*[]const u8 {
//    return null;
//}
extern fn VID_MenuInit() void;
extern fn VID_MenuDraw() void;
extern fn VID_MenuKey(k: i32) ?*[]const u8;

export fn VID_Init() void {
    return;
}