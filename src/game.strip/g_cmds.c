// SPDX-License-Identifier: GPL-2.0-or-later
#include "g_local.h"
#include "m_player.h"

/*
==================
Cmd_God_f

Sets client to godmode

argv(0) god
==================
*/
void Cmd_God_f( edict_t *ent ) {
    char *msg;

    if ( deathmatch->value && !sv_cheats->value ) {
        gi.cprintf( ent, PRINT_HIGH, "You must run the server with '+set cheats 1' to enable this command.\n" );
        return;
    }

    ent->flags ^= FL_GODMODE;
    if ( !( ent->flags & FL_GODMODE ) )
        msg = "godmode OFF\n";
    else
        msg = "godmode ON\n";

    gi.cprintf( ent, PRINT_HIGH, msg );
}

/*
==================
Cmd_Noclip_f

argv(0) noclip
==================
*/
void Cmd_Noclip_f( edict_t *ent ) {
    char *msg;

    if ( deathmatch->value && !sv_cheats->value ) {
        gi.cprintf( ent, PRINT_HIGH,
                    "You must run the server with '+set cheats 1' to enable "
                    "this command.\n" );
        return;
    }

    if ( ent->movetype == MOVETYPE_NOCLIP ) {
        ent->movetype = MOVETYPE_WALK;
        msg = "noclip OFF\n";
    } else {
        ent->movetype = MOVETYPE_NOCLIP;
        msg = "noclip ON\n";
    }

    gi.cprintf( ent, PRINT_HIGH, msg );
}


/*
=================
Cmd_Kill_f
=================
*/
void Cmd_Kill_f( edict_t *ent ) {
    if ( ( level.time - ent->client->respawn_time ) < 5 )
        return;
    ent->flags &= ~FL_GODMODE;
    ent->health = 0;
    meansOfDeath = MOD_SUICIDE;
    player_die( ent, ent, ent, 100000, vec3_origin );
}

/*
=================
Cmd_PutAway_f
=================
*/
void Cmd_PutAway_f( edict_t *ent ) {
    ent->client->showscores = false;
    ent->client->showhelp = false;
    ent->client->showinventory = false;
}

int PlayerSort( void const *a, void const *b ) {
    int anum, bnum;

    anum = *(int *)a;
    bnum = *(int *)b;

    anum = game.clients[anum].ps.stats[STAT_FRAGS];
    bnum = game.clients[bnum].ps.stats[STAT_FRAGS];

    if ( anum < bnum )
        return -1;
    if ( anum > bnum )
        return 1;
    return 0;
}

/*
=================
Cmd_Players_f
=================
*/
void Cmd_Players_f( edict_t *ent ) {
    int i;
    int count;
    char small[64];
    char large[1280];
    int index[256];

    count = 0;
    for ( i = 0; i < maxclients->value; i++ )
        if ( game.clients[i].pers.connected ) {
            index[count] = i;
            count++;
        }

    // sort by frags
    qsort( index, count, sizeof( index[0] ), PlayerSort );

    // print information
    large[0] = 0;

    for ( i = 0; i < count; i++ ) {
        Com_sprintf( small, sizeof( small ), "%3i %s\n",
                     game.clients[index[i]].ps.stats[STAT_FRAGS],
                     game.clients[index[i]].pers.netname );
        if ( strlen( small ) + strlen( large ) >
             sizeof( large ) - 100 ) {  // can't print all of them in one packet
            strcat( large, "...\n" );
            break;
        }
        strcat( large, small );
    }

    gi.cprintf( ent, PRINT_HIGH, "%s\n%i players\n", large, count );
}

/*
==================
Cmd_Say_f
==================
*/
void Cmd_Say_f( edict_t *ent, qboolean team, qboolean arg0 ) {
    int i, j;
    edict_t *other;
    char *p;
    char text[2048];
    gclient_t *cl;

    if ( gi.argc() < 2 && !arg0 )
        return;

    if ( !( (int)( dmflags->value ) & ( DF_MODELTEAMS | DF_SKINTEAMS ) ) )
        team = false;

    if ( team )
        Com_sprintf( text, sizeof( text ),
                     "(%s): ", ent->client->pers.netname );
    else
        Com_sprintf( text, sizeof( text ), "%s: ", ent->client->pers.netname );

    if ( arg0 ) {
        strcat( text, gi.argv( 0 ) );
        strcat( text, " " );
        strcat( text, gi.args() );
    } else {
        p = gi.args();

        if ( *p == '"' ) {
            p++;
            p[strlen( p ) - 1] = 0;
        }
        strcat( text, p );
    }

    // don't let text be too long for malicious reasons
    if ( strlen( text ) > 150 )
        text[150] = 0;

    strcat( text, "\n" );

    if ( dedicated->value )
        gi.cprintf( NULL, PRINT_CHAT, "%s", text );

    for ( j = 1; j <= game.maxclients; j++ ) {
        other = &g_edicts[j];
        if ( !other->inuse )
            continue;
        if ( !other->client )
            continue;
        gi.cprintf( other, PRINT_CHAT, "%s", text );
    }
}

void Cmd_PlayerList_f( edict_t *ent ) {
    int i;
    char st[80];
    char text[1400];
    edict_t *e2;

    // connect time, ping, score, name
    *text = 0;
    for ( i = 0, e2 = g_edicts + 1; i < maxclients->value; i++, e2++ ) {
        if ( !e2->inuse )
            continue;

        Com_sprintf(
            st, sizeof( st ), "%02d:%02d %4d %3d %s%s\n",
            ( level.framenum - e2->client->resp.enterframe ) / 600,
            ( ( level.framenum - e2->client->resp.enterframe ) % 600 ) / 10,
            e2->client->ping, e2->client->resp.score, e2->client->pers.netname,
            e2->client->resp.spectator ? " (spectator)" : "" );
        if ( strlen( text ) + strlen( st ) > sizeof( text ) - 50 ) {
            sprintf( text + strlen( text ), "And more...\n" );
            gi.cprintf( ent, PRINT_HIGH, "%s", text );
            return;
        }
        strcat( text, st );
    }
    gi.cprintf( ent, PRINT_HIGH, "%s", text );
}

/*
=================
ClientCommand
=================
*/
void ClientCommand( edict_t *ent ) {
    char *cmd;

    if ( !ent->client )
        return;  // not fully in game yet

    cmd = gi.argv( 0 );

    if ( Q_stricmp( cmd, "players" ) == 0 ) {
        Cmd_Players_f( ent );
        return;
    }
    if ( Q_stricmp( cmd, "say" ) == 0 ) {
        Cmd_Say_f( ent, false, false );
        return;
    }
    if ( Q_stricmp( cmd, "score" ) == 0 ) {
        Cmd_Score_f( ent );
        return;
    }

    if ( level.intermissiontime )
        return;

    else if ( Q_stricmp( cmd, "god" ) == 0 )
        Cmd_God_f( ent );
    else if ( Q_stricmp( cmd, "noclip" ) == 0 )
        Cmd_Noclip_f( ent );
    else if ( Q_stricmp( cmd, "kill" ) == 0 )
        Cmd_Kill_f( ent );
    else if ( Q_stricmp( cmd, "putaway" ) == 0 )
        Cmd_PutAway_f( ent );
    else if ( Q_stricmp( cmd, "playerlist" ) == 0 )
        Cmd_PlayerList_f( ent );
    else  // anything that doesn't match a command will be a chat
        Cmd_Say_f( ent, false, true );
}
