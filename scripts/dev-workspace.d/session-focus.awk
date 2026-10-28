BEGIN {
  directory = ENVIRON["DEV_WORKSPACE_FOCUS_DIR"]
  getline target < (directory "/target")
  getline best < (directory "/position")
  getline query < (directory "/position.query")
  getline reset < (directory "/reset")
}

!reset && $3 == target { position = NR }

END {
  # Query changes can produce a result event before the reload finishes.
  # Only consume the reset when results for that query have arrived.
  if (query != ENVIRON["DEV_WORKSPACE_QUERY"]) exit
  printf "pos(%d)", position ? position : best
  printf "" > (directory "/reset")
}
