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

pub const ScreenDisplay = struct {
    screenSize: Pos,
    cursorPos: Pos,
    menuItems: []const []const u8,
    cmdline: []const u8,
    lines: []const LineInfo,
};

const alice = @embedFile("alice.txt");
const frankenstein = @embedFile("Frankenstein.txt");

const colPos: usize = 50;

pub const disp = ScreenDisplay{
    .screenSize = .{ .x = 0, .y = 0 },
    .cursorPos = .{ .x = 1, .y = 10 },
    .menuItems = &.{ "File", "Edit", "Options", "Buffers", "Tools", "Help" },
    .cmdline = "[C-<F1>]",
    .lines = &.{
        .{ .lineNum = 1, .text = "CHAPTER I.", .len = colPos, .pos = .{ .x = 1, .y = 1 } },
        .{ .lineNum = 2, .text = "Down the Rabbit-Hole", .len = colPos, .pos = .{ .x = 1, .y = 2 } },
        .{ .lineNum = 3, .text = "", .len = colPos, .pos = .{ .x = 1, .y = 3 } },
        .{ .lineNum = 4, .text = "Alice was beginning to get very tired of sitting by", .len = colPos, .pos = .{ .x = 1, .y = 4 } },
        .{ .lineNum = 5, .text = "her sister on the bank, and of having nothing to do:", .len = colPos, .pos = .{ .x = 1, .y = 5 } },
        .{ .lineNum = 6, .text = "once or twice she had peeped into the book her sister", .len = colPos, .pos = .{ .x = 1, .y = 6 } },
        .{ .lineNum = 7, .text = "was reading, but it had no pictures or conversations", .len = colPos, .pos = .{ .x = 1, .y = 7 } },
        .{ .lineNum = 8, .text = "in it, “and what is the use of a book,” thought Alice", .len = colPos, .pos = .{ .x = 1, .y = 8 } },
        .{ .lineNum = 9, .text = "“without pictures or conversations?”", .len = colPos, .pos = .{ .x = 1, .y = 9 } },

        .{ .lineNum = 10, .text = "So she was considering in her own mind (as well as she", .len = colPos, .pos = .{ .x = 1, .y = 10 } },
        .{ .lineNum = 11, .text = "could, for the hot day made her feel very sleepy and stupid),", .len = colPos, .pos = .{ .x = 1, .y = 11 } },
        .{ .lineNum = 12, .text = "whether the pleasure of making a daisy-chain would be worth", .len = colPos, .pos = .{ .x = 1, .y = 12 } },
        .{ .lineNum = 13, .text = "the trouble of getting up and picking the daisies, when", .len = colPos, .pos = .{ .x = 1, .y = 13 } },
        .{ .lineNum = 14, .text = "suddenly a White Rabbit with pink eyes ran close by her.", .len = colPos, .pos = .{ .x = 1, .y = 14 } },

        .{ .lineNum = 15, .text = "There was nothing so very remarkable in that; nor did Alice", .len = colPos, .pos = .{ .x = 1, .y = 15 } },
        .{ .lineNum = 16, .text = " think it so very much out of the way to hear the Rabbit say", .len = colPos, .pos = .{ .x = 1, .y = 16 } },
        .{ .lineNum = 17, .text = "to itself, “Oh dear! Oh dear! I shall be late!” (when she", .len = colPos, .pos = .{ .x = 1, .y = 17 } },
        .{ .lineNum = 18, .text = "thought it over afterwards, it occurred to her that she ought", .len = colPos, .pos = .{ .x = 1, .y = 18 } },
        .{ .lineNum = 19, .text = "to have wondered at this, but at the time it all seemed quite", .len = colPos, .pos = .{ .x = 1, .y = 19 } },
        .{ .lineNum = 20, .text = "natural); but when the Rabbit actually took a watch out of its", .len = colPos, .pos = .{ .x = 1, .y = 20 } },
        .{ .lineNum = 21, .text = "waistcoat-pocket, and looked at it, and then hurried on, Alice", .len = colPos, .pos = .{ .x = 1, .y = 21 } },
        .{ .lineNum = 22, .text = "started to her feet, for it flashed across her mind that she had", .len = colPos, .pos = .{ .x = 1, .y = 22 } },
        .{ .lineNum = 23, .text = " never before seen a rabbit with either a waistcoat-pocket, or a", .len = colPos, .pos = .{ .x = 1, .y = 23 } },
        .{ .lineNum = 24, .text = " watch to take out of it, and burning with curiosity, she ran across", .len = colPos, .pos = .{ .x = 1, .y = 24 } },
        .{ .lineNum = 25, .text = "the field after it, and fortunately was just in time to see it pop", .len = colPos, .pos = .{ .x = 1, .y = 25 } },
        .{ .lineNum = 26, .text = "down a large rabbit-hole under the hedge.", .len = colPos, .pos = .{ .x = 1, .y = 26 } },
    },
};
//
//
