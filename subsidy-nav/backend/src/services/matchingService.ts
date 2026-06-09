import { PrismaClient, TargetAudience, Prisma } from '@prisma/client';

const prisma = new PrismaClient();

export interface UserProfile {
  prefectureCode?: string;
  municipalityCode?: string;
  targetAudience: TargetAudience;
  categoryIds?: number[];
  budgetMin?: number;   // 希望する最低補助額（円）
  isStartup?: boolean;
  hasEmployees?: boolean;
  keywords?: string;
}

interface ScoredSubsidy {
  id: number;
  title: string;
  description: string;
  score: number;
  reasons: string[];
  category: { name: string; icon: string };
  maxAmount?: string | null;
  applicationEnd?: string | null;
  status: string;
  prefecture?: { name: string } | null;
  municipality?: { name: string } | null;
  isNational: boolean;
}

function scoreSubsidy(subsidy: {
  id: number;
  title: string;
  description: string;
  tags: string[];
  targetAudience: TargetAudience[];
  maxAmount: bigint | null;
  status: string;
  applicationEnd: Date | null;
  categoryId: number;
  isNational: boolean;
  prefectureId: number | null;
  municipalityId: number | null;
  category: { id: number; name: string; icon: string };
  prefecture: { id: number; code: string } | null;
  municipality: { id: number; code: string } | null;
}, profile: UserProfile, prefectureId?: number, municipalityId?: number): { score: number; reasons: string[] } {
  let score = 0;
  const reasons: string[] = [];

  // 対象者マッチ（最重要）
  if (subsidy.targetAudience.includes(profile.targetAudience)) {
    score += 4;
    reasons.push('対象者が一致');
  }

  // 地域マッチ
  if (municipalityId && subsidy.municipalityId === municipalityId) {
    score += 5;
    reasons.push('お住まいの市区町村の補助金');
  } else if (prefectureId && subsidy.prefectureId === prefectureId) {
    score += 3;
    reasons.push('お住まいの都道府県の補助金');
  } else if (subsidy.isNational) {
    score += 2;
    reasons.push('全国対象の国の補助金');
  }

  // カテゴリマッチ
  if (profile.categoryIds?.includes(subsidy.categoryId)) {
    score += 3;
    reasons.push('希望カテゴリと一致');
  }

  // 受付中ボーナス
  if (subsidy.status === 'ACTIVE') {
    score += 2;
    reasons.push('現在受付中');
  }

  // 補助額フィルタ
  if (profile.budgetMin && subsidy.maxAmount) {
    if (Number(subsidy.maxAmount) >= profile.budgetMin) {
      score += 2;
      reasons.push(`補助額 ${Math.round(Number(subsidy.maxAmount) / 10000)}万円以上`);
    }
  }

  // 締め切りが近い場合はボーナス（見逃し防止）
  if (subsidy.applicationEnd) {
    const daysLeft = Math.ceil(
      (subsidy.applicationEnd.getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );
    if (daysLeft > 0 && daysLeft <= 30) {
      score += 1;
      reasons.push(`締切まで${daysLeft}日`);
    }
  }

  // キーワードマッチ
  if (profile.keywords) {
    const kw = profile.keywords.toLowerCase();
    const text = (subsidy.title + ' ' + subsidy.description + ' ' + subsidy.tags.join(' ')).toLowerCase();
    if (text.includes(kw)) {
      score += 2;
      reasons.push('キーワード一致');
    }
  }

  // 創業者フラグ
  if (profile.isStartup && subsidy.targetAudience.includes(TargetAudience.STARTUP)) {
    score += 2;
    reasons.push('創業者向け');
  }

  return { score, reasons };
}

export async function matchSubsidies(profile: UserProfile): Promise<ScoredSubsidy[]> {
  // プロフィールから地域IDを解決
  const [prefecture, municipality] = await Promise.all([
    profile.prefectureCode
      ? prisma.prefecture.findUnique({ where: { code: profile.prefectureCode } })
      : null,
    profile.municipalityCode
      ? prisma.municipality.findUnique({ where: { code: profile.municipalityCode } })
      : null,
  ]);

  // 有効な補助金を取得（終了済みは除く）
  const subsidies = await prisma.subsidy.findMany({
    where: {
      status: { not: 'ENDED' },
      OR: [
        { isNational: true },
        ...(prefecture ? [{ prefectureId: prefecture.id }] : []),
        ...(municipality ? [{ municipalityId: municipality.id }] : []),
      ],
    },
    include: {
      category: true,
      prefecture: { select: { id: true, code: true, name: true } },
      municipality: { select: { id: true, code: true, name: true } },
    },
    take: 200,
  });

  const scored = subsidies
    .map((s) => {
      const { score, reasons } = scoreSubsidy(
        s,
        profile,
        prefecture?.id,
        municipality?.id
      );
      return {
        id: s.id,
        title: s.title,
        description: s.description,
        score,
        reasons,
        category: s.category,
        maxAmount: s.maxAmount ? s.maxAmount.toString() : null,
        applicationEnd: s.applicationEnd?.toISOString() ?? null,
        status: s.status,
        prefecture: s.prefecture ? { name: s.prefecture.name } : null,
        municipality: s.municipality ? { name: s.municipality.name } : null,
        isNational: s.isNational,
      };
    })
    .filter((s) => s.score >= 2)
    .sort((a, b) => b.score - a.score)
    .slice(0, 20);

  return scored;
}
