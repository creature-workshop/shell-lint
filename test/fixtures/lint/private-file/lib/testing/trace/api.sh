: <<'MODULE'
"$SHELLOPS_DIR/lib/testing/trace/location.sh" is prose in here, not an import.
MODULE

import \
  "$SHELLOPS_DIR/lib/testing/trace/_tracer.sh" \
  "$SHELLOPS_DIR/lib/testing/trace/location.sh" \
  "$SHELLOPS_DIR/lib/testing/trace/kept.sh"
