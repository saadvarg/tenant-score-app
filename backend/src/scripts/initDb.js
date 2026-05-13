import 'dotenv/config';
import { pool } from '../config/db.js';

async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS tenants (
      id SERIAL PRIMARY KEY,
      landlord_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      full_name VARCHAR(160) NOT NULL,
      email VARCHAR(160),
      phone VARCHAR(40),
      monthly_income NUMERIC(12, 2) NOT NULL DEFAULT 0,
      rent_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
      employment_status VARCHAR(40) NOT NULL DEFAULT 'employed',
      credit_score INTEGER NOT NULL,
      eviction_count INTEGER NOT NULL DEFAULT 0,
      late_payments INTEGER NOT NULL DEFAULT 0,
      criminal_record BOOLEAN NOT NULL DEFAULT FALSE,
      notes TEXT,
      risk_score INTEGER NOT NULL,
      risk_level VARCHAR(20) NOT NULL,
      recommendation VARCHAR(20) NOT NULL DEFAULT 'review',
      application_status VARCHAR(20) NOT NULL DEFAULT 'pending',
      score_factors JSONB NOT NULL DEFAULT '[]'::jsonb,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await pool.query("ALTER TABLE tenants ADD COLUMN IF NOT EXISTS recommendation VARCHAR(20) NOT NULL DEFAULT 'review'");
  await pool.query("ALTER TABLE tenants ADD COLUMN IF NOT EXISTS application_status VARCHAR(20) NOT NULL DEFAULT 'pending'");
  await pool.query("ALTER TABLE tenants ADD COLUMN IF NOT EXISTS score_factors JSONB NOT NULL DEFAULT '[]'::jsonb");

  await pool.query('CREATE INDEX IF NOT EXISTS idx_tenants_landlord_id ON tenants(landlord_id)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_tenants_risk_level ON tenants(risk_level)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_tenants_application_status ON tenants(application_status)');

  await pool.query(`
    CREATE TABLE IF NOT EXISTS tenant_events (
      id SERIAL PRIMARY KEY,
      tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
      actor_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      event_type VARCHAR(40) NOT NULL,
      message TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  await pool.query('CREATE INDEX IF NOT EXISTS idx_tenant_events_tenant_id ON tenant_events(tenant_id)');
  await pool.query('CREATE INDEX IF NOT EXISTS idx_tenant_events_created_at ON tenant_events(created_at)');

  console.log('Database initialized.');
}

initDb()
  .catch((error) => {
    console.error('Unable to initialize database:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
