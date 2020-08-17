// SPDX-License-Identifier: GPL-2.0-or-later
// g_weapon.c

#include "g_local.h"
#include "m_player.h"

static qboolean is_quad;
static byte is_silenced;

static void P_ProjectSource( gclient_t *client, vec3_t point, vec3_t distance,
                             vec3_t forward, vec3_t right, vec3_t result ) {
    vec3_t _distance;

    VectorCopy( distance, _distance );
    if ( client->pers.hand == LEFT_HANDED )
        _distance[1] *= -1;
    else if ( client->pers.hand == CENTER_HANDED )
        _distance[1] = 0;
    G_ProjectSource( point, _distance, forward, right, result );
}

/*
===============
PlayerNoise

Each player can have two noise objects associated with it:
a personal noise (jumping, pain, weapon firing), and a weapon
target noise (bullet wall impacts)

Monsters that don't directly see the player can move
to a noise in hopes of seeing the player from there.
===============
*/
void PlayerNoise( edict_t *who, vec3_t where, int type ) {
    edict_t *noise;

    if ( deathmatch->value )
        return;

    if ( who->flags & FL_NOTARGET )
        return;

    if ( !who->mynoise ) {
        noise = G_Spawn();
        noise->classname = "player_noise";
        VectorSet( noise->mins, -8, -8, -8 );
        VectorSet( noise->maxs, 8, 8, 8 );
        noise->owner = who;
        noise->svflags = SVF_NOCLIENT;
        who->mynoise = noise;

        noise = G_Spawn();
        noise->classname = "player_noise";
        VectorSet( noise->mins, -8, -8, -8 );
        VectorSet( noise->maxs, 8, 8, 8 );
        noise->owner = who;
        noise->svflags = SVF_NOCLIENT;
        who->mynoise2 = noise;
    }

    if ( type == PNOISE_SELF || type == PNOISE_WEAPON ) {
        noise = who->mynoise;
        level.sound_entity = noise;
        level.sound_entity_framenum = level.framenum;
    } else  // type == PNOISE_IMPACT
    {
        noise = who->mynoise2;
        level.sound2_entity = noise;
        level.sound2_entity_framenum = level.framenum;
    }

    VectorCopy( where, noise->s.origin );
    VectorSubtract( where, noise->maxs, noise->absmin );
    VectorAdd( where, noise->maxs, noise->absmax );
    noise->teleport_time = level.time;
    gi.linkentity( noise );
}

/*
===============
ChangeWeapon

The old weapon has been dropped all the way, so make the new one
current
===============
*/
void ChangeWeapon( edict_t *ent ) {
    int i;

    ent->client->pers.lastweapon = ent->client->pers.weapon;
    ent->client->pers.weapon = ent->client->newweapon;
    ent->client->newweapon = NULL;

    // set visible model
    if ( ent->s.modelindex == 255 ) {
        if ( ent->client->pers.weapon )
            i = ( ( ent->client->pers.weapon->weapmodel & 0xff ) << 8 );
        else
            i = 0;
        ent->s.skinnum = ( ent - g_edicts - 1 ) | i;
    }

    if ( ent->client->pers.weapon && ent->client->pers.weapon->ammo )
        ent->client->ammo_index =
            ITEM_INDEX( FindItem( ent->client->pers.weapon->ammo ) );
    else
        ent->client->ammo_index = 0;

    if ( !ent->client->pers.weapon ) {  // dead
        ent->client->ps.gunindex = 0;
        return;
    }

    ent->client->weaponstate = WEAPON_ACTIVATING;
    ent->client->ps.gunframe = 0;
    ent->client->ps.gunindex =
        gi.modelindex( ent->client->pers.weapon->view_model );

    ent->client->anim_priority = ANIM_PAIN;
    if ( ent->client->ps.pmove.pm_flags & PMF_DUCKED ) {
        ent->s.frame = FRAME_crpain1;
        ent->client->anim_end = FRAME_crpain4;
    } else {
        ent->s.frame = FRAME_pain301;
        ent->client->anim_end = FRAME_pain304;
    }
}

/*
=================
NoAmmoWeaponChange
=================
*/
void NoAmmoWeaponChange( edict_t *ent ) {
    ent->client->newweapon = FindItem( "railgun" );
}

/*
=================
Think_Weapon

Called by ClientBeginServerFrame and ClientThink
=================
*/
void Think_Weapon( edict_t *ent ) {
    // if just died, put the weapon away
    if ( ent->health < 1 ) {
        ent->client->newweapon = NULL;
        ChangeWeapon( ent );
    }

    // call active weapon think routine
    if ( ent->client->pers.weapon && ent->client->pers.weapon->weaponthink ) {
        ent->client->pers.weapon->weaponthink( ent );
    }
}

/*
================
Use_Weapon
================
*/
void Use_Weapon( edict_t *ent, gitem_t *item ) {
    // see if we're already using it
    if ( item == ent->client->pers.weapon )
        return;

    // change to this weapon when down
    ent->client->newweapon = item;
}


/*
================
Weapon_Generic

A generic function to handle the basics of weapon thinking
================
*/
#define FRAME_FIRE_FIRST ( FRAME_ACTIVATE_LAST + 1 )
#define FRAME_IDLE_FIRST ( FRAME_FIRE_LAST + 1 )
#define FRAME_DEACTIVATE_FIRST ( FRAME_IDLE_LAST + 1 )

void Weapon_Generic( edict_t *ent, int FRAME_ACTIVATE_LAST, int FRAME_FIRE_LAST,
                     int FRAME_IDLE_LAST, int FRAME_DEACTIVATE_LAST,
                     int *pause_frames, int *fire_frames,
                     void ( *fire )( edict_t *ent ) ) {
    int n;

    if ( ent->deadflag ||
         ent->s.modelindex != 255 )  // VWep animations screw up corpses
    {
        return;
    }

    if ( ent->client->weaponstate == WEAPON_DROPPING ) {
        if ( ent->client->ps.gunframe == FRAME_DEACTIVATE_LAST ) {
            ChangeWeapon( ent );
            return;
        } else if ( ( FRAME_DEACTIVATE_LAST - ent->client->ps.gunframe ) ==
                    4 ) {
            ent->client->anim_priority = ANIM_REVERSE;
            if ( ent->client->ps.pmove.pm_flags & PMF_DUCKED ) {
                ent->s.frame = FRAME_crpain4 + 1;
                ent->client->anim_end = FRAME_crpain1;
            } else {
                ent->s.frame = FRAME_pain304 + 1;
                ent->client->anim_end = FRAME_pain301;
            }
        }

        ent->client->ps.gunframe++;
        return;
    }

    if ( ent->client->weaponstate == WEAPON_ACTIVATING ) {
        if ( ent->client->ps.gunframe == FRAME_ACTIVATE_LAST ) {
            ent->client->weaponstate = WEAPON_READY;
            ent->client->ps.gunframe = FRAME_IDLE_FIRST;
            return;
        }

        ent->client->ps.gunframe++;
        return;
    }

    if ( ( ent->client->newweapon ) &&
         ( ent->client->weaponstate != WEAPON_FIRING ) ) {
        ent->client->weaponstate = WEAPON_DROPPING;
        ent->client->ps.gunframe = FRAME_DEACTIVATE_FIRST;

        if ( ( FRAME_DEACTIVATE_LAST - FRAME_DEACTIVATE_FIRST ) < 4 ) {
            ent->client->anim_priority = ANIM_REVERSE;
            if ( ent->client->ps.pmove.pm_flags & PMF_DUCKED ) {
                ent->s.frame = FRAME_crpain4 + 1;
                ent->client->anim_end = FRAME_crpain1;
            } else {
                ent->s.frame = FRAME_pain304 + 1;
                ent->client->anim_end = FRAME_pain301;
            }
        }
        return;
    }

    if ( ent->client->weaponstate == WEAPON_READY ) {
        if ( ( ( ent->client->latched_buttons | ent->client->buttons ) & BUTTON_ATTACK ) ) {
            ent->client->latched_buttons &= ~BUTTON_ATTACK;
            ent->client->ps.gunframe = FRAME_FIRE_FIRST;
            ent->client->weaponstate = WEAPON_FIRING;

            // start the animation
            ent->client->anim_priority = ANIM_ATTACK;
            if ( ent->client->ps.pmove.pm_flags & PMF_DUCKED ) {
                ent->s.frame = FRAME_crattak1 - 1;
                ent->client->anim_end = FRAME_crattak9;
            } else {
                ent->s.frame = FRAME_attack1 - 1;
                ent->client->anim_end = FRAME_attack8;
            }
        } else {
            if ( ent->client->ps.gunframe == FRAME_IDLE_LAST ) {
                ent->client->ps.gunframe = FRAME_IDLE_FIRST;
                return;
            }

            if ( pause_frames ) {
                for ( n = 0; pause_frames[n]; n++ ) {
                    if ( ent->client->ps.gunframe == pause_frames[n] ) {
                        if ( rand() & 15 )
                            return;
                    }
                }
            }

            ent->client->ps.gunframe++;
            return;
        }
    }

    if ( ent->client->weaponstate == WEAPON_FIRING ) {
        for ( n = 0; fire_frames[n]; n++ ) {
            if ( ent->client->ps.gunframe == fire_frames[n] ) {
                fire( ent );
                break;
            }
        }

        if ( !fire_frames[n] )
            ent->client->ps.gunframe++;

        if ( ent->client->ps.gunframe == FRAME_IDLE_FIRST + 1 )
            ent->client->weaponstate = WEAPON_READY;
    }
}

/*
======================================================================

RAILGUN

======================================================================
*/

void weapon_railgun_fire( edict_t *ent ) {
    vec3_t start;
    vec3_t forward, right;
    vec3_t offset;
    int damage;
    int kick;

    if ( deathmatch->value ) {  // normal damage is too extreme in dm
        damage = 100;
        kick = 200;
    } else {
        damage = 150;
        kick = 250;
    }

    AngleVectors( ent->client->v_angle, forward, right, NULL );

    VectorScale( forward, -3, ent->client->kick_origin );
    ent->client->kick_angles[0] = -3;

    VectorSet( offset, 0, 7, ent->viewheight - 8 );
    P_ProjectSource( ent->client, ent->s.origin, offset, forward, right,
                     start );
    fire_rail( ent, start, forward, damage, kick );

    // send muzzle flash
    gi.WriteByte( svc_muzzleflash );
    gi.WriteShort( ent - g_edicts );
    gi.WriteByte( MZ_RAILGUN | is_silenced );
    gi.multicast( ent->s.origin, MULTICAST_PVS );

    ent->client->ps.gunframe++;
    PlayerNoise( ent, start, PNOISE_WEAPON );

    if ( !( (int)dmflags->value & DF_INFINITE_AMMO ) )
        ent->client->pers.inventory[ent->client->ammo_index]--;
}

void Weapon_Railgun( edict_t *ent ) {
    static int pause_frames[] = {56, 0};
    static int fire_frames[] = {4, 0};

    Weapon_Generic( ent, 3, 18, 56, 61, pause_frames, fire_frames,
                    weapon_railgun_fire );
}