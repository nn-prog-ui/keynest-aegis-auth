import axios from 'axios';
import * as cheerio from 'cheerio';
import { PrismaClient } from '@prisma/client';
import { CronJob } from 'node-cron';
import { SCRAPE_TARGETS, ScrapeTarget } from '../data/scrape-targets';

const prisma = new PrismaClient();

function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export async function scrapeMunicipality(target: ScrapeTarget): Promise<{ scraped: number; saved: number; errors: string[] }> {
  const errors: string[] = [];
  let scraped = 0;
  let saved = 0;

  const municipality = await prisma.municipality.findUnique({ where: { code: target.municipalityCode } });
  if (!municipality) {
    return { scraped: 0, saved: 0, errors: [`Municipality not found: ${target.municipalityCode}`] };
  }

  const startedAt = new Date();

  for (const url of target.urls) {
    try {
      await delay(3000);
      const { data } = await axios.get(url, {
        timeout: 15000,
        headers: { 'User-Agent': 'Mozilla/5.0 (compatible; SubsidyNavBot/1.0)' },
      });
      const $ = cheerio.load(data);

      const subsidyLinks: Array<{ title: string; href: string }> = [];

      $('a').each((_i, el) => {
        const href = $(el).attr('href') || '';
        const text = $(el).text().trim();
        const isSubsidyLink = ['補助金', '助成金', '支援', '給付', '交付'].some(k => text.includes(k));
        if (isSubsidyLink && text.length > 5 && text.length < 200) {
          subsidyLinks.push({ title: text, href });
        }
      });

      scraped += subsidyLinks.length;

      for (const link of subsidyLinks.slice(0, 10)) {
        try {
          const category = await prisma.subsidyCategory.findFirst({
            where: { slug: { in: target.categoryHints } },
          });

          await prisma.subsidy.upsert({
            where: {
              title_municipalityId: {
                title: link.title.slice(0, 200),
                municipalityId: municipality.id,
              },
            },
            update: { sourceUrl: link.href.startsWith('http') ? link.href : `${url}${link.href}`, updatedAt: new Date() },
            create: {
              title: link.title.slice(0, 200),
              description: `${target.name}の補助金・助成金情報`,
              status: 'ACTIVE',
              municipalityId: municipality.id,
              categoryId: category?.id,
              sourceUrl: link.href.startsWith('http') ? link.href : `${url}${link.href}`,
              targetAudiences: [],
            },
          });
          saved++;
        } catch {
          errors.push(`Save error: ${link.title}`);
        }
      }
    } catch (err) {
      errors.push(`Fetch error ${url}: ${err instanceof Error ? err.message : String(err)}`);
    }
  }

  await prisma.scrapeLog.create({
    data: { municipalityId: municipality.id, startedAt, completedAt: new Date(), scraped, saved, errors, success: errors.length === 0 },
  });

  return { scraped, saved, errors };
}

export async function scrapeAll(): Promise<{ total: number; saved: number; errors: string[] }> {
  let total = 0;
  let saved = 0;
  const errors: string[] = [];

  for (const target of SCRAPE_TARGETS) {
    const result = await scrapeMunicipality(target);
    total += result.scraped;
    saved += result.saved;
    errors.push(...result.errors);
  }

  return { total, saved, errors };
}

export function startScrapeCron(): void {
  new CronJob('0 0 2 * * 1', async () => {
    console.log('[ScrapeCron] Starting weekly scrape...');
    const result = await scrapeAll();
    console.log(`[ScrapeCron] Done: scraped=${result.total} saved=${result.saved} errors=${result.errors.length}`);
  }, null, true);
}
