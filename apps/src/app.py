from flask import Flask, render_template, jsonify
from prometheus_flask_exporter import PrometheusMetrics
import os
import psycopg
import threading
import time
import datetime
import random
import logging

from pythonjsonlogger import json as jsonlogger

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Import OTel Logging components
from opentelemetry._logs import set_logger_provider
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.exporter.otlp.proto.http._log_exporter import OTLPLogExporter

from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.psycopg import PsycopgInstrumentor

# Initialize Tracing Provider
resource = Resource.create({"service.name": "keystone-app"})
provider = TracerProvider(resource=resource)
# Grafana Alloy OTLP HTTP receiver (traces)
exporter = OTLPSpanExporter(endpoint="http://localhost:4318/v1/traces")
provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(provider)

# Initialize Logging Provider
logger_provider = LoggerProvider(resource=resource)
set_logger_provider(logger_provider)
log_exporter = OTLPLogExporter(endpoint="http://localhost:4318/v1/logs")
logger_provider.add_log_record_processor(BatchLogRecordProcessor(log_exporter))

# Structured JSON logging for better Loki querying
json_handler = logging.StreamHandler()
json_handler.setFormatter(
    jsonlogger.JsonFormatter(
        fmt="%(asctime)s %(levelname)s %(name)s %(message)s",
        rename_fields={"asctime": "timestamp", "levelname": "level", "name": "logger"},
    )
)

# Attached OTel handler to root python logger
otel_handler = LoggingHandler(level=logging.INFO, logger_provider=logger_provider)
root_logger = logging.getLogger()
root_logger.addHandler(otel_handler)
root_logger.addHandler(json_handler)
root_logger.setLevel(logging.INFO)

# Also capture Werkzeug request logs
logging.getLogger('werkzeug').addHandler(otel_handler)
logging.getLogger('werkzeug').addHandler(json_handler)

app = Flask(__name__, template_folder=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'templates'))

# Instrument Flask & DB
FlaskInstrumentor().instrument_app(app)
PsycopgInstrumentor().instrument()

metrics = PrometheusMetrics(app, group_by='endpoint')

# static information as metric
metrics.info('app_info', 'Application info', version='1.0.17')

# ──────────────────────────────────────────────
# Infracost-based monthly cost estimates (USD)
# Source: `infracost breakdown` across all stacks
# ──────────────────────────────────────────────

MONTHLY_COSTS = [
    # terraform-eu-north-1-app-dev ($9.01)
    ("Amazon Elastic Container Service", 9.01),

    # terraform-eu-north-1-data-dev ($13.98)
    ("Amazon Relational Database Service", 13.98),

    # terraform-eu-north-1-infra-dev ($19.49)
    ("Amazon Elastic Load Balancing", 16.43),
    ("Amazon Elastic Compute Cloud", 3.07),      # fck-nat t4g.nano

    # Usage-based estimates (small but non-zero)
    ("Amazon CloudWatch", 0.15),
    ("Amazon EC2 Container Registry (ECR)", 0.05),
    ("Amazon Route 53", 0.02),
    ("AWS Secrets Manager", 0.29),
]


def get_db_connection():
    conn = psycopg.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        port=int(os.environ.get('DB_PORT', '5432')),
        dbname=os.environ.get('DB_NAME', 'postgres'),
        user=os.environ.get('DB_USER', 'postgres'),
        password=os.environ.get('DB_PASSWORD', 'secret')
    )
    return conn

# ──────────────────────────────────────────────
# Routes
# ──────────────────────────────────────────────

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/architecture')
def architecture():
    return render_template('architecture.html')

@app.route('/health')
def health():
    """Health check endpoint used by ALB and monitoring."""
    try:
        conn = get_db_connection()
        conn.close()
        db_ok = True
    except Exception:
        db_ok = False
    return jsonify({"status": "ok", "db": "ok" if db_ok else "unavailable"}), 200

@app.route('/api/cost')
def api_cost():
    """JSON endpoint returning current cost data."""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('''
            SELECT service_name, cost_per_hour, total_cost
            FROM aws_costs
            ORDER BY total_cost DESC;
        ''')
        rows = cur.fetchall()

        cur.execute('SELECT last_synced_at FROM app_metadata WHERE id = 1;')
        meta = cur.fetchone()
        last_synced_at = meta[0].isoformat() if meta and meta[0] else None

        cur.close()
        conn.close()

        return jsonify({
            "last_synced_at": last_synced_at,
            "costs": [
                {
                    "service_name": r[0],
                    "cost_per_hour": float(r[1]),
                    "total_cost": float(r[2]),
                }
                for r in rows
            ]
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/cost')
def cost():
    costs = []
    error = None
    last_synced_at = None
    total_cost_sum = 0.0
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('''
            SELECT service_name, cost_per_hour, total_cost
            FROM aws_costs
            ORDER BY total_cost DESC;
        ''')
        costs = cur.fetchall()

        cur.execute('SELECT last_synced_at FROM app_metadata WHERE id = 1;')
        meta = cur.fetchone()
        if meta and meta[0]:
            last_synced_at = meta[0].strftime('%B %-d, %Y at %H:%M UTC')

        total_cost_sum = sum(float(row[2]) for row in costs)

        cur.close()
        conn.close()
    except Exception as e:
        error = str(e)

    return render_template(
        'cost.html',
        costs=costs,
        error=error,
        last_synced_at=last_synced_at,
        total_cost_sum=total_cost_sum
    )


# ──────────────────────────────────────────────
# Startup: DB initialisation (with retry)
# ──────────────────────────────────────────────

def init_db(max_retries=12, retry_delay=5):
    """Run the initialisation SQL script, retrying if the DB isn't ready yet."""
    sql_path = os.path.join(os.path.dirname(__file__), 'init.pgsql')
    with open(sql_path, 'r') as f:
        sql_script = f.read()

    for attempt in range(1, max_retries + 1):
        logging.info("DB init attempt", extra={"attempt": attempt, "max_retries": max_retries})
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute(sql_script)
            conn.commit()
            cur.close()
            conn.close()
            logging.info("Database initialised successfully")
            return
        except Exception as e:
            logging.info("DB not ready yet", extra={"error": str(e), "attempt": attempt})
            if attempt < max_retries:
                time.sleep(retry_delay)

    logging.warning("Could not initialise the database after all retries", extra={"max_retries": max_retries})


# ──────────────────────────────────────────────
# Background: Prorated cost simulation
# ──────────────────────────────────────────────

def update_costs():
    """Background thread that writes accumulated infracost estimates to the DB every hour.

    Costs accumulate from PROJECT_START and never reset. For each service:
        daily_cost  = monthly_cost / 30.44
        total_cost  = daily_cost × days_since_start × jitter

    A small ±3 % random jitter is applied per service on each run so the
    numbers feel alive without drifting far from the baseline.
    """
    PROJECT_START = datetime.date(2026, 2, 28)
    AVG_DAYS_PER_MONTH = 30.44

    while True:
        logging.info("Updating cost data")
        try:
            now = datetime.datetime.utcnow()
            today = now.date()

            # Total days elapsed since project launch (including partial day)
            days_elapsed = (today - PROJECT_START).days + now.hour / 24.0

            conn = get_db_connection()
            cur = conn.cursor()

            # Clear old rows so only current data is shown
            cur.execute('DELETE FROM aws_costs;')

            for service_name, monthly_cost in MONTHLY_COSTS:
                jitter = 1.0 + random.uniform(-0.03, 0.03)
                daily_cost = monthly_cost / AVG_DAYS_PER_MONTH
                total_cost = round(daily_cost * days_elapsed * jitter, 2)
                cost_per_hour = round(monthly_cost / (AVG_DAYS_PER_MONTH * 24), 4)

                if total_cost > 0.001:
                    cur.execute('''
                        INSERT INTO aws_costs (service_name, cost_per_hour, total_cost)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (service_name) DO UPDATE SET
                            cost_per_hour = EXCLUDED.cost_per_hour,
                            total_cost    = EXCLUDED.total_cost;
                    ''', (service_name, cost_per_hour, total_cost))

            cur.execute('''
                INSERT INTO app_metadata (id, last_synced_at) VALUES (1, NOW())
                ON CONFLICT (id) DO UPDATE SET last_synced_at = NOW();
            ''')

            conn.commit()
            cur.close()
            conn.close()
            logging.info("Cost data updated successfully")
        except Exception as e:
            logging.error("Failed to update cost data", extra={"error": str(e)})

        # Refresh every hour
        time.sleep(3600)


if __name__ == '__main__':
    init_db()

    cost_thread = threading.Thread(target=update_costs, daemon=True)
    cost_thread.start()

    app.run(host='0.0.0.0', port=8080)
