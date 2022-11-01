// swimp_null - stubbed out driver to aid porting efforts

const c = @cImport({
    @cInclude("ref_soft/r_local.h");
    @cInclude("client/keys.h");
    @cInclude("SDL.h");
});

const std = @import("std");
const video = @import("vid_sdl.zig");
extern var vid: c.viddef_t;
const allocator = std.heap.c_allocator;

const SDL_WINDOWPOS_UNDEFINED = @bitCast(c_int, c.SDL_WINDOWPOS_UNDEFINED_MASK);
var window: *c.SDL_Window = undefined;
var wsurface: [*c]c.SDL_Surface = undefined;
var bsurface: [*c]c.SDL_Surface = undefined;
var rsurface: [*c]c.SDL_Surface = undefined;
var pixel: [*c]c.SDL_Surface = undefined;
export var sw_pixelscale: ?*c.cvar_t = null;


var currentPalette: [256]c.SDL_Color = undefined;

// ========================
// Keyboard input functions
// ========================

extern fn Key_Event( key: c_int, down: bool, time: c_uint ) void;

fn ScanToKey( scancode: c.SDL_Scancode ) u8 {
    var r : u8 = 0;

    r = switch ( scancode ) {
        c.SDL_SCANCODE_ESCAPE => c.K_ESCAPE,
        c.SDL_SCANCODE_1 => '1',
        c.SDL_SCANCODE_2 => '2',
        c.SDL_SCANCODE_3 => '3',
        c.SDL_SCANCODE_4 => '4',
        c.SDL_SCANCODE_5 => '5',
        c.SDL_SCANCODE_6 => '6',
        c.SDL_SCANCODE_7 => '7',
        c.SDL_SCANCODE_8 => '8',
        c.SDL_SCANCODE_9 => '9',
        c.SDL_SCANCODE_0 => '0',
        c.SDL_SCANCODE_MINUS => '-',
        c.SDL_SCANCODE_EQUALS => '=',
        c.SDL_SCANCODE_BACKSPACE => c.K_BACKSPACE,
        c.SDL_SCANCODE_TAB => c.K_TAB,
        c.SDL_SCANCODE_Q => 'q',
        c.SDL_SCANCODE_W => 'w',
        c.SDL_SCANCODE_E => 'e',
        c.SDL_SCANCODE_R => 'r',
        c.SDL_SCANCODE_T => 't',
        c.SDL_SCANCODE_Y => 'y',
        c.SDL_SCANCODE_U => 'u',
        c.SDL_SCANCODE_I => 'i',
        c.SDL_SCANCODE_O => 'o',
        c.SDL_SCANCODE_P => 'p',
        c.SDL_SCANCODE_LEFTBRACKET => '[',
        c.SDL_SCANCODE_RIGHTBRACKET => ']',
        c.SDL_SCANCODE_RETURN => c.K_ENTER,
        c.SDL_SCANCODE_LCTRL => c.K_CTRL,
        c.SDL_SCANCODE_RCTRL => c.K_CTRL,
        c.SDL_SCANCODE_A => 'a',
        c.SDL_SCANCODE_S => 's',
        c.SDL_SCANCODE_D => 'd',
        c.SDL_SCANCODE_F => 'f',
        c.SDL_SCANCODE_G => 'g',
        c.SDL_SCANCODE_H => 'h',
        c.SDL_SCANCODE_J => 'j',
        c.SDL_SCANCODE_K => 'k',
        c.SDL_SCANCODE_L => 'l',
        c.SDL_SCANCODE_SEMICOLON => ';',
        c.SDL_SCANCODE_APOSTROPHE => '\'',
        c.SDL_SCANCODE_GRAVE => '`',
        c.SDL_SCANCODE_LSHIFT => c.K_SHIFT,
        c.SDL_SCANCODE_RSHIFT => c.K_SHIFT,
        c.SDL_SCANCODE_BACKSLASH => '\\',
        c.SDL_SCANCODE_Z => 'z',
        c.SDL_SCANCODE_X => 'x',
        c.SDL_SCANCODE_C => 'c',
        c.SDL_SCANCODE_V => 'v',
        c.SDL_SCANCODE_B => 'b',
        c.SDL_SCANCODE_N => 'n',
        c.SDL_SCANCODE_M => 'm',
        c.SDL_SCANCODE_COMMA => ',',
        c.SDL_SCANCODE_PERIOD => '.',
        c.SDL_SCANCODE_SLASH => '/',
        c.SDL_SCANCODE_KP_MULTIPLY => '*',
        c.SDL_SCANCODE_LALT => c.K_ALT,
        c.SDL_SCANCODE_RALT => c.K_ALT,
        c.SDL_SCANCODE_SPACE => ' ',
        c.SDL_SCANCODE_F1 => c.K_F1,
        c.SDL_SCANCODE_F2 => c.K_F2,
        c.SDL_SCANCODE_F3 => c.K_F3,
        c.SDL_SCANCODE_F4 => c.K_F4,
        c.SDL_SCANCODE_F5 => c.K_F5,
        c.SDL_SCANCODE_F6 => c.K_F6,
        c.SDL_SCANCODE_F7 => c.K_F7,
        c.SDL_SCANCODE_F8 => c.K_F8,
        c.SDL_SCANCODE_F9 => c.K_F9,
        c.SDL_SCANCODE_F10 => c.K_F10,
        c.SDL_SCANCODE_F11 => c.K_F11,
        c.SDL_SCANCODE_F12 => c.K_F12,
        
        c.SDL_SCANCODE_PAUSE => c.K_PAUSE,
        c.SDL_SCANCODE_HOME => c.K_HOME,
        c.SDL_SCANCODE_UP => c.K_UPARROW,
        c.SDL_SCANCODE_PAGEUP => c.K_PGUP,
        c.SDL_SCANCODE_LEFT => c.K_LEFTARROW,
        c.SDL_SCANCODE_RIGHT => c.K_RIGHTARROW,
        c.SDL_SCANCODE_END => c.K_END,
        c.SDL_SCANCODE_DOWN => c.K_DOWNARROW,
        c.SDL_SCANCODE_PAGEDOWN => c.K_PGDN,
        c.SDL_SCANCODE_INSERT => c.K_INS,
        c.SDL_SCANCODE_DELETE => c.K_DEL,
        else => 0,
    };

    return r;
}

pub fn KeyHandler( scancode: c.SDL_Scancode, pressed: bool ) void {
    const key = ScanToKey( scancode );
    Key_Event( key, pressed, 0 );
}

pub fn MouseHandler( button: u8, pressed: bool ) void {
    var code: i32 = switch( button ) {
        c.SDL_BUTTON_LEFT => c.K_MOUSE1,
        c.SDL_BUTTON_RIGHT => c.K_MOUSE2,
        c.SDL_BUTTON_MIDDLE => c.K_MOUSE3,
        c.SDL_BUTTON_X1 => c.K_MOUSE4,
        c.SDL_BUTTON_X2 => c.K_MOUSE5,
        else => 0,
    };
    if ( code != 0 ) {
        Key_Event( code, pressed, 0 );
    }
}

pub fn WheelHandler( wx: i32, wy: i32 ) void {
    if ( wy < 0 ) {
        Key_Event( c.K_MWHEELDOWN, true, 0 );
        Key_Event( c.K_MWHEELDOWN, false, 0 );
    } else if ( wy > 0 ) {
        Key_Event( c.K_MWHEELUP, true, 0 );
        Key_Event( c.K_MWHEELUP, false, 0 );
    }

    if ( wx < 0 ) {
        Key_Event( c.K_MWHEELRIGHT, true, 0 );
        Key_Event( c.K_MWHEELRIGHT, false, 0 );
    } else if ( wx > 0 ) {
        Key_Event( c.K_MWHEELLEFT, true, 0 );
        Key_Event( c.K_MWHEELLEFT, false, 0 );
    }
}


// ========================
// SWimp functions
// ========================

export fn SWimp_AppActivate( active: bool ) void {
    _ = active;
    return;
}

export fn SWimp_BeginFrame(camera_separation: f32) void {
    _ = camera_separation;
    return;
}

export fn SWimp_EndFrame() void {
    var x : usize = 0;
    var y : usize = 0;

    _ = c.SDL_LockSurface(rsurface);

    while ( x < ( vid.width * vid.height ) ) : ( x += 1 ) {
            var colorIndex = vid.buffer[ ( y * @intCast( usize, vid.rowbytes ) ) + x ]; 
            var pixels: [*]u8 = @ptrCast( [*]u8, rsurface.*.pixels );

            pixels[x] = colorIndex;
    }

    //std.mem.copy( u8, vid.buffer[0..(x*y)], @ptrCast( [*]u8, rsurface.*.pixels )[0..(x*y)]);

    c.SDL_UnlockSurface(rsurface);

    //var rect1 = c.SDL_Rect{ .x = 0, .y = 0, .w = @intCast( c_int, vid.width ), .h = @intCast( c_int, vid.height ) };

    if ( c.SDL_BlitSurface( rsurface, 0, bsurface, 0 ) != 0 ) {
        std.debug.print("warning: first blit failed: {s}\n", .{c.SDL_GetError()});
    }
    if ( c.SDL_BlitScaled( bsurface, 0, wsurface, 0 ) != 0 ) {
        std.debug.print("warning: second blit failed: {s}\n", .{c.SDL_GetError()});
    }

    if ( c.SDL_UpdateWindowSurface( window ) != 0 ) {
        std.debug.print("warning: update surface failed\n", .{});
    }
    var e: c.SDL_Event = undefined;
    while ( c.SDL_PollEvent( &e ) != 0 ) {
        if ( e.type == c.SDL_QUIT ) {
            c.exit(1);
        } else if ( e.type == c.SDL_KEYDOWN ) {
            KeyHandler( e.key.keysym.scancode, true );
        } else if ( e.type == c.SDL_KEYUP ) {
            KeyHandler( e.key.keysym.scancode, false );
        } else if ( e.type == c.SDL_MOUSEBUTTONDOWN ) {
            MouseHandler( e.button.button, true );
        } else if ( e.type == c.SDL_MOUSEBUTTONUP ) {
            MouseHandler( e.button.button, false );
        } else if ( e.type == c.SDL_MOUSEWHEEL ) {
            WheelHandler( e.wheel.x, e.wheel.y );
        }
    }
}

pub export fn SWimp_SdlLog( userdata: ?*anyopaque, category: i32, priority: c.SDL_LogPriority, message: ?[*:0]const u8 ) void {
    _ = priority;
    _ = category;
    _ = userdata;
    std.debug.print("[SDL]: {s}\n", .{message.?} );
}


export fn SWimp_Init(hInstance: usize, wndProc: usize) i32 {
    _ = hInstance;
    _ = wndProc;
    std.debug.print("------- SWimp_Init -------\n", .{} );
    c.SDL_LogSetOutputFunction(SWimp_SdlLog, null);
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL video: %s", c.SDL_GetError());
        @panic("no sdl");
        //return 1;
    }

    vid.width = 800;
    vid.height = 600;
    sw_pixelscale = c.Cvar_Get( "sw_pixelscale", "1", c.CVAR_ARCHIVE );
    if ( SWimp_InitGraphics( false ) == false ) {
        std.debug.print("warning: couldn't set graphics mode\n", .{});
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
        _ = c.SDL_SetPaletteColors( rsurface.*.format.*.palette, &currentPalette, 0, 256 );
    }
}

export fn SWimp_InitGraphics( fullscreen: bool ) bool {
    _ = fullscreen;
    var scale: c_int = @floatToInt(c_int, sw_pixelscale.?.value);
    var w = vid.width * scale;
    var h = vid.height * scale;

    std.debug.print("creating window with size {}x{}\n", .{w, h});


    window = c.SDL_CreateWindow( "ztech2", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,  @intCast( c_int, vid.width * scale ),  @intCast( c_int, vid.height * scale), 0 ) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return false;
    };
    wsurface = c.SDL_GetWindowSurface( window );
    if ( wsurface == null )
        return false;
    
    std.debug.print("creating render surface with size {}x{}\n", .{vid.width, vid.height});


    rsurface = c.SDL_CreateRGBSurface( 0,  @intCast( c_int, vid.width ),  @intCast( c_int, vid.height ), 8, 0, 0, 0, 0 );
    if ( rsurface == null )
        return false;

    bsurface = c.SDL_CreateRGBSurface( 0,  @intCast( c_int, vid.width ),  @intCast( c_int, vid.height ), 32, 0, 0, 0, 0 );
    if ( bsurface == null )
        return false;

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
    _ = fullscreen;
    
    if ( video.VID_GetModeInfo( pwidth, pheight, mode ) == false ) {
        std.debug.print("invalid graphics mode selected", .{});
        return c.rserr_invalid_mode;
    }
    std.debug.print("graphics mode selected: {}x{}\n", .{pwidth.*, pheight.*});

    const bufferLen : usize = @intCast( usize, (pwidth.*) * (pheight.*) );
    const bufferSlice = allocator.alloc( u8, bufferLen ) catch unreachable;
    vid.buffer = bufferSlice.ptr;
    vid.rowbytes = @intCast(i32, pwidth.*);
    vid.width = @intCast(i32, pwidth.*);
    vid.height = @intCast(i32, pheight.*);
    SWimp_Shutdown();
    if ( SWimp_InitGraphics( false ) == false ) {
        std.debug.print("couldn't set graphics mode", .{});
        return c.rserr_invalid_mode;
    }

    return c.rserr_ok;
}
