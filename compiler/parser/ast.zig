pub const BinaryOp = enum {
    add,
    subtract,
    multiply,
    divide,
    modulo,
    equal,
    not_equal,
    less,
    less_equal,
    greater,
    greater_equal,
    op_and,
    op_or,
};

pub const UnaryOp = enum {
    negate,
    not,
};

pub const MapEntry = struct {
    key: []const u8,
    value: Expr,
};

pub const Expr = union(enum) {
    integer_lit: i64,
    float_lit: f64,
    boolean_lit: bool,
    string_lit: []const u8,
    nil_lit: void,
    list_lit: []const Expr,
    map_lit: []const MapEntry,
    index_expr: struct {
        target: *Expr,
        index: *Expr,
    },
    variable: []const u8,
    binary: struct {
        left: *Expr,
        op: BinaryOp,
        right: *Expr,
    },
    unary: struct {
        op: UnaryOp,
        right: *Expr,
    },
    grouping: *Expr,
    call: struct {
        callee: []const u8,
        args: []const Expr,
    },
    this_expr: void,
    get_prop: struct {
        object: *Expr,
        name: []const u8,
    },
    method_call: struct {
        object: *Expr,
        method: []const u8,
        args: []const Expr,
    },
    new_expr: struct {
        class_name: []const u8,
        args: []const Expr,
    },
};

pub const OrMaybeBranch = struct {
    condition: Expr,
    branch: *Stmt,
};

pub const Stmt = union(enum) {
    remember_stmt: struct {
        name: []const u8,
        type_annotation: ?[]const u8,
        initializer: Expr,
        is_promise: bool,
    },
    assign_stmt: struct {
        name: []const u8,
        value: Expr,
    },
    index_assign: struct {
        target: *Expr,
        index: Expr,
        value: Expr,
    },
    devour_stmt: []const u8,
    set_prop: struct {
        object: *Expr,
        name: []const u8,
        value: Expr,
    },
    maybe_stmt: struct {
        condition: Expr,
        then_branch: *Stmt,
        or_maybe_branches: []const OrMaybeBranch,
        snooze_branch: ?*Stmt,
    },
    again_while_stmt: struct {
        condition: Expr,
        body: *Stmt,
    },
    again_times_stmt: struct {
        count: Expr,
        body: *Stmt,
    },
    again_each_stmt: struct {
        variable: []const u8,
        iterable: Expr,
        body: *Stmt,
    },
    wake_up_stmt: void,
    turn_over_stmt: void,
    wake_with_stmt: ?Expr,
    save_point_stmt: struct {
        try_branch: *Stmt,
        return_by_death_branch: *Stmt,
    },
    die_stmt: Expr,
    rem_wakes_up_stmt: *Stmt,
    goodnight_stmt: void,
    borrow_stmt: []const u8,
    sleep_talk_stmt: Expr,
    block: []const Stmt,
    expression: Expr,
    dream: *FunctionStmt,
    class_stmt: *ClassStmt,
};

pub const FunctionStmt = struct {
    name: []const u8,
    params: []const []const u8,
    body: []const Stmt,
};

pub const ClassStmt = struct {
    name: []const u8,
    methods: []const FunctionStmt,
};
