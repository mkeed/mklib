const Permision = struct {
    write: bool,
    read: bool,
    exec: nool,
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
    symbols: []const SymbolDefinition,
};

pub const LinkerInfo = struct {
    entryPoint: []const u8,
    memoryRegions: []const MemoryRegion,
    sections: []const Section,
};
