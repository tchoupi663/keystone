# Keystone Demo Application

The **Keystone Demo Application** is a containerized Python (Flask) web application designed to demonstrate a modern, production-ready stack on AWS ECS Fargate. It serves as the core application layer for the Keystone project.

This application is built with a focus on **observability** (metrics, traces, and logs) and **secure architecture**, integrating seamlessly with Grafana Cloud and Cloudflare Zero Trust.

## Key Features

- **Flask-based Web Server**: Simple, lightweight routing for the project demo.
- **Integrated Observability**:
    - **Prometheus**: Native metrics export via `prometheus-flask-exporter`.
    - **OpenTelemetry (OTLP)**: Distributed tracing and log forwarding for Grafana Cloud (Tempo/Loki).
- **PostgreSQL Ready**: Uses `psycopg` for robust, asynchronous database connectivity.
- **Health Monitoring**: Dedicated `/health` endpoint for ALB and ECS health checks.
- **Dockerized**: Multi-stage build for optimized production images.

---

## Tech Stack

- **Language**: Python 3.11
- **Framework**: Flask 3.1
- **Database Adapter**: Psycopg 3 (PostgreSQL)
- **Observability**: OpenTelemetry SDK, Prometheus
- **Containerization**: Docker & Docker Compose
- **Deployment Target**: AWS ECS Fargate

---

## Prerequisites

- **Docker & Docker Compose** (Recommended for local development)
- **Python 3.11+** (If running natively)
- **PostgreSQL** (If running natively)

---

## Getting Started

### 1. Run with Docker Compose (Recommended)

The easiest way to get the app and its database running is using the provided `docker-compose.yml` in the `apps` directory:

```bash
cd apps
docker-compose up --build
```

- **Application**: [http://localhost:80](http://localhost:80)
- **Database**: `localhost:5432` (User: `dbadmin`, Pass: `localdev`, DB: `appdb`)

### 2. Manual Setup (Alternative)

If you prefer to run the application natively:

#### A. Create a Virtual Environment
```bash
cd apps/src
python3 -m venv .venv
source .venv/bin/activate
```

#### B. Install Dependencies
```bash
pip install -r requirements.in
```

#### C. Configure Environment Variables
You will need a running PostgreSQL instance if you wish to use a PostgreSQL DB with the application. Set the following variables:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=appdb
export DB_USER=dbadmin
export DB_PASSWORD=localdev
```

#### D. Start the Application
```bash
python app.py
```
The app will be accessible at [http://localhost:8080](http://localhost:8080).

---

## Architecture

### Directory Structure

```text
apps/
├── docker-compose.yml   # Orchestrates local app + DB
└── src/
    ├── app.py           # Main Flask application logic
    ├── Dockerfile       # Production-ready Docker configuration
    ├── requirements.in  # Direct dependencies
    ├── templates/       # HTML layouts & Interactive Architecture Map
    └── .venv/           # Local virtual environment
```

### Request Lifecycle
1. **Ingress**: Traffic hits the ECS Service (or local port 8080).
2. **Instrumentation**: OpenTelemetry middleware intercepts the request to start a trace.
3. **Routing**: `app.py` processes the route (`/`, `/architecture`).
4. **Database**: If a database call is needed, `Psycopg` executes the query (instrumented by OTel).
5. **Observability**: Metrics are updated in the Prometheus registry, and traces/logs are queued for the OTLP exporter.
6. **Response**: Flask renders the template and returns the HTML.

---

## Environment Variables

| Variable | Description | Default (Local) |
| :--- | :--- | :--- |
| `DB_HOST` | PostgreSQL Hostname | `localhost` / `db` |
| `DB_PORT` | PostgreSQL Port | `5432` |
| `DB_NAME` | Database Name | `appdb` |
| `DB_USER` | Database Username | `dbadmin` |
| `DB_PASSWORD` | Database Password | `localdev` |

---

## Observability Details

### Metrics
The application exposes Prometheus-compatible metrics on the default route. These are scraped by the Grafana Alloy sidecar in production.

### Tracing & Logs
OpenTelemetry is configured to send traces and logs via **OTLP HTTP** to `http://localhost:4318`. In the Keystone architecture, this endpoint is provided by a **Grafana Alloy** sidecar which forwards the data to Grafana Cloud.

---

## Troubleshooting

### Database Connection Failure
**Error**: `psycopg.OperationalError: connection to server at "db" (172.x.x.x), port 5432 failed`

**Solution**: Ensure the `db` service is healthy in Docker. The app service is configured with `depends_on: { db: { condition: service_healthy } }`, but if the DB is starting for the first time, it may take a few seconds.

### Missing Templates
**Error**: `jinja2.exceptions.TemplateNotFound: index.html`

**Solution**: Ensure you are running the application from the `apps/src` directory, or that the `template_folder` path in `app.py` is correctly resolving to the absolute path of the templates directory.
