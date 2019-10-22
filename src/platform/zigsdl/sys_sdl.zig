// sys_null.h -- null system driver to aid porting efforts

const c = @cImport(@cInclude("qcommon/qcommon.h"));

int	curtime;
unsigned	sys_frame_time;

void Sys_mkdir (char *path) {
}

void Sys_Quit (void) {
	exit (0);
}

void	Sys_UnloadGame (void) {
}

void	*Sys_GetGameAPI (void *parms) {
	return NULL;
}

fn Sys_ConsoleInput () [*]u8 {
	return NULL;
}

fn Sys_ConsoleOutput (char *string) void {
	sys.debug.warn(string);
}

fn Sys_SendKeyEvents () void {
}

fn Sys_AppActivate () void {
}

fn Sys_CopyProtect () void {
	// no copy protection here...
}

fn Sys_GetClipboardData() [*]u8 {
	return NULL;
}

void	*Hunk_Begin (int maxsize) {
	return NULL;
}

void	*Hunk_Alloc (int size) {
	return NULL;
}

void	Hunk_Free (void *buf) {
}

int		Hunk_End (void) {
	return 0;
}

int		Sys_Milliseconds (void) {
	return 0;
}

void	Sys_Mkdir (char *path) {
}

char	*Sys_FindFirst (char *path, unsigned musthave, unsigned canthave) {
	return NULL;
}

char	*Sys_FindNext (unsigned musthave, unsigned canthave) {
	return NULL;
}

void	Sys_FindClose (void) {
}

void	Sys_Init (void) {
}


//=============================================================================

int main (int argc, char **argv)
{
	Qcommon_Init (argc, argv);

	while (1)
	{
		Qcommon_Frame (0.1);
	}
}


