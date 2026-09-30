# Prints a finding when a decision record spends more words of prose than the
# variable `page_words` allows, counted from its Context heading to its end.
# Fenced examples and figure lines are free, since neither is prose. Reads one
# record, named on the command line. Exits 1 when there is a finding. Loaded
# after lib/markdown/lines.awk, which reads the fences.
#
#     a record of 512 words, page_words=450
#       ->  <file>:1: 512 words of prose; a page is 450

function main(line) {
  if (is_code_fence(line) || in_fence) {
    return
  }
  if (line ~ /^## Context/) {
    counting = 1
    return
  }
  if (is_prose(line)) {
    words += NF
  }
}

function verdict() {
  if (words > page_words) {
    printf "%s:1: %s words of prose; a page is %s\n", FILENAME, words, page_words
    return 1
  }
  return 0
}

function is_prose(line) {
  return counting && line !~ /^!\[/
}

    { main($0) }
END { exit verdict() }
