# syntax=docker/dockerfile:1

# adopt a multistage build process for efficiency
FROM python:3.12-alpine@sha256:1b668429b3511ab407d8e00648891631b0b1a4d7e15e3ca70f38ab5b91ad4ab4 AS build

# removed apt-get update and apt-get install to improve efficiency as they're unused and not required

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

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

EXPOSE 8080

CMD ["gunicorn", "--chdir", "app", "--bind", "0.0.0.0:8080", "--workers", "2", "--worker-tmp-dir", "/dev/shm", "--access-logfile", "-", "app:app"]
