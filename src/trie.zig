const std = @import("std");

pub const TrieView = struct {
    nodes: []const [26]u32,
    width: u8,

    pub fn child(self: TrieView, node_index: u32, letter: u8) ?u32 {
        const idx = letter - 'a';
        std.debug.assert(idx < 26);
        const val = self.nodes[node_index][idx];
        if (val == 0) return null;
        return val; // may be a real node index, or WORD_END (maxInt(u32)) — caller's job to know which, based on depth
    }

    // Caller owns the returned slice (nodes backs into it).
    pub fn read(allocator: std.mem.Allocator, path: []const u8) !TrieView {
        const bytes = try std.fs.cwd().readFileAlloc(allocator, path, 256 * 1024 * 1024);
        if (bytes.len < 10 or !std.mem.eql(u8, bytes[0..4], "TRIE"))
            return error.BadFormat;
        if (bytes[4] != 1) return error.UnsupportedVersion;
        const width = bytes[5];
        const node_count = std.mem.readInt(u32, bytes[6..10][0..4], .little);
        const payload = bytes[10..];
        if (payload.len != @as(usize, node_count) * 26 * @sizeOf(u32))
            return error.BadFormat;
        // payload may not be u32-aligned; copy into aligned buffer
        const aligned = try allocator.alignedAlloc(u8, std.mem.Alignment.fromByteUnits(@alignOf(u32)), payload.len);
        @memcpy(aligned, payload);
        return .{
            .nodes = std.mem.bytesAsSlice([26]u32, aligned),
            .width = width,
        };
    }
};

const PrefixTrie = struct {
    allocator: std.mem.Allocator,
    data: std.ArrayList([26]u32),
    width: usize,

    pub fn init(allocator: std.mem.Allocator, width: usize) !PrefixTrie {
        var data = std.ArrayList([26]u32).empty;
        try data.append(allocator, [_]u32{0} ** 26); // root at index 0
        return .{ .allocator = allocator, .data = data, .width = width };
    }

    pub fn insert(self: *PrefixTrie, word: []const u8) !void {
        if (word.len != self.width) return error.BadInput;

        var node_index: u32 = 0;
        for (word, 1..) |c, i| {
            const idx = std.ascii.toLower(c) - 'a';
            if (idx >= 26) return error.BadInput;

            const is_last_letter = i == self.width;
            if (is_last_letter) {
                self.data.items[node_index][idx] = std.math.maxInt(u32);
                return;
            }
            if (self.data.items[node_index][idx] == 0) {
                self.data.items[node_index][idx] = @intCast(self.data.items.len);
                try self.data.append(self.allocator, [_]u32{0} ** 26);
            }
            node_index = self.data.items[node_index][idx];
        }
    }

    pub fn write(self: *const PrefixTrie, path: []const u8) !void {
        const body_len = self.data.items.len * 26 * @sizeOf(u32);
        const buf = try self.allocator.alloc(u8, 10 + body_len);
        defer self.allocator.free(buf);

        var fbs = std.io.fixedBufferStream(buf);
        const w = fbs.writer();
        try w.writeAll("TRIE");
        try w.writeByte(1); // version
        try w.writeByte(@intCast(self.width));
        try w.writeInt(u32, @intCast(self.data.items.len), .little);
        try w.writeAll(std.mem.sliceAsBytes(self.data.items));

        const f = try std.fs.cwd().createFile(path, .{});
        defer f.close();
        try f.writeAll(fbs.getWritten());
    }
};

pub fn buildFromFile(allocator: std.mem.Allocator, words_path: []const u8, n: usize, out_path: []const u8) !void {
    var trie = try PrefixTrie.init(allocator, n);
    const words_text = try std.fs.cwd().readFileAlloc(allocator, words_path, 64 * 1024 * 1024);
    var it = std.mem.splitScalar(u8, words_text, '\n');
    while (it.next()) |raw| {
        const w = std.mem.trimRight(u8, raw, "\r \t");
        if (w.len != n) continue;
        trie.insert(w) catch continue;
    }
    try trie.write(out_path);
}
