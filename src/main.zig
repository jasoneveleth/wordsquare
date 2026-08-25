const std = @import("std");
const ws = @import("wordsquare.zig");

// build a prefix trie of words of length n
// store the trie as a arraylist of size-26-arrays of u32s

// each cell in the grid is a decision point in our search tree
// (so we have at most 81 recurseive call depth)
// store the backtracking state a mutable NxN array of indices, which represent which level of the trie that column is at
// store the current raster order index and current letter

// for each cell from 0 to n^2
//   if we're past the last cell, return success
//   if the letter is fixed
//      update column index of your raster order index using the one above + letter, if none exist, return failure
//      recurse to next cell in raster order, if success, return success
//   else
//      for 'a' to 'z'
//         update column index of your raster order index using the one above + letter, if none exist, continue
//         recurse to next cell in raster order, if success, return success
//   return failure

pub fn solve(trie: ws.TrieView, n: u8, fixed: []const ?u8, state: []u32, raster_index: u8) bool {
    if (raster_index == n * n) return true;

    const row = raster_index / n;
    const col = raster_index % n;
    const node_index = if (row == 0) 0 else state[(row - 1) * n + col];
    if (fixed[raster_index] != null) {
        state[row*n + col] = trie.nodes[node_index][fixed[raster_index] - 'a'];
        if (solve(trie, n, fixed, state, raster_index + 1)) return true;
    } else {
        for ('a'..='z') |c| {
            state[row*n + col] = trie.nodes[node_index][c - 'a'];
            if (solve(trie, n, fixed, state, raster_index + 1)) return true;
        }
    }

    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();

    const trie = try ws.TrieView.read(a, "src/trie8.bin");
    std.debug.print("hello world (nodes={d}, width={d})\n", .{ trie.nodes.len, trie.width });
}
