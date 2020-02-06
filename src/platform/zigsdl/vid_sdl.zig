// vid_null -- null video driver to aid porting efforts
// this assumes that one of the refs is statically linked to the executable

const c = @cImport({
    @cInclude("client/client.h");
    @cInclude("client/qmenu.h");
});
const std = @import("std");

export var viddef: c.viddef_t = undefined;
export var re: c.refexport_t = undefined;

extern fn GetRefAPI (rimp: c.refimport_t) c.refexport_t;
extern fn VID_Printf (print_level: c_int, fmt: [*c]const u8, ...) void;

pub export fn VID_NewWindow (width: c_int, height: c_int) void {
        viddef.width = @intCast( c_uint, width );
        viddef.height = @intCast( c_uint, height );
}

const VidMode = struct {
    desc: [*:0]const u8,
    width: u32,
    height: u32,
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

pub export fn VID_GetModeInfo( width: ?*u32, height: ?*u32, mode: usize ) c.qboolean {
    if ( mode < 0 or mode >= 16 ) {
        return false;
    }

    width.?.* = vid_modes[@intCast(usize, mode)].width;
    height.?.* = vid_modes[@intCast(usize,mode)].height;

    return true;
}

export fn VID_Shutdown() void {
    if (re.Shutdown) |reShutdown| {
        reShutdown();
    }
}

export fn VID_CheckChanges() void {
}

// ===============================================================
// video menu code
// ===============================================================

extern var vid_ref: ?*c.cvar_t;
extern var scr_viewsize: ?*c.cvar_t;
var sw_mode: ?*c.cvar_t = null;
var sw_stipplealpha: ?*c.cvar_t = null;

var s_menu:                 c.menuframework_s = undefined;
var s_mode_list:            c.menulist_s = undefined;
var s_screensize_slider:    c.menuslider_s = undefined;
var s_stipple_box:          c.menulist_s = undefined;
var s_apply_action:         c.menuaction_s = undefined;
var s_defaults_action:      c.menuaction_s = undefined;

extern fn M_ForceMenuOff() void;
extern fn M_PopMenu() void;

export fn ScreenSizeCallback( s_optional: ?*c_void ) void {
    if ( s_optional ) |s| {
        const slider = @ptrCast( *c.menuslider_s, @alignCast( @alignOf( c.menuslider_s ), s ) );
        c.Cvar_SetValue( "viewsize", slider.*.curvalue * 10 );
    }
}

export fn ResetDefaults( s: ?*c_void ) void {
    VID_MenuInit();
}

export fn ApplyChanges( s: ?*c_void ) void {
    c.Cvar_SetValue( "sw_stipplealpha", @intToFloat( f32, s_stipple_box.curvalue ) );
    c.Cvar_SetValue( "sw_mode", @intToFloat( f32, s_mode_list.curvalue ) );
    M_ForceMenuOff();
}

export fn VID_MenuInit() void {
    var resolutions = [_]?[*:0]u8 {
        "[320 240  ]",
        "[400 300  ]",
        "[512 384  ]",
        "[640 480  ]",
        "[800 600  ]",
        "[960 720  ]",
        "[1024 768 ]",
        "[1152 864 ]",
        "[1280 1024]",
        "[1600 1200]",
    };
    var yesno_names = [_]?[*:0]u8 {
        "no",
        "yes",
        null,
    };

    if ( sw_stipplealpha == null ) {
        sw_stipplealpha = c.Cvar_Get( "sw_stipplealpha", "0", c.CVAR_ARCHIVE );
    }

    if ( sw_mode == null ) {
        sw_mode = c.Cvar_Get("sw_mode", "4", c.CVAR_ARCHIVE);
    }
    s_mode_list.curvalue = @floatToInt( c_int, sw_mode.?.value ); 
    
    if ( scr_viewsize == null ) {
        scr_viewsize = c.Cvar_Get ("viewsize", "100", c.CVAR_ARCHIVE);
    }

    s_screensize_slider.curvalue = scr_viewsize.?.*.value / 10;

    s_menu.x = @intCast( c_int, viddef.width / 2 );
    s_menu.nitems = 0;

    s_mode_list.generic.type = c.MTYPE_SPINCONTROL;
    s_mode_list.generic.name = "video mode";
    s_mode_list.generic.x = 0;
    s_mode_list.generic.y = 10;
    s_mode_list.itemnames = &resolutions;

    s_screensize_slider.generic.type    = c.MTYPE_SLIDER;
    s_screensize_slider.generic.x        = 0;
    s_screensize_slider.generic.y        = 20;
    s_screensize_slider.generic.name    = "screen size";
    s_screensize_slider.minvalue = 3;
    s_screensize_slider.maxvalue = 12;
    s_screensize_slider.generic.callback = ScreenSizeCallback;

    s_defaults_action.generic.type = c.MTYPE_ACTION;
    s_defaults_action.generic.name = "reset to default";
    s_defaults_action.generic.x    = 0;
    s_defaults_action.generic.y    = 90;
    s_defaults_action.generic.callback = ResetDefaults;

    s_apply_action.generic.type = c.MTYPE_ACTION;
    s_apply_action.generic.name = "apply";
    s_apply_action.generic.x    = 0;
    s_apply_action.generic.y    = 100;
    s_apply_action.generic.callback = ApplyChanges;

    s_stipple_box.generic.type = c.MTYPE_SPINCONTROL;
    s_stipple_box.generic.x    = 0;
    s_stipple_box.generic.y    = 60;
    s_stipple_box.generic.name    = "stipple alpha";
    s_stipple_box.curvalue = @bitCast( f32, sw_stipplealpha.?.value );
    s_stipple_box.itemnames = &yesno_names;

    c.Menu_AddItem( &s_menu, &s_mode_list );
    c.Menu_AddItem( &s_menu, &s_screensize_slider );
    c.Menu_AddItem( &s_menu, &s_stipple_box );
    c.Menu_AddItem( &s_menu, &s_defaults_action );
    c.Menu_AddItem( &s_menu, &s_apply_action );

    c.Menu_Center( &s_menu );
    s_menu.x -= 8;
}

export fn VID_MenuDraw() void {
    var w: u32 = 0;
    var h: u32 = 0;
    
    if ( c.re.DrawGetPicSize ) | DrawGetPicSize | {
        DrawGetPicSize( &w, &h, "m_banner_video" );
    }
    
    if ( c.re.DrawPic ) | DrawPic | {
        DrawPic( (viddef.width / 2) - (w / 2) , @divFloor( viddef.height, 2 ) - 110, "m_banner_video" );
    }

    c.Menu_AdjustCursor( &s_menu, 1 );
    c.Menu_Draw( &s_menu );
}

export fn VID_MenuKey(key: i32) ?[*:0]u8 {
    const sound = "misc/menu1.wav";

    if ( key == c.K_ESCAPE ) {
        M_PopMenu();
        return null;
    } else if ( key == c.K_UPARROW ) {
        s_menu.cursor = s_menu.cursor - 1;
        c.Menu_AdjustCursor( &s_menu, -1 );
    } else if ( key == c.K_DOWNARROW ) {
        s_menu.cursor = s_menu.cursor + 1;
        c.Menu_AdjustCursor( &s_menu, 1 );
    } else if ( key == c.K_LEFTARROW ) {
        c.Menu_SlideItem( &s_menu, -1 );
    } else if ( key == c.K_RIGHTARROW ) {
        c.Menu_SlideItem( &s_menu, 1 );
    } else if ( key == c.K_ENTER ) {
        _ = c.Menu_SelectItem( &s_menu );
    }
    return sound;
}


export fn VID_Init() void {
    var ri_local = c.refimport_t {
        .Cmd_AddCommand     = c.Cmd_AddCommand,
        .Cmd_RemoveCommand  = c.Cmd_RemoveCommand,
        .Cmd_Argc           = c.Cmd_Argc,
        .Cmd_Argv           = c.Cmd_Argv,
        .Cmd_ExecuteText    = c.Cbuf_ExecuteText,
        .Con_Printf         = VID_Printf,
        .Sys_Error          = c.Com_Error,
        .FS_LoadFile        = c.FS_LoadFile,
        .FS_FreeFile        = c.FS_FreeFile,
        .FS_Gamedir         = c.FS_Gamedir,
        .Vid_NewWindow      = VID_NewWindow,
        .Cvar_Get           = c.Cvar_Get,
        .Cvar_Set           = c.Cvar_Set,
        .Cvar_SetValue      = c.Cvar_SetValue,
        .Vid_GetModeInfo    = VID_GetModeInfo,
        .Vid_MenuInit       = VID_MenuInit,
    };

    viddef.width = 800;
    viddef.height = 600;

    re = GetRefAPI(ri_local);

    if (re.api_version != c.API_VERSION) {
        c.Com_Error(c.ERR_FATAL, @ptrCast([*c]u8, &"Re has incompatible api_version"));
    }

    // call the init function
    if (re.Init) |reInit| {
        if (reInit (null, null) == false) {
            c.Com_Error (c.ERR_FATAL, @ptrCast([*c]u8, &"Couldn't start refresh"));
        }
    } else {
        c.Com_Error (c.ERR_FATAL, @ptrCast([*c]u8, &"Re has no init function"));
    }
}
