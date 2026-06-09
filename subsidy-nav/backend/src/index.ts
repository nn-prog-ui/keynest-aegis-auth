import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

import subsidyRoutes from './routes/subsidies';
import municipalityRoutes from './routes/municipalities';
import alertRoutes from './routes/alerts';
import consultingRoutes from './routes/consulting';
import adminRoutes from './routes/admin';
import scraperRoutes from './routes/scraper';
import matchingRoutes from './routes/matching';
import pdfRoutes from './routes/pdf';
import { errorHandler } from './middleware/errorHandler';
import { startDeadlineNotificationCron } from './services/notificationService';
import { startScrapeCron } from './services/scraperService';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

app.use(helmet());
app.use(cors({ origin: process.env.FRONTEND_URL || 'http://localhost:3000' }));
app.use(morgan('dev'));
app.use(express.json());

const limiter = rateLimit({
  windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: Number(process.env.RATE_LIMIT_MAX) || 100,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/api/subsidies', subsidyRoutes);
app.use('/api/municipalities', municipalityRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/api/consulting', consultingRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/scraper', scraperRoutes);
app.use('/api/matching', matchingRoutes);
app.use('/api/pdf', pdfRoutes);

app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`補助金ナビ API サーバー起動: http://localhost:${PORT}`);
  startDeadlineNotificationCron();
  startScrapeCron();
});

export default app;
