from flask import Flask, render_template
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

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/architecture')
def architecture():
    return render_template('architecture.html')

@app.route('/cost')
def cost():
    costs = []
    error = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        # Example query - adjust based on your actual RDS schema
        cur.execute('SELECT service_name, cost_per_hour, total_cost FROM aws_costs ORDER BY total_cost DESC;')
        costs = cur.fetchall()
        cur.close()
        conn.close()
    except Exception as e:
        error = str(e)
    
    return render_template('cost.html', costs=costs, error=error)
def init_db():
    """Run the initialization script against the database."""
    print("Attempting to initialize the database...")
    try:
        conn = get_db_connection()
        sql_path = os.path.join(os.path.dirname(__file__), 'init.pgsql')
        with open(sql_path, 'r') as f:
            sql_script = f.read()
            
        cur = conn.cursor()
        cur.execute(sql_script)
        conn.commit()
        cur.close()
        conn.close()
        print("Database initialized successfully!")
    except Exception as e:
        print(f"Failed to initialize database (it might not be ready yet): {e}")

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
                # Only insert services that actually cost something notable (e.g > $0.001)
                if total_cost > 0.001:
                    cost_per_hour = total_cost / hours_elapsed
                    cur.execute('''
                        INSERT INTO aws_costs (service_name, cost_per_hour, total_cost)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (service_name) DO UPDATE SET 
                            cost_per_hour = EXCLUDED.cost_per_hour, 
                            total_cost = EXCLUDED.total_cost;
                    ''', (service_name, cost_per_hour, total_cost))
                    
            conn.commit()
            cur.close()
            conn.close()
            print("AWS costs synced successfully.")
        except Exception as e:
            print(f"Failed to sync AWS costs (safe to ignore in local dev): {e}")

        # Sleep for 12 hours before syncing again
        time.sleep(12 * 3600)

if __name__ == '__main__':
    init_db()
    
    # Start the background fetcher thread as a daemon so it exits when the app stops
    fetcher_thread = threading.Thread(target=sync_aws_costs, daemon=True)
    fetcher_thread.start()
    
    # Listen on all interfaces so it works inside a Docker container
    app.run(host='0.0.0.0', port=5555)
