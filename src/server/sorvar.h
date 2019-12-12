#define MAX_INFO_STRING 256

typedef struct client_s {
    char userinfo[MAX_INFO_STRING];
    int ping;
    int some_other_state_data;
} client_t;

typedef struct {
    client_t *clients;
} server_static_t;

extern server_static_t svs;  // persistant server info

void SV_FinalMessage( char *message, qboolean reconnect );
