const Permision = struct {
    write: bool = false,
    read: bool = false,
    exec: bool = false,
};
pub const MemoryRegion = struct {
    name: []const u8,
    permison: Permision,
    origin: usize,
    length: usize,
};

pub const Section = struct {
    name: []const u8,
    location: *const MemoryRegion,
    storage: ?*const MemoryRegion,
    alignment: usize,
    symbols: []const SymbolDefinition,
};

pub const SymbolDefinition = struct {
    name: []const u8,
    keep: bool = false,
};

pub const LinkerInfo = struct {
    entryPoint: []const u8,
    memoryRegions: []const *MemoryRegion,
    sections: []const Section,
};

fn k(len: usize) usize {
    return len * 1024;
}
fn m(len: usize) usize {
    return len * 1024 * 1024;
}

test {
    const ram = Memory{
        .name = "RAM",
        .permision = .{ .write = true, .read = true, .exec = true },
        .origin = 0x20000000,
        .length = k(20),
    };
    const flash = Memory{
        .name = "FLASH",
        .permision = .{ .write = true, .exec = true },
        .origin = 0x08000000,
        .length = k(128),
    };
    const isrVectors = Section{
        .name = ".isr_vectors",
        .location = &flash,
        .alignment = 4,
        .symbols = &.{
            .{
                .placement = .{
                    .name = ".isr_vector",
                    .keep = true,
                },
            },
        },
    };

    const text = Section{
        .name = "text",
        .location = &flash,
        .alignment = 4,
        .symbols = &.{
            .{
                .placement = .{
                    .name = ".text",
                },
            },
            .{
                .placement = .{
                    .name = ".text*",
                },
            },
            .{
                .declare = .{
                    .name = "_etext",
                },
            },
        },
    };

    const rodata = Section{
        .name = "rodata",
        .location = &flash,
        .alignment = 4,
        .symbols = &.{
            .{
                .placement = .{
                    .name = ".rodata",
                },
            },
            .{
                .placement = .{
                    .name = ".rodata*",
                },
            },
        },
    };

    const data = Section{
        .name = "data",
        .location = &ram,
        .storage = &flash,
        .alignment = 4,
        .symbols = &.{
            .{
                .declare = .{
                    .name = "_sdata",
                },
            },
            .{
                .placement = .{
                    .name = ".data",
                },
            },
        },
    };

    const li = LinkerInfo{
        .entryPoint = "start",
        .memoryRegions = &.{
            &ram,
            &flash,
        },
        .sections = &.{
            &isrVectors,
            &text,
            &rodata,
            &data,
        },
    };
}
