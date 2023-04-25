pub const Colour = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const Face = struct {
    fg: Colour,
    bg: Colour,
};

pub const Pos = struct {
    x: isize,
    y: isize,
};

pub const LineInfo = struct {
    lineNum: usize,
    text: []const u8,
    len: usize,
    pos: Pos,
};

pub const Line = []const u8;

pub const BufferDisplay = struct {
    lines: []const Line,
    modeLine: []const u8,
};

pub const BufferInfo = struct {
    pos: Pos,
    buffer: BufferDisplay,
};

pub const ScreenDisplay = struct {
    screenSize: Pos,
    cursorPos: Pos,
    menuItems: []const []const u8,
    cmdline: []const u8,
    buffers: []const BufferInfo,
};

const colPos: usize = 50;
