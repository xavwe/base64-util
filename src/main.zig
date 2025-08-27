const std = @import("std");

const Base64 = struct {
    _encode_table: *const [64]u8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
    _decode_table: [256]u8 = blk: {
        var table = [_]u8{255} ** 256;

        // A-Z: 0-25
        for (0..26) |i| {
            table['A' + i] = @intCast(i);
        }

        // a-z: 26-51
        for (0..26) |i| {
            table['a' + i] = @intCast(26 + i);
        }

        // 0-9: 52-61
        for (0..10) |i| {
            table['0' + i] = @intCast(52 + i);
        }

        table['+'] = 62;
        table['/'] = 63;
        table['='] = 254; // padding marker

        break :blk table;
    },

    pub fn encode(self: @This(), allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        const output_len = (input.len + 2) / 3 * 4;
        var output = try allocator.alloc(u8, output_len);
        var i: usize = 0;
        var out_idx: usize = 0;

        while (i + 2 < input.len) : (i += 3) {
            const group = (@as(u24, input[i]) << 16) | (@as(u24, input[i + 1]) << 8) | input[i + 2];
            output[out_idx] = self._encode_table[(group >> 18) & 0x3F];
            output[out_idx + 1] = self._encode_table[(group >> 12) & 0x3F];
            output[out_idx + 2] = self._encode_table[(group >> 6) & 0x3F];
            output[out_idx + 3] = self._encode_table[group & 0x3F];
            out_idx += 4;
        }

        if (i < input.len) {
            var group: u24 = @as(u24, input[i]) << 16;
            if (i + 1 < input.len) group |= @as(u24, input[i + 1]) << 8;

            output[out_idx] = self._encode_table[(group >> 18) & 0x3F];
            output[out_idx + 1] = self._encode_table[(group >> 12) & 0x3F];
            output[out_idx + 2] = if (i + 1 < input.len) self._encode_table[(group >> 6) & 0x3F] else '=';
            output[out_idx + 3] = '=';
        }

        return output;
    }

    pub fn decode(self: @This(), allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        var padding: usize = 0;
        if (input.len >= 2) {
            if (input[input.len - 1] == '=') padding += 1;
            if (input[input.len - 2] == '=') padding += 1;
        }

        const output_len = input.len * 3 / 4 - padding;
        var output = try allocator.alloc(u8, output_len);
        var out_idx: usize = 0;
        var i: usize = 0;

        while (i + 3 < input.len) : (i += 4) {
            const group = (@as(u32, self._decode_table[input[i]]) << 18) |
                (@as(u32, self._decode_table[input[i + 1]]) << 12) |
                (@as(u32, if (input[i + 2] == '=') 0 else self._decode_table[input[i + 2]]) << 6) |
                (if (input[i + 3] == '=') 0 else self._decode_table[input[i + 3]]);

            if (out_idx < output.len) output[out_idx] = @intCast((group >> 16) & 0xFF);
            if (out_idx + 1 < output.len) output[out_idx + 1] = @intCast((group >> 8) & 0xFF);
            if (out_idx + 2 < output.len) output[out_idx + 2] = @intCast(group & 0xFF);
            out_idx += 3;
        }

        return output;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const base64 = Base64{};
    const input =
        \\This is a test!
        \\This is a test!
    ;

    const encoded = try base64.encode(allocator, input);
    defer allocator.free(encoded);
    std.debug.print("base64 encoded:\n{s}\n", .{encoded});

    const decoded = try base64.decode(allocator, encoded);
    defer allocator.free(decoded);
    std.debug.print("base64 decoded:\n{s}\n", .{decoded});
}
