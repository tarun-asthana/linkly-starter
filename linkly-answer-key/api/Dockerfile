# Build stage: install dependencies into a virtual environment.
FROM python:3.12-slim-bookworm AS build
WORKDIR /app
COPY requirements.txt .
RUN python -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# Runtime stage: only the venv and the app code, running as a non-root user.
FROM python:3.12-slim-bookworm
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY --from=build /opt/venv /opt/venv
COPY app.py healthcheck.py ./
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    LOG_FILE=- \
    LOG_FORMAT=json
USER 10001
EXPOSE 5000
HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=3 \
  CMD ["python", "healthcheck.py"]
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--graceful-timeout", "20", "app:app"]
