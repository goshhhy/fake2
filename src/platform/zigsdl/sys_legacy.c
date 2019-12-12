/* this file is for stuff i don't know how to write in zig
    or that i expect will not ultimately be included or necessary
*/

#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>

#include "../../qcommon/qcommon.h"

#define MAXPRINTMSG 4096
void VID_Printf( int print_level, char *fmt, ... ) {
    va_list argptr;
    char msg[MAXPRINTMSG];
    static qboolean inupdate;

    va_start( argptr, fmt );
    vsprintf( msg, fmt, argptr );
    va_end( argptr );

    if ( print_level == PRINT_ALL )
        Com_Printf( "%s", msg );
    else
        Com_DPrintf( "%s", msg );
}

void Sys_ConsoleOutput( char *string ) { fputs( string, stdout ); }

void Sys_Printf( char *fmt, ... ) {
    va_list argptr;
    char text[1024];
    unsigned char *p;

    va_start( argptr, fmt );
    vsprintf( text, fmt, argptr );
    va_end( argptr );

    if ( strlen( text ) > sizeof( text ) )
        Sys_Error( "memory overwrite in Sys_Printf" );

    for ( p = (unsigned char *)text; *p; p++ ) {
        *p &= 0x7f;
        if ( ( *p > 128 || *p < 32 ) && *p != 10 && *p != 13 && *p != 9 )
            printf( "[%02x]", *p );
        else
            putc( *p, stdout );
    }
}

void Sys_Error( char *error, ... ) {
    va_list argptr;
    char string[1024];

    CL_Shutdown();
    Qcommon_Shutdown();

    va_start( argptr, error );
    vsprintf( string, error, argptr );
    va_end( argptr );
    fprintf( stderr, "Error: %s\n", string );

    _exit( 1 );
}

void Sys_Warn( char *warning, ... ) {
    va_list argptr;
    char string[1024];

    va_start( argptr, warning );
    vsprintf( string, warning, argptr );
    va_end( argptr );
    fprintf( stderr, "Warning: %s", string );
}

/*
============
Sys_FileTime

returns -1 if not present
============
*/
int Sys_FileTime( char *path ) {
    struct stat buf;

    if ( stat( path, &buf ) == -1 )
        return -1;

    return buf.st_mtime;
}