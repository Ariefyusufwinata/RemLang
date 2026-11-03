const std = @import("std");

pub const MemoryManager = struct {
    arena: std.heap.ArenaAllocator,
    total_allocations: usize = 0,

    pub fn init(backing_allocator: std.mem.Allocator) MemoryManager {
        return MemoryManager{
            .arena = std.heap.ArenaAllocator.init(backing_allocator),
            .total_allocations = 0,
        };
    }

    pub fn deinit(self: *MemoryManager) void {
        self.arena.deinit();
    }

    pub fn allocator(self: *MemoryManager) std.mem.Allocator {
        return self.arena.allocator();
    }

    pub fn create(self: *MemoryManager, comptime T: type) !*T {
        self.total_allocations += 1;
        return try self.allocator().create(T);
    }

    pub fn alloc(self: *MemoryManager, comptime T: type, count: usize) ![]T {
        self.total_allocations += 1;
        return try self.allocator().alloc(T, count);
    }

    pub fn duplicateString(self: *MemoryManager, str: []const u8) ![]const u8 {
        self.total_allocations += 1;
        return try self.allocator().dupe(u8, str);
    }
};
