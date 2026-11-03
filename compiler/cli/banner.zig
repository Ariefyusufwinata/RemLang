const std = @import("std");

pub const REM_ART = @embedFile("rem_art.txt");

pub fn printBanner(writer: anytype) !void {
    try writer.print("{s}\n", .{REM_ART});
    try writer.print("💙 Rem: \"No matter what happens, even when you don't believe in yourself, I will believe in you.\"\n", .{});
}
