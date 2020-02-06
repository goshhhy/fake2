
const c = @cImport({
    @cInclude("server/server.h");
});

extern var hostname: *c.cvar_t;
extern var maxclients: *c.cvar_t;

extern fn Master_Shutdown() void;

pub export fn SV_DropClient( drop: *c.client_t ) void {
    c.MSG_WriteByte( &drop.*.netchan.message, c.svc_disconnect );

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
    @memset( @ptrCast( [*]u8, &c.sv ), 0, @sizeOf( @TypeOf( c.sv ) ) );
    c.Com_SetServerState( c.sv.state );

    if ( c.svs.clients != null )
        c.Z_Free( c.svs.clients );
    if ( c.svs.client_entities != null )
        c.Z_Free( c.svs.client_entities );
    if ( c.svs.demofile != null )
        _ = c.fclose( c.svs.demofile );
    @memset( @ptrCast( [*]u8, &c.svs ), 0, @sizeOf( @TypeOf( c.svs ) ) );
}

var status: [c.MAX_MSGLEN - 16]u8 = undefined;

pub export fn SV_StatusString() [*]const u8 {
    var player: [1024]u8 = undefined; 
    var i: u32 = 0;
    var playerLength: u32 = 0;

    _ = c.strcpy( &status, c.Cvar_Serverinfo() );
    _ = c.strcat( &status, "\n" );
    var statusLength = c.strlen( &status );

    var clientList = c.svs.clients[0..@floatToInt(usize, c.maxclients.*.value)];
    for ( clientList ) | cl | {
        if ( (cl.state == @intToEnum( c.client_state_t, c.cs_connected ) ) or ( cl.state == @intToEnum( c.client_state_t, c.cs_spawned ) ) ) {
            c.Com_sprintf( &player, 1024, "%i %i \"%s\"\n",
                        cl.edict.*.client.*.ps.stats[c.STAT_FRAGS], cl.ping,
                        cl.name );
            playerLength = @intCast(u32, c.strlen( &player ) );
            if ( statusLength + playerLength >= (c.MAX_MSGLEN - 16) )
                break;  // can't hold any more
            _ = c.strcpy( status[statusLength], &player );
            statusLength += playerLength;
        }
    }
    return &status;
}

//
pub export fn SVC_Status() void {
    c.Netchan_OutOfBandPrint( c.NS_SERVER, c.net_from, "print\n%s", SV_StatusString() );
}

// Ping request from client
pub export fn SVC_Ping() void {
    c.Netchan_OutOfBandPrint( c.NS_SERVER, c.net_from, "ack" );
}

// Ping acknowledgement from client
pub export fn SVC_Ack() void {
    c.Com_Printf( "Ping ack from %s\n", c.NET_AdrToString( c.net_from ) );
}

//  Respond with short info for broadcast scans
//  Second parameter should be protocol version
pub export fn SVC_Info() void {
    if ( maxclients.*.value == 1 )
        return;
    
    var string: [64]u8 = undefined;
    var version: c_int = c.atoi( c.Cmd_Argv( 1 ) );

    if ( version != c.PROTOCOL_VERSION ) {
        c.Com_sprintf( &string, 64, "%s: wrong version\n", hostname.*.string, @intCast( c_int, 64 ) );
    } else {
        var i: u32 = 0;
        var count: u32 = 0;
        while ( i < @floatToInt( u32, maxclients.*.value ) ) : ( i += 1 ) {
            if ( @enumToInt( c.svs.clients[i].state ) >= c.cs_connected ) {
                count += 1;
            }
        }
        c.Com_sprintf( &string,  64, "%16s %8s %2i/%2i\n", hostname.*.string, 
                                                            c.sv.name, count, @floatToInt( c_int, maxclients.*.value ) );
    }
    c.Netchan_OutOfBandPrint( c.NS_SERVER, c.net_from, "info\n%s", string );
}
