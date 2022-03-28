const c = @cImport({
    @cInclude("client/client.h");
});

const common = @import("qcommon");

pub export fn CL_ParseInventory() void {
    var i: usize = 0;

    while ( i < c.MAX_ITEMS ) : ( i += 1 ) { 
        c.cl.inventory[i] = common.msg.ReadShort( &common.c.net_message ) catch 0;
    }
}

fn Inv_DrawString( _x: u32, _y: u32, string: [*:0]const u8 ) void {
    var i: usize = 0;
    var x: u32 = _x;
    var y: u32 = _y;

    while ( string[i] != 0 ) : ( i += 1 ) {
        c.re.DrawChar.?( x, y, string[i] );
        x += 8;
    }
}

fn SetStringHighBit( s: [*:0]u8 ) void {
    var i: usize = 0;
    while ( s[i] != 0 ) : ( i += 1 ) {
        s[i] |= 128;
    }
}

const DISPLAY_ITEMS = 17;

pub export fn CL_DrawInventory() void {
    var index: [c.MAX_ITEMS]usize = undefined;
    var selected = c.cl.frame.playerstate.stats[c.STAT_SELECTED_ITEM];
    
    var i: usize = 0;
    var num: i32 = 0;
    var selected_num: i32 = 0;
    while ( i < c.MAX_ITEMS ) : ( i += 1 ) {
        if ( i == selected ) {
            selected_num = num;
        }
        if ( c.cl.inventory[i] != 0 ) {
            index[@intCast(usize, num)] = i;
            num += 1;
        }
    }

    // determine scroll point
    var top: i32 = selected_num - DISPLAY_ITEMS / 2;
    if ( num - top < DISPLAY_ITEMS )
        top = num - DISPLAY_ITEMS;
    if ( top < 0 )
        top = 0;

    var x: u32 = ( c.viddef.width - 256 ) / 2;
    var y: u32 = ( c.viddef.height - 240 ) / 2;

    // repaint everything next frame
    c.SCR_DirtyScreen();

    c.re.DrawPic.?( x, y + 8, "inventory" );

    y += 24;
    x += 24;
    Inv_DrawString( x, y, "hotkey ### item" );
    Inv_DrawString( x, y + 8, "------ --- ----" );
    y += 16;
    i = @intCast(u32, top);

    var binding: [1024:0]u8 = undefined;
    var bind: [*]const u8 = "";
    var string: [1024:0]u8 = undefined;

    while ( i < num and i < top + DISPLAY_ITEMS ) : ( i += 1 ) {
        var item = index[i];
        // search for a binding
        c.Com_sprintf( &binding, 1024, "use %s",
                     c.cl.configstrings[@intCast(usize, c.CS_ITEMS) + item] );
        bind = "";
        var j: usize = 0;
        while ( j < 256 ) : ( j += 1 ) {
            if ( c.keybindings[j] != 0 and c.Q_stricmp( c.keybindings[j], &binding ) == 0 ) {
                bind = c.Key_KeynumToString( @intCast( i32, j ) );
                break;
            }
        }

        c.Com_sprintf( &string, 1024, "%6s %3i %s", bind,
                     c.cl.inventory[item], c.cl.configstrings[@intCast(usize, c.CS_ITEMS) + item] );
        if ( item != selected ) {
            SetStringHighBit( &string );
        } else { // draw a blinky cursor by the selected item
            if ( ( ( c.cls.realtime * 10 ) & 1 ) != 0 )
                c.re.DrawChar.?( x - 8, y, 15 );
        }
        Inv_DrawString( x, y, &string );
        y += 8;
    }
}
