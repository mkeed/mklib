const std = @import("std");
pub const Input = @import("App/Input.zig");
// zig fmt: off
pub const KeyCode = enum {
    A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
    Home, Insert, Delete, End, PgUp, PgDn,
    F0, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
    F13, F14, F15, F16, F17, F18, F19, F20, F21, F22, F23, F24,
    Up, Down, Left, Right,
    Zero, One, Two, Three, Four, Five, Six, Seven, Eight, Nine,
    At,  Backslash, Caret, Backtick, Ins, Del, Win,
    Apps, Space, Exclamation, DoubleQuote, SingleQuote, Hash, Dollar, Percent,
    Ambersand, OpenParen, CloseParen, Asterisk, Comma, Dot, ForwardSlash,
    Colon, SemiColon, LeftAngle, RightAngle, Equal, QuestionMark,
    OpenBracket, CloseBracket, OpenBrace, CloseBrace, Pipe, Tilde, Add, Minus,
    Underscore, Esc, Enter, Tab,
    // zig fmt: on
    pub fn toString(self: KeyCode) []const u8 {
        return switch (self) {
            .A => "A",
            .B => "B",
            .C => "C",
            .D => "D",
            .E => "E",
            .F => "F",
            .G => "G",
            .H => "H",
            .I => "I",
            .J => "J",
            .K => "K",
            .L => "L",
            .M => "M",
            .N => "N",
            .O => "O",
            .P => "P",
            .Q => "Q",
            .R => "R",
            .S => "S",
            .T => "T",
            .U => "U",
            .V => "V",
            .W => "W",
            .X => "X",
            .Y => "Y",
            .Z => "Z",
            .Home => "Home",
            .Insert => "Insert",
            .Delete => "Delete",
            .End => "End",
            .PgUp => "PgUp",
            .PgDn => "PgDn",
            .F0 => "<F0>",
            .F1 => "<F1>",
            .F2 => "<F2>",
            .F3 => "<F3>",
            .F4 => "<F4>",
            .F5 => "<F5>",
            .F6 => "<F6>",
            .F7 => "<F7>",
            .F8 => "<F8>",
            .F9 => "<F9>",
            .F10 => "<F10>",
            .F11 => "<F11>",
            .F12 => "<F12>",
            .F13 => "<F13>",
            .F14 => "<F14>",
            .F15 => "<F15>",
            .F16 => "<F16>",
            .F17 => "<F17>",
            .F18 => "<F18>",
            .F19 => "<F19>",
            .F20 => "<F20>",
            .F21 => "<F21>",
            .F22 => "<F22>",
            .F23 => "<F23>",
            .F24 => "<F24>",
            .Up => "<Up>",
            .Down => "<Down>",
            .Left => "<Left>",
            .Right => "<Right>",
            .Zero => "0",
            .One => "1",
            .Two => "2",
            .Three => "3",
            .Four => "4",
            .Five => "5",
            .Six => "6",
            .Seven => "7",
            .Eight => "8",
            .Nine => "9",
            .At => "@",
            .Backslash => "|",
            .Caret => "^",
            .Backtick => "`",
            .Ins => "<insert>",
            .Del => "<delete>",
            .Win => "<os>",
            .Apps => "Apps",
            .Space => "SPC",
            .Exclamation => "!",
            .DoubleQuote => "\"",
            .SingleQuote => "\'",
            .Hash => "#",
            .Dollar => "$",
            .Percent => "%",
            .Ambersand => "&",
            .OpenParen => "(",
            .CloseParen => ")",
            .Asterisk => "*",
            .Comma => ",",
            .Dot => ".",
            .ForwardSlash => "/",
            .Colon => ":",
            .SemiColon => ";",
            .LeftAngle => "<",
            .RightAngle => ">",
            .Equal => "=",
            .QuestionMark => "?",
            .OpenBracket => "[",
            .CloseBracket => "]",
            .OpenBrace => "{",
            .CloseBrace => "}",
            .Pipe => "|",
            .Tilde => "~",
            .Add => "+",
            .Minus => "-",
            .Underscore => "_",
            .Esc => "<Esc>",
            .Enter => "<Enter>",
            .Tab => "<tab>",
        };
    }
};

pub const KeyboardEvent = struct {
    ctrl: bool = false,
    shift: bool = false,
    alt: bool = false,
    key: KeyCode,
    pub fn format(self: KeyboardEvent, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.ctrl) {
            try std.fmt.format(writer, "C-", .{});
        }
        if (self.alt) {
            try std.fmt.format(writer, "M-", .{});
        }
        if (self.shift) {
            try std.fmt.format(writer, "S-", .{});
        }
        try std.fmt.format(writer, "{s}", .{self.key.toString()});
    }
    pub fn equal(self: KeyboardEvent, other: KeyboardEvent) bool {
        return self.ctrl == other.ctrl and
            self.alt == other.alt and
            self.shift == other.shift and
            self.key == other.key;
    }
};

pub const MouseEvent = struct {
    pub const Button = enum(u8) {
        Left,
        Middle,
        Right,
        Release,
        ScrollUp,
        ScrollDn,
    };
    button: ?Button,
    x: isize,
    y: isize,
    ctrl: bool,
    meta: bool,
    shift: bool,
};

pub const InputEvent = union(enum) {
    keyboard: KeyboardEvent,
    mouse: MouseEvent,
};

pub const Movement = union(enum) {
    Char: isize,
    Line: isize,
    Word: isize,
};

pub const Command = union(enum) {
    movement: Movement,
};
