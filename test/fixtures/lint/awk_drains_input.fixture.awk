# A sample for test/lint.awk-early-exit.bats: the shape the check asks for.

decided { next }
/^[ \t]*$/ { next }
{ quoted = ($0 ~ /^>/); decided = 1 }

END { exit !quoted }
