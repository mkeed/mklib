const std = @import("std");

const REG = struct {
    const CR = packed struct(u32) {
        mode1: u2,
        cnf1: u2,
        mode2: u2,
        cnf2: u2,
        mode3: u2,
        cnf3: u2,
        mode4: u2,
        cnf4: u2,
        mode5: u2,
        cnf5: u2,
        mode6: u2,
        cnf6: u2,
        mode7: u2,
        cnf7: u2,
        mode8: u2,
        cnf8: u2,
    };

    const IDR = packed struct(u32) {
        idr: u16,
        res: u16,
    };

    const ODR = packed struct(u32) {
        idr: u16,
        res: u16,
    };

    const BSRR = packed struct(u32) {
        set: u16,
        reset: u16,
    };

    const BRR = packed struct(u32) {
        br: u16,
        res: u16,
    };

    const LCKR = packed struct(u32) {
        lck: u16,
        lckk: u1,
        res: u15,
    };
    crl: CR,
    crlh: CR,
    idr: IDR,
    odr: ODR,
    bsrr: BSRR,
    brr: BRR,
    lckr: LCKR,
};

test {
    std.log.err("{x}", .{@sizeOf(REG)});
}
