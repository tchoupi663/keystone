-- Create the aws_costs table
CREATE TABLE IF NOT EXISTS aws_costs (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(255) UNIQUE NOT NULL,
    cost_per_hour DECIMAL(10, 4) NOT NULL,
    total_cost DECIMAL(10, 2) NOT NULL
);

-- Insert some mock AWS services and cost data
INSERT INTO aws_costs (service_name, cost_per_hour, total_cost) VALUES
('Amazon EC2 (t3.micro)', 0.0104, 7.50),
('Amazon RDS (db.t3.micro)', 0.0170, 12.24),
('Amazon S3 (Standard Storage)', 0.0003, 0.25),
('Elastic Load Balancing (ALB)', 0.0225, 16.20),
('Amazon CloudFront', 0.0000, 1.50),
('Amazon Route 53', 0.0000, 0.50),
('AWS CloudTrail', 0.0000, 0.00),
('Amazon ECS Fargate', 0.0400, 28.80),
('Amazon EKS', 0.1000, 72.00)
ON CONFLICT (service_name) DO UPDATE SET 
    cost_per_hour = EXCLUDED.cost_per_hour, 
    total_cost = EXCLUDED.total_cost;
