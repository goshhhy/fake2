// sys_null.h -- null system driver to aid porting efforts

const c = @cImport({
    @cInclude("qcommon/qcommon.h");
    @cInclude("game/game.h");
});

const std = @import("std");

// hunk allocation

var memBase: ?[*]u8 = null;
var maxHunkSize: u32 = 0;
var curHunkSize: u32 = 0;

pub export fn Hunk_Begin( maxSize: u32 ) [*]u8 {
    maxHunkSize = maxSize + @sizeOf( u32 );
    curHunkSize = 0;

    const base = std.os.mmap( null, maxHunkSize, 
                            std.os.PROT.READ | std.os.PROT.WRITE,
                            std.os.MAP.PRIVATE | std.os.MAP.ANONYMOUS,
                            -1, 0 ) catch @panic("Memory allocation failed in Hunk_Begin"); 

    memBase = base.ptr;
    const mBaseU32Ptr = @ptrCast( [*]u32, @alignCast( 4096, memBase ) );

    mBaseU32Ptr[0] = curHunkSize;

    return @intToPtr( [*]u8, @ptrToInt( memBase ) + @sizeOf( u32 ) );
}

pub export fn Hunk_Alloc( size: u32 ) [*]u8 {
    const fixedSize = size + 32;

    if ( curHunkSize + fixedSize > maxHunkSize ) {
        @panic("Hunk_Alloc overflowed");
    }
    const buf = @ptrToInt( memBase ) + @sizeOf( u32 ) + curHunkSize;
    curHunkSize = curHunkSize + fixedSize;
    return @intToPtr( [*]u8, buf );
}

// normally this function would remap the entire hunk
// not bothering here, since zig doesn't provide mremap, and this function
// is going to be removed later anyway
pub export fn Hunk_End() u32 {
    const mBaseU32Ptr = @ptrCast( [*]u32, @alignCast( 4096, memBase ) );
    mBaseU32Ptr[0] = maxHunkSize;

    return maxHunkSize;
}

pub export fn Hunk_Free( base_optional: ?[*]u8 ) void {
    if ( base_optional ) |base| {
        const baseAdjust = base - 4;
        const mBaseU32Ptr = @ptrCast( [*]u32, @alignCast( 4096, baseAdjust ) );
        const len = mBaseU32Ptr[0];
        const baseSlice = baseAdjust[0..len];
        std.os.munmap( @alignCast( 16384, baseSlice ) );
    }
}

// time

pub export var curtime: u64 = 0;
pub export var sys_frame_time: u64 = 0;

pub export fn Sys_Milliseconds() u64 {
    curtime = @intCast( u64, std.time.milliTimestamp() );
    return curtime;
}

pub export fn Sys_Init() void {
}

pub export fn Sys_Quit() void {
    c.CL_Shutdown();
    c.Qcommon_Shutdown();
    c.exit(0);
}

extern fn GetGameAPI( gi: *i32 ) *i32;
pub export fn Sys_GetGameAPI (parms: *i32) *i32 {
    return GetGameAPI (parms);
}

pub export fn Sys_UnloadGame() void {
}

pub export fn Sys_ConsoleInput() [*c]u8 {
    return null;
}

pub export fn Sys_SendKeyEvents() void {
    sys_frame_time = Sys_Milliseconds();
}

pub export fn Sys_AppActivate() void {
}

pub export fn Sys_GetClipboardData() [*c]u8 {
    return null;
}

pub export fn Sys_Mkdir( path: [*]u8 ) void {
    std.os.mkdir( path[0..(c.strlen(path))], 0o777 ) catch {
        std.debug.print("Sys_Mkdir: couldn't make directory {*}\n", .{path} );
    };
}

pub fn main () void {
    var time: u64 = 0;
    var oldtime: u64 = Sys_Milliseconds();
    var newtime: u64 = 0;

    c.Qcommon_Init( 0, null );
    while ( true ) {
        time = 0;
        while ( time < 1 ) {
            newtime = Sys_Milliseconds();
            time = newtime - oldtime;
        }
        c.Qcommon_Frame( time );
        oldtime = newtime;
    }
}


