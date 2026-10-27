# 05: api fails under --read-only

## Symptom
With `--read-only` the api container exits immediately.

## Commands and output
```
$ docker logs api
PermissionError: [Errno 13] Permission denied: 'logs'
```

## Root cause
By default the app writes to `logs/api.log` relative to its working directory. The root filesystem is read-only, so creating the folder fails.

## Fix
Set `LOG_FILE=-` and `LOG_FORMAT=json` in the Dockerfile so logs go to stdout as JSON. Add `--tmpfs /tmp` for Gunicorn's worker temp files.

## Check that catches it
`docker inspect -f '{{.HostConfig.ReadonlyRootfs}}' api` is `true` and the api is healthy.
