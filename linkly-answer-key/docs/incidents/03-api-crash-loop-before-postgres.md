# 03: api crash-loops when started together with Postgres

## Symptom
Right after a fresh start the api restarts several times before it stays up.

## Commands and output
```
$ docker logs api
psycopg.OperationalError: connection failed: Connection refused
```

## Root cause
The api creates its tables at import time. On a new volume Postgres needs several seconds to initialize, so the api's first connection is refused.

## Fix
`up.sh` starts db and cache first and waits for `pg_isready` and `redis-cli ping` health checks to report `healthy` before starting the api.

## Check that catches it
`up.sh` fails with the container's last logs if a dependency is not healthy within 2 minutes.
