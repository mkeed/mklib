const dir = "Modules/Lua/lua-5.4.4/src/";

const core_src = [_][]const u8{
    dir ++ "lapi.c",
    dir ++ "lcode.c",
    dir ++ "lctype.c",
    dir ++ "ldebug.c",
    dir ++ "ldo.c",
    dir ++ "ldump.c",
    dir ++ "lfunc.c",
    dir ++ "lgc.c",
    dir ++ "llex.c",
    dir ++ "lmem.c",
    dir ++ "lobject.c",
    dir ++ "lopcodes.c",
    dir ++ "lparser.c",
    dir ++ "lstate.c",
    dir ++ "lstring.c",
    dir ++ "ltable.c",
    dir ++ "ltm.c",
    dir ++ "lundump.c",
    dir ++ "lvm.c",
    dir ++ "lzio.c",
};

const lib_src = [_][]const u8{
    dir ++ "lauxlib.c",
    dir ++ "lbaselib.c",
    dir ++ "lcorolib.c",
    dir ++ "ldblib.c",
    dir ++ "liolib.c",
    dir ++ "lmathlib.c",
    dir ++ "loadlib.c",
    dir ++ "loslib.c",
    dir ++ "lstrlib.c",
    dir ++ "ltablib.c",
    dir ++ "lutf8lib.c",
    dir ++ "linit.c",
};

const base_src = core_src ++ lib_src;

const flags = [_][]const u8{
    "-DLUA_COMPAT_5_3",
};
