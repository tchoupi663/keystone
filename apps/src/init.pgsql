-- Create the aws_costs table
CREATE TABLE IF NOT EXISTS aws_costs (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(255) UNIQUE NOT NULL,
    cost_per_hour DECIMAL(10, 4) NOT NULL,
    total_cost DECIMAL(10, 2) NOT NULL
);

-- Single-row metadata table for tracking the last cost update
CREATE TABLE IF NOT EXISTS app_metadata (
    id INT PRIMARY KEY DEFAULT 1,
    last_synced_at TIMESTAMPTZ,
    CONSTRAINT single_row CHECK (id = 1)
);

-- Ensure the metadata row exists
INSERT INTO app_metadata (id, last_synced_at) VALUES (1, NULL)
ON CONFLICT (id) DO NOTHING;
