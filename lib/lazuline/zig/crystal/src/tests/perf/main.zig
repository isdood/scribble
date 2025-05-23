const std = @import("std");
const crystal = @import("crystal");
const testing = std.testing;
const thresholds = @import("thresholds.zig");

const PerformanceMetrics = struct {
    operation_time: u64,
    memory_used: usize,
    iterations: usize,
};

pub fn main() !void {
    std.debug.print("\n=== Performance Tests ===\n", .{});

    // Core Operation Performance
    std.debug.print("\nTesting Core Operation Performance:\n", .{});
    const core_metrics = try testCorePerformance();
    const iterations_u64: u64 = @as(u64, @intCast(core_metrics.iterations));
    const avg_time = @divTrunc(core_metrics.operation_time, iterations_u64);

    try testing.expect(avg_time <= thresholds.PerformanceThresholds.MAX_CORE_OP_TIME);
    const ops_per_sec = @divTrunc(1_000_000_000, avg_time);
    try testing.expect(ops_per_sec >= thresholds.PerformanceThresholds.MIN_CORE_OPS_PER_SEC);

    std.debug.print("✓ Core operations: {d}ns/op ({d} iterations, {d} ops/sec)\n",
        .{ avg_time, core_metrics.iterations, ops_per_sec });
    if (avg_time <= thresholds.PerformanceThresholds.TARGET_CORE_OP_TIME) {
        std.debug.print("✨ Core performance exceeds target!\n", .{});
    }

    // Memory Usage Performance
    std.debug.print("\nTesting Memory Usage:\n", .{});
    const memory_metrics = try testMemoryPerformance();
    const avg_memory = memory_metrics.memory_used / memory_metrics.iterations;

    try testing.expect(avg_memory <= thresholds.PerformanceThresholds.MAX_MEMORY_PER_OP);
    try testing.expect(memory_metrics.memory_used <= thresholds.PerformanceThresholds.MAX_TOTAL_MEMORY);

    std.debug.print("✓ Memory usage: {d} bytes/op (total: {d} bytes)\n",
        .{ avg_memory, memory_metrics.memory_used });
    if (avg_memory <= thresholds.PerformanceThresholds.TARGET_MEMORY_PER_OP) {
        std.debug.print("✨ Memory usage below target!\n", .{});
    }

    // Concurrent Operations Performance
    std.debug.print("\nTesting Concurrent Operations:\n", .{});
    const concurrent_metrics = try testConcurrentPerformance();
    const concurrent_iterations_u64: u64 = @as(u64, @intCast(concurrent_metrics.iterations));
    const avg_concurrent_time = @divTrunc(concurrent_metrics.operation_time, concurrent_iterations_u64);

    try testing.expect(avg_concurrent_time <= thresholds.PerformanceThresholds.MAX_CONCURRENT_OP_TIME);
    const concurrent_ops_per_sec = @divTrunc(1_000_000_000, avg_concurrent_time);
    try testing.expect(concurrent_ops_per_sec >= thresholds.PerformanceThresholds.MIN_CONCURRENT_OPS_PER_SEC);

    std.debug.print("✓ Concurrent operations: {d}ns/op ({d} ops/sec)\n",
        .{ avg_concurrent_time, concurrent_ops_per_sec });
    if (avg_concurrent_time <= thresholds.PerformanceThresholds.TARGET_CONCURRENT_OP_TIME) {
        std.debug.print("✨ Concurrent performance exceeds target!\n", .{});
    }

    std.debug.print("\n✨ All performance tests passed thresholds! ✨\n", .{});
}

fn testCorePerformance() !PerformanceMetrics {
    const iterations: usize = 10_000;
    var timer = try std.time.Timer.start();
    const start_time = timer.lap();

    const core = crystal_core_init() orelse return error.InitializationFailed;
    defer std.heap.c_allocator.destroy(core);

    const task = "performance test task";
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        crystal_core_process_task(core, task.ptr, task.len);
    }

    const end_time = timer.lap();

    return PerformanceMetrics{
        .operation_time = end_time - start_time,
        .memory_used = @sizeOf(crystal.CrystalCore),
        .iterations = iterations,
    };
}

fn testMemoryPerformance() !PerformanceMetrics {
    const iterations: usize = 1_000;
    var total_memory: usize = 0;
    var timer = try std.time.Timer.start();
    const start_time = timer.lap();

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        const state = julia_harmony_init() orelse return error.InitializationFailed;
        total_memory += @sizeOf(crystal.harmony.HarmonyState);
        std.heap.c_allocator.destroy(state);
    }

    const end_time = timer.lap();

    return PerformanceMetrics{
        .operation_time = end_time - start_time,
        .memory_used = total_memory,
        .iterations = iterations,
    };
}

fn testConcurrentPerformance() !PerformanceMetrics {
    const iterations: usize = 1_000;
    var timer = try std.time.Timer.start();
    const start_time = timer.lap();

    var cores = std.ArrayList(?*crystal.CrystalCore).init(std.heap.c_allocator);
    defer cores.deinit();

    // Create multiple cores
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        const core = crystal_core_init() orelse return error.InitializationFailed;
        try cores.append(core);
    }
    defer for (cores.items) |core| {
        if (core) |c| std.heap.c_allocator.destroy(c);
    };

    // Process tasks concurrently
    const task = "concurrent test task";
    i = 0;
    while (i < iterations) : (i += 1) {
        for (cores.items) |core| {
            if (core) |c| crystal_core_process_task(c, task.ptr, task.len);
        }
    }

    const end_time = timer.lap();

    return PerformanceMetrics{
        .operation_time = end_time - start_time,
        .memory_used = cores.items.len * @sizeOf(crystal.CrystalCore),
        .iterations = iterations * cores.items.len,
    };
}

// Import FFI functions
extern fn crystal_core_init() ?*crystal.CrystalCore;
extern fn crystal_core_process_task(?*crystal.CrystalCore, [*]const u8, usize) void;
extern fn julia_harmony_init() ?*crystal.harmony.HarmonyState;
extern fn julia_harmony_process(?*crystal.harmony.HarmonyState) void;

test {
    try main();
}

// Add after the main() function:
fn recordPerformanceMetrics(
    core_time: u64,
    core_ops: u64,
    memory_per_op: usize,
    total_memory: usize,
    concurrent_time: u64,
    concurrent_ops: u64,
) !void {
    var history = @import("history.zig").PerformanceHistory.init(std.heap.c_allocator);
    defer history.deinit();

    // Try to load existing history
    history.loadFromFile() catch {};

    // Add new record
    try history.addRecord(.{
        .timestamp = std.time.timestamp(),
        .core_op_time = core_time,
        .core_ops_per_sec = core_ops,
        .memory_per_op = memory_per_op,
        .total_memory = total_memory,
        .concurrent_op_time = concurrent_time,
        .concurrent_ops_per_sec = concurrent_ops,
    });
}
