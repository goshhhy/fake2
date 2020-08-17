// SPDX-License-Identifier: GPL-2.0-or-later
#include "g_local.h"

qboolean Pickup_Weapon( edict_t *ent, edict_t *other );
void Use_Weapon( edict_t *ent, gitem_t *inv );

void Weapon_Railgun( edict_t *ent );

#define HEALTH_IGNORE_MAX 1
#define HEALTH_TIMED 2

//======================================================================

/*
===============
GetItemByIndex
===============
*/
gitem_t *GetItemByIndex( int index ) {
    if ( index == 0 || index >= game.num_items )
        return NULL;

    return &itemlist[index];
}

/*
===============
FindItemByClassname

===============
*/
gitem_t *FindItemByClassname( char *classname ) {
    int i;
    gitem_t *it;

    it = itemlist;
    for ( i = 0; i < game.num_items; i++, it++ ) {
        if ( !it->classname )
            continue;
        if ( !Q_stricmp( it->classname, classname ) )
            return it;
    }

    return NULL;
}

/*
===============
FindItem

===============
*/
gitem_t *FindItem( char *pickup_name ) {
    int i;
    gitem_t *it;

    it = itemlist;
    for ( i = 0; i < game.num_items; i++, it++ ) {
        if ( !it->pickup_name )
            continue;
        if ( !Q_stricmp( it->pickup_name, pickup_name ) )
            return it;
    }

    return NULL;
}

/*
===============
PrecacheItem

Precaches all data needed for a given item.
This will be called for each item spawned in a level,
and for each item in each client's inventory.
===============
*/
void PrecacheItem( gitem_t *it ) {
    char *s, *start;
    char data[MAX_QPATH];
    int len;
    gitem_t *ammo;

    if ( !it )
        return;

    if ( it->pickup_sound )
        gi.soundindex( it->pickup_sound );
    if ( it->world_model )
        gi.modelindex( it->world_model );
    if ( it->view_model )
        gi.modelindex( it->view_model );
    if ( it->icon )
        gi.imageindex( it->icon );

    // parse everything for its ammo
    if ( it->ammo && it->ammo[0] ) {
        ammo = FindItem( it->ammo );
        if ( ammo != it )
            PrecacheItem( ammo );
    }

    // parse the space seperated precache string for other items
    s = it->precaches;
    if ( !s || !s[0] )
        return;

    while ( *s ) {
        start = s;
        while ( *s && *s != ' ' ) s++;

        len = s - start;
        if ( len >= MAX_QPATH || len < 5 )
            gi.err( "PrecacheItem: %s has bad precache string", it->classname );
        memcpy( data, start, len );
        data[len] = 0;
        if ( *s )
            s++;

        // determine type based on extension
        if ( !strcmp( data + len - 3, "md2" ) )
            gi.modelindex( data );
        else if ( !strcmp( data + len - 3, "sp2" ) )
            gi.modelindex( data );
        else if ( !strcmp( data + len - 3, "wav" ) )
            gi.soundindex( data );
        if ( !strcmp( data + len - 3, "pcx" ) )
            gi.imageindex( data );
    }
}

/*
============
SpawnItem

Sets the clipping size and plants the object on the floor.

Items can't be immediately dropped to floor, because they might
be on an entity that hasn't spawned yet.
============
*/
void SpawnItem( edict_t *ent, gitem_t *item ) {
    PrecacheItem( item );
    G_FreeEdict( ent );
}

//======================================================================

gitem_t itemlist[] = {
    {NULL},  // leave index 0 alone

    /*QUAKED weapon_railgun (.3 .3 1) (-16 -16 -16) (16 16 16)
     */
    {"weapon_railgun", NULL, Use_Weapon, NULL, Weapon_Railgun,
     "misc/w_pkup.wav", "models/weapons/g_rail/tris.md2", EF_ROTATE,
     "models/weapons/v_rail/tris.md2",
     /* icon */ "w_railgun",
     /* pickup */ "Railgun", 0, 1, "Slugs", IT_WEAPON | IT_STAY_COOP,
     WEAP_RAILGUN, NULL, 0,
     /* precache */ "weapons/rg_hum.wav"},

    /*QUAKED ammo_slugs (.3 .3 1) (-16 -16 -16) (16 16 16)
     */
    {"ammo_slugs", NULL, NULL, NULL, NULL, "misc/am_pkup.wav",
     "models/items/ammo/slugs/medium/tris.md2", 0, NULL,
     /* icon */ "a_slugs",
     /* pickup */ "Slugs",
     /* width */ 3, 10, NULL, IT_AMMO, 0, NULL, AMMO_SLUGS,
     /* precache */ ""},
    {NULL}
};

void InitItems( void ) {
    game.num_items = sizeof( itemlist ) / sizeof( itemlist[0] ) - 1;
}

/*
===============
SetItemNames

Called by worldspawn
===============
*/
void SetItemNames( void ) {
    int i;
    gitem_t *it;

    for ( i = 0; i < game.num_items; i++ ) {
        it = &itemlist[i];
        gi.configstring( CS_ITEMS + i, it->pickup_name );
    }
}
