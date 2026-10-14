# syntax=docker/dockerfile:1

# adopt a multistage build process for efficiency
FROM python:3.12-alpine@sha256:1b668429b3511ab407d8e00648891631b0b1a4d7e15e3ca70f38ab5b91ad4ab4 AS build

# removed apt-get update and apt-get install to improve efficiency as they're unused and not required

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /build

COPY app/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-alpine@sha256:1b668429b3511ab407d8e00648891631b0b1a4d7e15e3ca70f38ab5b91ad4ab4 AS runtime

ENV PATH="/opt/venv/bin:$PATH"

# adding a none root user. Setting this to a uuid so kuberenetes can use it
RUN addgroup -g 10001 app && adduser -D -u 10001 -G app app

WORKDIR /app

COPY --from=build /opt/venv /opt/venv

COPY app/ ./app/

USER 10001:10001

ENV PORT=8080
EXPOSE ${PORT}

LABEL org.opencontainers.image.title="sample-app" \
      org.opencontainers.image.description="Coding test submission for DWP" \
      org.opencontainers.image.source="https://github.com/JackHalladay/greeting-container" \
      org.opencontainers.image.version="1.0.5"

# adding a healthcheck for testing purposes. can be removed or ignored when deploying to kuberenetes since it has its own methods for healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:{os.environ.get(\"PORT\", \"8080\")}/healthz', timeout=2)"]

CMD ["sh", "-c", "gunicorn --chdir app --bind 0.0.0.0:${PORT} --workers 2 --worker-tmp-dir /dev/shm --access-logfile - app:app"]