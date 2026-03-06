-- Create the aws_costs table
CREATE TABLE IF NOT EXISTS aws_costs (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(255) UNIQUE NOT NULL,
    cost_per_hour DECIMAL(10, 4) NOT NULL,
    total_cost DECIMAL(10, 2) NOT NULL
);

-- Single-row metadata table for tracking the last successful CE sync
CREATE TABLE IF NOT EXISTS app_metadata (
    id INT PRIMARY KEY DEFAULT 1,
    last_synced_at TIMESTAMPTZ,
    CONSTRAINT single_row CHECK (id = 1)
);

-- Ensure the row exists (upsert no-op on conflict)
INSERT INTO app_metadata (id, last_synced_at) VALUES (1, NULL)
ON CONFLICT (id) DO NOTHING;

-- Manual one-time costs not captured by Cost Explorer
INSERT INTO aws_costs (service_name, cost_per_hour, total_cost) VALUES
('Domain Registration (edenkeystone.com)', 0.0000, 15.00)
ON CONFLICT (service_name) DO UPDATE SET
    cost_per_hour = EXCLUDED.cost_per_hour,
    total_cost = EXCLUDED.total_cost;
