import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth.routes.js';
import tenantRoutes from './routes/tenant.routes.js';


const app = express();

app.use(cors());
app.use(express.json());
app.use('/api/auth', authRoutes);
app.use('/api/tenants', tenantRoutes);

app.get('/', (req, res) => {
  res.send('API running');
});

export default app;
