//const c = @cImport({
//    @cInclude("qcommon/qcommon.h");
//});

const common = @import("qcommon.zig");
const c = common.c;

pub fn WriteChar( sb: *c.sizebuf_t, c: i32 ) void {
    var buf: [*]u8 = c.SZ_GetSpace( sb, 1 );
    buf[0] = c;
}

pub fn ReadChar( sb: *c.sizebuf_t ) !u8 {
    if ( sb.*.readcount + 1 > sb.*.cursize ) {
        return error.EndOfStream;
    }
    var ret = sb.*.data[sb.*.readcount];
    sb.*.readcount += 1;
    return ret;
}

pub fn ReadShort( sb: *c.sizebuf_t ) !u16 {
    if ( sb.*.readcount + 1 > sb.*.cursize ) {
        return error.EndOfStream;
    }
    var ret: u16 = sb.*.data[@intCast(usize, sb.*.readcount)];
    const testest: u16 = 4 << 8;
    ret += @intCast(u16, sb.*.data[@intCast(usize, sb.*.readcount + 1)]) << 8;

    sb.*.readcount += 2;
    return ret;
}