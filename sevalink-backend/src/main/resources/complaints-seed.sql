-- Seed example complaints if no records exist yet.
-- Run this manually in PostgreSQL when you want sample admin complaints.

-- Create a sample client user if none exist yet.
INSERT INTO users (
    full_name, email, phone_number, password_hash, role, birthday, is_phone_verified,
    is_email_verified, is_active, created_at, updated_at
)
SELECT 'Sample Client', 'client@example.com', '0770000001', 'dummyhash', 'CLIENT', CURRENT_DATE, true, true, true, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'client@example.com');

-- Create a sample worker user if none exist yet.
INSERT INTO users (
    full_name, email, phone_number, password_hash, role, birthday, is_phone_verified,
    is_email_verified, is_active, created_at, updated_at
)
SELECT 'Sample Worker', 'worker@example.com', '0770000002', 'dummyhash', 'WORKER', CURRENT_DATE, true, true, true, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'worker@example.com');

-- Create a sample job if none exist yet.
INSERT INTO job_posts (
    client_id, title, description, location_name, budget_min, budget_max, urgency, status, created_at
)
SELECT u.id, 'Plumbing repair request', 'Need urgent plumbing repair at home.', 'Colombo', 1500, 2500, 'URGENT', 'OPEN', NOW()
FROM users u
WHERE u.email = 'client@example.com'
  AND NOT EXISTS (SELECT 1 FROM job_posts LIMIT 1);

-- Insert complaint rows using the first available user and job.
INSERT INTO complaints (job_post_id, filed_by_id, description, created_at)
SELECT j.id, u.id, 'The worker requested payment before finishing the service and never responded.', NOW()
FROM job_posts j
JOIN users u ON u.email = 'client@example.com'
WHERE NOT EXISTS (SELECT 1 FROM complaints);

INSERT INTO complaints (job_post_id, filed_by_id, description, created_at)
SELECT j.id, u.id, 'I suspect this is a fake job posting and the client is trying to scam workers.', NOW()
FROM job_posts j
JOIN users u ON u.email = 'worker@example.com'
WHERE (SELECT COUNT(*) FROM complaints) < 2;
