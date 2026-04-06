from flask import Flask, render_template, jsonify
from prometheus_flask_exporter import PrometheusMetrics
import os
import logging
import signal
import sys

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

# Attached OTel handler to root python logger
otel_handler = LoggingHandler(level=logging.INFO, logger_provider=logger_provider)
logging.getLogger().addHandler(otel_handler)
logging.getLogger().setLevel(logging.INFO)

# Also capture Werkzeug request logs
logging.getLogger('werkzeug').addHandler(otel_handler)

# Capture Gunicorn logs (essential for Fargate/Gunicorn production environments)
logging.getLogger("gunicorn.error").addHandler(otel_handler)
logging.getLogger("gunicorn.access").addHandler(otel_handler)

app = Flask(__name__, template_folder=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'templates'))

# Instrument Flask
FlaskInstrumentor().instrument_app(app)

metrics = PrometheusMetrics(app, group_by='endpoint')

# static information as metric
metrics.info('app_info', 'Application info', version='1.0.17')




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
    logging.info("Health check heartbeat")
    return jsonify({"status": "ok"}), 200



# ──────────────────────────────────────────────
# Runtime Initialization
# ──────────────────────────────────────────────
if __name__ == '__main__':
    logging.info("Starting Keystone application in development mode...")
    app.run(host='0.0.0.0', port=8080)
else:
    logging.info("Starting Keystone application under Gunicorn...")
