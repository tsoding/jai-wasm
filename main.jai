foo :: #foreign_library "libfoo";

bar :: (a: int, b: int) -> int #foreign foo;

sum :: (a: int, b: int) -> int #no_context {
    return bar(a, b);
}

main :: () {
}
