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

-- Seed dummy data emulating ~3 weeks of running the project
-- Based on infracost estimates: ECS ~$9/mo, RDS ~$14/mo, ALB ~$16/mo, fck-nat ~$4/mo, misc ~$0.50/mo
-- Prorated to 21 days: multiply monthly cost by (21/30)

INSERT INTO aws_costs (service_name, cost_per_hour, total_cost) VALUES
('Amazon Elastic Container Service', 0.0124, 6.31),
('Amazon Relational Database Service', 0.0192, 9.79),
('Amazon Elastic Load Balancing', 0.0240, 12.22),
('Amazon Elastic Compute Cloud', 0.0053, 2.71),
('Amazon EC2 Container Registry (ECR)', 0.0001, 0.08),
('Amazon Route 53', 0.0001, 0.04),
('Amazon Simple Storage Service', 0.0000, 0.02),
('AWS Secrets Manager', 0.0006, 0.28),
('Amazon CloudWatch', 0.0003, 0.14),
('Domain Registration (edenkeystone.com)', 0.0000, 15.00)
ON CONFLICT (service_name) DO UPDATE SET
    cost_per_hour = EXCLUDED.cost_per_hour,
    total_cost = EXCLUDED.total_cost;

-- Mark as synced ~now (the background thread will overwrite this with real data)
INSERT INTO app_metadata (id, last_synced_at) VALUES (1, NOW())
ON CONFLICT (id) DO UPDATE SET last_synced_at = NOW();
