const std = @import("std");
const ws = @import("trie.zig");

const SolveIter = struct {
    trie: ws.TrieView,
    n: usize,
    fixed: []const ?u8,
    grid: []u8,
    col_state: [81]u32,
    row_state: [81]u32,
    cand: [81]u8,
    sp: usize,
    started: bool,

    fn init(trie: ws.TrieView, fixed: []const ?u8, grid: []u8) SolveIter {
        return .{
            .trie = trie,
            .n = trie.width,
            .fixed = fixed,
            .grid = grid,
            .col_state = undefined,
            .row_state = undefined,
            .cand = @splat(0),
            .sp = 0,
            .started = false,
        };
    }

    fn next(self: *SolveIter) bool {
        const n = self.n;
        const alphabet = "abcdefghijklmnopqrstuvwxyz";
        if (self.started and self.sp == n * n) self.sp -= 1;
        self.started = true;
        while (true) {
            if (self.sp == n * n) return true;
            const col_node: u32 = if (self.sp < n) 0 else self.col_state[self.sp - n];
            const row_node: u32 = if (self.sp % n == 0) 0 else self.row_state[self.sp - 1];
            const candidates: []const u8 = if (self.fixed[self.sp]) |*c| c[0..1] else alphabet;
            var placed = false;
            while (self.cand[self.sp] < candidates.len) {
                const letter = candidates[self.cand[self.sp]];
                self.cand[self.sp] += 1;
                const col_next = self.trie.nodes[col_node][letter - 'a'];
                if (col_next == 0) continue;
                const row_next = self.trie.nodes[row_node][letter - 'a'];
                if (row_next == 0) continue;
                self.col_state[self.sp] = col_next;
                self.row_state[self.sp] = row_next;
                self.grid[self.sp] = letter;
                self.sp += 1;
                placed = true;
                break;
            }
            if (!placed) {
                if (self.sp == 0) return false;
                self.cand[self.sp] = 0;
                self.sp -= 1;
            }
        }
    }

    // Serialize to JSON into writer. Only emits n*n entries for arrays.
    fn serialize(self: *const SolveIter, w: anytype) !void {
        const nn = self.n * self.n;
        try w.print("{{\"n\":{d},\"sp\":{d},\"started\":{},\"fixed\":[", .{ self.n, self.sp, self.started });
        for (0..nn) |i| {
            if (i > 0) try w.writeByte(',');
            if (self.fixed[i]) |c| try w.print("\"{c}\"", .{c}) else try w.writeAll("null");
        }
        try w.writeAll("],\"grid\":\"");
        try w.writeAll(self.grid[0..nn]);
        try w.writeAll("\",\"cand\":[");
        for (0..nn) |i| {
            if (i > 0) try w.writeByte(',');
            try w.print("{d}", .{self.cand[i]});
        }
        try w.writeAll("],\"col_state\":[");
        for (0..nn) |i| {
            if (i > 0) try w.writeByte(',');
            try w.print("{d}", .{self.col_state[i]});
        }
        try w.writeAll("],\"row_state\":[");
        for (0..nn) |i| {
            if (i > 0) try w.writeByte(',');
            try w.print("{d}", .{self.row_state[i]});
        }
        try w.writeByte(']');
        try w.writeByte('}');
    }

    // Deserialize from a JSON object. Uses the server's loaded trie.
    // Allocates fixed and grid from `a`.
    fn deserialize(a: std.mem.Allocator, trie: ws.TrieView, obj: std.json.ObjectMap) !SolveIter {
        const n = @as(usize, @intCast(obj.get("n").?.integer));
        if (n != trie.width) return error.TrieWidthMismatch;
        const nn = n * n;

        const fixed = try a.alloc(?u8, nn);
        for (obj.get("fixed").?.array.items, 0..nn) |item, i| {
            fixed[i] = switch (item) {
                .string => |s| if (s.len > 0) s[0] else null,
                else => null,
            };
        }

        const grid = try a.alloc(u8, nn);
        const grid_str = obj.get("grid").?.string;
        @memcpy(grid[0..nn], grid_str[0..nn]);

        var iter = SolveIter.init(trie, fixed, grid);
        iter.sp = @intCast(obj.get("sp").?.integer);
        iter.started = obj.get("started").?.bool;

        for (obj.get("cand").?.array.items, 0..nn) |item, i| {
            iter.cand[i] = @intCast(item.integer);
        }
        for (obj.get("col_state").?.array.items, 0..nn) |item, i| {
            iter.col_state[i] = @intCast(item.integer);
        }
        for (obj.get("row_state").?.array.items, 0..nn) |item, i| {
            iter.row_state[i] = @intCast(item.integer);
        }

        return iter;
    }

    // Build a fresh iterator from a JSON array of fixed letters (nulls or single-char strings).
    // Allocates fixed and grid from `a`.
    fn fromFixed(a: std.mem.Allocator, trie: ws.TrieView, fixed_json: ?std.json.Value) !SolveIter {
        const n = trie.width;
        const nn = @as(usize, n) * n;
        const fixed = try a.alloc(?u8, nn);
        @memset(fixed, null);
        if (fixed_json) |val| {
            for (val.array.items, 0..) |item, i| {
                if (i >= nn) break;
                fixed[i] = switch (item) {
                    .string => |s| if (s.len > 0) s[0] else null,
                    else => null,
                };
            }
        }
        const grid = try a.alloc(u8, nn);
        return SolveIter.init(trie, fixed, grid);
    }
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var global_trie: ws.TrieView = undefined;

const cors_headers: []const std.http.Header = &.{
    .{ .name = "access-control-allow-origin", .value = "*" },
    .{ .name = "access-control-allow-methods", .value = "GET, POST, OPTIONS" },
    .{ .name = "access-control-allow-headers", .value = "content-type" },
};

fn handleRequest(
    request: *std.http.Server.Request,
    a: std.mem.Allocator,
    body_buf: []u8,
) !void {
    var target_buf: [256]u8 = undefined;
    const target = target_buf[0..@min(request.head.target.len, target_buf.len)];
    @memcpy(target, request.head.target[0..target.len]);
    std.debug.print("{s} {s}\n", .{ @tagName(request.head.method), target });

    if (request.head.method == .OPTIONS) {
        try request.respond("", .{ .extra_headers = cors_headers });
        return;
    }

    if (std.mem.eql(u8, target, "/count")) {
        const content_length = request.head.content_length;
        const body_reader = request.readerExpectNone(body_buf);
        const raw: []u8 = if (content_length) |cl| blk: {
            const buf = try a.alloc(u8, cl);
            try body_reader.readSliceAll(buf);
            break :blk buf;
        } else &.{};
        const body_str = std.mem.trim(u8, raw, " \t\r\n");

        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const aa = arena.allocator();

        const fixed_json: ?std.json.Value = if (body_str.len > 0) blk: {
            const parsed = try std.json.parseFromSlice(std.json.Value, aa, body_str, .{});
            break :blk parsed.value.object.get("fixed");
        } else null;

        var iter = try SolveIter.fromFixed(aa, global_trie, fixed_json);
        var count: usize = 0;
        while (iter.next()) count += 1;
        var buf: [32]u8 = undefined;
        const resp = try std.fmt.bufPrint(&buf, "{{\"count\":{d}}}", .{count});
        try request.respond(resp, .{
            .extra_headers = cors_headers ++ &[_]std.http.Header{.{ .name = "content-type", .value = "application/json" }},
        });
        return;
    }

    if (std.mem.eql(u8, target, "/next")) {
        // Read body (only if Content-Length was given).
        const content_length = request.head.content_length;
        const body_reader = request.readerExpectNone(body_buf);
        const raw: []u8 = if (content_length) |cl| blk: {
            const buf = try a.alloc(u8, cl);
            try body_reader.readSliceAll(buf);
            break :blk buf;
        } else &.{};
        const body_str = std.mem.trim(u8, raw, " \t\r\n");
        std.debug.print("  body: {s}\n", .{if (body_str.len > 120) body_str[0..120] else body_str});

        // Use an arena so all per-request allocations are freed at once.
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const aa = arena.allocator();

        var iter: SolveIter = undefined;
        if (body_str.len == 0) {
            // No body: start fresh with all-null fixed.
            iter = try SolveIter.fromFixed(aa, global_trie, null);
        } else {
            const parsed = try std.json.parseFromSlice(std.json.Value, aa, body_str, .{});
            const obj = parsed.value.object;
            if (obj.get("started") != null) {
                // Resume from serialized state.
                iter = try SolveIter.deserialize(aa, global_trie, obj);
            } else {
                // Start fresh from fixed letters.
                iter = try SolveIter.fromFixed(aa, global_trie, obj.get("fixed"));
            }
        }

        var out_buf: [131072]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&out_buf);
        const w = fbs.writer();

        if (iter.next()) {
            const n = iter.n;
            try w.writeAll("{\"solution\":[");
            for (0..n) |row| {
                if (row > 0) try w.writeByte(',');
                try w.writeByte('"');
                try w.writeAll(iter.grid[row * n ..][0..n]);
                try w.writeByte('"');
            }
            try w.writeAll("],\"state\":");
            try iter.serialize(w);
            try w.writeByte('}');
        } else {
            try w.writeAll("{\"solution\":null}");
        }

        try request.respond(fbs.getWritten(), .{
            .extra_headers = cors_headers ++ &[_]std.http.Header{.{ .name = "content-type", .value = "application/json" }},
        });
        return;
    }

    try request.respond("not found\n", .{ .status = .not_found, .extra_headers = cors_headers });
}

pub fn main() !void {
    const a = gpa.allocator();
    const args = try std.process.argsAlloc(a);
    const trie_path: []const u8 = if (args.len >= 2) args[1] else "src/trie8.bin";
    const port: u16 = if (args.len >= 3) try std.fmt.parseInt(u16, args[2], 10) else 8080;

    global_trie = try ws.TrieView.read(a, trie_path);

    const address = try std.net.Address.parseIp("127.0.0.1", port);
    var listener = try address.listen(.{ .reuse_address = true });
    defer listener.deinit();

    std.debug.print("listening on http://127.0.0.1:{d}\n", .{port});
    std.debug.print("  GET  /count\n", .{});
    std.debug.print("  POST /next   body: {{\"fixed\":[...]}} or serialized state\n", .{});

    var read_buf: [8192]u8 = undefined;
    var write_buf: [65536]u8 = undefined;
    var body_buf: [65536]u8 = undefined;

    outer: while (true) {
        const conn = try listener.accept();
        defer conn.stream.close();

        var stream_reader = conn.stream.reader(&read_buf);
        var stream_writer = conn.stream.writer(&write_buf);
        var http_server = std.http.Server.init(stream_reader.interface(), &stream_writer.interface);

        while (http_server.reader.state == .ready) {
            var request = http_server.receiveHead() catch |err| {
                if (err != error.HttpConnectionClosing) {
                    std.debug.print("receiveHead: {}\n", .{err});
                }
                continue :outer;
            };
            handleRequest(&request, a, &body_buf) catch |err| {
                std.debug.print("handler: {}\n", .{err});
            };
        }
    }
}
