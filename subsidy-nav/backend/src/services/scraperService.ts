import axios from 'axios';
import * as cheerio from 'cheerio';
import { PrismaClient, SubsidyStatus, TargetAudience } from '@prisma/client';
import { CronJob } from 'cron';
import { SCRAPE_TARGETS as TARGET_LIST, ScrapeTarget } from '../data/scrape-targets';

const prisma = new PrismaClient();

interface ScrapedSubsidy {
  title: string;
  description: string;
  applicationEnd?: string;
  applicationStart?: string;
  maxAmount?: number;
  sourceUrl: string;
  tags: string[];
}

// ドメインごとのレート制限（ms）
const DOMAIN_DELAY_MS = 3000;
const REQUEST_TIMEOUT_MS = 15000;

function extractDomain(url: string): string {
  try {
    return new URL(url).hostname;
  } catch {
    return url;
  }
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// 汎用HTML補助金パーサー
function parseSubsidiesFromHtml(html: string, baseUrl: string): ScrapedSubsidy[] {
  const $ = cheerio.load(html);
  const results: ScrapedSubsidy[] = [];

  // パターン1: <table>形式
  $('table tr').each((_i, row) => {
    const cells = $(row).find('td');
    if (cells.length >= 2) {
      const title = cells.eq(0).text().trim();
      const desc = cells.eq(1).text().trim();
      if (title.length > 5 && (
        title.includes('補助') || title.includes('助成') ||
        title.includes('給付') || title.includes('支援')
      )) {
        const linkEl = cells.eq(0).find('a');
        const href = linkEl.attr('href');
        results.push({
          title,
          description: desc.slice(0, 500) || title,
          sourceUrl: href ? new URL(href, baseUrl).toString() : baseUrl,
          tags: extractTags(title + ' ' + desc),
        });
      }
    }
  });

  // パターン2: <ul><li>形式
  if (results.length === 0) {
    $('ul li, ol li').each((_i, el) => {
      const text = $(el).text().trim();
      const link = $(el).find('a');
      if (
        text.length > 10 &&
        (text.includes('補助') || text.includes('助成') || text.includes('支援金'))
      ) {
        const href = link.attr('href');
        results.push({
          title: link.text().trim() || text.slice(0, 80),
          description: text.slice(0, 300),
          sourceUrl: href ? new URL(href, baseUrl).toString() : baseUrl,
          tags: extractTags(text),
        });
      }
    });
  }

  // パターン3: <dl><dt><dd>形式
  if (results.length === 0) {
    $('dl').each((_i, dl) => {
      const dt = $(dl).find('dt').first().text().trim();
      const dd = $(dl).find('dd').first().text().trim();
      if (
        dt.length > 5 &&
        (dt.includes('補助') || dt.includes('助成') || dt.includes('給付'))
      ) {
        results.push({
          title: dt,
          description: dd.slice(0, 500) || dt,
          sourceUrl: baseUrl,
          tags: extractTags(dt + ' ' + dd),
        });
      }
    });
  }

  return results;
}

function extractTags(text: string): string[] {
  const tagPatterns: Record<string, string> = {
    '子育て': '子育て',
    '育児': '子育て',
    '保育': '子育て',
    '創業': '創業',
    '起業': '創業',
    'IT': 'IT',
    'デジタル': 'デジタル化',
    '省エネ': '省エネ',
    '太陽光': '再生可能エネルギー',
    '住宅': '住宅',
    'リフォーム': 'リフォーム',
    '農業': '農業',
    '高齢': '高齢者支援',
    '障害': '障害者支援',
    '中小企業': '中小企業',
  };

  const found = new Set<string>();
  for (const [keyword, tag] of Object.entries(tagPatterns)) {
    if (text.includes(keyword)) found.add(tag);
  }
  return [...found];
}

function inferTargetAudience(text: string): TargetAudience[] {
  const audiences: TargetAudience[] = [];
  if (text.includes('法人') || text.includes('中小企業') || text.includes('事業者')) {
    audiences.push(TargetAudience.CORPORATION);
  }
  if (text.includes('個人') || text.includes('一般市民')) {
    audiences.push(TargetAudience.INDIVIDUAL);
  }
  if (text.includes('創業') || text.includes('起業')) {
    audiences.push(TargetAudience.STARTUP);
  }
  if (text.includes('農業') || text.includes('農家')) {
    audiences.push(TargetAudience.FARMER);
  }
  if (text.includes('子育て') || text.includes('保育') || text.includes('育児')) {
    audiences.push(TargetAudience.CHILD);
  }
  if (text.includes('高齢')) {
    audiences.push(TargetAudience.ELDERLY);
  }
  if (text.includes('障害')) {
    audiences.push(TargetAudience.DISABLED);
  }
  return audiences.length > 0 ? audiences : [TargetAudience.INDIVIDUAL];
}

// URLを複数試みて最初に成功したHTMLを返す
async function fetchFirstSuccess(
  urls: string[]
): Promise<{ html: string; url: string } | null> {
  for (const url of urls) {
    try {
      const res = await axios.get(url, {
        timeout: REQUEST_TIMEOUT_MS,
        headers: {
          'User-Agent':
            'Mozilla/5.0 (compatible; SubsidyNavBot/1.0; +https://subsidy-nav.jp/bot)',
          Accept: 'text/html,application/xhtml+xml',
          'Accept-Language': 'ja,en;q=0.9',
        },
      });
      return { html: res.data, url };
    } catch {
      // 次のURLを試みる
    }
  }
  return null;
}

// 1件の市区町村をスクレイピング
export async function scrapeMunicipality(
  target: ScrapeTarget
): Promise<{ scraped: number; saved: number; errors: string[] }> {
  const errors: string[] = [];
  let saved = 0;

  try {
    const result = await fetchFirstSuccess(target.urls);
    if (!result) {
      const msg = `全てのURLに失敗: ${target.urls.join(', ')}`;
      errors.push(`${target.name}: ${msg}`);
      await prisma.scrapeLog.create({
        data: {
          municipalityCode: target.municipalityCode,
          url: target.urls[0],
          scrapedCount: 0,
          savedCount: 0,
          status: 'ERROR',
          errorMessage: msg,
        },
      });
      return { scraped: 0, saved, errors };
    }

    const { html, url: successUrl } = result;

    // カテゴリIDを解決
    const categories = await prisma.subsidyCategory.findMany({
      where: { slug: { in: target.categoryHints } },
    });
    const primaryCategoryId = categories[0]?.id ?? 3; // fallback: business

    const subsidies = parseSubsidiesFromHtml(html, successUrl);

    const municipality = await prisma.municipality.findUnique({
      where: { code: target.municipalityCode },
      include: { prefecture: true },
    });

    if (!municipality) {
      errors.push(`市区町村コード ${target.municipalityCode} が見つかりません`);
      await prisma.scrapeLog.create({
        data: {
          municipalityCode: target.municipalityCode,
          url: successUrl,
          scrapedCount: subsidies.length,
          savedCount: 0,
          status: 'ERROR',
          errorMessage: `市区町村コード ${target.municipalityCode} が見つかりません`,
        },
      });
      return { scraped: subsidies.length, saved, errors };
    }

    for (const s of subsidies) {
      // 重複チェック（タイトル + 市区町村）
      const existing = await prisma.subsidy.findFirst({
        where: {
          title: s.title,
          municipalityId: municipality.id,
        },
      });

      if (!existing) {
        await prisma.subsidy.create({
          data: {
            title: s.title,
            description: s.description,
            categoryId: primaryCategoryId,
            municipalityId: municipality.id,
            prefectureId: municipality.prefectureId,
            sourceUrl: s.sourceUrl,
            applicationEnd: s.applicationEnd ? new Date(s.applicationEnd) : undefined,
            applicationStart: s.applicationStart
              ? new Date(s.applicationStart)
              : undefined,
            maxAmount: s.maxAmount ? BigInt(s.maxAmount) : undefined,
            status: SubsidyStatus.ACTIVE,
            tags: s.tags,
            targetAudience: inferTargetAudience(s.title + ' ' + s.description),
          },
        });
        saved++;
      }
    }

    // スクレイピングログを記録
    await prisma.scrapeLog.create({
      data: {
        municipalityCode: target.municipalityCode,
        url: successUrl,
        scrapedCount: subsidies.length,
        savedCount: saved,
        status: 'SUCCESS',
      },
    });

    return { scraped: subsidies.length, saved, errors };
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    errors.push(`${target.name}: ${msg}`);

    await prisma.scrapeLog.create({
      data: {
        municipalityCode: target.municipalityCode,
        url: target.urls[0],
        scrapedCount: 0,
        savedCount: 0,
        status: 'ERROR',
        errorMessage: msg,
      },
    });

    return { scraped: 0, saved, errors };
  }
}

// 全対象市区町村を順番にスクレイピング（レート制限あり）
export async function scrapeAll(): Promise<{
  total: number;
  saved: number;
  errors: string[];
}> {
  let totalScraped = 0;
  let totalSaved = 0;
  const allErrors: string[] = [];

  const domainLastAccess: Record<string, number> = {};

  for (const target of TARGET_LIST) {
    const domain = extractDomain(target.urls[0]);
    const lastAccess = domainLastAccess[domain] || 0;
    const elapsed = Date.now() - lastAccess;

    if (elapsed < DOMAIN_DELAY_MS) {
      await sleep(DOMAIN_DELAY_MS - elapsed);
    }

    domainLastAccess[domain] = Date.now();

    const result = await scrapeMunicipality(target);
    totalScraped += result.scraped;
    totalSaved += result.saved;
    allErrors.push(...result.errors);

    console.log(
      `[スクレイパー] ${target.name}: ${result.scraped}件取得 / ${result.saved}件保存`
    );
  }

  return { total: totalScraped, saved: totalSaved, errors: allErrors };
}

// 毎週月曜日 深夜2時に自動スクレイピング
export function startScrapeCron() {
  const job = new CronJob('0 0 2 * * 1', async () => {
    console.log('[スクレイパー] 週次スクレイピング開始...');
    const result = await scrapeAll();
    console.log(
      `[スクレイパー] 完了: ${result.total}件取得 / ${result.saved}件保存 / エラー${result.errors.length}件`
    );
  });
  job.start();
  console.log('スクレイパーCronジョブ開始 (毎週月曜 02:00)');
}
