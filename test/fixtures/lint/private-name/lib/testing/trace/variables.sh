testing__trace__latest() {
  __testing__trace__latest__dir="$1"
  __trace_latest__map="$(__testing__trace__read "$__testing__trace__latest__dir")"
  printf '%s\n' "$__trace_latest__map"
}
testing_trace_read_map() {
  __testing__trace__read_map__path="$1"
  __testing__trace__read_map__map="$(testing__trace__read "$__testing__trace__read_map__path")"
  printf '%s\n' "$__testing__trace__read_map__map" "$__testing__trace__CACHE" "$__other_fn__x"
}
__testing__trace__api__helper() {
  @let "$1" __helper__ major minor
  @defined "$__helper__minor" || __helper__minor=0
  printf '%s\n' "$__helper__major"
  @unlet __helper__ major minor
}
