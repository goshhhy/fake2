// snddma_null.c
// all other sound mixing is portable

const c = @cImport({
    @cInclude("client/client.h");
    @cInclude("client/snd_loc.h");
    @cInclude("SDL.h");
});

const std = @import("std");

var audio: c.SDL_AudioDeviceID = 0;

var bufpos: usize = 0;
var buffer: [32768]u8 = undefined;

export fn fillbuff(udata: ?*c_void, stream: [*c]u8, len: i32) void {
    var i: usize = 0;

    while ( i < len ) {
        stream[i] = buffer[bufpos];
        bufpos = bufpos + 1;
        if ( bufpos >= 32768 ) {
            bufpos = 0;
        }
        i = i + 1;
    }
}

pub export fn SNDDMA_Init() bool {
    var spec_want: c.SDL_AudioSpec = undefined;
    var spec_have: c.SDL_AudioSpec = undefined;

    if ( c.SDL_WasInit(c.SDL_INIT_AUDIO ) == 0 ) {
        if (c.SDL_Init(c.SDL_INIT_AUDIO) != 0) {
            c.SDL_Log("Unable to initialize SDL video: %s", c.SDL_GetError());
            return false;
        }
    }

    var khz: i32 = @floatToInt(i32, c.Cvar_Get("s_khz", "44", c.CVAR_ARCHIVE).*.value);
    var depth: i32 = @floatToInt(i32, c.Cvar_Get("s_depth", "16", c.CVAR_ARCHIVE).*.value);

    spec_want.freq = switch( khz ) {
        11 => 11025,
        22 => 22050,
        44 => 44100,
        48 => 48000,
        else => 44100,
    };

    if ( depth == 8 ) {
        spec_want.format = c.AUDIO_U8;
        c.dma.samples = 32768;
        c.dma.samplebits = 8;
    } else {
        spec_want.format = c.AUDIO_S16LSB;
        c.dma.samples = 16384;
        c.dma.samplebits = 16;
    }
    spec_want.channels = 2;
    spec_want.samples = 512;
    spec_want.callback = fillbuff;

    audio = c.SDL_OpenAudioDevice(null, 0, &spec_want, &spec_have, c.SDL_AUDIO_ALLOW_FREQUENCY_CHANGE);
    if ( audio == 0 ) {
        std.debug.print("snddma: unable to find a suitable audio mode\n", .{});
        return false;
    }

    c.dma.speed = spec_have.freq;
    c.dma.channels = spec_have.channels;
    c.dma.samplepos = 0;
    c.dma.buffer = &buffer;
    c.dma.submission_chunk = 64;

    c.SDL_PauseAudioDevice(audio, 0);

    return true;
}

pub export fn SNDDMA_GetDMAPos() i32 {
    return @intCast(i32, bufpos);
}

pub export fn SNDDMA_Shutdown() void {
    c.SDL_PauseAudioDevice(audio, 1);
    c.SDL_CloseAudioDevice(audio);
}

pub export fn SNDDMA_BeginPainting () void {
    c.SDL_LockAudioDevice(audio);
}

pub export fn SNDDMA_Submit() void {
    c.SDL_UnlockAudioDevice(audio);
}
