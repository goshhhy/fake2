export fn VID_MenuInit() void {
}

export fn VID_MenuDraw() void {
}

export fn VID_MenuKey(k: i32) ?*[]const u8 {
    _ = k;
    return null;
}