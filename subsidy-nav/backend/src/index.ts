import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

dotenv.config();

import subsidiesRouter from './routes/subsidies';
import alertsRouter from './routes/alerts';
import consultingRouter from './routes/consulting';
import matchingRouter from './routes/matching';
import pdfRouter from './routes/pdf';
import scraperRouter from './routes/scraper';
import adminRouter from './routes/admin';
import { startDeadlineNotificationCron } from './services/deadlineNotificationService';
import { startScrapeCron } from './services/scraperService';
import { startWeeklyDigestCron } from './services/weeklyDigestService';

const app = express();
const PORT = process.env.PORT || 4000;

app.use(helmet());
app.use(cors({ origin: process.env.FRONTEND_URL || 'http://localhost:3000' }));
app.use(express.json());

const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 });
app.use(limiter);

app.use('/api/subsidies', subsidiesRouter);
app.use('/api/alerts', alertsRouter);
app.use('/api/consulting', consultingRouter);
app.use('/api/matching', matchingRouter);
app.use('/api/pdf', pdfRouter);
app.use('/api/scraper', scraperRouter);
app.use('/api/admin', adminRouter);

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.listen(PORT, () => {
  console.log(`Backend running on port ${PORT}`);
  startDeadlineNotificationCron();
  startScrapeCron();
  startWeeklyDigestCron();
});

export default app;
