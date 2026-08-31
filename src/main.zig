const std = @import("std");
const ws = @import("trie.zig");

pub fn solve_iter(trie: ws.TrieView, n: usize, fixed: []const ?u8, grid: []u8) bool {
    const alphabet = "abcdefghijklmnopqrstuvwxyz";
    var col_state: [81]u32 = undefined;
    var row_state: [81]u32 = undefined;
    var cand: [81]u8 = @splat(0);
    var sp: usize = 0;

    while (sp < n * n) {
        const col_node: u32 = if (sp < n) 0 else col_state[sp - n];
        const row_node: u32 = if (sp % n == 0) 0 else row_state[sp - 1];
        const candidates: []const u8 = if (fixed[sp]) |*c| c[0..1] else alphabet;

        var placed = false;
        while (cand[sp] < candidates.len) {
            const letter = candidates[cand[sp]];
            cand[sp] += 1;
            const col_next = trie.nodes[col_node][letter - 'a'];
            if (col_next == 0) continue;
            const row_next = trie.nodes[row_node][letter - 'a'];
            if (row_next == 0) continue;
            col_state[sp] = col_next;
            row_state[sp] = row_next;
            grid[sp] = letter;
            sp += 1;
            placed = true;
            break;
        }

        if (!placed) {
            if (sp == 0) return false;
            cand[sp] = 0;
            sp -= 1;
        }
    }

    return true;
}

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

pub fn main(init: std.process.Init) !void {
    const a = init.gpa;
    const io = init.io;

    var args_list: std.ArrayList([]const u8) = .empty;
    var args_it = std.process.Args.Iterator.init(init.minimal.args);
    while (args_it.next()) |arg| try args_list.append(a, arg);
    const args = args_list.items;

    // usage: wordsquare <trie.bin>
    //        wordsquare <words.txt> <n> <trie.bin>
    const trie_path: []const u8 = switch (args.len) {
        1 => "src/trie8.bin",
        2 => args[1],
        4 => blk: {
            const n = try std.fmt.parseInt(usize, args[2], 10);
            try ws.buildFromFile(io, a, args[1], n, args[3]);
            break :blk args[3];
        },
        else => {
            std.debug.print("usage: wordsquare [<words.txt> <n>] <trie.bin>\n", .{});
            return;
        },
    };
    const trie = try ws.TrieView.read(io, a, trie_path);
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
