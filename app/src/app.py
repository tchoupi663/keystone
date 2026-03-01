from flask import Flask, render_template
import os
import psycopg

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

if __name__ == '__main__':
    init_db()
    # Listen on all interfaces so it works inside a Docker container
    app.run(host='0.0.0.0', port=5555)
