const std = @import("std");
const ArrayList = std.ArrayList;

const deck_arr = [52]Card{
    .two,
    .three,
    .four,
    .five,
    .six,
    .seven,
    .eight,
    .nine,
    .ten,
    .jack,
    .queen,
    .king,
    .ace,
    .two,
    .three,
    .four,
    .five,
    .six,
    .seven,
    .eight,
    .nine,
    .ten,
    .jack,
    .queen,
    .king,
    .ace,
    .two,
    .three,
    .four,
    .five,
    .six,
    .seven,
    .eight,
    .nine,
    .ten,
    .jack,
    .queen,
    .king,
    .ace,
    .two,
    .three,
    .four,
    .five,
    .six,
    .seven,
    .eight,
    .nine,
    .ten,
    .jack,
    .queen,
    .king,
    .ace,
};

pub fn main() anyerror!void {
    const num_of_times = 100_000;
    const rows_to_write: [num_of_times]CSVRow = war(num_of_times);
    var w = (try std.fs.cwd().createFile("./out.csv", .{})).writer();
    try w.print("who_won, times, len_of_p1, len_of_p2\n", .{});
    for (rows_to_write) |row| {
        try w.print("{}, {}, {}, {}\n", .{ row.who_won, row.times, row.len_of_p1, row.len_of_p2 });
    }
}

const CSVRow = struct {
    who_won: bool,
    times: u32,
    len_of_p1: usize,
    len_of_p2: usize,
};

const Card = enum(u4) {
    two = 1,
    three = 2,
    four = 3,
    five = 4,
    six = 5,
    seven = 6,
    eight = 7,
    nine = 8,
    ten = 9,
    jack = 10,
    queen = 11,
    king = 12,
    ace = 13,
};

fn war(comptime how_many_tries: u32) [how_many_tries]CSVRow {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    var deck: Deck = Deck.init(allocator);
    defer deck.deinit();
    return deck.war(how_many_tries);
}

const Deck = struct {
    const Self = @This();
    const State = enum {
        Regular,
        InWar,
    };

    p1: ArrayList(Card),
    p2: ArrayList(Card),
    war_buf: ArrayList(Card),
    allocator: *std.mem.Allocator,
    count: u32 = 0,

    fn init(a: *std.mem.Allocator) Self {
        var self = .{
            .p1 = ArrayList(Card).init(a),
            .p2 = ArrayList(Card).init(a),
            .war_buf = ArrayList(Card).init(a),
            .allocator = a,
        };
        self.p1.appendSlice(deck_arr[0..26]) catch unreachable;
        self.p2.appendSlice(deck_arr[26..52]) catch unreachable;
        var buf: [8]u8 = undefined;
        std.crypto.randomBytes(buf[0..]) catch unreachable;
        const seed = std.mem.readIntLittle(u64, buf[0..8]);
        var r = std.rand.DefaultPrng.init(seed);
        r.random.shuffle(Card, self.p1.items);
        r.random.shuffle(Card, self.p2.items);
        return self;
    }
    fn reset(self: *Self) void {
        self.p1.items.len = 0;
        self.p2.items.len = 0;
        self.count = 0;
        self.war_buf.items.len = 0;
        self.p1.appendSlice(deck_arr[0..26]) catch unreachable;
        self.p2.appendSlice(deck_arr[26..52]) catch unreachable;
        var buf: [8]u8 = undefined;
        std.crypto.randomBytes(buf[0..]) catch unreachable;
        const seed = std.mem.readIntLittle(u64, buf[0..8]);
        var r = std.rand.DefaultPrng.init(seed);
        r.random.shuffle(Card, self.p1.items);
        r.random.shuffle(Card, self.p2.items);
    }
    fn deinit(self: *Self) void {
        std.debug.assert(self.p1.items.len + self.p2.items.len + self.war_buf.items.len == 52);
        self.p1.deinit();
        self.p2.deinit();
    }
    fn print(self: *Self) void {
        std.debug.print("count: {}\n", .{self.count});
        std.debug.print("p1:", .{});
        for (self.p1.items) |card| {
            std.debug.print("{} ", .{@tagName(card)});
        }
        std.debug.print("\n", .{});
        std.debug.print("p2:", .{});
        for (self.p2.items) |card| {
            std.debug.print("{} ", .{@tagName(card)});
        }
        std.debug.print("\n", .{});
        std.debug.print("war_buf:", .{});
        for (self.war_buf.items) |card| {
            std.debug.print("{} ", .{@tagName(card)});
        }
        std.debug.print("\n", .{});
        std.debug.print("items_len: {}\n", .{self.p1.items.len + self.p2.items.len + self.war_buf.items.len});
        std.debug.print("\n", .{});
    }
    fn _war(self: *Self) CSVRow {
        while (self.p1.items.len > 3 and self.p2.items.len > 3) {
            const a = self.p1.pop();
            const b = self.p2.pop();
            if (@enumToInt(a) > @enumToInt(b)) {
                self.p1.insert(0, a) catch unreachable;
                self.p1.insert(0, b) catch unreachable;
                self.p1.insertSlice(0, self.war_buf.items) catch unreachable;
                self.war_buf.items.len = 0;
                self.count += 1;
            } else if (@enumToInt(b) > @enumToInt(a)) {
                self.p2.insert(0, b) catch unreachable;
                self.p2.insert(0, a) catch unreachable;
                self.p2.insertSlice(0, self.war_buf.items) catch unreachable;
                self.war_buf.items.len = 0;
                self.count += 1;
            } else {
                var index: u3 = 0;
                while (index < 3) : (index += 1) {
                    self.war_buf.append(self.p1.pop()) catch unreachable;
                    self.war_buf.append(self.p2.pop()) catch unreachable;
                }
                self.war_buf.append(a) catch unreachable;
                self.war_buf.append(b) catch unreachable;
                self.count += 1;
            }
        }
        return .{
            .who_won = self.p1.items.len > self.p2.items.len,
            .times = self.count,
            .len_of_p1 = self.p1.items.len,
            .len_of_p2 = self.p2.items.len,
        };
    }
    fn war(self: *Self, comptime how_many_tries: u32) [how_many_tries]CSVRow {
        var index: u32 = 0;
        var results: [how_many_tries]CSVRow = undefined;
        while (index < how_many_tries) : (index += 1) {
            results[index] = self._war();
            self.reset();
        }
        return results;
    }
};
