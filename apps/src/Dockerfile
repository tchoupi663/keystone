FROM python:3.11-slim@sha256:9358444059ed78e2975ada2c189f1c1a3144a5dab6f35bff8c981afb38946634 AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir pip-tools
COPY requirements.in .
RUN pip-compile requirements.in -o requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --no-create-home appuser

COPY --from=builder /usr/local /usr/local

COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "2", "app:app"]
