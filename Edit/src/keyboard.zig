// zig fmt: off
pub const KeyCode = enum {
    A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
    Home, Insert, Delete, End, PgUp, PgDn,
    F0, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
    F13, F14, F15, F16, F17, F18, F19, F20, F21, F22, F23, F24,
    Up, Down, Left, Right,
    Zero, One, Two, Three, Four, Five, Six, Seven, Eight, Nine,
    At, LeftBracket, Backslash, RightBracket, Caret, Backtick, Ins, Del, Win,
    Apps, Space, Exclamation, DoubleQuote, SingleQuote, Hash, Dollar, Percent,
    Ambersand, OpenParen, CloseParen, Asterisk, Comma, Hyphen, Dot, ForwardSlash,
    Colon, SemiColon, LeftAngle, RightAngle, Equal, QuestionMark,
    OpenBracket, CloseBracket, OpenBrace, CloseBrace, Pipe, Tilde, Add, Minus,
    Underscore, Esc, Enter, Tab };

// zig fmt: on
pub const KeyboardEvent = struct {
    ctrl: bool = false,
    shift: bool = false,
    alt: bool = false,
    key: KeyCode,
};

pub const InputEvent = union(enum) {
    keyboard: KeyboardEvent,
    mouse: MouseEvent,
};

pub fn decodeMouse(data: []const u8, len: *usize) App.InputEvent {
    const cb = data[0];
    const cx = data[1];
    const cy = data[2];
    len.* = 3;

    return .{ .mouse = .{ .button = cb & 0b11, .x = cx - 32, .y = cy - 32 } };
}

pub fn read(input: []const u8, output: *std.ArrayList(App.InputEvent)) !void {
    var idx: usize = 0;
    inputLoop: while (idx < input.len) : (idx += 1) {
        const val = input[idx];
        switch (val) {
            0x1b => {
                idx += 1;
                const availLength = input.len - idx;
                if (availLength >= 2 and std.mem.eql(u8, "[M", input[idx .. idx + 2])) {
                    idx += 2;
                    var len: usize = 0;
                    const mouseEv = decodeMouse(input[idx..], &len);
                    idx += len;
                    try output.append(mouseEv);
                } else {
                    for (escapeCodes) |ec| {
                        if (availLength >= ec.seq.len) {
                            if (std.mem.eql(
                                u8,
                                ec.seq,
                                input[idx .. idx + ec.seq.len],
                            )) {
                                try output.append(ec.key);
                                idx += ec.seq.len;
                                continue :inputLoop;
                            }
                        }
                    }

                    if (availLength > 0) {
                        if (input[idx] <= 0x7F) {
                            var key = AsciiToKeyCode[input[idx]];
                            key.keyboard.alt = true;
                            try output.append(key);
                        } else {
                            try output.append(AsciiToKeyCode[0x7F]);
                        }
                    }
                }
            },
            0...0x1a, 0x1c...0x7F => {
                try output.append(AsciiToKeyCode[val]);
            },
            else => {
                //unexpected value
            },
        }
    }
}
