
const c = @cImport({
    @cInclude("server/server.h");
});

extern fn Master_Shutdown() void;

pub export fn SV_DropClient( drop: *c.client_t ) void {
    c.MSG_WriteByte( &drop.*.netchan.message, @enumToInt( c.svc_disconnect ) );

    if ( @enumToInt( drop.*.state ) == c.cs_spawned ) {
        c.ge.*.ClientDisconnect.?( drop.*.edict );
    }

    if ( drop.*.download != null ) {
        c.FS_FreeFile( drop.*.download );
        drop.*.download = null;
    }
    drop.*.state = @intToEnum( c.client_state_t, c.cs_zombie );
    drop.*.name[0] = 0;
}

pub export fn SV_Shutdown( finalmsg: [*]u8, reconnect: bool ) void {
    if ( c.svs.clients != null )
        c.SV_FinalMessage( finalmsg, reconnect );
    Master_Shutdown();
    c.SV_ShutdownGameProgs();

    if ( c.sv.demofile != null ) 
        _ = c.fclose( c.sv.demofile );
    @memset( @ptrCast( [*]u8, &c.sv ), 0, @sizeOf( @typeOf( c.sv ) ) );
    c.Com_SetServerState( c.sv.state );

    if ( c.svs.clients != null )
        c.Z_Free( c.svs.clients );
    if ( c.svs.client_entities != null )
        c.Z_Free( c.svs.client_entities );
    if ( c.svs.demofile != null )
        _ = c.fclose( c.svs.demofile );
    @memset( @ptrCast( [*]u8, &c.svs ), 0, @sizeOf( @typeOf( c.svs ) ) );
}

var status: [c.MAX_MSGLEN - 16]u8 = undefined;
pub export fn SV_StatusString() [*]const u8 {
    var player: [1024]u8 = undefined; 
    var i: u32 = 0;
    var playerLength: u32 = 0;

    _ = c.strcpy( &status, c.Cvar_Serverinfo() );
    _ = c.strcat( &status, c"\n" );
    const statusLength = c.strlen( &status );

    const clientList = c.svs.clients[0..@floatToInt(usize, c.maxclients.*.value)];
    for ( clientList ) | cl | {
        if ( (cl.state == @intToEnum( c.client_state_t, c.cs_connected ) ) or ( cl.state == @intToEnum( c.client_state_t, c.cs_spawned ) ) ) {
            c.Com_sprintf( &player, 1024, c"%i %i \"%s\"\n",
                         cl.edict.*.client.*.ps.stats[c.STAT_FRAGS], cl.ping,
                         cl.name );
            playerLength = strlen( player );
            if ( statusLength + playerLength >= sizeof( status ) )
                break;  // can't hold any more
            strcpy( status + statusLength, player );
            statusLength += playerLength;
        }
    }

    return status;
}

pub export fn SVC_Status() void {
    c.Netchan_OutOfBandPrint( c.NS_SERVER, c.net_from, c"print\n%s", SV_StatusString() );
}