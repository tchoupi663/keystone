from flask import Flask, render_template, jsonify
import os
import psycopg
import threading
import time
import datetime
import boto3

app = Flask(__name__)

def get_db_connection():
    # To be configured via environment variables injected by Terraform/ECS
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
        print(f"DB init attempt {attempt}/{max_retries}...")
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute(sql_script)
            conn.commit()
            cur.close()
            conn.close()
            print("Database initialised successfully!")
            return
        except Exception as e:
            print(f"DB not ready yet: {e}")
            if attempt < max_retries:
                time.sleep(retry_delay)

    print("WARNING: Could not initialise the database after all retries.")


# ──────────────────────────────────────────────
# Background: AWS Cost Explorer sync
# ──────────────────────────────────────────────

def sync_aws_costs():
    """Background thread to fetch AWS costs using boto3 and store them in the DB."""
    while True:
        print("Attempting to sync AWS costs...")
        try:
            # Cost Explorer endpoint is global but requires us-east-1 region
            client = boto3.client('ce', region_name='us-east-1')
            today = datetime.date.today()
            start = today.replace(day=1)
            end = today
            if start == end:
                # If first day of the month, pull last month's data
                start = (today - datetime.timedelta(days=1)).replace(day=1)

            start_str = start.strftime('%Y-%m-%d')
            end_str = end.strftime('%Y-%m-%d')

            response = client.get_cost_and_usage(
                TimePeriod={'Start': start_str, 'End': end_str},
                Granularity='MONTHLY',
                Metrics=['UnblendedCost'],
                GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
            )

            results = response['ResultsByTime'][0]['Groups']
            days_elapsed = max((end - start).days, 1)
            hours_elapsed = days_elapsed * 24

            conn = get_db_connection()
            cur = conn.cursor()

            for group in results:
                service_name = group['Keys'][0]
                total_cost = float(group['Metrics']['UnblendedCost']['Amount'])
                # Only store services that actually cost something notable
                if total_cost > 0.00001:
                    cost_per_hour = total_cost / hours_elapsed
                    cur.execute('''
                        INSERT INTO aws_costs (service_name, cost_per_hour, total_cost)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (service_name) DO UPDATE SET
                            cost_per_hour = EXCLUDED.cost_per_hour,
                            total_cost = EXCLUDED.total_cost;
                    ''', (service_name, cost_per_hour, total_cost))

            # Record the sync timestamp
            cur.execute('''
                INSERT INTO app_metadata (id, last_synced_at) VALUES (1, NOW())
                ON CONFLICT (id) DO UPDATE SET last_synced_at = NOW();
            ''')

            conn.commit()
            cur.close()
            conn.close()
            print("AWS costs synced successfully.")
        except Exception as e:
            print(f"Failed to sync AWS costs (safe to ignore in local dev): {e}")

        # Sleep for 1h before syncing again
        time.sleep(3600)


if __name__ == '__main__':
    init_db()

    # Start the background CE fetcher as a daemon thread
    fetcher_thread = threading.Thread(target=sync_aws_costs, daemon=True)
    fetcher_thread.start()

    # Listen on all interfaces so it works inside a Docker container
    app.run(host='0.0.0.0', port=80)
