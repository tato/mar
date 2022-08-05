kind: Kind,
start: u32,

pub const Kind = enum(u32) {
    newline,
    identifier,
    print,
    integer,
    @"true",
    @"false",
    plus,
    minus,
    asterisk,
    slash,
    left_paren,
    right_paren,
    err,
    eof,
};