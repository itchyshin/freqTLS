# freqTLS Mission-Control Dashboard

This directory stores the durable source for the local phase-plan dashboard. The
live copy is served from `/tmp/profiletls-dashboard` so agents can update JSON
status while the repository remains the source of truth.

Start or refresh the board with:

```sh
sh tools/start-mission-control.sh --background
```

Then open:

```text
http://127.0.0.1:8767/
```

The page reads `status.json` and `sweep.json` every eight seconds. Update those
JSON files as slices move from `queued` to `active`, `blocked`, `verified`,
`banked`, or `deferred`.

Keep `version.txt` equal to the `BUILD` constant in `index.html`. Change both
only when the HTML or JavaScript changes. JSON data updates do not need a version
bump.

The port is 8767 (drmTMB uses 8765, hsquared 8766), so the three boards can run
side by side.
