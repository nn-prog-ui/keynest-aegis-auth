import { PrismaClient } from '@prisma/client';
import { CronJob } from 'node-cron';
import { sendDeadlineAlert } from './emailService';

const prisma = new PrismaClient();

export async function sendDeadlineNotifications(): Promise<{ sentCount: number }> {
  const sevenDaysLater = new Date();
  sevenDaysLater.setDate(sevenDaysLater.getDate() + 7);
  const today = new Date();

  const endingSoon = await prisma.subsidy.findMany({
    where: {
      status: 'ACTIVE',
      applicationEnd: { gte: today, lte: sevenDaysLater },
    },
    include: { municipality: { include: { prefecture: true } } },
  });

  if (endingSoon.length === 0) return { sentCount: 0 };

  const activeAlerts = await prisma.alertPreference.findMany({
    where: { isActive: true, isVerified: true },
  });

  let sentCount = 0;
  for (const alert of activeAlerts) {
    const matching = endingSoon.filter(s => {
      const prefMatch = alert.prefectureCodes.length === 0 || (s.municipality && alert.prefectureCodes.includes(s.municipality.prefecture.code));
      const audMatch = alert.audiences.length === 0 || s.targetAudiences.some(a => alert.audiences.includes(a));
      return prefMatch && audMatch;
    });

    if (matching.length > 0) {
      await sendDeadlineAlert(alert.email, matching.map(s => ({
        title: s.title,
        applicationEnd: s.applicationEnd!,
        id: s.id,
      })));
      sentCount++;
    }
  }

  return { sentCount };
}

export function startDeadlineNotificationCron(): void {
  new CronJob('0 0 9 * * *', async () => {
    console.log('[DeadlineCron] Running deadline notifications...');
    const result = await sendDeadlineNotifications();
    console.log(`[DeadlineCron] Sent ${result.sentCount} notifications`);
  }, null, true);
}
