// SPDX-License-Identifier: GPL-2.0-or-later
#include "g_local.h"

void fire_rail( edict_t *self, vec3_t start, vec3_t aimdir, int damage,
                int kick ) {
    vec3_t from;
    vec3_t end;
    trace_t tr;
    edict_t *ignore;
    int mask;
    qboolean water;

    VectorMA( start, 8192, aimdir, end );
    VectorCopy( start, from );
    ignore = self;
    water = false;
    mask = MASK_SHOT | CONTENTS_SLIME | CONTENTS_LAVA;
    while ( ignore ) {
        tr = gi.trace( from, NULL, NULL, end, ignore, mask );

        if ( tr.contents & ( CONTENTS_SLIME | CONTENTS_LAVA ) ) {
            mask &= ~( CONTENTS_SLIME | CONTENTS_LAVA );
            water = true;
        } else {
            // ZOID--added so rail goes through SOLID_BBOX entities (gibs, etc)
            if ( ( tr.ent->svflags & SVF_MONSTER ) || ( tr.ent->client ) ||
                 ( tr.ent->solid == SOLID_BBOX ) )
                ignore = tr.ent;
            else
                ignore = NULL;

            if ( ( tr.ent != self ) && ( tr.ent->takedamage ) )
                T_Damage( tr.ent, self, self, aimdir, tr.endpos,
                          tr.plane.normal, damage, kick, 0, MOD_RAILGUN );
        }

        VectorCopy( tr.endpos, from );
    }

    // send gun puff / flash
    gi.WriteByte( svc_temp_entity );
    gi.WriteByte( TE_RAILTRAIL );
    gi.WritePosition( start );
    gi.WritePosition( tr.endpos );
    gi.multicast( self->s.origin, MULTICAST_PHS );
    //	gi.multicast (start, MULTICAST_PHS);
    if ( water ) {
        gi.WriteByte( svc_temp_entity );
        gi.WriteByte( TE_RAILTRAIL );
        gi.WritePosition( start );
        gi.WritePosition( tr.endpos );
        gi.multicast( tr.endpos, MULTICAST_PHS );
    }

    if ( self->client )
        PlayerNoise( self, tr.endpos, PNOISE_IMPACT );
}