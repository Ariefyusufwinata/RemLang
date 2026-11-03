const std = @import("std");
const MemoryManager = @import("../memory/memory.zig").MemoryManager;
const FunctionStmt = @import("../parser/ast.zig").FunctionStmt;
const ClassStmt = @import("../parser/ast.zig").ClassStmt;

pub const ValueTag = enum {
    forgotten,
    truth,
    whole,
    drift,
    words,
    memories,
    diary,
    dream,
    native_fn,
    class_val,
    instance,
};

pub const Instance = struct {
    class_stmt: *ClassStmt,
    fields: std.StringHashMap(Value),

    pub fn init(mem: *MemoryManager, class_stmt: *ClassStmt) Instance {
        return Instance{
            .class_stmt = class_stmt,
            .fields = std.StringHashMap(Value).init(mem.allocator()),
        };
    }

    pub fn get(self: *Instance, name: []const u8) ?Value {
        return self.fields.get(name);
    }

    pub fn set(self: *Instance, name: []const u8, val: Value) !void {
        try self.fields.put(name, val);
    }
};

pub const NativeFn = *const fn (mem: *MemoryManager, args: []const Value) anyerror!Value;

pub const Value = union(ValueTag) {
    forgotten: void,
    truth: bool,
    whole: i64,
    drift: f64,
    words: []const u8,
    memories: *std.ArrayList(Value),
    diary: *std.StringHashMap(Value),
    dream: *FunctionStmt,
    native_fn: NativeFn,
    class_val: *ClassStmt,
    instance: *Instance,

    pub fn isTruthy(self: Value) bool {
        return switch (self) {
            .forgotten => false,
            .truth => |b| b,
            .whole => |i| i != 0,
            .drift => |d| d != 0.0,
            .words => |s| s.len > 0,
            .memories => |m| m.items.len > 0,
            .diary => |d| d.count() > 0,
            .dream, .native_fn, .class_val, .instance => true,
        };
    }

    pub fn typeName(self: Value) []const u8 {
        return switch (self) {
            .forgotten => "forgotten",
            .truth => "truth",
            .whole => "whole",
            .drift => "drift",
            .words => "words",
            .memories => "memories",
            .diary => "diary",
            .dream => "dream",
            .native_fn => "native_fn",
            .class_val => "class",
            .instance => "instance",
        };
    }

    pub fn format(self: Value, writer: anytype) anyerror!void {
        switch (self) {
            .forgotten => try writer.writeAll("forgotten"),
            .truth => |b| try writer.writeAll(if (b) "yes" else "no"),
            .whole => |i| try writer.print("{}", .{i}),
            .drift => |d| {
                if (@floor(d) == d) {
                    try writer.print("{d:.1}", .{d});
                } else {
                    try writer.print("{d}", .{d});
                }
            },
            .words => |s| try writer.writeAll(s),
            .memories => |m| {
                try writer.writeAll("[");
                for (m.items, 0..) |item, idx| {
                    if (idx > 0) try writer.writeAll(", ");
                    if (item == .words) {
                        try writer.print("\"{s}\"", .{item.words});
                    } else {
                        try item.format(writer);
                    }
                }
                try writer.writeAll("]");
            },
            .diary => |d| {
                try writer.writeAll("{");
                var it = d.iterator();
                var first = true;
                while (it.next()) |entry| {
                    if (!first) try writer.writeAll(", ");
                    first = false;
                    try writer.print("\"{s}\": ", .{entry.key_ptr.*});
                    if (entry.value_ptr.* == .words) {
                        try writer.print("\"{s}\"", .{entry.value_ptr.*.words});
                    } else {
                        try entry.value_ptr.*.format(writer);
                    }
                }
                try writer.writeAll("}");
            },
            .dream => |f| try writer.print("<dream {s}>", .{f.name}),
            .native_fn => try writer.writeAll("<native fn>"),
            .class_val => |c| try writer.print("<class {s}>", .{c.name}),
            .instance => |inst| try writer.print("<instance of {s}>", .{inst.class_stmt.name}),
        }
    }
};

pub fn opAdd(mem: *MemoryManager, a: Value, b: Value) !Value {
    if (a == .whole and b == .whole) {
        return Value{ .whole = a.whole + b.whole };
    }
    if (a == .drift and b == .drift) {
        return Value{ .drift = a.drift + b.drift };
    }
    if (a == .whole and b == .drift) {
        return Value{ .drift = @as(f64, @floatFromInt(a.whole)) + b.drift };
    }
    if (a == .drift and b == .whole) {
        return Value{ .drift = a.drift + @as(f64, @floatFromInt(b.whole)) };
    }

    if (a == .words or b == .words) {
        var buf_a: [64]u8 = undefined;
        var buf_b: [64]u8 = undefined;

        const str_a: []const u8 = switch (a) {
            .words => |s| s,
            .whole => |i| std.fmt.bufPrint(&buf_a, "{}", .{i}) catch "whole",
            .drift => |d| std.fmt.bufPrint(&buf_a, "{d}", .{d}) catch "drift",
            .truth => |v| if (v) "yes" else "no",
            .forgotten => "forgotten",
            else => a.typeName(),
        };

        const str_b: []const u8 = switch (b) {
            .words => |s| s,
            .whole => |i| std.fmt.bufPrint(&buf_b, "{}", .{i}) catch "whole",
            .drift => |d| std.fmt.bufPrint(&buf_b, "{d}", .{d}) catch "drift",
            .truth => |v| if (v) "yes" else "no",
            .forgotten => "forgotten",
            else => b.typeName(),
        };

        const combined = try std.fmt.allocPrint(mem.allocator(), "{s}{s}", .{ str_a, str_b });
        return Value{ .words = combined };
    }

    return error.InvalidAdditionTypes;
}

pub fn opSubtract(a: Value, b: Value) !Value {
    if (a == .whole and b == .whole) {
        return Value{ .whole = a.whole - b.whole };
    }
    if (a == .drift and b == .drift) {
        return Value{ .drift = a.drift - b.drift };
    }
    if (a == .whole and b == .drift) {
        return Value{ .drift = @as(f64, @floatFromInt(a.whole)) - b.drift };
    }
    if (a == .drift and b == .whole) {
        return Value{ .drift = a.drift - @as(f64, @floatFromInt(b.whole)) };
    }
    return error.InvalidSubtractionTypes;
}

pub fn opMultiply(a: Value, b: Value) !Value {
    if (a == .whole and b == .whole) {
        return Value{ .whole = a.whole * b.whole };
    }
    if (a == .drift and b == .drift) {
        return Value{ .drift = a.drift * b.drift };
    }
    if (a == .whole and b == .drift) {
        return Value{ .drift = @as(f64, @floatFromInt(a.whole)) * b.drift };
    }
    if (a == .drift and b == .whole) {
        return Value{ .drift = a.drift * @as(f64, @floatFromInt(b.whole)) };
    }
    return error.InvalidMultiplicationTypes;
}

pub fn opDivide(a: Value, b: Value) !Value {
    if (a == .whole and b == .whole) {
        if (b.whole == 0) return error.DivisionByZero;
        return Value{ .whole = @divTrunc(a.whole, b.whole) };
    }
    if (a == .drift and b == .drift) {
        if (b.drift == 0.0) return error.DivisionByZero;
        return Value{ .drift = a.drift / b.drift };
    }
    if (a == .whole and b == .drift) {
        if (b.drift == 0.0) return error.DivisionByZero;
        return Value{ .drift = @as(f64, @floatFromInt(a.whole)) / b.drift };
    }
    if (a == .drift and b == .whole) {
        if (b.whole == 0) return error.DivisionByZero;
        return Value{ .drift = a.drift / @as(f64, @floatFromInt(b.whole)) };
    }
    return error.InvalidDivisionTypes;
}

pub fn opModulo(a: Value, b: Value) !Value {
    if (a == .whole and b == .whole) {
        if (b.whole == 0) return error.ModuloByZero;
        return Value{ .whole = @mod(a.whole, b.whole) };
    }
    return error.InvalidModuloTypes;
}

pub fn opEqual(a: Value, b: Value) bool {
    if (a == .whole and b == .drift) {
        return @as(f64, @floatFromInt(a.whole)) == b.drift;
    }
    if (a == .drift and b == .whole) {
        return a.drift == @as(f64, @floatFromInt(b.whole));
    }
    if (@as(ValueTag, a) != @as(ValueTag, b)) return false;

    return switch (a) {
        .forgotten => true,
        .truth => |v| v == b.truth,
        .whole => |v| v == b.whole,
        .drift => |v| v == b.drift,
        .words => |v| std.mem.eql(u8, v, b.words),
        .memories => |v| v == b.memories,
        .diary => |v| v == b.diary,
        .dream => |v| v == b.dream,
        .native_fn => |v| v == b.native_fn,
        .class_val => |v| v == b.class_val,
        .instance => |v| v == b.instance,
    };
}

pub fn opNotEqual(a: Value, b: Value) bool {
    return !opEqual(a, b);
}

pub fn opLessThan(a: Value, b: Value) !Value {
    if (a == .whole and b == .whole) return Value{ .truth = a.whole < b.whole };
    if (a == .drift and b == .drift) return Value{ .truth = a.drift < b.drift };
    if (a == .whole and b == .drift) return Value{ .truth = @as(f64, @floatFromInt(a.whole)) < b.drift };
    if (a == .drift and b == .whole) return Value{ .truth = a.drift < @as(f64, @floatFromInt(b.whole)) };
    return error.InvalidComparisonTypes;
}

pub fn opLessOrEqual(a: Value, b: Value) !Value {
    if (a == .whole and b == .whole) return Value{ .truth = a.whole <= b.whole };
    if (a == .drift and b == .drift) return Value{ .truth = a.drift <= b.drift };
    if (a == .whole and b == .drift) return Value{ .truth = @as(f64, @floatFromInt(a.whole)) <= b.drift };
    if (a == .drift and b == .whole) return Value{ .truth = a.drift <= @as(f64, @floatFromInt(b.whole)) };
    return error.InvalidComparisonTypes;
}

pub fn opGreaterThan(a: Value, b: Value) !Value {
    if (a == .whole and b == .whole) return Value{ .truth = a.whole > b.whole };
    if (a == .drift and b == .drift) return Value{ .truth = a.drift > b.drift };
    if (a == .whole and b == .drift) return Value{ .truth = @as(f64, @floatFromInt(a.whole)) > b.drift };
    if (a == .drift and b == .whole) return Value{ .truth = a.drift > @as(f64, @floatFromInt(b.whole)) };
    return error.InvalidComparisonTypes;
}

pub fn opGreaterOrEqual(a: Value, b: Value) !Value {
    if (a == .whole and b == .whole) return Value{ .truth = a.whole >= b.whole };
    if (a == .drift and b == .drift) return Value{ .truth = a.drift >= b.drift };
    if (a == .whole and b == .drift) return Value{ .truth = @as(f64, @floatFromInt(a.whole)) >= b.drift };
    if (a == .drift and b == .whole) return Value{ .truth = a.drift >= @as(f64, @floatFromInt(b.whole)) };
    return error.InvalidComparisonTypes;
}

pub fn opNegate(a: Value) !Value {
    if (a == .whole) return Value{ .whole = -a.whole };
    if (a == .drift) return Value{ .drift = -a.drift };
    return error.InvalidNegateType;
}

pub fn opNot(a: Value) Value {
    return Value{ .truth = !a.isTruthy() };
}
