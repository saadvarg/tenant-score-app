import express from 'express';
import {
  createTenant,
  deleteTenant,
  getTenant,
  listTenants,
  updateTenant,
} from '../controllers/tenant.controller.js';
import authMiddleware from '../middleware/auth.middleware.js';

const router = express.Router();

router.use(authMiddleware);

router.get('/', listTenants);
router.post('/', createTenant);
router.get('/:id', getTenant);
router.put('/:id', updateTenant);
router.delete('/:id', deleteTenant);

export default router;
