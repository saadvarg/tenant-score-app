import pkg from 'pg';
const { Pool } = pkg;

export const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'tenant_score',
  password: process.env.DB_PASSWORD || 'watfatima666',
  port: Number(process.env.DB_PORT || 5432),
});
