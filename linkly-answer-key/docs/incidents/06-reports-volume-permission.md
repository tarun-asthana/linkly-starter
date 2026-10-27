# 06: worker gets Permission denied on the reports volume

## Symptom
The worker, running as UID 10001, fails when writing its first report.

## Commands and output
```
$ docker logs worker
PermissionError: [Errno 13] Permission denied: '/data/reports/clicks-2026-10-20.csv'
$ docker exec worker ls -ld /data/reports
drwxr-xr-x 2 root root 4096 /data/reports
```

## Root cause
A new named volume is owned by root. The worker runs as a non-root UID, so it cannot write.

## Fix
In `worker/Dockerfile`, create `/data/reports` and `chown` it to 10001 before the `USER` line. When an empty named volume is first mounted there, Docker copies that ownership into the volume.

```
$ docker exec worker ls -ld /data/reports
drwxr-xr-x 2 app app 4096 /data/reports
```

## Check that catches it
The worker `HEALTHCHECK`, and the grader's click count after following a link.
