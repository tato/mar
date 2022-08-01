kind: Kind,
start: u32,

pub const Kind = enum(u32) {
    integer,
    plus,
    minus,
    asterisk,
    slash,
    left_paren,
    right_paren,
    err,
    eof,
};