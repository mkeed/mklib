const std = @import("std");
const HighEnable = packed enum(u1) {
    Disable = 0,
    Enable = 1,
};

const ParityEvenLow = packed enum(u1) {
    Even = 0,
    Odd = 1,
};

const REG = packed struct {
    const SR = packed struct(u32) {
        pe: bool, //parity error
        fe: bool, //framing error
        ne: bool, //noise error
        ore: bool, //overrun error
        idle: bool, //idel line detected
        rxne: bool, //read data register not empty
        tc: bool, //transmission complete
        txe: bool, //trasmit data register empty
        lbd: bool, //LIN break detection
        ctx: bool, //cts flag
        res1: u6,
        res2: u16,
    };

    const DR = packed struct(u32) {
        data: u8,
        res1: u24,
    };
    const BRR = packed struct(u32) {
        divFrac: u4,
        divMant: u12,
        res: u16,
    };
    const CR1 = packed struct(u32) {
        sbk: HighEnable, //send break
        rwu: bool, //receiver wakeup
        re: HighEnable, //reciever enable
        te: HighEnable, //transmitter enable
        idleie: HighEnable, //idle interupt enable
        rxneie: HighEnable, //RXNE interrupt enable
        tcie: HighEnable, //transmission complete interrupt enable
        txeie: HighEnable, //TXE interrupt enable
        peie: HighEnable, //PE interrup enable
        ps: ParityEvenLow, // parity selection
        pce: HighEnable, // parity control enable
        wake: bool, //wakeup method
        m: bool, //word length
        ue: bool, //usage enable
        res: u18,
    };
    const CR2 = packed struct(u32) {
        add: u4, //address of the USART node
        res: u1,
        lbdl: u1, //lin break detection length
        lbdie: u1, //lib break detection interrupt enable
        res: u1,
        lbcl: u1, //last bit clock pulse
        cpha: u1, //clock phase
        cpol: u1, //clock polarity
        clken: u1, //clock enable
        stop: u2, //stopbits,
        linen: u1, //lin mode enable
        res: u17,
    };
    const CR3 = packed struct(u32) {
        eie: u1, //error interrupt enable
        iren: u1, //irDA mode enable,
        ir,
    };
    const GTPR = u32;
    sr: SR,
    dr: DR,
    brr: BRR,
    cr1: CR1,
    cr2: CR2,
    cr3: CR3,
    gtpr: GTPR,
};

test {
    const sr = @bitCast(REG.SR, @as(u32, 0));
    _ = sr;
    const reg: REG = undefined;
    _ = reg;
    std.log.err("{} {}", .{ @sizeOf(REG), 7 * 4 });
    std.log.err("{x} {x}", .{ @sizeOf(REG), 7 * 4 });
    const info = switch (@typeInfo(REG)) {
        .Struct => |s| s,
        else => unreachable,
    };
    inline for (info.fields) |f| {
        std.log.err("{}", .{f});
        std.log.err("{}", .{@offsetOf(REG, f.name)});
    }
}
