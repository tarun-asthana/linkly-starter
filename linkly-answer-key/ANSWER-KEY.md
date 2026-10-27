# Linkly answer key (instructor only)

Reference solution: the starter code plus these files.
- api/Dockerfile, worker/Dockerfile, api/.dockerignore, worker/.dockerignore
- scripts/up.sh, down.sh, backup.sh, netcheck.sh
- docs/incidents/01..06 (reference write-ups) and README.md

docs/architecture.png is referenced in README.md but not included; add the diagram from the brief.

Run: bash scripts/up.sh, then bash scripts/netcheck.sh.

Planted issues in the starter and their fixes:
1. No --network: the default bridge has no DNS -> user-defined networks.
2. The README runs `gunicorn app:app`, which binds 127.0.0.1:8000 -> CMD with --bind 0.0.0.0:5000.
3. The api creates tables at start and crash-loops before Postgres is ready -> up.sh waits for health.
4. The api writes logs/api.log, which fails under --read-only -> LOG_FILE=- and LOG_FORMAT=json.
5. A new reports volume is owned by root -> mkdir and chown /data/reports before USER in worker/Dockerfile.
