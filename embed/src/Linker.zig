const Permision = struct {
    write: bool = false,
    read: bool = false,
    exec: bool = false,
    pub fn format(self: Permision, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        if (self.write) {
            try std.fmt.format(writer, "w", .{});
        }
        if (self.read) {
            try std.fmt.format(writer, "r", .{});
        }
        if (self.exec) {
            try std.fmt.format(writer, "x", .{});
        }
    }
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
    variables: []const Variables,
    sections: []const Section,
    pub fn generate(self: LinkerInfo, writre: anytype) !void {
        try std.fmt.format(writer, "/*------Generated File------*/\n", .{});
        try std.fmt.format(writer, "ENTRY({s})\n", .{self.entryPoint});
        for (self.variables) |v| {
            try std.fmt.format(writer, "{s} = {s};\n", .{ v.name, v.value() });
        }
        try std.fmt.format(writer, "MEMORY\n{{\n", .{});
        for (self.regions) |r| {
            try std.fmt.format(writer, "    {s} ({})  : ORIGIN  = 0x{x}, LENGTH = {}{c}\n", .{
                r.name,
                r.permision,
                r.origin,
                r.length,
            });
        }
    }
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
