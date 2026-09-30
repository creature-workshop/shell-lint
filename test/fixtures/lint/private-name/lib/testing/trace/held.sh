: <<'DOC'
A private name __nope__ written in a heredoc is prose.
DOC
__testing__trace__read() {
  __testing__trace__read__path="$1"
  for __testing__trace__read__line in "$@"; do
    read -r __testing__trace__read__word
    mapfile -t __testing__trace__read__lines < "$__testing__trace__read__path"
  done
}
__nope__kept=1 # private-name-check: allow -- the one spelling the rule does not fit
__testing__trace__SEEN=0
testing__trace__mark() {
  __testing__trace__SEEN=1
}
testing__trace__count() {
  __testing__trace__count__n=0
  __testing__trace__count__n=$((__testing__trace__count__n + 1))
  printf '%s\n' ".ops/__unp@cked__" "window.__frame_ticks"
}
testing__trace__dispatch() {
  "__testing__trace__${__testing__trace__BACKEND}__read" "$@"
}
__testing__trace__DELIMITER='__TRACE_END__'
testing__trace__emit() {
  cat <<'__TRACE_END__'
body
__TRACE_END__
}
