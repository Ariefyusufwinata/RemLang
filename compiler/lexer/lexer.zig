const std = @import("std");
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;

pub const Lexer = struct {
    source: []const u8,
    start: usize = 0,
    current: usize = 0,
    line: usize = 1,

    pub fn init(source: []const u8) Lexer {
        return Lexer{
            .source = source,
            .start = 0,
            .current = 0,
            .line = 1,
        };
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Lexer) u8 {
        const c = self.source[self.current];
        self.current += 1;
        return c;
    }

    fn peek(self: *Lexer) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn peekNext(self: *Lexer) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn match(self: *Lexer, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;
        self.current += 1;
        return true;
    }

    fn skipWhitespaceAndComments(self: *Lexer) void {
        while (!self.isAtEnd()) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => {
                    _ = self.advance();
                },
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                'z' => {
                    if (self.current + 2 < self.source.len and
                        self.source[self.current + 1] == 'z' and
                        self.source[self.current + 2] == 'z')
                    {
                        const next_idx = self.current + 3;
                        if (next_idx >= self.source.len or
                            self.source[next_idx] == ' ' or
                            self.source[next_idx] == '\t' or
                            self.source[next_idx] == '\r' or
                            self.source[next_idx] == '\n')
                        {
                            while (!self.isAtEnd() and self.peek() != '\n') {
                                _ = self.advance();
                            }
                            continue;
                        }
                    }
                    return;
                },
                '/' => {
                    if (self.peekNext() == '/') {
                        while (!self.isAtEnd() and self.peek() != '\n') {
                            _ = self.advance();
                        }
                    } else {
                        return;
                    }
                },
                else => return,
            }
        }
    }

    fn makeToken(self: *Lexer, token_type: TokenType) Token {
        return Token{
            .token_type = token_type,
            .lexeme = self.source[self.start..self.current],
            .line = self.line,
        };
    }

    fn string(self: *Lexer, quote: u8) !Token {
        while (!self.isAtEnd() and self.peek() != quote) {
            if (self.peek() == '\n') self.line += 1;
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            return error.UnterminatedString;
        }

        _ = self.advance();

        return Token{
            .token_type = .string_lit,
            .lexeme = self.source[self.start + 1 .. self.current - 1],
            .line = self.line,
        };
    }

    fn number(self: *Lexer) Token {
        while (!self.isAtEnd() and std.ascii.isDigit(self.peek())) {
            _ = self.advance();
        }

        if (self.peek() == '.' and std.ascii.isDigit(self.peekNext())) {
            _ = self.advance();
            while (!self.isAtEnd() and std.ascii.isDigit(self.peek())) {
                _ = self.advance();
            }
            return self.makeToken(.float_lit);
        }

        return self.makeToken(.integer_lit);
    }

    fn identifierOrKeyword(self: *Lexer) Token {
        while (!self.isAtEnd() and (std.ascii.isAlphanumeric(self.peek()) or self.peek() == '_')) {
            _ = self.advance();
        }

        const text = self.source[self.start..self.current];
        const token_type: TokenType = if (std.mem.eql(u8, text, "remember"))
            .kw_remember
        else if (std.mem.eql(u8, text, "promise"))
            .kw_promise
        else if (std.mem.eql(u8, text, "devour"))
            .kw_devour
        else if (std.mem.eql(u8, text, "whole"))
            .kw_whole
        else if (std.mem.eql(u8, text, "drift"))
            .kw_drift
        else if (std.mem.eql(u8, text, "words"))
            .kw_words
        else if (std.mem.eql(u8, text, "truth"))
            .kw_truth
        else if (std.mem.eql(u8, text, "forgotten"))
            .kw_forgotten
        else if (std.mem.eql(u8, text, "memories"))
            .kw_memories
        else if (std.mem.eql(u8, text, "diary"))
            .kw_diary
        else if (std.mem.eql(u8, text, "yes"))
            .kw_yes
        else if (std.mem.eql(u8, text, "no"))
            .kw_no
        else if (std.mem.eql(u8, text, "maybe"))
            .kw_maybe
        else if (std.mem.eql(u8, text, "or_maybe"))
            .kw_or_maybe
        else if (std.mem.eql(u8, text, "snooze"))
            .kw_snooze
        else if (std.mem.eql(u8, text, "again"))
            .kw_again
        else if (std.mem.eql(u8, text, "while"))
            .kw_while
        else if (std.mem.eql(u8, text, "times"))
            .kw_times
        else if (std.mem.eql(u8, text, "each"))
            .kw_each
        else if (std.mem.eql(u8, text, "in"))
            .kw_in
        else if (std.mem.eql(u8, text, "wake_up"))
            .kw_wake_up
        else if (std.mem.eql(u8, text, "turn_over"))
            .kw_turn_over
        else if (std.mem.eql(u8, text, "dream"))
            .kw_dream
        else if (std.mem.eql(u8, text, "wake_with"))
            .kw_wake_with
        else if (std.mem.eql(u8, text, "save_point"))
            .kw_save_point
        else if (std.mem.eql(u8, text, "return_by_death"))
            .kw_return_by_death
        else if (std.mem.eql(u8, text, "die"))
            .kw_die
        else if (std.mem.eql(u8, text, "rem_wakes_up"))
            .kw_rem_wakes_up
        else if (std.mem.eql(u8, text, "goodnight"))
            .kw_goodnight
        else if (std.mem.eql(u8, text, "sleep_talk"))
            .kw_sleep_talk
        else if (std.mem.eql(u8, text, "listen"))
            .kw_listen
        else if (std.mem.eql(u8, text, "borrow"))
            .kw_borrow
        else if (std.mem.eql(u8, text, "count"))
            .kw_count
        else if (std.mem.eql(u8, text, "add"))
            .kw_add
        else if (std.mem.eql(u8, text, "what_is"))
            .kw_what_is
        else if (std.mem.eql(u8, text, "and"))
            .kw_and
        else if (std.mem.eql(u8, text, "or"))
            .kw_or
        else if (std.mem.eql(u8, text, "not"))
            .kw_not
        else if (std.mem.eql(u8, text, "class"))
            .kw_class
        else if (std.mem.eql(u8, text, "new"))
            .kw_new
        else if (std.mem.eql(u8, text, "this"))
            .kw_this
        else if (std.mem.eql(u8, text, "init"))
            .kw_init
        else if (std.mem.eql(u8, text, "let"))
            .kw_remember
        else if (std.mem.eql(u8, text, "fn"))
            .kw_dream
        else if (std.mem.eql(u8, text, "if"))
            .kw_maybe
        else if (std.mem.eql(u8, text, "else"))
            .kw_snooze
        else if (std.mem.eql(u8, text, "return"))
            .kw_wake_with
        else if (std.mem.eql(u8, text, "true"))
            .kw_yes
        else if (std.mem.eql(u8, text, "false"))
            .kw_no
        else if (std.mem.eql(u8, text, "nil"))
            .kw_forgotten
        else if (std.mem.eql(u8, text, "say"))
            .kw_sleep_talk
        else
            .identifier;

        return self.makeToken(token_type);
    }

    pub fn nextToken(self: *Lexer) !Token {
        self.skipWhitespaceAndComments();
        self.start = self.current;

        if (self.isAtEnd()) {
            return Token{
                .token_type = .eof,
                .lexeme = "",
                .line = self.line,
            };
        }

        const c = self.advance();

        if (std.ascii.isDigit(c)) {
            return self.number();
        }

        if (std.ascii.isAlphabetic(c) or c == '_') {
            return self.identifierOrKeyword();
        }

        switch (c) {
            '(' => return self.makeToken(.l_paren),
            ')' => return self.makeToken(.r_paren),
            '{' => return self.makeToken(.l_brace),
            '}' => return self.makeToken(.r_brace),
            '[' => return self.makeToken(.l_bracket),
            ']' => return self.makeToken(.r_bracket),
            ',' => return self.makeToken(.comma),
            ':' => return self.makeToken(.colon),
            ';' => return self.makeToken(.semicolon),
            '.' => return self.makeToken(.dot),
            '+' => return self.makeToken(.plus),
            '-' => {
                if (self.match('>')) return self.makeToken(.arrow);
                return self.makeToken(.minus);
            },
            '*' => return self.makeToken(.star),
            '/' => return self.makeToken(.slash),
            '%' => return self.makeToken(.percent),
            '!' => {
                if (self.match('=')) return self.makeToken(.bang_equal);
                return self.makeToken(.bang);
            },
            '=' => {
                if (self.match('=')) return self.makeToken(.equal_equal);
                if (self.match('>')) return self.makeToken(.fat_arrow);
                return self.makeToken(.equal);
            },
            '<' => {
                if (self.match('=')) return self.makeToken(.less_equal);
                return self.makeToken(.less);
            },
            '>' => {
                if (self.match('=')) return self.makeToken(.greater_equal);
                return self.makeToken(.greater);
            },
            '"' => return try self.string('"'),
            '\'' => return try self.string('\''),
            else => return error.UnexpectedCharacter,
        }
    }
};
