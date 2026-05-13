import express from 'express';
import {
  deleteAnyTenant,
  getAdminStats,
  listAllTenants,
  listTenantEvents,
  listUsers,
} from '../controllers/admin.controller.js';
import authMiddleware from '../middleware/auth.middleware.js';
import { requireRole } from '../middleware/role.middleware.js';

const router = express.Router();

router.use(authMiddleware);
router.use(requireRole('admin'));

router.get('/stats', getAdminStats);
router.get('/users', listUsers);
router.get('/tenants', listAllTenants);
router.get('/tenants/:id/events', listTenantEvents);
router.delete('/tenants/:id', deleteAnyTenant);

export default router;
