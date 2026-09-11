# ---- builder ----------------------------------------------------------
FROM python:3.14-slim AS builder

# Static uv binary, not installed via pip -- kept out of the runtime stage.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /app

# Install dependencies in their own layer first, so changes to src/ don't
# invalidate this (much slower) layer on rebuilds.
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

COPY src/ ./src/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# ---- runtime ------------------------------------------------------------
FROM python:3.14-slim

WORKDIR /app
COPY --from=builder /app /app

ENV PATH="/app/.venv/bin:$PATH"
ENV PORT=8080
EXPOSE 8080

# gunicorn serves the Flask app defined as `app` in src/main.py. --chdir
# moves into src/ first so Flask's default template/static resolution
# (relative to main.py's own location) keeps working unmodified.
CMD ["gunicorn", "--chdir", "src", "--bind", "0.0.0.0:8080", "--workers", "2", "main:app"]
