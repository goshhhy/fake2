const c = @cImport({
    @cInclude("server/server.h");
});

const common = @import("qcommon");
const sv_init = @import ("sv_init.zig");

export var ge: ?*c.game_export_t = null;

fn num_to_edict( n: i32 ) *c.edict_t {
    return ( ge.?.edicts[n] );
}

fn edict_to_num( e: *c.edict_t ) i32 {
    return @intCast( i32, ( @ptrToInt(e) - @ptrToInt(ge.?.edicts) ) / @intCast(usize, ge.?.edict_size) );
}

extern fn PF_cprintf( ent: [*c]c.edict_t, level: c_int, fmt: [*c]const u8, ... ) void;
extern fn PF_centerprintf( ent: [*c]c.edict_t, fmt: [*c]const u8, ... ) void;
extern fn PF_error( fmt: [*c]const u8, ... ) void;

export fn PF_WriteChar( char: i32 ) void { c.MSG_WriteChar( &c.sv.multicast, char ); }
export fn PF_WriteByte( char: i32 ) void { c.MSG_WriteByte( &c.sv.multicast, char ); }
export fn PF_WriteShort( char: i32 ) void { c.MSG_WriteShort( &c.sv.multicast, char ); }
export fn PF_WriteLong( char: i32 ) void { c.MSG_WriteLong( &c.sv.multicast, char ); }
export fn PF_WriteFloat( f: f32 ) void { c.MSG_WriteFloat( &c.sv.multicast, f ); }
export fn PF_WriteString( s: [*c]u8 ) void { c.MSG_WriteString( &c.sv.multicast, s ); }
export fn PF_WritePos( pos: [*c]f32 ) void { c.MSG_WritePos( &c.sv.multicast, pos ); }
export fn PF_WriteDir( dir: [*c]f32 ) void { c.MSG_WriteDir( &c.sv.multicast, dir ); }
export fn PF_WriteAngle( f: f32 ) void { c.MSG_WriteAngle( &c.sv.multicast, f ); }

export fn PF_StartSound( entity: [*c]c.edict_t, channel: c_int, sound_num: c_int, volume: f32, attenuation: f32, timeofs: f32 ) void {
    if ( entity == null )
        return;
    c.SV_StartSound( null, entity, channel, sound_num, volume, attenuation, timeofs );
}

/// checks portalareas so that doors block sight
export fn PF_inPVS( p1: [*c]f32, p2: [*c]f32 ) bool {
    var leafnum: i32 = c.CM_PointLeafnum( p1 );
    var cluster: i32 = c.CM_LeafCluster( leafnum );
    var area1: i32 = c.CM_LeafArea( leafnum );
    var mask: [*c]u8 = c.CM_ClusterPVS( cluster );

    leafnum = c.CM_PointLeafnum( p2 );
    cluster = c.CM_LeafCluster( leafnum );
    var area2: i32 = c.CM_LeafArea( leafnum );
    
    if ( mask != null and ( !( mask[@intCast( usize, cluster ) >> 3] & ( @intCast( u6, 1) << ( @intCast( u3, cluster ) & 7 ) ) == 0 ) ) )
        return false;
    if ( !c.CM_AreasConnected( area1, area2 ) )
        return false;  // a door blocks sight

    return true;
}

/// Also checks portalareas so that doors block sound
export fn PF_inPHS( p1: [*c]f32, p2: [*c]f32 ) bool {
    var leafnum: i32 = c.CM_PointLeafnum( p1 );
    var cluster: i32 = c.CM_LeafCluster( leafnum );
    var area1: i32 = c.CM_LeafArea( leafnum );
    var mask: [*c]u8 = c.CM_ClusterPVS( cluster );

    leafnum = c.CM_PointLeafnum( p2 );
    cluster = c.CM_LeafCluster( leafnum );
    var area2: i32 = c.CM_LeafArea( leafnum );

    if ( mask != null and ( !( mask[@intCast( usize, cluster ) >> 3] & ( @intCast(u32, 1) << ( @truncate( u3, @intCast( u32, cluster ) ) & 7 ) ) == 0 ) ) )
        return false;  // more than one bounce away
    if ( !c.CM_AreasConnected( area1, area2 ) )
        return false;  // a door blocks hearing

    return true;
}

/// Sends the contents of the mutlicast buffer to a single client
export fn PF_Unicast( ent: [*c]c.edict_t, reliable: bool ) void {
    var p: i32 = 0;
    var cl: ?*c.client_t = null;

    if ( ent == null )
        return;

    p = edict_to_num( ent );
    if ( p < 1 or p > @floatToInt( i32, c.maxclients.*.value ) )
        return;

    cl = @intToPtr( ?*c.client_t, @ptrToInt( c.svs.clients ) + @intCast( usize, ( p - 1 ) ) );

    if ( reliable ) { 
        c.SZ_Write( &cl.?.netchan.message, c.sv.multicast.data, c.sv.multicast.cursize );
    } else {
        c.SZ_Write( &cl.?.datagram, c.sv.multicast.data, c.sv.multicast.cursize );
    }
    
    c.SZ_Clear( &c.sv.multicast );
}

export fn PF_Configstring( index: i32, val: [*c]const u8 ) void {
    var rval: [*:0]const u8 = val orelse "";
    if ( index < 0 or index >= c.MAX_CONFIGSTRINGS )
        c.Com_Error( c.ERR_DROP, "configstring: bad index %i\n", index );

    // change the string in sv
    _ = c.strcpy( &c.sv.configstrings[@intCast(usize, index)], rval );

    if ( c.sv.state != c.ss_loading ) {  // send the update to everyone
        c.SZ_Clear( &c.sv.multicast );
        c.MSG_WriteChar( &c.sv.multicast, c.svc_configstring );
        c.MSG_WriteShort( &c.sv.multicast, index );
        c.MSG_WriteString( &c.sv.multicast, rval );

        c.SV_Multicast( &c.vec3_origin, c.MULTICAST_ALL_R );
    }
}

/// set model, and also mins and maxs for inline bmodels
export fn PF_setmodel( ent: [*c]c.edict_t, name: [*c]const u8 ) void {
    var i: i32 = 0;

    if ( name == null )
        c.Com_Error( c.ERR_DROP, "PF_setmodel: NULL" );

    i = sv_init.ModelIndex( name );

    ent.*.s.modelindex = i;

    // if it is an inline model, get the size information for it
    if ( name[0] == '*' ) {
        var mod: *c.cmodel_t = c.CM_InlineModel( name );
        common.VectorCopy( *c.vec3_t, &mod.*.mins, &ent.*.mins );
        common.VectorCopy( *c.vec3_t, &mod.*.maxs, &ent.*.maxs );
        c.SV_LinkEdict( ent );
    }
}


// called when server is being killed or
// game has been changed
pub export fn SV_ShutdownGameProgs() void {
    if ( ge == null )
        return;
    ge.?.Shutdown.?();
    c.Sys_UnloadGame();
    ge = null;
}

extern fn SCR_DebugGraph( value: f32, color: i32 ) void;

var import: c.game_import_t = undefined;
/// Init the game subsystem for a new map
export fn SV_InitGameProgs() void {
    // unload anything we have now
    if ( ge != null )
        SV_ShutdownGameProgs();

    // load a new game dll
    import.multicast = c.SV_Multicast;
    import.unicast = PF_Unicast;
    import.bprintf = c.SV_BroadcastPrintf;
    import.dprintf = c.Com_Printf;
    import.cprintf = PF_cprintf;
    import.centerprintf = PF_centerprintf;
    import.err = PF_error;

    import.linkentity = c.SV_LinkEdict;
    import.unlinkentity = c.SV_UnlinkEdict;
    import.BoxEdicts = c.SV_AreaEdicts;
    import.trace = c.SV_Trace;
    import.pointcontents = c.SV_PointContents;
    import.setmodel = PF_setmodel;
    import.inPVS = PF_inPVS;
    import.inPHS = PF_inPHS;
    import.Pmove = c.Pmove;

    import.modelindex = sv_init.ModelIndex;
    import.soundindex = sv_init.SoundIndex;
    import.imageindex = sv_init.ImageIndex;

    import.configstring = PF_Configstring;
    import.sound = PF_StartSound;
    import.positioned_sound = c.SV_StartSound;

    import.WriteChar = PF_WriteChar;
    import.WriteByte = PF_WriteByte;
    import.WriteShort = PF_WriteShort;
    import.WriteLong = PF_WriteLong;
    import.WriteFloat = PF_WriteFloat;
    import.WriteString = PF_WriteString;
    import.WritePosition = PF_WritePos;
    import.WriteDir = PF_WriteDir;
    import.WriteAngle = PF_WriteAngle;

    import.TagMalloc = c.Z_TagMalloc;
    import.TagFree = c.Z_Free;
    import.FreeTags = c.Z_FreeTags;

    import.cvar = c.Cvar_Get;
    import.cvar_set = c.Cvar_Set;
    import.cvar_forceset = c.Cvar_ForceSet;

    import.argc = c.Cmd_Argc;
    import.argv = c.Cmd_Argv;
    import.args = c.Cmd_Args;
    import.AddCommandString = c.Cbuf_AddText;

    import.DebugGraph = SCR_DebugGraph;
    import.SetAreaPortalState = c.CM_SetAreaPortalState;
    import.AreasConnected = c.CM_AreasConnected;

    ge = @ptrCast( ?*c.game_export_t, @alignCast( @alignOf( ?*c.game_export_t ), c.Sys_GetGameAPI( &import ) ) );

    if ( ge == null )
        c.Com_Error( c.ERR_DROP, "failed to load game library" );
    if ( ge.?.apiversion != c.GAME_API_VERSION )
        c.Com_Error( c.ERR_DROP, "wromg game api version");

    ge.?.Init.?();
}