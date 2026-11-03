const std = @import("std");

pub fn printUsage(writer: anytype) !void {
    try writer.print(
        \\  💙 RemLang CLI (.rem)
        \\
        \\  Usage:
        \\    rem run <file.rem>    Execute a RemLang program file
        \\    rem <file.rem>        Direct execution shortcut
        \\    rem rem               Display Rem ASCII art 💙
        \\    rem version           Display the RemLang version
        \\    rem help              Show this help information
        \\
        \\  Examples:
        \\    rem run hello_world.rem
        \\    rem examples/hello_world.rem
        \\    rem rem
        \\
        \\
    , .{});
}
