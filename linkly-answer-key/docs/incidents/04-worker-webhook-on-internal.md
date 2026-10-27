# 04: worker exits when it posts its first report

## Symptom
The worker writes its first CSV report, then exits.

## Commands and output
```
$ docker logs worker
report written: /data/reports/clicks-2026-10-20.csv (1 codes)
requests.exceptions.ConnectionError: HTTPSConnectionPool(host='httpbin.org', port=443): Max retries exceeded
```

## Root cause
The worker is only on `internal`, which is created with `--internal` and has no route to the internet. Its default `WEBHOOK_URL` points at an external service.

## Fix
Set `WEBHOOK_URL=` (empty) to disable the external call. The data tier keeps no internet access. If the notification were required, the api, which sits on `dmz`, would be the right place to send it.

## Check that catches it
`netcheck.sh` row `worker -> 1.1.1.1 443 blocked`, and the worker `HEALTHCHECK`.
