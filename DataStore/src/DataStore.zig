const std = @import("std");

// file layout
// all integers are LittleEndian
// Location: u64 offset into file
// magicNumber(4) ['M','K','D','S']
// header(36) [
//     Location: indexTable
//     Location: FieldDefinition
//     Location: DataStream
//
// ]

pub fn write(writer: anytype, stream: DataStreamMap) !void {
    //
}
