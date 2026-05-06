import 'dotenv/config';
import bcrypt from 'bcrypt';
import { pool } from '../config/db.js';
import { calculateTenantScore } from '../services/score.service.js';

const SALT_ROUNDS = Number(process.env.BCRYPT_SALT_ROUNDS || 12);
const password = 'Password123!';

const demoUsers = [
  {
    email: 'landlord@tenantscore.test',
    role: 'landlord',
  },
  {
    email: 'admin@tenantscore.test',
    role: 'admin',
  },
];

const demoTenants = [
  {
    full_name: 'Maya Johnson',
    email: 'maya@example.com',
    phone: '555-0134',
    monthly_income: 6200,
    rent_amount: 1800,
    employment_status: 'employed',
    credit_score: 735,
    eviction_count: 0,
    late_payments: 1,
    criminal_record: false,
    notes: 'Strong applicant with stable income.',
  },
  {
    full_name: 'Omar Benali',
    email: 'omar@example.com',
    phone: '555-0198',
    monthly_income: 4100,
    rent_amount: 1700,
    employment_status: 'self_employed',
    credit_score: 642,
    eviction_count: 0,
    late_payments: 3,
    criminal_record: false,
    notes: 'Self-employed, ask for bank statements.',
  },
  {
    full_name: 'Jordan Lee',
    email: 'jordan@example.com',
    phone: '555-0161',
    monthly_income: 2900,
    rent_amount: 1650,
    employment_status: 'unemployed',
    credit_score: 560,
    eviction_count: 1,
    late_payments: 6,
    criminal_record: true,
    notes: 'High-risk profile. Requires guarantor review.',
  },
];

async function seedUsers() {
  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

  for (const user of demoUsers) {
    await pool.query(
      `INSERT INTO users (email, password, role)
       VALUES ($1, $2, $3)
       ON CONFLICT (email)
       DO UPDATE SET password = EXCLUDED.password, role = EXCLUDED.role`,
      [user.email, passwordHash, user.role]
    );
  }

  const landlordResult = await pool.query('SELECT id FROM users WHERE email = $1', ['landlord@tenantscore.test']);
  const landlordId = landlordResult.rows[0]?.id;

  if (landlordId) {
    await pool.query('DELETE FROM tenants WHERE landlord_id = $1', [landlordId]);

    for (const tenant of demoTenants) {
      const score = calculateTenantScore(tenant);
      await pool.query(
        `INSERT INTO tenants (
           landlord_id, full_name, email, phone, monthly_income, rent_amount,
           employment_status, credit_score, eviction_count, late_payments,
           criminal_record, notes, risk_score, risk_level, recommendation, score_factors
         )
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)`,
        [
          landlordId,
          tenant.full_name,
          tenant.email,
          tenant.phone,
          tenant.monthly_income,
          tenant.rent_amount,
          tenant.employment_status,
          tenant.credit_score,
          tenant.eviction_count,
          tenant.late_payments,
          tenant.criminal_record,
          tenant.notes,
          score.risk_score,
          score.risk_level,
          score.recommendation,
          JSON.stringify(score.score_factors),
        ]
      );
    }
  }

  console.log('Demo users ready:');
  for (const user of demoUsers) {
    console.log(`${user.role}: ${user.email} / ${password}`);
  }
  console.log('Sample landlord tenants ready.');
}

seedUsers()
  .catch((error) => {
    console.error('Unable to seed demo users:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
