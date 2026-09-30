__testing__trace__inner__walk() {
  __testing__trace__read "$1"
  __testing__read "$1"
  __testing__selectors__areas__attach "$1"
}
__testing__trace__inner__peek() {
  printf '%s\n' "$__testing__trace__DIR" "$__testing__trace__read__path"
}
