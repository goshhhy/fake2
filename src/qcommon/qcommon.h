/*
Copyright (C) 1997-2001 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

// qcommon.h -- definitions common between client and server, but not game.dll

#define _XOPEN_SOURCE 500

#include "../game/q_shared.h"

#define VERSION 3.21

#define BASEDIRNAME "baseq2"

#ifdef WIN32

#ifdef NDEBUG
#define BUILDSTRING "Win32 RELEASE"
#else
#define BUILDSTRING "Win32 DEBUG"
#endif

#ifdef _M_IX86
#define CPUSTRING "x86"
#elif defined _M_ALPHA
#define CPUSTRING "AXP"
#endif

#elif defined __linux__

#define BUILDSTRING "Linux"

#ifdef __i386__
#define CPUSTRING "i386"
#elif defined __alpha__
#define CPUSTRING "axp"
#else
#define CPUSTRING "Unknown"
#endif

#elif defined __sun__

#define BUILDSTRING "Solaris"

#ifdef __i386__
#define CPUSTRING "i386"
#else
#define CPUSTRING "sparc"
#endif

#else  // !WIN32

#define BUILDSTRING "NON-WIN32"
#define CPUSTRING "NON-WIN32"

#endif

//============================================================================

typedef struct sizebuf_s {
    bool allowoverflow;  // if false, do a Com_Error
    bool overflowed;     // set to true if the buffer size failed
    byte *data;
    int maxsize;
    int cursize;
    int readcount;
} sizebuf_t;

void SZ_Init( sizebuf_t *buf, byte *data, int length );
void SZ_Clear( sizebuf_t *buf );
void *SZ_GetSpace( sizebuf_t *buf, int length );
void SZ_Write( sizebuf_t *buf, void *data, int length );
void SZ_Print( sizebuf_t *buf, char *data );  // strcats onto the sizebuf

//============================================================================

struct usercmd_s;
struct entity_state_s;

void MSG_WriteChar( sizebuf_t *sb, int c );
void MSG_WriteByte( sizebuf_t *sb, int c );
void MSG_WriteShort( sizebuf_t *sb, int c );
void MSG_WriteLong( sizebuf_t *sb, int c );
void MSG_WriteFloat( sizebuf_t *sb, float f );
void MSG_WriteString( sizebuf_t *sb, const char *s );
void MSG_WriteCoord( sizebuf_t *sb, float f );
void MSG_WritePos( sizebuf_t *sb, vec3_t pos );
void MSG_WriteAngle( sizebuf_t *sb, float f );
void MSG_WriteAngle16( sizebuf_t *sb, float f );
void MSG_WriteDeltaUsercmd( sizebuf_t *sb, struct usercmd_s *from,
                            struct usercmd_s *cmd );
void MSG_WriteDeltaEntity( struct entity_state_s *from,
                           struct entity_state_s *to, sizebuf_t *msg,
                           bool force, bool newentity );
void MSG_WriteDir( sizebuf_t *sb, vec3_t vector );

void MSG_BeginReading( sizebuf_t *sb );

int MSG_ReadChar( sizebuf_t *sb );
int MSG_ReadByte( sizebuf_t *sb );
int MSG_ReadShort( sizebuf_t *sb );
int MSG_ReadLong( sizebuf_t *sb );
float MSG_ReadFloat( sizebuf_t *sb );
char *MSG_ReadString( sizebuf_t *sb );
char *MSG_ReadStringLine( sizebuf_t *sb );

float MSG_ReadCoord( sizebuf_t *sb );
void MSG_ReadPos( sizebuf_t *sb, vec3_t pos );
float MSG_ReadAngle( sizebuf_t *sb );
float MSG_ReadAngle16( sizebuf_t *sb );
void MSG_ReadDeltaUsercmd( sizebuf_t *sb, struct usercmd_s *from,
                           struct usercmd_s *cmd );

void MSG_ReadDir( sizebuf_t *sb, vec3_t vector );

void MSG_ReadData( sizebuf_t *sb, void *buffer, int size );

//============================================================================

extern bool bigendien;

extern short BigShort( short l );
extern short LittleShort( short l );
extern int BigLong( int l );
extern int LittleLong( int l );
extern float BigFloat( float l );
extern float LittleFloat( float l );

//============================================================================

int COM_Argc( void );
char *COM_Argv( int arg );  // range and null checked
void COM_ClearArgv( int arg );
int COM_CheckParm( char *parm );
void COM_AddParm( char *parm );

void COM_Init( void );
void COM_InitArgv( int argc, char **argv );

char *CopyString( char *in );

//============================================================================

void Info_Print( char *s );

/* crc.h */

void CRC_Init( unsigned short *crcvalue );
void CRC_ProcessByte( unsigned short *crcvalue, byte data );
unsigned short CRC_Value( unsigned short crcvalue );
unsigned short CRC_Block( byte *start, int count );

/*
==============================================================

PROTOCOL

==============================================================
*/

#include "protocol.h"

/*
==============================================================

CMD

Command text buffering and command execution

==============================================================
*/

/*

Any number of commands can be added in a frame, from several different sources.
Most commands come from either keybindings or console line input, but remote
servers can also send across commands and entire text files can be execed.

The + command line options are also added to the command buffer.

The game starts with a Cbuf_AddText ("exec quake.rc\n"); Cbuf_Execute ();

*/

#define EXEC_NOW 0     // don't return until completed
#define EXEC_INSERT 1  // insert at current position, but don't run yet
#define EXEC_APPEND 2  // add to end of the command buffer

void Cbuf_Init( void );
// allocates an initial text buffer that will grow as needed

void Cbuf_AddText( char *text );
// as new commands are generated from the console or keybindings,
// the text is added to the end of the command buffer.

void Cbuf_InsertText( char *text );
// when a command wants to issue other commands immediately, the text is
// inserted at the beginning of the buffer, before any remaining unexecuted
// commands.

void Cbuf_ExecuteText( int exec_when, char *text );
// this can be used in place of either Cbuf_AddText or Cbuf_InsertText

void Cbuf_AddEarlyCommands( bool clear );
// adds all the +set commands from the command line

bool Cbuf_AddLateCommands( void );
// adds all the remaining + commands from the command line
// Returns true if any late commands were added, which
// will keep the demoloop from immediately starting

void Cbuf_Execute( void );
// Pulls off \n terminated lines of text from the command buffer and sends
// them through Cmd_ExecuteString.  Stops when the buffer is empty.
// Normally called once per frame, but may be explicitly invoked.
// Do not call inside a command function!

void Cbuf_CopyToDefer( void );
void Cbuf_InsertFromDefer( void );
// These two functions are used to defer any pending commands while a map
// is being loaded

//===========================================================================

/*

Command execution takes a null terminated string, breaks it into tokens,
then searches for a command or variable that matches the first token.

*/

typedef void ( *xcommand_t )( void );

void Cmd_Init( void );

void Cmd_AddCommand( const char *cmd_name, xcommand_t function );
// called by the init functions of other parts of the program to
// register commands and functions to call for them.
// The cmd_name is referenced later, so it should not be in temp memory
// if function is NULL, the command will be forwarded to the server
// as a clc_stringcmd instead of executed locally
void Cmd_RemoveCommand( char *cmd_name );

bool Cmd_Exists( char *cmd_name );
// used by the cvar code to check for cvar / command name overlap

char *Cmd_CompleteCommand( char *partial );
// attempts to match a partial command for automatic command line completion
// returns NULL if nothing fits

int Cmd_Argc( void );
char *Cmd_Argv( int arg );
char *Cmd_Args( void );
// The functions that execute commands get their parameters with these
// functions. Cmd_Argv () will return an empty string, not a NULL
// if arg > argc, so string operations are always safe.

void Cmd_TokenizeString( char *text, bool macroExpand );
// Takes a null terminated string.  Does not need to be /n terminated.
// breaks the string up into arg tokens.

void Cmd_ExecuteString( char *text );
// Parses a single line of text into arguments and tries to execute it
// as if it was typed at the console

void Cmd_ForwardToServer( void );
// adds the current command line as a clc_stringcmd to the client message.
// things like godmode, noclip, etc, are commands directed to the server,
// so when they are typed in at the console, they will need to be forwarded.

/*
==============================================================

CVAR

==============================================================
*/

/*

cvar_t variables are used to hold scalar or string variables that can be changed
or displayed at the console or prog code as well as accessed directly in C code.

The user can access cvars from the console in three ways:
r_draworder			prints the current value
r_draworder 0		sets the current value to 0
set r_draworder 0	as above, but creates the cvar if not present
Cvars are restricted from having the same names as commands to keep this
interface from being ambiguous.
*/

extern cvar_t *cvar_vars;

cvar_t *Cvar_Get( const char *var_name, const char *value, int flags );
// creates the variable if it doesn't exist, or returns the existing one
// if it exists, the value will not be changed, but flags will be ORed in
// that allows variables to be unarchived without needing bitflags

cvar_t *Cvar_Set( const char *var_name, const char *value );
// will create the variable if it doesn't exist

cvar_t *Cvar_ForceSet( const char *var_name, const char *value );
// will set the variable even if NOSET or LATCH

cvar_t *Cvar_FullSet( const char *var_name, const char *value, int flags );

void Cvar_SetValue( const char *var_name, float value );
// expands value to a string and calls Cvar_Set

float Cvar_VariableValue( const char *var_name );
// returns 0 if not defined or non numeric

char *Cvar_VariableString( const char *var_name );
// returns an empty string if not defined

char *Cvar_CompleteVariable( const char *partial );
// attempts to match a partial variable name for command line completion
// returns NULL if nothing fits

void Cvar_GetLatchedVars( void );
// any CVAR_LATCHED variables that have been set will now take effect

bool Cvar_Command( void );
// called by Cmd_ExecuteString when Cmd_Argv(0) doesn't match a known
// command.  Returns true if the command was a variable reference that
// was handled. (print or change)

void Cvar_WriteVariables( const char *path );
// appends lines containing "set variable value" for all variables
// with the archive flag set to true.

void Cvar_Init( void );

char *Cvar_Userinfo( void );
// returns an info string containing all the CVAR_USERINFO cvars

char *Cvar_Serverinfo( void );
// returns an info string containing all the CVAR_SERVERINFO cvars

extern bool userinfo_modified;
// this is set each time a CVAR_USERINFO variable is changed
// so that the client knows to send it to the server

/*
==============================================================

NET

==============================================================
*/

// net.h -- quake's interface to the networking layer

#define PORT_ANY -1

#define MAX_MSGLEN 1400   // max length of a message
#define PACKET_HEADER 10  // two ints and a short

typedef enum { NA_LOOPBACK, NA_BROADCAST, NA_IP } netadrtype_t;

typedef enum { NS_CLIENT, NS_SERVER } netsrc_t;

typedef struct {
    netadrtype_t type;

    byte ip[4];

    unsigned short port;
} netadr_t;

void NET_Init( void );
void NET_Shutdown( void );

void NET_Config( bool multiplayer );

bool NET_GetPacket( netsrc_t sock, netadr_t *net_from,
                        sizebuf_t *net_message );
void NET_SendPacket( netsrc_t sock, int length, void *data, netadr_t to );

bool NET_CompareAdr( netadr_t a, netadr_t b );
bool NET_CompareBaseAdr( netadr_t a, netadr_t b );
bool NET_IsLocalAddress( netadr_t adr );
char *NET_AdrToString( netadr_t a );
bool NET_StringToAdr( char *s, netadr_t *a );
void NET_Sleep( int msec );

//============================================================================

#define OLD_AVG 0.99  // total = oldtotal*OLD_AVG + new*(1-OLD_AVG)

#define MAX_LATENT 32

typedef struct {
    bool fatal_error;

    netsrc_t sock;

    int dropped;  // between last packet and previous

    uint64_t last_received;  // for timeouts
    uint64_t last_sent;      // for retransmits

    netadr_t remote_address;
    int qport;  // qport value to write when transmitting

    // sequencing variables
    int incoming_sequence;
    int incoming_acknowledged;
    int incoming_reliable_acknowledged;  // single bit

    int incoming_reliable_sequence;  // single bit, maintained local

    int outgoing_sequence;
    int reliable_sequence;       // single bit
    int last_reliable_sequence;  // sequence number of last send

    // reliable staging and holding areas
    sizebuf_t message;                  // writing buffer to send to server
    byte message_buf[MAX_MSGLEN - 16];  // leave space for header

    // message is copied to this buffer when it is first transfered
    int reliable_length;
    byte reliable_buf[MAX_MSGLEN - 16];  // unacked reliable message
} netchan_t;

extern netadr_t net_from;
extern sizebuf_t net_message;
extern byte net_message_buffer[MAX_MSGLEN];

void Netchan_Init( void );
void Netchan_Setup( netsrc_t sock, netchan_t *chan, netadr_t adr, int qport );

bool Netchan_NeedReliable( netchan_t *chan );
void Netchan_Transmit( netchan_t *chan, int length, byte *data );
void Netchan_OutOfBand( int net_socket, netadr_t adr, int length, byte *data );
void Netchan_OutOfBandPrint( int net_socket, netadr_t adr, const char *format, ... );
bool Netchan_Process( netchan_t *chan, sizebuf_t *msg );

bool Netchan_CanReliable( netchan_t *chan );

/*
==============================================================

CMODEL

==============================================================
*/

#include "../qcommon/qfiles.h"

cmodel_t *CM_LoadMap( char *name, bool clientload, unsigned *checksum );
cmodel_t *CM_InlineModel( const char *name );  // *1, *2, etc

int CM_NumClusters( void );
int CM_NumInlineModels( void );
char *CM_EntityString( void );

// creates a clipping hull for an arbitrary box
int CM_HeadnodeForBox( vec3_t mins, vec3_t maxs );

// returns an ORed contents mask
int CM_PointContents( vec3_t p, int headnode );
int CM_TransformedPointContents( vec3_t p, int headnode, vec3_t origin,
                                 vec3_t angles );

trace_t CM_BoxTrace( vec3_t start, vec3_t end, vec3_t mins, vec3_t maxs,
                     int headnode, int brushmask );
trace_t CM_TransformedBoxTrace( vec3_t start, vec3_t end, vec3_t mins,
                                vec3_t maxs, int headnode, int brushmask,
                                vec3_t origin, vec3_t angles );

byte *CM_ClusterPVS( int cluster );
byte *CM_ClusterPHS( int cluster );

int CM_PointLeafnum( vec3_t p );

// call with topnode set to the headnode, returns with topnode
// set to the first node that splits the box
int CM_BoxLeafnums( vec3_t mins, vec3_t maxs, int *list, int listsize,
                    int *topnode );

int CM_LeafContents( int leafnum );
int CM_LeafCluster( int leafnum );
int CM_LeafArea( int leafnum );

void CM_SetAreaPortalState( int portalnum, bool open );
bool CM_AreasConnected( int area1, int area2 );

int CM_WriteAreaBits( byte *buffer, int area );
bool CM_HeadnodeVisible( int headnode, byte *visbits );

void CM_WritePortalState( FILE *f );
void CM_ReadPortalState( FILE *f );

/*
==============================================================

PLAYER MOVEMENT CODE

Common between server and client so prediction matches

==============================================================
*/

extern float pm_airaccelerate;

void Pmove( pmove_t *pmove );

/*
==============================================================

FILESYSTEM

==============================================================
*/

void FS_InitFilesystem( void );
void FS_SetGamedir( char *dir );
char *FS_Gamedir( void );
char *FS_NextPath( char *prevpath );
void FS_ExecAutoexec( void );

int FS_FOpenFile( char *filename, FILE **file );
void FS_FCloseFile( FILE *f );
// note: this can't be called from another DLL, due to MS libc issues

int FS_LoadFile( char *path, void **buffer );
// a null buffer will just return the file length without loading
// a -1 length is not present

void FS_Read( void *buffer, int len, FILE *f );
// properly handles partial reads

void FS_FreeFile( void *buffer );

void FS_CreatePath( char *path );

/*
==============================================================

MISC

==============================================================
*/

#define ERR_FATAL 0  // exit the entire game with a popup window
#define ERR_DROP 1   // print to console and disconnect from game
#define ERR_QUIT 2   // not an error, just a normal exit

#define EXEC_NOW 0     // don't return until completed
#define EXEC_INSERT 1  // insert at current position, but don't run yet
#define EXEC_APPEND 2  // add to end of the command buffer

#define PRINT_ALL 0
#define PRINT_DEVELOPER 1  // only print when "developer 1"

void Com_BeginRedirect( int target, char *buffer, int buffersize,
                        void( *flush ) );
void Com_EndRedirect( void );
void Com_Printf( const char *fmt, ... );
void Com_DPrintf( const char *fmt, ... );
void Com_Error( int code, const char *fmt, ... );
void Com_Quit( void );

int Com_ServerState( void );  // this should have just been a cvar...
void Com_SetServerState( int state );

uint32_t Com_BlockChecksum( void *buffer, size_t length );
byte COM_BlockSequenceCRCByte( byte *base, int length, int sequence );

float frand( void );  // 0 ti 1
float crand( void );  // -1 to 1

extern cvar_t *developer;
extern cvar_t *dedicated;
extern cvar_t *host_speeds;
extern cvar_t *log_stats;

extern FILE *log_stats_file;

// host_speeds times
extern int time_before_game;
extern int time_after_game;
extern int time_before_ref;
extern int time_after_ref;

// stuff
extern const char* GetPlatformString();

void Z_Free( void *ptr );
void *Z_Malloc( int size );  // returns 0 filled memory
void *Z_TagMalloc( int size, int tag );
void Z_FreeTags( int tag );

void Qcommon_Init( int argc, char **argv );
void Qcommon_Frame( uint64_t msec );
void Qcommon_Shutdown( void );

#define NUMVERTEXNORMALS 162
extern vec3_t bytedirs[NUMVERTEXNORMALS];

// this is in the client code, but can be used for debugging from server
void SCR_DebugGraph( float value, int color );

/*
==============================================================

NON-PORTABLE SYSTEM SERVICES

==============================================================
*/

void Sys_Init( void );

void Sys_AppActivate( void );

void Sys_UnloadGame( void );
void *Sys_GetGameAPI( void *parms );
// loads the game dll and calls the api init function

char *Sys_ConsoleInput( void );
void Sys_ConsoleOutput( char *string );
void Sys_SendKeyEvents( void );
void Sys_Error( char *error, ... );
void Sys_Quit( void );
char *Sys_GetClipboardData( void );

/*
==============================================================

CLIENT / SERVER SYSTEMS

==============================================================
*/

void CL_Init( void );
void CL_Drop( void );
void CL_Shutdown( void );
void CL_Frame( int msec );
void Con_Print( char *text );
void SCR_BeginLoadingPlaque( void );

void SV_Init( void );
void SV_Shutdown( char *finalmsg, bool reconnect );
void SV_Frame( int msec );
