import { SubsidyStatus, TargetAudience } from '@/types';

export function formatAmount(amount: string | number | bigint): string {
  const n = typeof amount === 'string' ? parseInt(amount) : Number(amount);
  if (n >= 100_000_000) return `${(n / 100_000_000).toFixed(0)}億円`;
  if (n >= 10_000) return `${(n / 10_000).toFixed(0)}万円`;
  return `${n.toLocaleString()}円`;
}

export function formatDeadline(isoDate: string): { label: string; daysLeft: number } {
  const end = new Date(isoDate);
  const now = new Date();
  const diff = end.getTime() - now.getTime();
  const daysLeft = Math.ceil(diff / (1000 * 60 * 60 * 24));
  const label = end.toLocaleDateString('ja-JP', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
  return { label, daysLeft };
}

export function getStatusLabel(status: SubsidyStatus): string {
  const map: Record<SubsidyStatus, string> = {
    ACTIVE: '受付中',
    UPCOMING: '公募前',
    ENDED: '終了',
  };
  return map[status];
}

export function getAudienceLabel(audience: TargetAudience): string {
  const map: Record<TargetAudience, string> = {
    INDIVIDUAL: '個人',
    CORPORATION: '法人・中小企業',
    FARMER: '農業者',
    NONPROFIT: 'NPO・非営利団体',
    STARTUP: '創業者・スタートアップ',
    ELDERLY: '高齢者',
    CHILD: '子育て世帯',
    DISABLED: '障害者・障害者雇用',
  };
  return map[audience];
}
