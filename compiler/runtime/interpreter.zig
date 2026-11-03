const std = @import("std");
const MemoryManager = @import("../memory/memory.zig").MemoryManager;
const value_mod = @import("value.zig");
const Value = value_mod.Value;
const ValueTag = value_mod.ValueTag;
const NativeFn = value_mod.NativeFn;
const Instance = value_mod.Instance;
const Expr = @import("../parser/ast.zig").Expr;
const Stmt = @import("../parser/ast.zig").Stmt;
const FunctionStmt = @import("../parser/ast.zig").FunctionStmt;
const ClassStmt = @import("../parser/ast.zig").ClassStmt;
const BinaryOp = @import("../parser/ast.zig").BinaryOp;

pub const ControlSignal = union(enum) {
    return_sig: Value,
    break_sig: void,
    continue_sig: void,
    die_sig: Value,
    goodnight_sig: void,
};

pub const Environment = struct {
    mem: *MemoryManager,
    parent: ?*Environment,
    values: std.StringHashMap(Value),
    promises: std.StringHashMap(void),

    pub fn init(mem: *MemoryManager, parent: ?*Environment) Environment {
        return Environment{
            .mem = mem,
            .parent = parent,
            .values = std.StringHashMap(Value).init(mem.allocator()),
            .promises = std.StringHashMap(void).init(mem.allocator()),
        };
    }

    pub fn define(self: *Environment, name: []const u8, val: Value, is_promise: bool) !void {
        try self.values.put(name, val);
        if (is_promise) {
            try self.promises.put(name, {});
        }
    }

    pub fn devour(self: *Environment, name: []const u8) bool {
        if (self.values.remove(name)) {
            _ = self.promises.remove(name);
            return true;
        }
        if (self.parent) |p| {
            return p.devour(name);
        }
        return false;
    }

    pub fn assign(self: *Environment, name: []const u8, val: Value) anyerror!void {
        if (self.promises.contains(name)) {
            std.debug.print("Runtime Error: Cannot reassign to promise '{s}'!\n", .{name});
            return error.PromiseReassignment;
        }
        if (self.values.contains(name)) {
            try self.values.put(name, val);
            return;
        }
        if (self.parent) |p| {
            return p.assign(name, val);
        }
        std.debug.print("Runtime Error: Undefined variable '{s}'\n", .{name});
        return error.UndefinedVariable;
    }

    pub fn get(self: *Environment, name: []const u8) ?Value {
        if (self.values.get(name)) |v| {
            return v;
        }
        if (self.parent) |p| {
            return p.get(name);
        }
        return null;
    }
};

pub const Interpreter = struct {
    mem: *MemoryManager,
    global_env: *Environment,
    stdout: std.fs.File.Writer,
    call_depth: usize = 0,
    max_call_depth: usize = 10000,
    return_register: Value = Value{ .forgotten = {} },

    pub fn init(mem: *MemoryManager, stdout: std.fs.File.Writer) !Interpreter {
        const global_env = try mem.create(Environment);
        global_env.* = Environment.init(mem, null);

        var interp = Interpreter{
            .mem = mem,
            .global_env = global_env,
            .stdout = stdout,
            .call_depth = 0,
            .max_call_depth = 10000,
            .return_register = Value{ .forgotten = {} },
        };

        try interp.registerBuiltins();
        return interp;
    }

    fn registerBuiltins(self: *Interpreter) !void {
        try self.global_env.define("sleep_talk", Value{ .native_fn = builtinSleepTalk }, false);
        try self.global_env.define("println", Value{ .native_fn = builtinSleepTalk }, false);
        try self.global_env.define("print", Value{ .native_fn = builtinPrint }, false);
        try self.global_env.define("say", Value{ .native_fn = builtinSleepTalk }, false);
        try self.global_env.define("listen", Value{ .native_fn = builtinListen }, false);
        try self.global_env.define("count", Value{ .native_fn = builtinCount }, false);
        try self.global_env.define("add", Value{ .native_fn = builtinAdd }, false);
        try self.global_env.define("what_is", Value{ .native_fn = builtinWhatIs }, false);
        try self.global_env.define("clock", Value{ .native_fn = builtinClock }, false);
    }

    pub fn interpret(self: *Interpreter, program: []const Stmt) anyerror!void {
        for (program) |stmt| {
            const res = self.executeStmt(stmt, self.global_env);
            if (res) |_| {} else |err| {
                if (err == error.Goodnight) return;
                return err;
            }
        }
    }

    fn executeStmt(self: *Interpreter, stmt: Stmt, env: *Environment) anyerror!void {
        switch (stmt) {
            .rem_wakes_up_stmt => |body| {
                try self.executeStmt(body.*, env);
            },
            .goodnight_stmt => {
                return error.Goodnight;
            },
            .borrow_stmt => |path| {
                try self.executeBorrow(path, env);
            },
            .remember_stmt => |rem_stmt| {
                const val = try self.evalExpr(rem_stmt.initializer, env);
                try env.define(rem_stmt.name, val, rem_stmt.is_promise);
            },
            .assign_stmt => |asgn| {
                const val = try self.evalExpr(asgn.value, env);
                try env.assign(asgn.name, val);
            },
            .devour_stmt => |name| {
                _ = env.devour(name);
            },
            .index_assign => |ia| {
                const target_val = try self.evalExpr(ia.target.*, env);
                const index_val = try self.evalExpr(ia.index, env);
                const val = try self.evalExpr(ia.value, env);

                switch (target_val) {
                    .memories => |list| {
                        if (index_val != .whole) return error.InvalidListIndex;
                        const idx = index_val.whole;
                        if (idx < 0 or idx >= list.items.len) return error.IndexOutOfBounds;
                        list.items[@as(usize, @intCast(idx))] = val;
                    },
                    .diary => |map| {
                        if (index_val != .words) return error.InvalidMapKey;
                        try map.put(index_val.words, val);
                    },
                    else => return error.CannotIndexAssign,
                }
            },
            .set_prop => |sp| {
                const obj_val = try self.evalExpr(sp.object.*, env);
                const val = try self.evalExpr(sp.value, env);
                if (obj_val != .instance) return error.InvalidPropertySet;
                try obj_val.instance.set(sp.name, val);
            },
            .sleep_talk_stmt => |expr| {
                const val = try self.evalExpr(expr, env);
                try val.format(self.stdout);
                try self.stdout.writeAll("\n");
            },
            .maybe_stmt => |m| {
                const cond = try self.evalExpr(m.condition, env);
                if (cond.isTruthy()) {
                    try self.executeStmt(m.then_branch.*, env);
                    return;
                }

                for (m.or_maybe_branches) |branch| {
                    const or_cond = try self.evalExpr(branch.condition, env);
                    if (or_cond.isTruthy()) {
                        try self.executeStmt(branch.branch.*, env);
                        return;
                    }
                }

                if (m.snooze_branch) |snooze| {
                    try self.executeStmt(snooze.*, env);
                }
            },
            .again_while_stmt => |loop| {
                while (true) {
                    const cond = try self.evalExpr(loop.condition, env);
                    if (!cond.isTruthy()) break;

                    const res = self.executeStmt(loop.body.*, env);
                    if (res) |_| {} else |err| {
                        if (err == error.WakeUp) break;
                        if (err == error.TurnOver) continue;
                        return err;
                    }
                }
            },
            .again_times_stmt => |t| {
                const count_val = try self.evalExpr(t.count, env);
                if (count_val != .whole) return error.InvalidTimesCount;
                const count = count_val.whole;

                var i: i64 = 0;
                while (i < count) : (i += 1) {
                    const res = self.executeStmt(t.body.*, env);
                    if (res) |_| {} else |err| {
                        if (err == error.WakeUp) break;
                        if (err == error.TurnOver) continue;
                        return err;
                    }
                }
            },
            .again_each_stmt => |each| {
                const iter_val = try self.evalExpr(each.iterable, env);

                const scope = try self.mem.create(Environment);
                scope.* = Environment.init(self.mem, env);

                switch (iter_val) {
                    .memories => |list| {
                        for (list.items) |item| {
                            try scope.define(each.variable, item, false);
                            const res = self.executeStmt(each.body.*, scope);
                            if (res) |_| {} else |err| {
                                if (err == error.WakeUp) break;
                                if (err == error.TurnOver) continue;
                                return err;
                            }
                        }
                    },
                    .diary => |map| {
                        var it = map.keyIterator();
                        while (it.next()) |k| {
                            try scope.define(each.variable, Value{ .words = k.* }, false);
                            const res = self.executeStmt(each.body.*, scope);
                            if (res) |_| {} else |err| {
                                if (err == error.WakeUp) break;
                                if (err == error.TurnOver) continue;
                                return err;
                            }
                        }
                    },
                    else => return error.InvalidIterable,
                }
            },
            .wake_up_stmt => {
                return error.WakeUp;
            },
            .turn_over_stmt => {
                return error.TurnOver;
            },
            .wake_with_stmt => |ret_expr| {
                var ret_val = Value{ .forgotten = {} };
                if (ret_expr) |e| {
                    ret_val = try self.evalExpr(e, env);
                }
                self.return_register = ret_val;
                return error.WakeWith;
            },
            .save_point_stmt => |sp| {
                const res = self.executeStmt(sp.try_branch.*, env);
                if (res) |_| {} else |_| {
                    try self.executeStmt(sp.return_by_death_branch.*, env);
                }
            },
            .die_stmt => |msg_expr| {
                const msg = try self.evalExpr(msg_expr, env);
                std.debug.print("RemLang Error: ", .{});
                try msg.format(self.stdout);
                try self.stdout.writeAll("\n");
                return error.Died;
            },
            .block => |stmts| {
                const scope = try self.mem.create(Environment);
                scope.* = Environment.init(self.mem, env);
                for (stmts) |s| {
                    try self.executeStmt(s, scope);
                }
            },
            .expression => |expr| {
                _ = try self.evalExpr(expr, env);
            },
            .dream => |func| {
                try env.define(func.name, Value{ .dream = func }, false);
            },
            .class_stmt => |c| {
                try env.define(c.name, Value{ .class_val = c }, false);
            },
        }
    }

    pub fn evalExpr(self: *Interpreter, expr: Expr, env: *Environment) anyerror!Value {
        switch (expr) {
            .integer_lit => |i| return Value{ .whole = i },
            .float_lit => |d| return Value{ .drift = d },
            .boolean_lit => |b| return Value{ .truth = b },
            .string_lit => |s| return Value{ .words = s },
            .nil_lit => return Value{ .forgotten = {} },
            .variable => |name| {
                if (env.get(name)) |v| return v;
                std.debug.print("Runtime Error: Undefined variable '{s}'\n", .{name});
                return error.UndefinedVariable;
            },
            .this_expr => {
                if (env.get("this")) |v| return v;
                return error.ThisOutsideClass;
            },
            .list_lit => |items| {
                const list = try self.mem.allocator().create(std.ArrayList(Value));
                list.* = std.ArrayList(Value).init(self.mem.allocator());
                for (items) |it| {
                    const item_val = try self.evalExpr(it, env);
                    try list.append(item_val);
                }
                return Value{ .memories = list };
            },
            .map_lit => |entries| {
                const map = try self.mem.allocator().create(std.StringHashMap(Value));
                map.* = std.StringHashMap(Value).init(self.mem.allocator());
                for (entries) |ent| {
                    const val = try self.evalExpr(ent.value, env);
                    try map.put(ent.key, val);
                }
                return Value{ .diary = map };
            },
            .index_expr => |ie| {
                const target = try self.evalExpr(ie.target.*, env);
                const idx = try self.evalExpr(ie.index.*, env);

                switch (target) {
                    .memories => |list| {
                        if (idx != .whole) return error.InvalidListIndex;
                        const i = idx.whole;
                        if (i < 0 or i >= list.items.len) return error.IndexOutOfBounds;
                        return list.items[@as(usize, @intCast(i))];
                    },
                    .diary => |map| {
                        if (idx != .words) return error.InvalidMapKey;
                        return map.get(idx.words) orelse Value{ .forgotten = {} };
                    },
                    .words => |s| {
                        if (idx != .whole) return error.InvalidStringIndex;
                        const i = idx.whole;
                        if (i < 0 or i >= s.len) return error.IndexOutOfBounds;
                        return Value{ .words = s[@as(usize, @intCast(i)) .. @as(usize, @intCast(i)) + 1] };
                    },
                    else => return error.CannotIndexType,
                }
            },
            .binary => |bin| {
                if (bin.op == .op_and) {
                    const left = try self.evalExpr(bin.left.*, env);
                    if (!left.isTruthy()) return left;
                    return try self.evalExpr(bin.right.*, env);
                }
                if (bin.op == .op_or) {
                    const left = try self.evalExpr(bin.left.*, env);
                    if (left.isTruthy()) return left;
                    return try self.evalExpr(bin.right.*, env);
                }

                const left = try self.evalExpr(bin.left.*, env);
                const right = try self.evalExpr(bin.right.*, env);

                return switch (bin.op) {
                    .add => value_mod.opAdd(self.mem, left, right),
                    .subtract => value_mod.opSubtract(left, right),
                    .multiply => value_mod.opMultiply(left, right),
                    .divide => value_mod.opDivide(left, right),
                    .modulo => value_mod.opModulo(left, right),
                    .equal => Value{ .truth = value_mod.opEqual(left, right) },
                    .not_equal => Value{ .truth = value_mod.opNotEqual(left, right) },
                    .less => value_mod.opLessThan(left, right),
                    .less_equal => value_mod.opLessOrEqual(left, right),
                    .greater => value_mod.opGreaterThan(left, right),
                    .greater_equal => value_mod.opGreaterOrEqual(left, right),
                    .op_and, .op_or => unreachable,
                };
            },
            .unary => |un| {
                const right = try self.evalExpr(un.right.*, env);
                return switch (un.op) {
                    .negate => value_mod.opNegate(right),
                    .not => value_mod.opNot(right),
                };
            },
            .grouping => |grp| {
                return try self.evalExpr(grp.*, env);
            },
            .call => |call| {
                const callee = env.get(call.callee) orelse {
                    std.debug.print("Runtime Error: Function '{s}' not found\n", .{call.callee});
                    return error.UndefinedFunction;
                };

                var eval_args = std.ArrayList(Value).init(self.mem.allocator());
                for (call.args) |a| {
                    try eval_args.append(try self.evalExpr(a, env));
                }

                return try self.executeCall(callee, eval_args.items);
            },
            .get_prop => |gp| {
                const obj = try self.evalExpr(gp.object.*, env);
                if (obj != .instance) return error.InvalidPropertyAccess;
                return obj.instance.get(gp.name) orelse Value{ .forgotten = {} };
            },
            .method_call => |mc| {
                const obj = try self.evalExpr(mc.object.*, env);
                if (obj != .instance) return error.InvalidMethodCall;

                var eval_args = std.ArrayList(Value).init(self.mem.allocator());
                for (mc.args) |a| {
                    try eval_args.append(try self.evalExpr(a, env));
                }

                return try self.executeMethodCall(obj.instance, mc.method, eval_args.items);
            },
            .new_expr => |ne| {
                const class_val = env.get(ne.class_name) orelse return error.ClassNotFound;
                if (class_val != .class_val) return error.NotAClass;

                const instance = try self.mem.allocator().create(Instance);
                instance.* = Instance.init(self.mem, class_val.class_val);

                var init_method: ?FunctionStmt = null;
                for (class_val.class_val.methods) |m| {
                    if (std.mem.eql(u8, m.name, "init")) {
                        init_method = m;
                        break;
                    }
                }

                if (init_method) |m| {
                    var eval_args = std.ArrayList(Value).init(self.mem.allocator());
                    for (ne.args) |a| {
                        try eval_args.append(try self.evalExpr(a, env));
                    }
                    _ = try self.executeInstanceMethod(instance, m, eval_args.items);
                }

                return Value{ .instance = instance };
            },
        }
    }

    fn executeCall(self: *Interpreter, callee: Value, args: []const Value) anyerror!Value {
        switch (callee) {
            .native_fn => |n_fn| {
                return try n_fn(self.mem, args);
            },
            .dream => |func| {
                if (self.call_depth >= self.max_call_depth) return error.StackOverflow;
                self.call_depth += 1;
                defer self.call_depth -= 1;

                const call_env = try self.mem.create(Environment);
                call_env.* = Environment.init(self.mem, self.global_env);

                for (func.params, 0..) |param_name, idx| {
                    const arg_val = if (idx < args.len) args[idx] else Value{ .forgotten = {} };
                    try call_env.define(param_name, arg_val, false);
                }

                for (func.body) |s| {
                    const res = self.executeStmt(s, call_env);
                    if (res) |_| {} else |err| {
                        if (err == error.WakeWith) return self.return_register;
                        return err;
                    }
                }
                return Value{ .forgotten = {} };
            },
            else => return error.NotCallable,
        }
    }

    fn executeMethodCall(self: *Interpreter, instance: *Instance, method_name: []const u8, args: []const Value) anyerror!Value {
        for (instance.class_stmt.methods) |m| {
            if (std.mem.eql(u8, m.name, method_name)) {
                return try self.executeInstanceMethod(instance, m, args);
            }
        }
        std.debug.print("Method '{s}' not found on class '{s}'\n", .{ method_name, instance.class_stmt.name });
        return error.MethodNotFound;
    }

    fn executeInstanceMethod(self: *Interpreter, instance: *Instance, method: FunctionStmt, args: []const Value) anyerror!Value {
        if (self.call_depth >= self.max_call_depth) return error.StackOverflow;
        self.call_depth += 1;
        defer self.call_depth -= 1;

        const method_env = try self.mem.create(Environment);
        method_env.* = Environment.init(self.mem, self.global_env);

        try method_env.define("this", Value{ .instance = instance }, false);

        for (method.params, 0..) |param_name, idx| {
            const arg_val = if (idx < args.len) args[idx] else Value{ .forgotten = {} };
            try method_env.define(param_name, arg_val, false);
        }

        for (method.body) |s| {
            const res = self.executeStmt(s, method_env);
            if (res) |_| {} else |err| {
                if (err == error.WakeWith) return self.return_register;
                return err;
            }
        }
        return Value{ .instance = instance };
    }

    fn executeBorrow(self: *Interpreter, file_path: []const u8, env: *Environment) anyerror!void {
        const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
            std.debug.print("Borrow error: could not open file '{s}'\n", .{file_path});
            return err;
        };
        defer file.close();

        const file_size = (try file.stat()).size;
        const buffer = try self.mem.allocator().alloc(u8, file_size);
        defer self.mem.allocator().free(buffer);
        _ = try file.readAll(buffer);

        const Lexer = @import("../lexer/lexer.zig").Lexer;
        const Token_T = @import("../lexer/token.zig").Token;
        const Parser = @import("../parser/parser.zig").Parser;

        var lexer = Lexer.init(buffer);
        var tokens = std.ArrayList(Token_T).init(self.mem.allocator());
        while (true) {
            const tok = try lexer.nextToken();
            try tokens.append(tok);
            if (tok.token_type == .eof) break;
        }

        var parser = Parser.init(self.mem, tokens.items);
        const ast = try parser.parseProgram();

        for (ast) |stmt| {
            try self.executeStmt(stmt, env);
        }
    }
};

pub fn builtinSleepTalk(_: *MemoryManager, args: []const Value) anyerror!Value {
    const stdout = std.io.getStdOut().writer();
    for (args, 0..) |arg, idx| {
        if (idx > 0) try stdout.writeAll(" ");
        try arg.format(stdout);
    }
    try stdout.writeAll("\n");
    return Value{ .forgotten = {} };
}

pub fn builtinPrint(_: *MemoryManager, args: []const Value) anyerror!Value {
    const stdout = std.io.getStdOut().writer();
    for (args, 0..) |arg, idx| {
        if (idx > 0) try stdout.writeAll(" ");
        try arg.format(stdout);
    }
    return Value{ .forgotten = {} };
}

pub fn builtinListen(mem: *MemoryManager, _: []const Value) anyerror!Value {
    const stdin = std.io.getStdIn().reader();
    var buf: [1024]u8 = undefined;
    if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const trimmed = std.mem.trimRight(u8, line, "\r");
        const str = try std.fmt.allocPrint(mem.allocator(), "{s}", .{trimmed});
        return Value{ .words = str };
    }
    return Value{ .words = "" };
}

pub fn builtinCount(_: *MemoryManager, args: []const Value) anyerror!Value {
    if (args.len == 0) return Value{ .whole = 0 };
    switch (args[0]) {
        .words => |s| return Value{ .whole = @as(i64, @intCast(s.len)) },
        .memories => |m| return Value{ .whole = @as(i64, @intCast(m.items.len)) },
        .diary => |d| return Value{ .whole = @as(i64, @intCast(d.count())) },
        else => return Value{ .whole = 0 },
    }
}

pub fn builtinAdd(_: *MemoryManager, args: []const Value) anyerror!Value {
    if (args.len < 2) return error.InvalidArgumentCount;
    if (args[0] != .memories) return error.InvalidTargetForAdd;
    try args[0].memories.append(args[1]);
    return args[0];
}

pub fn builtinWhatIs(_: *MemoryManager, args: []const Value) anyerror!Value {
    if (args.len == 0) return Value{ .words = "forgotten" };
    return Value{ .words = args[0].typeName() };
}

pub fn builtinClock(_: *MemoryManager, _: []const Value) anyerror!Value {
    const timestamp = std.time.milliTimestamp();
    return Value{ .whole = timestamp };
}
