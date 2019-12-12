// stubbed-out server system, for hypothetical pure clients

pub export fn SV_Init() void {}
pub export fn SV_Shutdown( finalmsg: [*]const u8, reconnect: bool ) void {}
pub export fn SV_Frame( time: f32 ) void {}
