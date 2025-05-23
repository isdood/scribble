cat > ../lazuline/src/lib.zig << 'EOF'
const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const Thread = std.Thread;
const Atomic = std.atomic.Value;

pub const WorkFn = *const fn (*anyopaque) void;

pub const Job = struct {
    context: *anyopaque,
    work_fn: WorkFn,
};

pub const ThreadPool = struct {
    const Self = @This();
    
    thread: Thread,
<<<<<<< HEAD
    current_job: ?Job,
    job_mutex: Thread.Mutex,
    job_available: Thread.Condition,
    allocator: std.mem.Allocator,
    running: Atomic(bool),
    jobs_completed: Atomic(usize),
    jobs_scheduled: Atomic(usize),
    
    pub fn init(allocator: std.mem.Allocator) !Self {
        print("[MAIN] Creating thread pool\n", .{});
        
        var pool = Self{
            .thread = undefined,
            .current_job = null,
            .job_mutex = .{},
            .job_available = .{},
            .allocator = allocator,
            .running = Atomic(bool).init(true),
            .jobs_completed = Atomic(usize).init(0),
            .jobs_scheduled = Atomic(usize).init(0),
        };
        
        print("[MAIN] Starting worker thread\n", .{});
        pool.thread = try Thread.spawn(.{}, workerFn, .{&pool});
        print("[MAIN] Worker thread started\n", .{});
=======
    job_queue: std.ArrayList(Job),
    job_mutex: Thread.Mutex,
    job_available: Thread.Condition,
    allocator: std.mem.Allocator,
    running: bool,
    
    pub fn init(allocator: std.mem.Allocator) !Self {
        print("[POOL] Init\n", .{});
        
        var pool = Self{
            .thread = undefined,
            .job_queue = std.ArrayList(Job).init(allocator),
            .job_mutex = .{},
            .job_available = .{},
            .allocator = allocator,
            .running = true,
        };
        
        try pool.job_queue.ensureTotalCapacity(100);
        
        print("[POOL] Starting worker\n", .{});
        pool.thread = try Thread.spawn(.{}, workerFn, .{&pool});
        
>>>>>>> a590742473f2b9020924db40aa0dfc9555d216ba
        return pool;
    }
    
    fn workerFn(pool: *Self) void {
<<<<<<< HEAD
        print("[WORKER] Thread starting\n", .{});
        var jobs_done: usize = 0;
        
        while (pool.running.load(.acquire)) {
            pool.job_mutex.lock();
            
            // Wait for a job to become available
            while (pool.current_job == null and pool.running.load(.acquire)) {
                print("[WORKER] Waiting for job (done: {})\n", .{jobs_done});
                pool.job_available.wait(&pool.job_mutex);
            }
            
            // Check if we have a job
            const job = if (pool.current_job) |j| blk: {
                print("[WORKER] Got job {} (scheduled: {})\n", 
                    .{jobs_done + 1, pool.jobs_scheduled.load(.acquire)});
                pool.current_job = null;
                break :blk j;
            } else null;
            
            pool.job_mutex.unlock();
            
            // Process job if we got one
            if (job) |j| {
                print("[WORKER] Starting job {}\n", .{jobs_done + 1});
                j.work_fn(j.context);
                jobs_done += 1;
                _ = pool.jobs_completed.fetchAdd(1, .release);
                print("[WORKER] Completed job {} (total: {})\n", 
                    .{jobs_done, pool.jobs_completed.load(.acquire)});
=======
        print("[WORKER] Starting\n", .{});
        
        while (true) {
            pool.job_mutex.lock();
            
            while (pool.job_queue.items.len == 0 and pool.running) {
                pool.job_available.wait(&pool.job_mutex);
>>>>>>> a590742473f2b9020924db40aa0dfc9555d216ba
            }
            
            if (!pool.running and pool.job_queue.items.len == 0) {
                pool.job_mutex.unlock();
                break;
            }
            
            const job = pool.job_queue.orderedRemove(0);
            print("[WORKER] Got job\n", .{});
            
            pool.job_mutex.unlock();
            
            job.work_fn(job.context);
            print("[WORKER] Finished job\n", .{});
        }
        
<<<<<<< HEAD
        print("[WORKER] Thread exiting after {} jobs\n", .{jobs_done});
    }
    
    pub fn deinit(self: *Self) void {
        print("[MAIN] Shutting down thread pool\n", .{});
        
        // Signal shutdown
        self.running.store(false, .release);
        
        // Wake up worker if it's waiting
        self.job_mutex.lock();
        self.job_available.signal();
        self.job_mutex.unlock();
        
        // Wait for thread to finish
        self.thread.join();
        
        // Print final stats
        const completed = self.jobs_completed.load(.acquire);
        const scheduled = self.jobs_scheduled.load(.acquire);
        print("[MAIN] Thread pool shutdown complete (completed {}/{} jobs)\n", 
            .{completed, scheduled});
=======
        print("[WORKER] Exiting\n", .{});
    }
    
    pub fn deinit(self: *Self) void {
        print("[POOL] Shutdown\n", .{});
        
        self.job_mutex.lock();
        self.running = false;
        self.job_available.signal();
        self.job_mutex.unlock();
        
        self.thread.join();
        self.job_queue.deinit();
>>>>>>> a590742473f2b9020924db40aa0dfc9555d216ba
    }
    
    pub fn schedule(self: *Self, context: anytype, comptime work_fn: fn (*const std.meta.Child(@TypeOf(context))) void) !void {
        print("[POOL] Schedule job\n", .{});
        
        const PtrType = *const std.meta.Child(@TypeOf(context));
        
        const Wrapper = struct {
            fn call(ptr: *anyopaque) void {
                print("[JOB] Converting context pointer\n", .{});
                const typed_ptr = @as(PtrType, @ptrCast(@alignCast(ptr)));
                print("[JOB] Calling user work function\n", .{});
                work_fn(typed_ptr);
                print("[JOB] User work function returned\n", .{});
            }
        };
        
<<<<<<< HEAD
        // Create job
=======
>>>>>>> a590742473f2b9020924db40aa0dfc9555d216ba
        const job = Job{
            .context = @constCast(context),
            .work_fn = Wrapper.call,
        };
        
<<<<<<< HEAD
        // Schedule job
        self.job_mutex.lock();
        defer self.job_mutex.unlock();
        
        if (!self.running.load(.acquire)) {
            print("[MAIN] Cannot schedule job - thread pool is shutting down\n", .{});
            return error.ThreadPoolShuttingDown;
        }
        
        print("[MAIN] Scheduling job {}\n", 
            .{self.jobs_scheduled.load(.acquire) + 1});
            
        if (self.current_job != null) {
            print("[MAIN] Warning: Overwriting pending job\n", .{});
        }
        
        self.current_job = job;
        _ = self.jobs_scheduled.fetchAdd(1, .release);
        
        // Signal worker
=======
        self.job_mutex.lock();
        defer self.job_mutex.unlock();
        
        if (!self.running) return error.ThreadPoolShutDown;
        
        try self.job_queue.append(job);
>>>>>>> a590742473f2b9020924db40aa0dfc9555d216ba
        self.job_available.signal();
    }
    
    pub fn wait(self: *Self) void {
<<<<<<< HEAD
        print("[MAIN] Waiting for current job to complete\n", .{});
        const start = std.time.milliTimestamp();
        const initial_completed = self.jobs_completed.load(.acquire);
        
        while (true) {
            const completed = self.jobs_completed.load(.acquire);
            const scheduled = self.jobs_scheduled.load(.acquire);
            
            if (completed == scheduled) {
                print("[MAIN] All jobs complete ({}/{})\n", .{completed, scheduled});
                break;
            }
            
            if (std.time.milliTimestamp() - start > 5000) {
                print("[MAIN] Wait timeout - completed {}/{}\n", 
                    .{completed, scheduled});
                break;
            }
            
            if (completed > initial_completed) {
                print("[MAIN] Progress: {}/{} jobs complete\n", 
                    .{completed, scheduled});
            }
            
            std.time.sleep(1 * std.time.ns_per_ms);
        }
=======
        print("[POOL] Wait\n", .{});
        
        while (true) {
            self.job_mutex.lock();
            const done = (self.job_queue.items.len == 0);
            self.job_mutex.unlock();
            
            if (done) break;
            
            std.time.sleep(10 * std.time.ns_per_ms);
        }
        
        print("[POOL] Done waiting\n", .{});
>>>>>>> a590742473f2b9020924db40aa0dfc9555d216ba
    }
};
EOF
