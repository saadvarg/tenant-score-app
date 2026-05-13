import { pool } from '../config/db.js';
import { calculateTenantScore } from '../services/score.service.js';

const allowedEmploymentStatuses = new Set([
  'employed',
  'self_employed',
  'student',
  'retired',
  'unemployed',
]);

const allowedApplicationStatuses = new Set(['pending', 'approved', 'rejected']);

function parseTenantPayload(body) {
  const tenant = {
    full_name: body.full_name?.trim(),
    email: body.email?.trim().toLowerCase() || null,
    phone: body.phone?.trim() || null,
    monthly_income: Number(body.monthly_income),
    rent_amount: Number(body.rent_amount),
    employment_status: body.employment_status || 'employed',
    credit_score: Number(body.credit_score),
    eviction_count: Number(body.eviction_count || 0),
    late_payments: Number(body.late_payments || 0),
    criminal_record: Boolean(body.criminal_record),
    notes: body.notes?.trim() || null,
  };

  if (!tenant.full_name) {
    return { error: 'Tenant name is required.' };
  }

  if (!Number.isFinite(tenant.monthly_income) || tenant.monthly_income < 0) {
    return { error: 'Monthly income must be a valid number.' };
  }

  if (!Number.isFinite(tenant.rent_amount) || tenant.rent_amount < 0) {
    return { error: 'Rent amount must be a valid number.' };
  }

  if (!Number.isFinite(tenant.credit_score) || tenant.credit_score < 300 || tenant.credit_score > 850) {
    return { error: 'Credit score must be between 300 and 850.' };
  }

  if (!Number.isInteger(tenant.eviction_count) || tenant.eviction_count < 0) {
    return { error: 'Eviction count must be zero or greater.' };
  }

  if (!Number.isInteger(tenant.late_payments) || tenant.late_payments < 0) {
    return { error: 'Late payments must be zero or greater.' };
  }

  if (!allowedEmploymentStatuses.has(tenant.employment_status)) {
    return { error: 'Employment status is invalid.' };
  }

  return { tenant };
}

function tenantQuery() {
  return `
    SELECT id, landlord_id, full_name, email, phone, monthly_income, rent_amount,
           employment_status, credit_score, eviction_count, late_payments,
           criminal_record, notes, risk_score, risk_level, recommendation,
           application_status, score_factors, created_at, updated_at
    FROM tenants
  `;
}

async function logTenantEvent(tenantId, actorId, eventType, message) {
  await pool.query(
    `INSERT INTO tenant_events (tenant_id, actor_id, event_type, message)
     VALUES ($1, $2, $3, $4)`,
    [tenantId, actorId, eventType, message]
  );
}

export async function listTenants(req, res) {
  try {
    const result = await pool.query(
      `${tenantQuery()} WHERE landlord_id = $1 ORDER BY created_at DESC`,
      [req.user.id]
    );

    return res.json({ tenants: result.rows });
  } catch (error) {
    console.error('List tenants error:', error);
    return res.status(500).json({ message: 'Unable to load tenants.' });
  }
}

export async function getTenant(req, res) {
  try {
    const result = await pool.query(
      `${tenantQuery()} WHERE id = $1 AND landlord_id = $2`,
      [req.params.id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Tenant not found.' });
    }

    return res.json({ tenant: result.rows[0] });
  } catch (error) {
    console.error('Get tenant error:', error);
    return res.status(500).json({ message: 'Unable to load tenant.' });
  }
}

export async function listTenantEvents(req, res) {
  try {
    const tenantResult = await pool.query(
      'SELECT id FROM tenants WHERE id = $1 AND landlord_id = $2',
      [req.params.id, req.user.id]
    );

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
    console.error('List tenant events error:', error);
    return res.status(500).json({ message: 'Unable to load tenant activity.' });
  }
}

export async function createTenant(req, res) {
  try {
    const { tenant, error } = parseTenantPayload(req.body);

    if (error) {
      return res.status(400).json({ message: error });
    }

    const score = calculateTenantScore(tenant);
    const result = await pool.query(
      `INSERT INTO tenants (
         landlord_id, full_name, email, phone, monthly_income, rent_amount,
         employment_status, credit_score, eviction_count, late_payments,
         criminal_record, notes, risk_score, risk_level, recommendation, score_factors
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
       RETURNING *`,
      [
        req.user.id,
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

    await logTenantEvent(result.rows[0].id, req.user.id, 'created', 'Tenant application created.');

    return res.status(201).json({ tenant: result.rows[0] });
  } catch (error) {
    console.error('Create tenant error:', error);
    return res.status(500).json({ message: 'Unable to create tenant.' });
  }
}

export async function updateTenant(req, res) {
  try {
    const { tenant, error } = parseTenantPayload(req.body);

    if (error) {
      return res.status(400).json({ message: error });
    }

    const score = calculateTenantScore(tenant);
    const result = await pool.query(
      `UPDATE tenants
       SET full_name = $1,
           email = $2,
           phone = $3,
           monthly_income = $4,
           rent_amount = $5,
           employment_status = $6,
           credit_score = $7,
           eviction_count = $8,
           late_payments = $9,
           criminal_record = $10,
           notes = $11,
           risk_score = $12,
           risk_level = $13,
           recommendation = $14,
           score_factors = $15,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $16 AND landlord_id = $17
       RETURNING *`,
      [
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
        req.params.id,
        req.user.id,
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Tenant not found.' });
    }

    await logTenantEvent(result.rows[0].id, req.user.id, 'updated', 'Tenant application details updated.');

    return res.json({ tenant: result.rows[0] });
  } catch (error) {
    console.error('Update tenant error:', error);
    return res.status(500).json({ message: 'Unable to update tenant.' });
  }
}

export async function updateTenantStatus(req, res) {
  try {
    const { status, note } = req.body;
    const decisionNote = typeof note === 'string' ? note.trim() : '';

    if (!allowedApplicationStatuses.has(status)) {
      return res.status(400).json({ message: 'Application status is invalid.' });
    }

    const result = await pool.query(
      `UPDATE tenants
       SET application_status = $1,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 AND landlord_id = $3
       RETURNING *`,
      [status, req.params.id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Tenant not found.' });
    }

    await logTenantEvent(
      result.rows[0].id,
      req.user.id,
      'status_changed',
      decisionNote
        ? `Application status changed to ${status}. Note: ${decisionNote}`
        : `Application status changed to ${status}.`
    );

    return res.json({ tenant: result.rows[0] });
  } catch (error) {
    console.error('Update tenant status error:', error);
    return res.status(500).json({ message: 'Unable to update tenant status.' });
  }
}

export async function deleteTenant(req, res) {
  try {
    const result = await pool.query(
      'DELETE FROM tenants WHERE id = $1 AND landlord_id = $2 RETURNING id',
      [req.params.id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Tenant not found.' });
    }

    return res.status(204).send();
  } catch (error) {
    console.error('Delete tenant error:', error);
    return res.status(500).json({ message: 'Unable to delete tenant.' });
  }
}
