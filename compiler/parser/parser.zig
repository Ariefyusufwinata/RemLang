const std = @import("std");
const MemoryManager = @import("../memory/memory.zig").MemoryManager;
const Token = @import("../lexer/token.zig").Token;
const TokenType = @import("../lexer/token.zig").TokenType;
const Expr = @import("ast.zig").Expr;
const Stmt = @import("ast.zig").Stmt;
const BinaryOp = @import("ast.zig").BinaryOp;
const UnaryOp = @import("ast.zig").UnaryOp;
const FunctionStmt = @import("ast.zig").FunctionStmt;
const ClassStmt = @import("ast.zig").ClassStmt;
const OrMaybeBranch = @import("ast.zig").OrMaybeBranch;
const MapEntry = @import("ast.zig").MapEntry;

pub const Parser = struct {
    mem: *MemoryManager,
    tokens: []const Token,
    current: usize = 0,

    pub fn init(mem: *MemoryManager, tokens: []const Token) Parser {
        return Parser{
            .mem = mem,
            .tokens = tokens,
            .current = 0,
        };
    }

    fn isAtEnd(self: *Parser) bool {
        return self.peek().token_type == .eof;
    }

    fn peek(self: *Parser) Token {
        return self.tokens[self.current];
    }

    fn peekNext(self: *Parser) Token {
        if (self.current + 1 >= self.tokens.len) return self.tokens[self.tokens.len - 1];
        return self.tokens[self.current + 1];
    }

    fn previous(self: *Parser) Token {
        return self.tokens[self.current - 1];
    }

    fn advance(self: *Parser) Token {
        if (!self.isAtEnd()) self.current += 1;
        return self.previous();
    }

    fn check(self: *Parser, token_type: TokenType) bool {
        if (self.isAtEnd()) return false;
        return self.peek().token_type == token_type;
    }

    fn match(self: *Parser, token_type: TokenType) bool {
        if (self.check(token_type)) {
            _ = self.advance();
            return true;
        }
        return false;
    }

    fn consume(self: *Parser, token_type: TokenType, err_msg: []const u8) !Token {
        if (self.check(token_type)) return self.advance();
        std.debug.print("Parse error at line {d}: {s}\n", .{ self.peek().line, err_msg });
        return error.ParseError;
    }

    fn consumeOptionalSemicolons(self: *Parser) void {
        while (self.match(.semicolon)) {}
    }

    pub fn parseProgram(self: *Parser) anyerror![]const Stmt {
        var stmts = std.ArrayList(Stmt).init(self.mem.allocator());
        while (!self.isAtEnd()) {
            self.consumeOptionalSemicolons();
            if (self.isAtEnd()) break;
            const stmt = try self.parseDeclaration();
            try stmts.append(stmt);
            self.consumeOptionalSemicolons();
        }
        return stmts.toOwnedSlice();
    }

    fn parseDeclaration(self: *Parser) anyerror!Stmt {
        if (self.match(.kw_rem_wakes_up)) {
            const body = try self.parseBlock();
            const heap_body = try self.mem.allocator().create(Stmt);
            heap_body.* = body;
            return Stmt{ .rem_wakes_up_stmt = heap_body };
        }

        if (self.match(.kw_goodnight)) {
            return Stmt{ .goodnight_stmt = {} };
        }

        if (self.match(.kw_borrow)) {
            const path_token = try self.consume(.string_lit, "Expect file path string after 'borrow'");
            return Stmt{ .borrow_stmt = path_token.lexeme };
        }

        if (self.match(.kw_class)) {
            return try self.parseClass();
        }

        if (self.match(.kw_dream) or self.match(.kw_fn)) {
            return try self.parseDream();
        }

        if (self.match(.kw_remember) or self.match(.kw_let)) {
            return try self.parseRemember(false);
        }

        if (self.match(.kw_promise)) {
            return try self.parseRemember(true);
        }

        if (self.match(.kw_devour)) {
            const name = try self.consume(.identifier, "Expect variable name after 'devour'");
            return Stmt{ .devour_stmt = name.lexeme };
        }

        return try self.parseStatement();
    }

    fn parseClass(self: *Parser) anyerror!Stmt {
        const name_tok = try self.consume(.identifier, "Expect class name after 'class'");
        _ = try self.consume(.l_brace, "Expect '{' before class body");

        var methods = std.ArrayList(FunctionStmt).init(self.mem.allocator());
        while (!self.check(.r_brace) and !self.isAtEnd()) {
            self.consumeOptionalSemicolons();
            if (self.check(.r_brace)) break;

            if (self.match(.kw_dream) or self.match(.kw_fn) or self.match(.kw_init) or self.check(.identifier)) {
                var method_name: []const u8 = "";
                if (self.previous().token_type == .kw_init) {
                    method_name = "init";
                } else if (self.previous().token_type == .kw_dream or self.previous().token_type == .kw_fn) {
                    if (self.match(.kw_init)) {
                        method_name = "init";
                    } else {
                        const m_tok = try self.consume(.identifier, "Expect method name");
                        method_name = m_tok.lexeme;
                    }
                } else {
                    const m_tok = self.advance();
                    method_name = m_tok.lexeme;
                }

                _ = try self.consume(.l_paren, "Expect '(' after method name");
                var params = std.ArrayList([]const u8).init(self.mem.allocator());
                if (!self.check(.r_paren)) {
                    while (true) {
                        const p_tok = try self.consume(.identifier, "Expect parameter name");
                        try params.append(p_tok.lexeme);
                        if (!self.match(.comma)) break;
                    }
                }
                _ = try self.consume(.r_paren, "Expect ')' after parameters");

                const body_stmt = try self.parseBlock();
                try methods.append(FunctionStmt{
                    .name = method_name,
                    .params = try params.toOwnedSlice(),
                    .body = body_stmt.block,
                });
            } else {
                return error.ExpectedMethodInClass;
            }
            self.consumeOptionalSemicolons();
        }

        _ = try self.consume(.r_brace, "Expect '}' after class body");

        const class_node = try self.mem.allocator().create(ClassStmt);
        class_node.* = ClassStmt{
            .name = name_tok.lexeme,
            .methods = try methods.toOwnedSlice(),
        };

        return Stmt{ .class_stmt = class_node };
    }

    fn parseDream(self: *Parser) anyerror!Stmt {
        const name_tok = try self.consume(.identifier, "Expect function name after 'dream'");
        _ = try self.consume(.l_paren, "Expect '(' after function name");

        var params = std.ArrayList([]const u8).init(self.mem.allocator());
        if (!self.check(.r_paren)) {
            while (true) {
                const param_tok = try self.consume(.identifier, "Expect parameter name");
                try params.append(param_tok.lexeme);
                if (!self.match(.comma)) break;
            }
        }
        _ = try self.consume(.r_paren, "Expect ')' after parameters");

        const body_stmt = try self.parseBlock();
        const func_node = try self.mem.allocator().create(FunctionStmt);
        func_node.* = FunctionStmt{
            .name = name_tok.lexeme,
            .params = try params.toOwnedSlice(),
            .body = body_stmt.block,
        };

        return Stmt{ .dream = func_node };
    }

    fn isTypeKeyword(self: *Parser, tt: TokenType) bool {
        _ = self;
        return tt == .kw_whole or tt == .kw_drift or tt == .kw_words or
            tt == .kw_truth or tt == .kw_memories or tt == .kw_diary or
            tt == .kw_forgotten;
    }

    fn parseRemember(self: *Parser, is_promise: bool) anyerror!Stmt {
        var type_ann: ?[]const u8 = null;
        var var_name: []const u8 = "";

        if (self.isTypeKeyword(self.peek().token_type) and
            self.current + 1 < self.tokens.len and
            self.tokens[self.current + 1].token_type == .identifier)
        {
            type_ann = self.advance().lexeme;
            const name_tok = self.advance();
            var_name = name_tok.lexeme;
        } else {
            if (self.peek().token_type == .identifier or
                self.peek().token_type == .kw_memories or
                self.peek().token_type == .kw_diary or
                self.peek().token_type == .kw_words or
                self.peek().token_type == .kw_whole or
                self.peek().token_type == .kw_drift or
                self.peek().token_type == .kw_truth)
            {
                const name_tok = self.advance();
                var_name = name_tok.lexeme;
            } else {
                std.debug.print("Parse error at line {d}: Expect variable name\n", .{self.peek().line});
                return error.ParseError;
            }
        }

        var initializer: Expr = Expr{ .nil_lit = {} };
        if (self.match(.equal)) {
            initializer = try self.parseExpression();
        }

        return Stmt{
            .remember_stmt = .{
                .name = var_name,
                .type_annotation = type_ann,
                .initializer = initializer,
                .is_promise = is_promise,
            },
        };
    }

    fn parseStatement(self: *Parser) anyerror!Stmt {
        if (self.match(.kw_maybe) or self.match(.kw_if)) {
            return try self.parseMaybe();
        }

        if (self.match(.kw_again)) {
            return try self.parseAgain();
        }

        if (self.match(.kw_while)) {
            const condition = try self.parseExpression();
            const body = try self.parseBlockOrStatement();
            const heap_body = try self.mem.allocator().create(Stmt);
            heap_body.* = body;
            return Stmt{ .again_while_stmt = .{ .condition = condition, .body = heap_body } };
        }

        if (self.match(.kw_wake_up)) {
            return Stmt{ .wake_up_stmt = {} };
        }

        if (self.match(.kw_turn_over)) {
            return Stmt{ .turn_over_stmt = {} };
        }

        if (self.match(.kw_wake_with) or self.match(.kw_return)) {
            if (self.check(.semicolon) or self.check(.r_brace) or self.isAtEnd()) {
                return Stmt{ .wake_with_stmt = null };
            }
            const val = try self.parseExpression();
            return Stmt{ .wake_with_stmt = val };
        }

        if (self.match(.kw_save_point)) {
            const try_branch = try self.parseBlockOrStatement();
            const heap_try = try self.mem.allocator().create(Stmt);
            heap_try.* = try_branch;

            _ = try self.consume(.kw_return_by_death, "Expect 'return_by_death' after 'save_point'");
            const catch_branch = try self.parseBlockOrStatement();
            const heap_catch = try self.mem.allocator().create(Stmt);
            heap_catch.* = catch_branch;

            return Stmt{
                .save_point_stmt = .{
                    .try_branch = heap_try,
                    .return_by_death_branch = heap_catch,
                },
            };
        }

        if (self.match(.kw_die)) {
            const msg = try self.parseExpression();
            return Stmt{ .die_stmt = msg };
        }

        if (self.match(.kw_sleep_talk) or self.match(.kw_say)) {
            const expr = try self.parseExpression();
            return Stmt{ .sleep_talk_stmt = expr };
        }

        if (self.check(.l_brace)) {
            return try self.parseBlock();
        }

        return try self.parseExpressionOrAssignStatement();
    }

    fn parseMaybe(self: *Parser) anyerror!Stmt {
        const condition = try self.parseExpression();
        const then_branch = try self.parseBlockOrStatement();
        const heap_then = try self.mem.allocator().create(Stmt);
        heap_then.* = then_branch;

        var or_maybe_list = std.ArrayList(OrMaybeBranch).init(self.mem.allocator());
        while (self.match(.kw_or_maybe)) {
            const or_cond = try self.parseExpression();
            const or_stmt = try self.parseBlockOrStatement();
            const heap_or = try self.mem.allocator().create(Stmt);
            heap_or.* = or_stmt;
            try or_maybe_list.append(OrMaybeBranch{
                .condition = or_cond,
                .branch = heap_or,
            });
        }

        var snooze_branch: ?*Stmt = null;
        if (self.match(.kw_snooze) or self.match(.kw_else)) {
            const else_stmt = try self.parseBlockOrStatement();
            const heap_else = try self.mem.allocator().create(Stmt);
            heap_else.* = else_stmt;
            snooze_branch = heap_else;
        }

        return Stmt{
            .maybe_stmt = .{
                .condition = condition,
                .then_branch = heap_then,
                .or_maybe_branches = try or_maybe_list.toOwnedSlice(),
                .snooze_branch = snooze_branch,
            },
        };
    }

    fn parseAgain(self: *Parser) anyerror!Stmt {
        if (self.match(.kw_while)) {
            const condition = try self.parseExpression();
            const body = try self.parseBlockOrStatement();
            const heap_body = try self.mem.allocator().create(Stmt);
            heap_body.* = body;
            return Stmt{ .again_while_stmt = .{ .condition = condition, .body = heap_body } };
        }

        if (self.match(.kw_each)) {
            const var_tok = try self.consume(.identifier, "Expect iteration variable after 'again each'");
            _ = try self.consume(.kw_in, "Expect 'in' after iteration variable");
            const iterable = try self.parseExpression();
            const body = try self.parseBlockOrStatement();
            const heap_body = try self.mem.allocator().create(Stmt);
            heap_body.* = body;
            return Stmt{
                .again_each_stmt = .{
                    .variable = var_tok.lexeme,
                    .iterable = iterable,
                    .body = heap_body,
                },
            };
        }

        const count = try self.parseExpression();
        _ = self.match(.kw_times);
        const body = try self.parseBlockOrStatement();
        const heap_body = try self.mem.allocator().create(Stmt);
        heap_body.* = body;
        return Stmt{ .again_times_stmt = .{ .count = count, .body = heap_body } };
    }

    fn parseBlock(self: *Parser) anyerror!Stmt {
        _ = try self.consume(.l_brace, "Expect '{' before block");
        var stmts = std.ArrayList(Stmt).init(self.mem.allocator());
        while (!self.check(.r_brace) and !self.isAtEnd()) {
            self.consumeOptionalSemicolons();
            if (self.check(.r_brace)) break;
            const stmt = try self.parseDeclaration();
            try stmts.append(stmt);
            self.consumeOptionalSemicolons();
        }
        _ = try self.consume(.r_brace, "Expect '}' after block");
        return Stmt{ .block = try stmts.toOwnedSlice() };
    }

    fn parseBlockOrStatement(self: *Parser) anyerror!Stmt {
        if (self.check(.l_brace)) {
            return try self.parseBlock();
        }
        return try self.parseStatement();
    }

    fn parseExpressionOrAssignStatement(self: *Parser) anyerror!Stmt {
        const expr = try self.parseExpression();

        if (self.match(.equal)) {
            const val = try self.parseExpression();
            switch (expr) {
                .variable => |name| {
                    return Stmt{ .assign_stmt = .{ .name = name, .value = val } };
                },
                .get_prop => |prop| {
                    return Stmt{ .set_prop = .{ .object = prop.object, .name = prop.name, .value = val } };
                },
                .index_expr => |idx| {
                    return Stmt{ .index_assign = .{ .target = idx.target, .index = idx.index.*, .value = val } };
                },
                else => return error.InvalidAssignmentTarget,
            }
        }

        return Stmt{ .expression = expr };
    }

    pub fn parseExpression(self: *Parser) anyerror!Expr {
        return try self.parseOr();
    }

    fn parseOr(self: *Parser) anyerror!Expr {
        var expr = try self.parseAnd();
        while (self.match(.kw_or)) {
            const right = try self.parseAnd();
            const heap_left = try self.mem.allocator().create(Expr);
            heap_left.* = expr;
            const heap_right = try self.mem.allocator().create(Expr);
            heap_right.* = right;
            expr = Expr{ .binary = .{ .left = heap_left, .op = .op_or, .right = heap_right } };
        }
        return expr;
    }

    fn parseAnd(self: *Parser) anyerror!Expr {
        var expr = try self.parseEquality();
        while (self.match(.kw_and)) {
            const right = try self.parseEquality();
            const heap_left = try self.mem.allocator().create(Expr);
            heap_left.* = expr;
            const heap_right = try self.mem.allocator().create(Expr);
            heap_right.* = right;
            expr = Expr{ .binary = .{ .left = heap_left, .op = .op_and, .right = heap_right } };
        }
        return expr;
    }

    fn parseEquality(self: *Parser) anyerror!Expr {
        var expr = try self.parseComparison();
        while (self.match(.equal_equal) or self.match(.bang_equal)) {
            const op: BinaryOp = if (self.previous().token_type == .equal_equal) .equal else .not_equal;
            const right = try self.parseComparison();
            const heap_left = try self.mem.allocator().create(Expr);
            heap_left.* = expr;
            const heap_right = try self.mem.allocator().create(Expr);
            heap_right.* = right;
            expr = Expr{ .binary = .{ .left = heap_left, .op = op, .right = heap_right } };
        }
        return expr;
    }

    fn parseComparison(self: *Parser) anyerror!Expr {
        var expr = try self.parseTerm();
        while (self.match(.less) or self.match(.less_equal) or self.match(.greater) or self.match(.greater_equal)) {
            const op: BinaryOp = switch (self.previous().token_type) {
                .less => .less,
                .less_equal => .less_equal,
                .greater => .greater,
                .greater_equal => .greater_equal,
                else => unreachable,
            };
            const right = try self.parseTerm();
            const heap_left = try self.mem.allocator().create(Expr);
            heap_left.* = expr;
            const heap_right = try self.mem.allocator().create(Expr);
            heap_right.* = right;
            expr = Expr{ .binary = .{ .left = heap_left, .op = op, .right = heap_right } };
        }
        return expr;
    }

    fn parseTerm(self: *Parser) anyerror!Expr {
        var expr = try self.parseFactor();
        while (self.match(.plus) or self.match(.minus)) {
            const op: BinaryOp = if (self.previous().token_type == .plus) .add else .subtract;
            const right = try self.parseFactor();
            const heap_left = try self.mem.allocator().create(Expr);
            heap_left.* = expr;
            const heap_right = try self.mem.allocator().create(Expr);
            heap_right.* = right;
            expr = Expr{ .binary = .{ .left = heap_left, .op = op, .right = heap_right } };
        }
        return expr;
    }

    fn parseFactor(self: *Parser) anyerror!Expr {
        var expr = try self.parseUnary();
        while (self.match(.star) or self.match(.slash) or self.match(.percent)) {
            const op: BinaryOp = switch (self.previous().token_type) {
                .star => .multiply,
                .slash => .divide,
                .percent => .modulo,
                else => unreachable,
            };
            const right = try self.parseUnary();
            const heap_left = try self.mem.allocator().create(Expr);
            heap_left.* = expr;
            const heap_right = try self.mem.allocator().create(Expr);
            heap_right.* = right;
            expr = Expr{ .binary = .{ .left = heap_left, .op = op, .right = heap_right } };
        }
        return expr;
    }

    fn parseUnary(self: *Parser) anyerror!Expr {
        if (self.match(.bang) or self.match(.kw_not)) {
            const right = try self.parseUnary();
            const heap_right = try self.mem.allocator().create(Expr);
            heap_right.* = right;
            return Expr{ .unary = .{ .op = .not, .right = heap_right } };
        }

        if (self.match(.minus)) {
            const right = try self.parseUnary();
            const heap_right = try self.mem.allocator().create(Expr);
            heap_right.* = right;
            return Expr{ .unary = .{ .op = .negate, .right = heap_right } };
        }

        return try self.parseCallOrIndex();
    }

    fn parseCallOrIndex(self: *Parser) anyerror!Expr {
        var expr = try self.parsePrimary();

        while (true) {
            if (self.match(.dot)) {
                const prop_name = try self.consume(.identifier, "Expect property/method name after '.'");
                if (self.match(.l_paren)) {
                    var args = std.ArrayList(Expr).init(self.mem.allocator());
                    if (!self.check(.r_paren)) {
                        while (true) {
                            const arg = try self.parseExpression();
                            try args.append(arg);
                            if (!self.match(.comma)) break;
                        }
                    }
                    _ = try self.consume(.r_paren, "Expect ')' after arguments");

                    const heap_obj = try self.mem.allocator().create(Expr);
                    heap_obj.* = expr;
                    expr = Expr{
                        .method_call = .{
                            .object = heap_obj,
                            .method = prop_name.lexeme,
                            .args = try args.toOwnedSlice(),
                        },
                    };
                } else {
                    const heap_obj = try self.mem.allocator().create(Expr);
                    heap_obj.* = expr;
                    expr = Expr{
                        .get_prop = .{
                            .object = heap_obj,
                            .name = prop_name.lexeme,
                        },
                    };
                }
            } else if (self.match(.l_bracket)) {
                const index_val = try self.parseExpression();
                _ = try self.consume(.r_bracket, "Expect ']' after index");
                const heap_target = try self.mem.allocator().create(Expr);
                heap_target.* = expr;
                const heap_index = try self.mem.allocator().create(Expr);
                heap_index.* = index_val;
                expr = Expr{
                    .index_expr = .{
                        .target = heap_target,
                        .index = heap_index,
                    },
                };
            } else if (self.match(.l_paren)) {
                var args = std.ArrayList(Expr).init(self.mem.allocator());
                if (!self.check(.r_paren)) {
                    while (true) {
                        const arg = try self.parseExpression();
                        try args.append(arg);
                        if (!self.match(.comma)) break;
                    }
                }
                _ = try self.consume(.r_paren, "Expect ')' after arguments");

                switch (expr) {
                    .variable => |callee| {
                        expr = Expr{
                            .call = .{
                                .callee = callee,
                                .args = try args.toOwnedSlice(),
                            },
                        };
                    },
                    else => return error.InvalidCallee,
                }
            } else {
                break;
            }
        }

        return expr;
    }

    fn parsePrimary(self: *Parser) anyerror!Expr {
        if (self.match(.integer_lit)) {
            const int_val = std.fmt.parseInt(i64, self.previous().lexeme, 10) catch return error.InvalidIntegerLiteral;
            return Expr{ .integer_lit = int_val };
        }

        if (self.match(.float_lit)) {
            const float_val = std.fmt.parseFloat(f64, self.previous().lexeme) catch return error.InvalidFloatLiteral;
            return Expr{ .float_lit = float_val };
        }

        if (self.match(.string_lit)) {
            return Expr{ .string_lit = self.previous().lexeme };
        }

        if (self.match(.kw_yes) or self.match(.kw_true)) {
            return Expr{ .boolean_lit = true };
        }

        if (self.match(.kw_no) or self.match(.kw_false)) {
            return Expr{ .boolean_lit = false };
        }

        if (self.match(.kw_forgotten) or self.match(.kw_nil)) {
            return Expr{ .nil_lit = {} };
        }

        if (self.match(.kw_this)) {
            return Expr{ .this_expr = {} };
        }

        if (self.match(.kw_listen)) {
            var args = std.ArrayList(Expr).init(self.mem.allocator());
            if (self.match(.l_paren)) {
                _ = try self.consume(.r_paren, "Expect ')' after listen");
            }
            return Expr{ .call = .{ .callee = "listen", .args = try args.toOwnedSlice() } };
        }

        if (self.match(.kw_new)) {
            const class_tok = try self.consume(.identifier, "Expect class name after 'new'");
            _ = try self.consume(.l_paren, "Expect '(' after class name");
            var args = std.ArrayList(Expr).init(self.mem.allocator());
            if (!self.check(.r_paren)) {
                while (true) {
                    const arg = try self.parseExpression();
                    try args.append(arg);
                    if (!self.match(.comma)) break;
                }
            }
            _ = try self.consume(.r_paren, "Expect ')' after constructor arguments");

            return Expr{
                .new_expr = .{
                    .class_name = class_tok.lexeme,
                    .args = try args.toOwnedSlice(),
                },
            };
        }

        if ((self.check(.kw_memories) and self.peekNext().token_type == .l_bracket) or self.check(.l_bracket)) {
            _ = self.match(.kw_memories);
            _ = try self.consume(.l_bracket, "Expect '[' to start list");
            var items = std.ArrayList(Expr).init(self.mem.allocator());
            if (!self.check(.r_bracket)) {
                while (true) {
                    const item = try self.parseExpression();
                    try items.append(item);
                    if (!self.match(.comma)) break;
                }
            }
            _ = try self.consume(.r_bracket, "Expect ']' after list items");
            return Expr{ .list_lit = try items.toOwnedSlice() };
        }

        if ((self.check(.kw_diary) and self.peekNext().token_type == .l_brace) or (self.check(.l_brace) and self.isMapLookahead())) {
            _ = self.match(.kw_diary);
            _ = try self.consume(.l_brace, "Expect '{' to start map");
            var entries = std.ArrayList(MapEntry).init(self.mem.allocator());
            if (!self.check(.r_brace)) {
                while (true) {
                    var key_str: []const u8 = "";
                    if (self.match(.string_lit) or self.match(.identifier)) {
                        key_str = self.previous().lexeme;
                    } else {
                        return error.ExpectKeyInMap;
                    }
                    _ = try self.consume(.colon, "Expect ':' after map key");
                    const val = try self.parseExpression();
                    try entries.append(MapEntry{ .key = key_str, .value = val });
                    if (!self.match(.comma)) break;
                }
            }
            _ = try self.consume(.r_brace, "Expect '}' after map entries");
            return Expr{ .map_lit = try entries.toOwnedSlice() };
        }

        if (self.match(.identifier) or self.match(.kw_memories) or self.match(.kw_diary) or
            self.match(.kw_count) or self.match(.kw_add) or self.match(.kw_what_is)) {
            const name = self.previous().lexeme;
            return Expr{ .variable = name };
        }

        if (self.match(.l_paren)) {
            const expr = try self.parseExpression();
            _ = try self.consume(.r_paren, "Expect ')' after expression");
            const heap_expr = try self.mem.allocator().create(Expr);
            heap_expr.* = expr;
            return Expr{ .grouping = heap_expr };
        }

        std.debug.print("Unexpected token at line {d}: {s}\n", .{ self.peek().line, self.peek().lexeme });
        return error.UnexpectedToken;
    }

    fn isMapLookahead(self: *Parser) bool {
        if (self.current + 2 < self.tokens.len) {
            const t1 = self.tokens[self.current + 1].token_type;
            const t2 = self.tokens[self.current + 2].token_type;
            if ((t1 == .string_lit or t1 == .identifier) and t2 == .colon) {
                return true;
            }
        }
        return false;
    }
};
