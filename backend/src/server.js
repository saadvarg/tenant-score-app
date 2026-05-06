import 'dotenv/config';
import app from './app.js';
import { pool } from './config/db.js';

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});


pool.connect()
  .then(() => console.log('DB connected'))
  .catch(err => console.error(err));
