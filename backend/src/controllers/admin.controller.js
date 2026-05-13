import { pool } from '../config/db.js';

function adminTenantQuery() {
  return `
    SELECT tenants.id,
           tenants.landlord_id,
           users.email AS landlord_email,
           tenants.full_name,
           tenants.email,
           tenants.phone,
           tenants.monthly_income,
           tenants.rent_amount,
           tenants.employment_status,
           tenants.credit_score,
           tenants.eviction_count,
           tenants.late_payments,
           tenants.criminal_record,
           tenants.notes,
           tenants.risk_score,
           tenants.risk_level,
           tenants.recommendation,
           tenants.application_status,
           tenants.score_factors,
           tenants.created_at,
           tenants.updated_at
    FROM tenants
    JOIN users ON users.id = tenants.landlord_id
  `;
}

export async function getAdminStats(req, res) {
  try {
    const [usersResult, tenantsResult, riskResult, statusResult, averageResult] = await Promise.all([
      pool.query(`
        SELECT
          COUNT(*)::int AS total_users,
          COUNT(*) FILTER (WHERE role = 'landlord')::int AS landlords,
          COUNT(*) FILTER (WHERE role = 'admin')::int AS admins
        FROM users
      `),
      pool.query('SELECT COUNT(*)::int AS total_tenants FROM tenants'),
      pool.query(`
        SELECT
          COUNT(*) FILTER (WHERE risk_level = 'low')::int AS low_risk,
          COUNT(*) FILTER (WHERE risk_level = 'medium')::int AS medium_risk,
          COUNT(*) FILTER (WHERE risk_level = 'high')::int AS high_risk
        FROM tenants
      `),
      pool.query(`
        SELECT
          COUNT(*) FILTER (WHERE application_status = 'pending')::int AS pending_applications,
          COUNT(*) FILTER (WHERE application_status = 'approved')::int AS approved_applications,
          COUNT(*) FILTER (WHERE application_status = 'rejected')::int AS rejected_applications
        FROM tenants
      `),
      pool.query('SELECT COALESCE(ROUND(AVG(risk_score)), 0)::int AS average_score FROM tenants'),
    ]);

    return res.json({
      stats: {
        ...usersResult.rows[0],
        ...tenantsResult.rows[0],
        ...riskResult.rows[0],
        ...statusResult.rows[0],
        ...averageResult.rows[0],
      },
    });
  } catch (error) {
    console.error('Admin stats error:', error);
    return res.status(500).json({ message: 'Unable to load admin stats.' });
  }
}

export async function listUsers(req, res) {
  try {
    const result = await pool.query(`
      SELECT users.id,
             users.email,
             users.role,
             users.created_at,
             COUNT(tenants.id)::int AS tenant_count
      FROM users
      LEFT JOIN tenants ON tenants.landlord_id = users.id
      GROUP BY users.id
      ORDER BY users.created_at DESC
    `);

    return res.json({ users: result.rows });
  } catch (error) {
    console.error('Admin users error:', error);
    return res.status(500).json({ message: 'Unable to load users.' });
  }
}

export async function listAllTenants(req, res) {
  try {
    const result = await pool.query(`${adminTenantQuery()} ORDER BY tenants.created_at DESC`);
    return res.json({ tenants: result.rows });
  } catch (error) {
    console.error('Admin tenants error:', error);
    return res.status(500).json({ message: 'Unable to load tenant applications.' });
  }
}

export async function listTenantEvents(req, res) {
  try {
    const tenantResult = await pool.query('SELECT id FROM tenants WHERE id = $1', [req.params.id]);

    if (tenantResult.rows.length === 0) {
      return res.status(404).json({ message: 'Tenant not found.' });
    }

    const result = await pool.query(
      `SELECT tenant_events.id,
              tenant_events.tenant_id,
              tenant_events.actor_id,
              users.email AS actor_email,
              tenant_events.event_type,
              tenant_events.message,
              tenant_events.created_at
       FROM tenant_events
       JOIN users ON users.id = tenant_events.actor_id
       WHERE tenant_events.tenant_id = $1
       ORDER BY tenant_events.created_at DESC`,
      [req.params.id]
    );

    return res.json({ events: result.rows });
  } catch (error) {
    console.error('Admin tenant events error:', error);
    return res.status(500).json({ message: 'Unable to load tenant activity.' });
  }
}

export async function deleteAnyTenant(req, res) {
  try {
    const result = await pool.query('DELETE FROM tenants WHERE id = $1 RETURNING id', [req.params.id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Tenant not found.' });
    }

    return res.status(204).send();
  } catch (error) {
    console.error('Admin delete tenant error:', error);
    return res.status(500).json({ message: 'Unable to delete tenant.' });
  }
}
