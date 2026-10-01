testing__trace__latest_read() {
  __testing__trace__latest_read__map="$1"
  testing__trace__latest__read "$__testing__trace__latest_read__map"
}

testing__trace__latest__read() {
  __testing__trace__latest__read__map="$1"
  println "$__testing__trace__latest__read__map"
}

__testing__trace__LATEST_SEEN=0

# testing__trace__latest_read is named in this comment and is not read.
cat <<'DOC'
testing__trace__latest_read is named in this heredoc and is not read.
DOC
testing__trace__latest_count() { :; }  # file-segment-check: allow -- shows the mark
testing__trace__latests=1
