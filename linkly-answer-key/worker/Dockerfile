# Build stage: install dependencies into a virtual environment.
FROM python:3.12-slim-bookworm AS build
WORKDIR /app
COPY requirements.txt .
RUN python -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Runtime stage: only the venv and the app code, running as a non-root user.
FROM python:3.12-slim-bookworm
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin app \
 && mkdir -p /data/reports \
 && chown 10001:10001 /data/reports
WORKDIR /app
COPY --from=build /opt/venv /opt/venv
COPY worker.py healthcheck.py ./
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    REPORT_DIR=/data/reports \
    HEARTBEAT_FILE=/tmp/worker-heartbeat
USER 10001
HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=3 \
  CMD ["python", "healthcheck.py"]
CMD ["python", "worker.py"]
