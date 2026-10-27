# 02: proxy returns 502 because Gunicorn listens on 127.0.0.1

## Symptom
`curl -k https://localhost/health` returns `502 Bad Gateway`.

## Commands and output
```
$ docker logs api | grep Listening
[INFO] Listening at: http://127.0.0.1:8000
```

## Root cause
The README's laptop command `gunicorn app:app` binds to Gunicorn's default, 127.0.0.1:8000. Inside a container, loopback is private to that container, so the proxy cannot connect, and the port is also not the 5000 that the proxy expects.

## Fix
Exec-form `CMD ["gunicorn", "--bind", "0.0.0.0:5000", ...]` in `api/Dockerfile`.

## Check that catches it
`netcheck.sh` row `proxy -> api 5000 allowed`.
