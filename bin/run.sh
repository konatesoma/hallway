#!/bin/sh
# Run hallway.py with whichever Python works: `python3` on macOS/Linux, `python` on
# Windows (where `python3` is often a Microsoft Store stub that does nothing).
here=$(dirname "$0")
for py in python3 python; do
  if "$py" -c "" >/dev/null 2>&1; then exec "$py" "$here/hallway.py" "$@"; fi
done
exit 0
