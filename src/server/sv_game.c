// SPDX-License-Identifier: GPL-2.0-or-later
// sv_game.c -- interface to the game dll

#include "server.h"

extern game_export_t *ge;

/// Print to a single client
void PF_cprintf( edict_t *ent, int level, const char *fmt, ... ) {
    char msg[1024];
    va_list argptr;
    int n;

    if ( ent ) {
        n = NUM_FOR_EDICT( ent );
        if ( n < 1 || n > maxclients->value )
            Com_Error( ERR_DROP, "cprintf to a non-client" );
    }

    va_start( argptr, fmt );
    vsprintf( msg, fmt, argptr );
    va_end( argptr );

    if ( ent )
        SV_ClientPrintf( svs.clients + ( n - 1 ), level, "%s", msg );
    else
        Com_Printf( "%s", msg );
}

/// centerprint to a single client
void PF_centerprintf( edict_t *ent, char *fmt, ... ) {
    char msg[1024];
    va_list argptr;
    int n;

    n = NUM_FOR_EDICT( ent );
    if ( n < 1 || n > maxclients->value )
        return;  // Com_Error (ERR_DROP, "centerprintf to a non-client");

    va_start( argptr, fmt );
    vsprintf( msg, fmt, argptr );
    va_end( argptr );

    MSG_WriteByte( &sv.multicast, svc_centerprint );
    MSG_WriteString( &sv.multicast, msg );
    PF_Unicast( ent, true );
}

/// Abort the server with a game error
void PF_error( char *fmt, ... ) {
    char msg[1024];
    va_list argptr;

    va_start( argptr, fmt );
    vsprintf( msg, fmt, argptr );
    va_end( argptr );

    Com_Error( ERR_DROP, "Game Error: %s", msg );
}
