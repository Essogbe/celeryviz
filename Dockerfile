# Pin the Python base image for all stages and
# install all shared dependencies.
FROM python:3-slim AS base

RUN apt-get update && apt-get install -y supervisor && apt-get install -y --no-install-recommends \
    libfoo libbar ... \
    && rm -rf /var/lib/apt/lists/*

# Tweak Python to run better in Docker
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=on

# Build stage: dev & build dependencies can be installed here
FROM base AS build

# Install the compiler toolchain(s), dev headers, etc.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libfoo-dev libbar-dev ... \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# The virtual environment is used to "package" the application
# and its dependencies in a self-contained way.
RUN python -m venv .venv
ENV PATH="/app/.venv/bin:$PATH"

COPY pyproject.toml setup.py requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -e

COPY app ./app
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install .

# Runtime stage: copy only the virtual environment.
FROM base AS runtime
WORKDIR /app

RUN addgroup --gid 1001 --system nonroot && \
    adduser --no-create-home --shell /bin/false \
      --disabled-password --uid 1001 --system --group nonroot

USER nonroot:nonroot

ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

COPY --from=build --chown=nonroot:nonroot /app ./

RUN celery -A app call app.add --args='[1, 100]' --kwargs='{"z":10000}'

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]

EXPOSE 9095
