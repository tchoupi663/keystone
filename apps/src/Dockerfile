FROM python:3.11-slim

WORKDIR /app

# Install system dependencies required for psycopg and OTel build extensions
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Flask typically runs on 8080 in this setup
EXPOSE 8080

# The command to start the app
RUN adduser --disabled-password --no-create-home appuser
USER appuser

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "2", "app:app"]
