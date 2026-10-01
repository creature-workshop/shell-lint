# Prints one finding per part of the one-page shape a decision record is
# missing or has out of order: the "# ADR.<n>: " title carrying the record's
# own number without leading zeros, the Status, Date and Merge request header
# lines, and the Context, Decision and Consequences sections in that order.
# Reads one record, named on the command line. Exits 1 when there is a finding.
# Loaded after lib/markdown/records.awk.
#
#     adrs/000007-fragments/adr.md opening "# ADR.8: ..."
#       ->  adrs/000007-fragments/adr.md:1: the title is "# ADR.7: <the decision>", the record's number

function main(line) {
  if (FNR == 1) {
    report_title(line)
  }
  note_header(line)
  note_section(line)
}

function verdict() {
  report_missing_header("Status")
  report_missing_header("Date")
  report_missing_header("Merge request")
  report_sections()
  return found
}

function note_header(line, __name) {
  if (match(line, /^- (Status|Date|Merge request): /)) {
    __name = substr(line, 3, RLENGTH - 4)
    seen[__name] = 1
  }
}

function note_section(line) {
  if (line ~ /^## /) {
    sections = sections substr(line, 4) ","
  }
}

function report(line_number, why) {
  printf "%s:%s: %s\n", FILENAME, line_number, why
  found = 1
}

function report_title(line, __number) {
  __number = plain_number(number_of(record_name(FILENAME)))
  if (index(line, "# ADR." __number ": ") != 1) {
    report(1, "the title is \"# ADR." __number ": <the decision>\", the record's number")
  }
}

function report_missing_header(name) {
  if (!(name in seen)) {
    report(1, "the header has no \"- " name ":\" line")
  }
}

function report_sections() {
  if (sections != "Context,Decision,Consequences,") {
    report(1, "the sections are Context, Decision, Consequences, in that order")
  }
}

    { main($0) }
END { exit verdict() }
