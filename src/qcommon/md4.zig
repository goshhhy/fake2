const std = @import("std");
const assert = std.debug.assert;

var X: [16]u32 = [_]u32 {0} ** 16;
var A: u32 = 0;
var B: u32 = 0;
var C: u32 = 0;
var D: u32 = 0;
var AA: u32 = 0;
var BB: u32 = 0;
var CC: u32 = 0;
var DD: u32 = 0;

fn F( x: u32, y: u32, z: u32 ) u32 {
    return ( ( (x) & (y) ) | ( (~x) & (z) ) );
}

fn G( x: u32, y: u32, z: u32 ) u32 {
    return ( ( (x) & (y) ) | ( (x) & (z) ) | ( (y) & (z) ) );
}

fn H( x: u32, y: u32, z: u32 ) u32 {
    return ( (x) ^ (y) ^ (z) );
}

fn S( a: *u32, b: u32, c: u32, d: u32, k: u32, s: u32 ) void {
    var f = F( ( b ), ( c ), ( d ) );
    _ = @addWithOverflow( u32, f, X[( k )], &f );
    _ = @addWithOverflow( u32, a.*, f, a );
    a.* = std.math.rotl(u32, a.*, s);
}

fn T( a: *u32, b: u32, c: u32, d: u32, k: u32, s: u32 ) void {
    var g = ( G( ( b ), ( c ), ( d ) ) );
    _ = @addWithOverflow( u32, g, X[( k )], &g );
    _ = @addWithOverflow( u32, g, 0x5A827999, &g );
    _ = @addWithOverflow( u32, a.*, g, a );
    a.* = std.math.rotl(u32, a.*, s);
}

fn U( a: *u32, b: u32, c: u32, d: u32, k: u32, s: u32 ) void {
    var h = ( H( ( b ), ( c ), ( d ) ) );
    _ = @addWithOverflow( u32, h, X[( k )], &h );
    _ = @addWithOverflow( u32, h, 0x6ED9EBA1, &h );
    _ = @addWithOverflow( u32, a.*, h, a );
    a.* = std.math.rotl(u32, a.*, s);
}

fn hash_core() void {
    AA = A;
    BB = B;
    CC = C;
    DD = D;

    S( &A, B, C, D, 0, 3 );
    S( &D, A, B, C, 1, 7 );
    S( &C, D, A, B, 2, 11 );
    S( &B, C, D, A, 3, 19 );
    S( &A, B, C, D, 4, 3 );
    S( &D, A, B, C, 5, 7 );
    S( &C, D, A, B, 6, 11 );
    S( &B, C, D, A, 7, 19 );
    S( &A, B, C, D, 8, 3 );
    S( &D, A, B, C, 9, 7 );
    S( &C, D, A, B, 10, 11 );
    S( &B, C, D, A, 11, 19 );
    S( &A, B, C, D, 12, 3 );
    S( &D, A, B, C, 13, 7 );
    S( &C, D, A, B, 14, 11 );
    S( &B, C, D, A, 15, 19 );

    T( &A, B, C, D, 0, 3 );
    T( &D, A, B, C, 4, 5 );
    T( &C, D, A, B, 8, 9 );
    T( &B, C, D, A, 12, 13 );
    T( &A, B, C, D, 1, 3 );
    T( &D, A, B, C, 5, 5 );
    T( &C, D, A, B, 9, 9 );
    T( &B, C, D, A, 13, 13 );
    T( &A, B, C, D, 2, 3 );
    T( &D, A, B, C, 6, 5 );
    T( &C, D, A, B, 10, 9 );
    T( &B, C, D, A, 14, 13 );
    T( &A, B, C, D, 3, 3 );
    T( &D, A, B, C, 7, 5 );
    T( &C, D, A, B, 11, 9 );
    T( &B, C, D, A, 15, 13 );

    U( &A, B, C, D, 0, 3 );
    U( &D, A, B, C, 8, 9 );
    U( &C, D, A, B, 4, 11 );
    U( &B, C, D, A, 12, 15 );
    U( &A, B, C, D, 2, 3 );
    U( &D, A, B, C, 10, 9 );
    U( &C, D, A, B, 6, 11 );
    U( &B, C, D, A, 14, 15 );
    U( &A, B, C, D, 1, 3 );
    U( &D, A, B, C, 9, 9 );
    U( &C, D, A, B, 5, 11 );
    U( &B, C, D, A, 13, 15 );
    U( &A, B, C, D, 3, 3 );
    U( &D, A, B, C, 11, 9 );
    U( &C, D, A, B, 7, 11 );
    U( &B, C, D, A, 15, 15 );

    _ = @addWithOverflow( u32, A, AA, &A );
    _ = @addWithOverflow( u32, B, BB, &B );
    _ = @addWithOverflow( u32, C, CC, &C );
    _ = @addWithOverflow( u32, D, DD, &D );
}

fn hash( buffer: [*]const u8, length: u32, _digest: *[4]u32 ) void {
    var len: u32 = length / 64;
    var rem: u32 = length % 64;
    var digest = @ptrCast( *[16]u8, _digest );

    A = 0x67452301;
    B = 0xEFCDAB89;
    C = 0x98BADCFE;
    D = 0x10325476;

    var ptr = buffer;

    var i: usize = 0;
    var j: usize = 0;
    while ( i < len ) : ( i += 1 ) {
        while ( j < 16 ) : ( j += 1 ) {
            X[j] = ( ( ptr[0] ) | std.math.shl( u32, ptr[1], 8 ) | std.math.shl( u32, ptr[2], 16 ) | std.math.shl( u32, ptr[3], 24 ) );

            ptr += 4;
        }
        hash_core();
    }

    i = rem / 4;
    j = 0;
    while ( j < i ) : ( j += 1 ) {
        X[j] = ( ( ptr[0] ) | std.math.shl( u32, ptr[1], 8 ) | std.math.shl( u32, ptr[2], 16 ) | std.math.shl( u32, ptr[3], 24 ) );

        ptr += 4;
    }
    
    switch ( rem % 4 ) {
        0 => { X[j] = 0x80; },
        1 => { X[j] = ( ( ptr[0] ) | std.math.shl( u32, ( 0x80 ), 8 ) ); },
        2 => { X[j] = ( ( ptr[0] ) | std.math.shl( u32, ptr[1], 8 ) | std.math.shl( u32, ( 0x80 ), 16 ) ); },
        3 => { X[j] = ( ( ptr[0] ) | std.math.shl( u32, ptr[1], 8 ) | std.math.shl( u32, ptr[2], 16 ) | std.math.shl( u32, ( 0x80 ), 24 ) ); },
        else => { @panic("impossible switch case in md4"); },   
    }

    j += 1;
    if ( j > 14 ) {
        while ( j < 16 ) : ( j += 1 ) {
            X[j] = 0;
        }
        hash_core();
        j = 0;
    }

    while ( j < 14 ) : ( j += 1 ) {
        X[j] = 0;
    }

    X[14] = std.math.shl( u32, ( length & 0x1FFFFFFF ), 3 );
    X[15] = std.math.shl( u32, ( length & 0xE0000000 ), 29 );

    hash_core();

    digest[0] = @truncate( u8, std.math.shr( u32, ( A & 0x000000FF ), 0 ) );
    digest[1] = @truncate( u8, std.math.shr( u32, ( A & 0x0000FF00 ), 8 ) );
    digest[2] = @truncate( u8, std.math.shr( u32, ( A & 0x00FF0000 ), 16 ) );
    digest[3] = @truncate( u8, std.math.shr( u32, ( A & 0xFF000000 ), 24 ) );
    digest[4] = @truncate( u8, std.math.shr( u32, ( B & 0x000000FF ), 0 ) );
    digest[5] = @truncate( u8, std.math.shr( u32, ( B & 0x0000FF00 ), 8 ) );
    digest[6] = @truncate( u8, std.math.shr( u32, ( B & 0x00FF0000 ), 16 ) );
    digest[7] = @truncate( u8, std.math.shr( u32, ( B & 0xFF000000 ), 24 ) );
    digest[8] = @truncate( u8, std.math.shr( u32, ( C & 0x000000FF ), 0 ) );
    digest[9] = @truncate( u8, std.math.shr( u32, ( C & 0x0000FF00 ), 8 ) );
    digest[10] = @truncate( u8, std.math.shr( u32, ( C & 0x00FF0000 ), 16 ) );
    digest[11] = @truncate( u8, std.math.shr( u32, ( C & 0xFF000000 ), 24 ) );
    digest[12] = @truncate( u8, std.math.shr( u32, ( D & 0x000000FF ), 0 ) );
    digest[13] = @truncate( u8, std.math.shr( u32, ( D & 0x0000FF00 ), 8 ) );
    digest[14] = @truncate( u8, std.math.shr( u32, ( D & 0x00FF0000 ), 16 ) );
    digest[15] = @truncate( u8, std.math.shr( u32, ( D & 0xFF000000 ), 24 ) );

    A = 0;
    B = 0;
    C = 0;
    D = 0;
    AA = 0;
    BB = 0;
    CC = 0;
    DD = 0;

    j = 0;
    while ( j < 16 ) : ( j += 1 ) {
        X[j] = 0;
    }
}

export fn Com_BlockChecksum( buffer: [*]const u8, len: u32 ) u32 {
    var digest = [_]u32{0} ** 4;
    hash(buffer, len, &digest);
    return digest[0] ^ digest[1] ^ digest[2] ^ digest[3];
}

test "empty string" {
    var buffer: [*]const u8 = "";
    var digest = [_]u32{0} ** 4;

    hash(buffer, 1, &digest);

    @import("std").debug.warn( "value is {x:8} {x:8} {x:8} {x:8}\n", .{digest[0], digest[1], digest[2], digest[3]} );

    @import("std").debug.assert(digest[0] == 0x31d6cfe0 );

}