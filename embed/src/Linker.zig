const std = @import("std");

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
    permision: Permision,
    origin: usize,
    length: usize,
};

pub const Section = struct {
    name: []const u8,
    location: *const MemoryRegion,
    storage: ?*const MemoryRegion = null,
    alignment: usize,
    symbols: []const SymbolDefinition,
};

pub const SymbolPlacement = struct {
    name: []const u8,
    keep: bool = false,
};

pub const SymbolDeclaration = struct {
    name: []const u8,
};

pub const SymbolDefinition = union(enum) {
    placement: SymbolPlacement,
    declare: SymbolDeclaration,
};

pub const Variable = struct {
    name: []const u8,
    value: []const u8,
};

pub const LinkerInfo = struct {
    entryPoint: []const u8,
    memoryRegions: []const *const MemoryRegion,
    variables: []const *const Variable,
    sections: []const *const Section,
    pub fn generate(self: LinkerInfo, writer: anytype) !void {
        try std.fmt.format(writer, "/*------Generated File------*/\n", .{});
        try std.fmt.format(writer, "ENTRY({s})\n", .{self.entryPoint});
        for (self.variables) |v| {
            try std.fmt.format(writer, "{s} = {s};\n", .{ v.name, v.value });
        }
        try std.fmt.format(writer, "MEMORY\n{{\n", .{});
        for (self.memoryRegions) |r| {
            try std.fmt.format(writer, "    {s} ({})  : ORIGIN  = 0x{x}, LENGTH = 0x{x}\n", .{
                r.name,
                r.permision,
                r.origin,
                r.length,
            });
        }
        try std.fmt.format(writer, "}}\n\n", .{});
        try std.fmt.format(writer, "SECTIONS\n{{\n", .{});
        for (self.sections) |s| {
            try std.fmt.format(writer,
                \\    {s} :
                \\    {{
                \\    . = ALIGN({});
                \\
            , .{ s.name, s.alignment });

            for (s.symbols) |sym| {
                switch (sym) {
                    .placement => |p| {
                        if (p.keep) {
                            try std.fmt.format(writer, "        KEEP(*(.{s}))\n", .{p.name});
                        } else {
                            try std.fmt.format(writer, "        *(.{s})\n", .{p.name});
                        }
                    },
                    .declare => |d| {
                        try std.fmt.format(writer, "        {s} = .;\n", .{d.name});
                    },
                }
            }
            try std.fmt.format(writer, "    }}>{s}", .{s.location.name});
            if (s.storage) |store| {
                try std.fmt.format(writer, " AT> {s}", .{store.name});
            }
            try std.fmt.format(writer, "\n\n", .{});
        }
        try std.fmt.format(writer, "}}", .{});
    }
};

fn k(len: usize) usize {
    return len * 1024;
}
fn m(len: usize) usize {
    return len * 1024 * 1024;
}

test {
    const ram = MemoryRegion{
        .name = "RAM",
        .permision = .{ .write = true, .read = true, .exec = true },
        .origin = 0x20000000,
        .length = k(20),
    };
    const flash = MemoryRegion{
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

    var li = LinkerInfo{
        .entryPoint = "start",
        .memoryRegions = &.{
            &ram,
            &flash,
        },
        .variables = &.{},
        .sections = &.{
            &isrVectors,
            &text,
            &rodata,
            &data,
        },
    };
    var stdout = std.io.getStdOut().writer();
    try li.generate(stdout);
}
