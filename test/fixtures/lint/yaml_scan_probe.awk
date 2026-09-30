# Probe for yaml_scan.awk's block model: prints what the model reads each
# record as, and for a key its name, depth and parent, so a test can assert
# on the model's reading of a document where no scanner on it can see it.
# Load after scan.awk and yaml_scan.awk:
# `awk -f scan.awk -f yaml_scan.awk -f yaml_scan_probe.awk <file>`.
#
#   3: key if depth=3 parent=
#   4: content

# The line a key is reported as: where it is, its name, and where it sits.
function key_report() {
  return FNR ": key " yaml_key " depth=" yaml_key_depth " parent=" yaml_key_parent
}

# The line any other classified record is reported as.
function kind_report(kind) {
  return FNR ": " kind
}

# Reports the record the model just read; a blank or comment line, which the
# model classifies as nothing, is not reported.
function report(kind) {
  if (kind == "key") {
    print key_report()
  } else if (kind != "") {
    print kind_report(kind)
  }
}

FNR == 1 {
  yaml_reset()
}

{
  report(yaml_advance($0))
}
