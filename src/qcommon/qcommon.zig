
const std = @import("std");

pub const c = @cImport({
    @cInclude("qcommon/qcommon.h");
});

pub const msg = @import("msg.zig");

var platformString: [128:0]u8 = undefined;
pub fn GetPlatformString() ?[*:0]u8 {
    _ = std.fmt.bufPrint( platformString[0..], "ztech2 0.1.0 {}/{}", .{ std.meta.tagName(std.builtin.os.tag), std.meta.tagName(std.builtin.arch) } ) catch return null;
    return &platformString;
}

// vector generics 
pub fn VectorCopy( comptime T: type, a: T, b: T ) void { b[0] = a[0]; b[1] = a[1]; b[2] = a[2]; }

pub fn va( print_level: c_int, fmt: [*c]u8, args: ?[*]u8 ) void {
    var msg: [4096]u8 = undefined;

    _ = c.sprintf( &msg, fmt, args );

    if ( true ) {
        c.Com_Printf( "VID: %s", msg );
    } else {
        c.Com_DPrintf( "VID: %s", msg );
    }
}

