const c = @cImport({
    @cInclude("server/server.h");
});

/// private: seek an atlas index for a specific asset
fn FindIndex( name: [*c]const u8, start: usize, max: usize, create: bool ) i32 {
    var i: usize = 0;
    while ( i < max and c.sv.configstrings[start + i][0] != 0 ) : ( i += 1) {
        if ( c.strcmp( &c.sv.configstrings[start + i], name ) == 0 )
            return @intCast( i32, i );
    }

    if ( !create )
        return 0;

    if ( i == max )
        c.Com_Error( c.ERR_DROP, "*Index: overflow" );

    _ = c.strncpy( &c.sv.configstrings[start + i], name, @sizeOf( @TypeOf( c.sv.configstrings[i] ) ) );

    if ( c.sv.state != c.ss_loading ) {  // send the update to everyone
        c.SZ_Clear( &c.sv.multicast );
        c.MSG_WriteChar( &c.sv.multicast, c.svc_configstring );
        c.MSG_WriteShort( &c.sv.multicast, @intCast( c_int, start + i ) );
        c.MSG_WriteString( &c.sv.multicast, name );
        c.SV_Multicast( &c.vec3_origin, @intToEnum( c.multicast_t, c.MULTICAST_ALL_R ) );
    }

    return @intCast( i32, i );
}

// //////////////////////////////////////// //
// these functions must remain C-compatible //
//   they are passed to the game library    //
// //////////////////////////////////////// //

pub export fn ModelIndex( name: [*c]const u8 ) i32 {
    return FindIndex( name, c.CS_MODELS, c.MAX_MODELS, true );
}

pub export fn SoundIndex( name: [*c]const u8 ) i32 {
    return FindIndex( name, c.CS_SOUNDS, c.MAX_SOUNDS, true );
}

pub export fn ImageIndex( name: [*c]const u8 ) i32 {
    return FindIndex( name, c.CS_IMAGES, c.MAX_IMAGES, true );
}