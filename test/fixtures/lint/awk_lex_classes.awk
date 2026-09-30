# A driver for test/lint.awk-lex.bats: prints each line of awk source with its
# code kept, every character of a string or regex as L, and every character of
# a comment as C.
#
#   x = "a" # b  ->  x = LLL CCC

function main(line, __i, __n, __c, __out) {
  if (NR == 1) {
    awk_lex_reset()
  }
  __n = length(line)
  for (__i = 1; __i <= __n; __i++) {
    __c = substr(line, __i, 1)
    __out = __out mark(awk_lex_char(__c), __c)
  }
  awk_lex_char("\n")
  print __out
}

function mark(class, c) {
  if (class == "literal") {
    return "L"
  }
  if (class == "comment") {
    return "C"
  }
  return c
}

{ main($0) }
