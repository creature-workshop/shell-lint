# A sample for test/lint.awk-early-exit.bats, which asserts on these line
# numbers. Every exit the check should find, and every one it should not.

function fail_loudly(message) {
  print message > "/dev/stderr"
  exit 3
}

function give_up() {
  exit
}

BEGIN {
  if (heading == "") {
    exit
  }
}

/^done/ { found = 1; exit }
/^zero/ { exit 0 }
/^expr/ { exit !found }
/^word/ { exits = "exit"; next }
$0 ~ /exit/ { next }
/^note/ { next } # exit
/^fail/ { exit 2 }

# early-exit-check: allow -- reads a named file, never a pipe.
/^file/ { exit }

END { exit !found }
