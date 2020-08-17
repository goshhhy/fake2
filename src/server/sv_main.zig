
const c = @cImport({
    @cInclude("server/server.h");
});

const common = @import("qcommon");

extern var hostname: *c.cvar_t;
extern var maxclients: *c.cvar_t;
extern var dedicated: ?*c.cvar_t;
extern var public_server: ?*c.cvar_t;


// Send a message to the master every few minutes to
// let it know we are alive, and log information
fn Master_Heartbeat() void {
    var string: [*]u8 = null;
    var string2: [*]u8 = null;
    var i: usize = 0;

    var nn_dedicated = dedicated orelse return;
    var nn_public_server = public_server orelse return;

    // check for time wraparound
    if ( c.svs.last_heartbeat > c.svs.realtime )
        c.svs.last_heartbeat = c.svs.realtime;

    if ( c.svs.realtime - c.svs.last_heartbeat < (300) * 1000 )
        return;  // not time to send yet

    c.svs.last_heartbeat = c.svs.realtime;

    // send the same string that we would give for a status OOB command
    string = SV_StatusString();

    // send to group master
    while ( i < c.MAX_MASTERS ) : ( i += 1 ) {
        if ( c.master_adr[i].port != 0 ) {
            c.Com_Printf( "Sending heartbeat to %s\n", c.NET_AdrToString( master_adr[i] ) );
            c.Netchan_OutOfBandPrint( c.NS_SERVER, c.master_adr[i], "heartbeat\n%s", string );
        }
    }
}

/// Informs all masters that this server is going down
export fn Master_Shutdown() void {
    var i: usize = 0;

    var nn_dedicated = dedicated orelse return;
    var nn_public_server = public_server orelse return;

    if ( nn_dedicated.*.value == 0 or nn_public_server.*.value == 0 )
        return;

    // send to group master
    while ( i < c.MAX_MASTERS ) : ( i += 1 ) {
        if ( c.master_adr[i].port != 0 ) {
            if ( i > 0 )
                c.Com_Printf( "Sending shutdown message to master server %s\n", c.NET_AdrToString( c.master_adr[i] ) );
            c.Netchan_OutOfBandPrint( c.NS_SERVER, c.master_adr[i], "shutdown" );
        }
    }
}

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

    var clientList = @as([*]c.client_t, c.svs.clients)[0..@floatToInt(usize, c.maxclients.*.value)];
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
        c.Com_sprintf( &string,  64, "%16s %8s %i/%i\n", hostname.*.string, 
                                                            c.sv.name, count, @floatToInt( c_int, maxclients.*.value ) );
    }
    c.Netchan_OutOfBandPrint( c.NS_SERVER, c.net_from, "info\n%s", string );
}

/// Used by SV_Shutdown to send a final message to all
/// connected clients before the server goes down.  The messages are sent
/// immediately, not just stuck on the outgoing message list, because the server is
/// going to totally exit after returning from this function.
pub export fn SV_FinalMessage( message: [*:0]u8, reconnect: bool ) void {
    var i: usize = 0;
    var cl: [*]c.client_t = c.svs.clients;

    c.SZ_Clear( &c.net_message );
    c.MSG_WriteByte( &c.net_message, c.svc_print );
    c.MSG_WriteByte( &c.net_message, c.PRINT_HIGH );
    c.MSG_WriteString( &c.net_message, message );

    if ( reconnect ) {
        c.MSG_WriteByte( &c.net_message, c.svc_reconnect );
    } else {
        c.MSG_WriteByte( &c.net_message, c.svc_disconnect );
    }
    // send it twice
    // stagger the packets to crutch operating system limited buffers

    while ( i < @floatToInt(usize, maxclients.*.value ) ) : ( i += 1 ) {
        if ( @enumToInt(cl[i].state) >= c.cs_connected ) {
            c.Netchan_Transmit( &cl[i].netchan, c.net_message.cursize, c.net_message.data );
        }
    }

    i = 0;
    cl = c.svs.clients;
    while ( i < @floatToInt(usize, maxclients.*.value ) ) : ( i += 1 ) {
        if ( @enumToInt(cl[i].state) >= c.cs_connected ) {
            c.Netchan_Transmit( &cl[i].netchan, c.net_message.cursize, c.net_message.data );
        }
    }
}

