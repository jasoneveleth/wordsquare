const std = @import("std");
const ws = @import("wordsquare.zig");

fn solve_rec(trie: ws.TrieView, n: u8, fixed: []const ?u8, col_state: []u32, row_state: *u32, grid: []u8, raster_index: u8) bool {
    if (raster_index == n * n) return true;

    const alphabet = "abcdefghijklmnopqrstuvwxyz";
    const candidates: []const u8 = if (fixed[raster_index]) |*c| c[0..1] else alphabet;

    const row = raster_index / n;
    const col = raster_index % n;
    const col_node_index = if (row == 0) 0 else col_state[(row - 1) * n + col];
    const row_node_index = if (col == 0) 0 else row_state.*;

    for (candidates) |letter| {
        const col_next = trie.nodes[col_node_index][letter - 'a'];
        if (col_next == 0) continue;
        col_state[row * n + col] = col_next;

        const row_next = trie.nodes[row_node_index][letter - 'a'];
        if (row_next == 0) continue;
        row_state.* = row_next;

        grid[raster_index] = letter;
        if (solve_rec(trie, n, fixed, col_state, row_state, grid, raster_index + 1)) return true;
    }
    return false;
}

pub fn solve(trie: ws.TrieView, n: u8, fixed: []const ?u8, grid: []u8) bool {
    var row_state: u32 = 0;
    var col_state: [81]u32 = undefined;
    return solve_rec(trie, n, fixed, col_state[0 .. @as(usize, n) * n], &row_state, grid, 0);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();

    const args = try std.process.argsAlloc(a);
    const trie_path = if (args.len > 1) args[1] else "src/trie8.bin";
    const trie = try ws.TrieView.read(a, trie_path);
    const n = trie.width;
    const n_cells = @as(usize, n) * n;

    const fixed = try a.alloc(?u8, n_cells);
    @memset(fixed, null);
    const grid = try a.alloc(u8, n_cells);

    if (solve(trie, n, fixed, grid)) {
        for (0..n) |row| {
            std.debug.print("{s}\n", .{grid[row * n ..][0..n]});
        }
    } else {
        std.debug.print("no solution\n", .{});
    }
}
