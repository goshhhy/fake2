// swimp_null - stubbed out driver to aid porting efforts

const c = @cImport({
    @cInclude("allegro5/allegro.h");
    @cInclude("ref_soft/r_local.h");
    @cInclude("client/keys.h");
});

const std = @import("std");
const video = @import("vid_allegro.zig");
extern var vid: c.viddef_t;
const allocator = std.heap.c_allocator;

const SDL_WINDOWPOS_UNDEFINED = @bitCast(c_int, c.SDL_WINDOWPOS_UNDEFINED_MASK);
var window: *c.SDL_Window = undefined;
var wsurface: [*c]c.SDL_Surface = undefined;
var rsurface: [*c]c.SDL_Surface = undefined;
var pixel: [*c]c.SDL_Surface = undefined;

var currentPalette: [256]c.SDL_Color = undefined;

// ========================
// Keyboard input functions
// ========================

extern fn Key_Event( key: c_int, down: bool, time: c_uint ) void;

fn ScanToKey( scancode: c.SDL_Scancode ) u8 {
    var r : u8 = 0;

    r = switch ( scancode ) {
        else => 0,
    };

    return r;
}

pub fn KeyHandler( scancode: c.SDL_Scancode, pressed: bool ) void {
    const key = ScanToKey( scancode );
    Key_Event( key, pressed, 0 );
}

// ========================
// SWimp functions
// ========================

export fn SWimp_AppActivate( active: bool ) void {
    return;
}

export fn SWimp_BeginFrame(camera_separation: f32) void {
    return;
}

export fn SWimp_EndFrame() void {
    var x : usize = 0;
    var y : usize = 0;

    while ( y < @intCast( usize, vid.height ) ) {
        //std.debug.warn("\n{}:  ", y );
        while ( x < @intCast( usize, vid.width ) ) {
            //std.debug.warn("{} ", x );
            var colorIndex = vid.buffer[ ( y * @intCast( usize, vid.rowbytes ) ) + x ]; 
            var color = currentPalette[colorIndex];
            var rect = c.SDL_Rect{ .x = 0, .y = 0, .w = 1, .h = 1 };
            if ( c.SDL_FillRect(pixel, &rect, c.SDL_MapRGB(pixel.*.format, color.r, color.g, color.b) ) != 0 ) {
                 std.debug.warn("fill failed", .{});               
            }

            var dest = c.SDL_Rect{ .x = @intCast( c_int, x ), .y = @intCast( c_int, y ), .w = 1, .h = 1 };
            if ( c.SDL_BlitSurface( pixel, &rect, rsurface, &dest ) != 0 ) {
                std.debug.warn("blit failed", .{});
            }        
            x = x + 1;
        }
        x = 0;
        y = y + 1;
    }

    var rect1 = c.SDL_Rect{ .x = 0, .y = 0, .w = @intCast( c_int, vid.width ), .h = @intCast( c_int, vid.height ) };
    if ( c.SDL_BlitScaled( rsurface, 0, wsurface, 0 ) != 0 ) {
        std.debug.warn("warning: blit surface failed\n", .{});
    }

    if ( c.SDL_UpdateWindowSurface( window ) != 0 ) {
        std.debug.warn("warning: update surface failed\n", .{});
    }
    var e: c.SDL_Event = undefined;
    while ( c.SDL_PollEvent( &e ) != 0 ) {
        if ( e.type == c.SDL_QUIT ) {
            c.exit(1);
        } else if ( e.type == c.SDL_KEYDOWN ) {
            KeyHandler( e.key.keysym.scancode, true );
        } else if ( e.type == c.SDL_KEYUP ) {
            KeyHandler( e.key.keysym.scancode, false );
        }
    }
}

pub export fn SWimp_SdlLog( userdata: ?*c_void, category: i32, priority: c.SDL_LogPriority, message: ?[*:0]const u8 ) void {
    std.debug.warn("[SDL]: {}\n", .{message} );
}


export fn SWimp_Init(hInstance: usize, wndProc: usize) i32 {
    std.debug.warn("------- SWimp_Init -------\n", .{} );
    c.SDL_LogSetOutputFunction(SWimp_SdlLog, null);
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        @panic("no sdl");
    }

    vid.width = 800;
    vid.height = 600;
    if ( SWimp_InitGraphics( false ) == false ) {
        std.debug.warn("warning: couldn't set graphics mode\n", .{});
    }
    return 0;
}

export fn SWimp_SetPalette( opt_pal: ?*[1024]u8 ) void {
    if ( opt_pal ) | pal | {
        for ( currentPalette ) | *color, i | {
            color.*.r = pal[ ( i * 4 ) + 0 ];
            color.*.g = pal[ ( i * 4 ) + 1 ];
            color.*.b = pal[ ( i * 4 ) + 2 ];
            color.*.a = 255;
        }
    }
}

export fn SWimp_InitGraphics( fullscreen: bool ) bool {
    std.debug.warn("creating window with size {}x{}\n", .{vid.width, vid.height});

    window = c.SDL_CreateWindow( "fake2", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,  @intCast( c_int, vid.width ),  @intCast( c_int, vid.height ), 0 ) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return false;
    };
    wsurface = c.SDL_GetWindowSurface( window );
    rsurface = c.SDL_CreateRGBSurface( 0,  @intCast( c_int, vid.width ),  @intCast( c_int, vid.height ), 32, 0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000 );
    pixel = c.SDL_CreateRGBSurface( 0, 1, 1, 32, 0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000 );
    video.VID_NewWindow ( @intCast( c_int, vid.width ),  @intCast( c_int, vid.height ) );
    return true;
}

export fn SWimp_Shutdown() void {
    if ( window != undefined ) {
        c.SDL_DestroyWindow( window );
    }
    c.SDL_FreeSurface( rsurface );
    c.SDL_FreeSurface( pixel );
}


export fn SWimp_SetMode( pwidth: *u32, pheight: *u32, mode: usize, fullscreen: bool ) c.rserr_t {
    if ( video.VID_GetModeInfo( pwidth, pheight, mode ) == false ) {
        std.debug.warn("invalid graphics mode selected", .{});
        return c.rserr_t.rserr_invalid_mode;
    }
    std.debug.warn("graphics mode selected: {}x{}\n", .{pwidth.*, pheight.*});

    const bufferLen : usize = @intCast( usize, (pwidth.*) * (pheight.*) );
    const bufferSlice = allocator.alloc( u8, bufferLen ) catch unreachable;
    vid.buffer = bufferSlice.ptr;
    vid.rowbytes = pwidth.*;
    vid.width = pwidth.*;
    vid.height = pheight.*;
    SWimp_Shutdown();
    if ( SWimp_InitGraphics( false ) == false ) {
        std.debug.warn("couldn't set graphics mode", .{});
        return c.rserr_t.rserr_invalid_mode;
    }

    return c.rserr_t.rserr_ok;
}
