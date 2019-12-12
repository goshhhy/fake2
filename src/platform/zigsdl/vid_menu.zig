const c = @cImport({
    @cInclude("client/client.h");
    @cInclude("client/qmenu.h");
});

extern var vid_ref: *c.cvar_t;
extern var scr_viewsize: *c.cvar_t;
var sw_mode: *c.cvar_t;
var sw_stipplealpha: *c.cvar_t;
extern fn M_ForceMenuOff() void;

var s_menu: menuframework_s; 
static menulist_s s_mode_list;
static menuslider_s        s_screensize_slider;
static menulist_s          s_stipple_box;
static menuaction_s        s_apply_action;
static menuaction_s        s_defaults_action;

static void ScreenSizeCallback( void *s ) {
    menuslider_s *slider = ( menuslider_s * ) s;
    Cvar_SetValue( "viewsize", slider->curvalue * 10 );
}

static void ResetDefaults( void *unused ) {
    VID_MenuInit();
}

static void ApplyChanges( void *unused ) {
    Cvar_SetValue( "sw_stipplealpha", s_stipple_box.curvalue );
    Cvar_SetValue( "sw_mode", s_mode_list.curvalue );
    M_ForceMenuOff();
}

void VID_MenuInit( void ) {
    static const char *resolutions[] = {
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
        0
    };
    static const char *yesno_names[] = {
        "no",
        "yes",
        0
    };
    int i;

    if ( !sw_stipplealpha )
        sw_stipplealpha = Cvar_Get( "sw_stipplealpha", "0", CVAR_ARCHIVE );

    if ( ! sw_mode )
        sw_mode = Cvar_Get("sw_mode", "4", CVAR_ARCHIVE);

    s_mode_list.curvalue = sw_mode->value;
    if ( !scr_viewsize )
        scr_viewsize = Cvar_Get ("viewsize", "100", CVAR_ARCHIVE);

    s_screensize_slider.curvalue = scr_viewsize->value/10;

    s_menu.x = viddef.width * 0.50;
    s_menu.nitems = 0;

    s_mode_list.generic.type = MTYPE_SPINCONTROL;
    s_mode_list.generic.name = "video mode";
    s_mode_list.generic.x = 0;
    s_mode_list.generic.y = 10;
    s_mode_list.itemnames = resolutions;

    s_screensize_slider.generic.type    = MTYPE_SLIDER;
    s_screensize_slider.generic.x        = 0;
    s_screensize_slider.generic.y        = 20;
    s_screensize_slider.generic.name    = "screen size";
    s_screensize_slider.minvalue = 3;
    s_screensize_slider.maxvalue = 12;
    s_screensize_slider.generic.callback = ScreenSizeCallback;

    s_defaults_action.generic.type = MTYPE_ACTION;
    s_defaults_action.generic.name = "reset to default";
    s_defaults_action.generic.x    = 0;
    s_defaults_action.generic.y    = 90;
    s_defaults_action.generic.callback = ResetDefaults;

    s_apply_action.generic.type = MTYPE_ACTION;
    s_apply_action.generic.name = "apply";
    s_apply_action.generic.x    = 0;
    s_apply_action.generic.y    = 100;
    s_apply_action.generic.callback = ApplyChanges;

    s_stipple_box.generic.type = MTYPE_SPINCONTROL;
    s_stipple_box.generic.x    = 0;
    s_stipple_box.generic.y    = 60;
    s_stipple_box.generic.name    = "stipple alpha";
    s_stipple_box.curvalue = sw_stipplealpha->value;
    s_stipple_box.itemnames = yesno_names;

    Menu_AddItem( &s_menu, ( void * ) &s_mode_list );
    Menu_AddItem( &s_menu, ( void * ) &s_screensize_slider );
    Menu_AddItem( &s_menu, ( void * ) &s_stipple_box );
    Menu_AddItem( &s_menu, ( void * ) &s_defaults_action );
    Menu_AddItem( &s_menu, ( void * ) &s_apply_action );

    Menu_Center( &s_menu );
    s_menu.x -= 8;
}

pun fn VID_MenuDraw() void {
    var w: i32 = 0;
    var h: i32 = 0;

    c.re.DrawGetPicSize( &w, &h, "m_banner_video" );
    c.re.DrawPic( viddef.width / 2 - w / 2, viddef.height /2 - 110, "m_banner_video" );

    Menu_AdjustCursor( &s_menu, 1 );
    Menu_Draw( &s_menu );
}


extern fn M_PopMenu() void;

pub export fn *VID_MenuKey( key: c_int ) ?[i*]const u8 {
    const sound = c"misc/menu1.wav";

    if ( key == c.K_ESCAPE ) {
        K_ESCAPE => M_PopMenu();
        return NULL;
    } else if ( key == c.K_UPARROW ) {
        m->cursor--;
        Menu_AdjustCursor( &s_menu, -1 );
    } else if ( key == c.K_DOWNARROW ) {
        m->cursor++;
        Menu_AdjustCursor( &s_menu, 1 );
    } else if ( key == c.K_LEFTARROW ) {
        Menu_SlideItem( &s_menu, -1 );
    } else if ( key == c.K_RIGHTARROW ) {
        Menu_SlideItem( &s_menu, 1 );
    } else if ( key == c.K_ENTER ) {
        Menu_SelectItem( &s_menu );
    }

    return sound;
}
