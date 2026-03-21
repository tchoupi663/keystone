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

# Flask typically runs on 80 in this setup
EXPOSE 80

# The command to start the app
CMD ["python", "app.py"]
