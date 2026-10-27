# 01: api cannot resolve db on the default bridge

## Symptom
The api container exits at start with a name resolution error for `db`.

## Commands and output
```
$ docker run -d --name db -e POSTGRES_PASSWORD=x postgres:16-alpine
$ docker run --rm busybox:1.36 nslookup db
** server can't find db: NXDOMAIN
```

## Root cause
Containers started without `--network` join the default bridge (`docker0`). Docker's embedded DNS (127.0.0.11) only serves user-defined networks, so container names do not resolve there.

## Fix
Create user-defined networks (`dmz`, `internal`, `admin`) and start every container with `--network`. `up.sh` does this.

## Check that catches it
`netcheck.sh` row `api -> db 5432 allowed`.
