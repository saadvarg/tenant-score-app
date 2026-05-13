import express from 'express';
import {
  createTenant,
  deleteTenant,
  getTenant,
  listTenantEvents,
  listTenants,
  updateTenantStatus,
  updateTenant,
} from '../controllers/tenant.controller.js';
import authMiddleware from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authMiddleware);

router.get('/', listTenants);
router.post('/', createTenant);
router.get('/:id', getTenant);
router.get('/:id/events', listTenantEvents);
router.put('/:id', updateTenant);
router.patch('/:id/status', updateTenantStatus);
router.delete('/:id', deleteTenant);

export default router;
