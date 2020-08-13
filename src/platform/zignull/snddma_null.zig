// snddma_null.c
// all other sound mixing is portable

const c = @cImport({
    @cInclude("../../client/client.h");
    @cInclude("../../client/snd_loc.h");
});

var audio: c.SDL_AudioDeviceID = null;

pub export fn SNDDMA_Init() bool {
    return false;
}

pub export fn SNDDMA_GetDMAPos() i32 {
    return 0;
}

pub export fn SNDDMA_Shutdown() void {
}

pub export fn SNDDMA_BeginPainting () void {
}

pub export fn SNDDMA_Submit() void {
}
