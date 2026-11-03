const std = @import("std");

pub const VERSION = "0.1.0";
pub const CODENAME = "Starting from Zero 💙";

pub fn printVersion(writer: anytype) !void {
    try writer.print("RemLang v{s} ({s})\n", .{ VERSION, CODENAME });
}
