import { PrismaClient, Subsidy, TargetAudience } from '@prisma/client';

const prisma = new PrismaClient();

interface MatchInput {
  municipalityCode?: string;
  prefectureCode?: string;
  audiences: TargetAudience[];
  categorySlugs: string[];
  budget?: number;
  isStartup?: boolean;
  keywords?: string;
}

interface MatchResult {
  subsidy: Subsidy & { municipality?: { code: string; name: string; prefecture: { name: string } } | null; category?: { slug: string; name: string } | null };
  score: number;
  reasons: string[];
}

export async function matchSubsidies(input: MatchInput): Promise<MatchResult[]> {
  const subsidies = await prisma.subsidy.findMany({
    where: { status: { in: ['ACTIVE', 'UPCOMING'] } },
    include: { municipality: { include: { prefecture: true } }, category: true },
    take: 200,
  });

  const results: MatchResult[] = subsidies.map(subsidy => {
    let score = 0;
    const reasons: string[] = [];

    if (input.municipalityCode && subsidy.municipality?.code === input.municipalityCode) {
      score += 5; reasons.push('お住まいの市区町村の補助金');
    } else if (input.prefectureCode && subsidy.municipality?.prefecture.code === input.prefectureCode) {
      score += 3; reasons.push('お住まいの都道府県の補助金');
    } else if (subsidy.isNational) {
      score += 2; reasons.push('全国対象の補助金');
    }

    const audienceMatch = input.audiences.filter(a => subsidy.targetAudiences.includes(a));
    if (audienceMatch.length > 0) {
      score += 4; reasons.push('対象者が一致');
    }

    if (input.categorySlugs.length > 0 && subsidy.category && input.categorySlugs.includes(subsidy.category.slug)) {
      score += 3; reasons.push('カテゴリが一致');
    }

    if (subsidy.status === 'ACTIVE') {
      score += 2; reasons.push('現在申請受付中');
    }

    if (input.budget && subsidy.maxAmount && Number(subsidy.maxAmount) <= input.budget * 2) {
      score += 2; reasons.push('予算規模が適合');
    }

    if (subsidy.applicationEnd) {
      const daysLeft = (subsidy.applicationEnd.getTime() - Date.now()) / (1000 * 60 * 60 * 24);
      if (daysLeft <= 30 && daysLeft > 0) {
        score += 1; reasons.push('締切が近い（30日以内）');
      }
    }

    if (input.keywords && subsidy.title.includes(input.keywords)) {
      score += 2; reasons.push('キーワードが一致');
    }

    if (input.isStartup && subsidy.isStartupFriendly) {
      score += 2; reasons.push('スタートアップ向け');
    }

    return { subsidy, score, reasons };
  });

  return results
    .filter(r => r.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 20);
}
