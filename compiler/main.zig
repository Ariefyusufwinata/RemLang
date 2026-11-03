const std = @import("std");
pub const version = @import("cli/version.zig");
pub const usage = @import("cli/usage.zig");
pub const banner = @import("cli/banner.zig");
pub const MemoryManager = @import("memory/memory.zig").MemoryManager;
pub const Token = @import("lexer/token.zig").Token;
pub const Lexer = @import("lexer/lexer.zig").Lexer;
pub const Parser = @import("parser/parser.zig").Parser;
pub const Interpreter = @import("runtime/interpreter.zig").Interpreter;

pub fn runSource(source: []const u8, stdout: std.fs.File.Writer) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var mem = MemoryManager.init(gpa.allocator());
    defer mem.deinit();

    var lexer = Lexer.init(source);
    var tokens = std.ArrayList(Token).init(mem.allocator());
    while (true) {
        const tok = try lexer.nextToken();
        try tokens.append(tok);
        if (tok.token_type == .eof) break;
    }

    var parser = Parser.init(&mem, tokens.items);
    const ast = try parser.parseProgram();

    var interpreter = try Interpreter.init(&mem, stdout);
    try interpreter.interpret(ast);
}

pub fn runFile(file_path: []const u8, stdout: std.fs.File.Writer) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var file_opt = std.fs.cwd().openFile(file_path, .{}) catch null;
    var fallback_buf: [512]u8 = undefined;

    if (file_opt == null) {
        if (std.fmt.bufPrint(&fallback_buf, "examples/{s}", .{file_path})) |cand| {
            file_opt = std.fs.cwd().openFile(cand, .{}) catch null;
        } else |_| {}
    }

    if (file_opt == null) {
        try stdout.print("Error: Could not open file '{s}'\n", .{file_path});
        return;
    }
    const file = file_opt.?;
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try gpa.allocator().alloc(u8, file_size);
    defer gpa.allocator().free(buffer);

    _ = try file.readAll(buffer);
    try runSource(buffer, stdout);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try usage.printUsage(stdout);
        return;
    }

    const command = args[1];

    if (std.mem.eql(u8, command, "version") or std.mem.eql(u8, command, "-v") or std.mem.eql(u8, command, "--version")) {
        try version.printVersion(stdout);
        return;
    }

    if (std.mem.eql(u8, command, "help") or std.mem.eql(u8, command, "-h") or std.mem.eql(u8, command, "--help")) {
        try usage.printUsage(stdout);
        return;
    }

    if (std.mem.eql(u8, command, "rem") or std.mem.eql(u8, command, "art") or std.mem.eql(u8, command, "ascii") or std.mem.eql(u8, command, "banner")) {
        try banner.printBanner(stdout);
        return;
    }

    if (std.mem.eql(u8, command, "run")) {
        if (args.len < 3) {
            try stdout.print("Error: Please specify the .rem file to run.\nExample: rem run hello_world.rem\n", .{});
            return;
        }

        const file_path = args[2];
        if (!std.mem.endsWith(u8, file_path, ".rem")) {
            try stdout.print("Warning: File '{s}' does not have a .rem extension.\n", .{file_path});
        }

        try runFile(file_path, stdout);
        return;
    }

    if (std.mem.endsWith(u8, command, ".rem")) {
        try runFile(command, stdout);
        return;
    }

    if (std.fs.cwd().access(command, .{})) |_| {
        try runFile(command, stdout);
        return;
    } else |_| {}

    try usage.printUsage(stdout);
}
