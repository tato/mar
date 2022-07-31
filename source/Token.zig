kind: Kind,
start: u32,

pub const Kind = enum(u32) {
    number,
    plus,
    minus,
    asterisk,
    slash,
    left_paren,
    right_paren,
};