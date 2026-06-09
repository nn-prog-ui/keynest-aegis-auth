import type { Metadata } from 'next';
import Link from 'next/link';
import { ExternalLink, MapPin, Calendar, Banknote, Users, ChevronLeft, FileText } from 'lucide-react';
import { getSubsidy } from '@/lib/api';
import { formatAmount, formatDeadline, getStatusLabel, getAudienceLabel } from '@/lib/utils';
import { notFound } from 'next/navigation';

interface PageProps {
  params: Promise<{ id: string }>;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  try {
    const { id } = await params;
    const subsidy = await getSubsidy(parseInt(id));
    return { title: subsidy.title, description: subsidy.description.slice(0, 120) };
  } catch {
    return { title: '補助金詳細' };
  }
}

export default async function SubsidyDetailPage({ params }: PageProps) {
  const { id } = await params;
  let subsidy;
  try {
    subsidy = await getSubsidy(parseInt(id));
  } catch {
    notFound();
  }

  const deadline = subsidy.applicationEnd ? formatDeadline(subsidy.applicationEnd) : null;
  const isUrgent = deadline?.daysLeft !== undefined && deadline.daysLeft >= 0 && deadline.daysLeft <= 14;

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <Link href="/subsidies" className="inline-flex items-center gap-1 text-gray-500 hover:text-gray-800 text-sm mb-6">
        <ChevronLeft size={16} />
        補助金一覧に戻る
      </Link>

      <div className="card p-8">
        <div className="flex flex-wrap items-center gap-2 mb-4">
          <span className={
            subsidy.status === 'ACTIVE' ? 'badge-active' :
            subsidy.status === 'UPCOMING' ? 'badge-upcoming' : 'badge-ended'
          }>
            {getStatusLabel(subsidy.status)}
          </span>
          <span className="text-sm text-gray-500 bg-gray-100 px-2.5 py-0.5 rounded-full">
            {subsidy.category.icon} {subsidy.category.name}
          </span>
          {isUrgent && (
            <span className="badge-ended bg-red-100 text-red-700">
              締切まで残り{deadline!.daysLeft}日
            </span>
          )}
        </div>

        <h1 className="text-2xl font-bold text-gray-900 mb-2">{subsidy.title}</h1>

        <p className="text-gray-600 leading-relaxed mb-8">{subsidy.description}</p>

        {/* Key info grid */}
        <div className="grid sm:grid-cols-2 gap-4 mb-8">
          <InfoRow
            icon={<MapPin size={16} className="text-brand-500" />}
            label="対象地域"
            value={
              subsidy.isNational
                ? '全国（国の補助金）'
                : subsidy.municipality
                ? `${subsidy.prefecture?.name} ${subsidy.municipality.name}`
                : subsidy.prefecture?.name || '—'
            }
          />
          {subsidy.maxAmount && (
            <InfoRow
              icon={<Banknote size={16} className="text-brand-500" />}
              label="最大補助額"
              value={formatAmount(subsidy.maxAmount)}
              highlight
            />
          )}
          {subsidy.subsidyRate && (
            <InfoRow
              icon={<Banknote size={16} className="text-brand-500" />}
              label="補助率"
              value={`${Math.round(subsidy.subsidyRate * 100)}%`}
            />
          )}
          {deadline && (
            <InfoRow
              icon={<Calendar size={16} className={isUrgent ? 'text-red-500' : 'text-brand-500'} />}
              label="申請締め切り"
              value={deadline.label}
              highlight={isUrgent}
              highlightClass="text-red-600 font-bold"
            />
          )}
          {subsidy.applicationStart && (
            <InfoRow
              icon={<Calendar size={16} className="text-brand-500" />}
              label="申請開始日"
              value={new Date(subsidy.applicationStart).toLocaleDateString('ja-JP', {
                year: 'numeric', month: 'long', day: 'numeric',
              })}
            />
          )}
          {subsidy.targetAudience.length > 0 && (
            <InfoRow
              icon={<Users size={16} className="text-brand-500" />}
              label="対象者"
              value={subsidy.targetAudience.map(getAudienceLabel).join('、')}
            />
          )}
        </div>

        {/* Tags */}
        {subsidy.tags.length > 0 && (
          <div className="flex flex-wrap gap-2 mb-8">
            {subsidy.tags.map((tag) => (
              <span key={tag} className="bg-gray-100 text-gray-600 text-xs px-2.5 py-1 rounded-full">
                #{tag}
              </span>
            ))}
          </div>
        )}

        {/* Detail sections */}
        {subsidy.detail && (
          <Section title="詳細説明">{subsidy.detail}</Section>
        )}
        {subsidy.requirements && (
          <Section title="申請要件・条件">{subsidy.requirements}</Section>
        )}
        {subsidy.howToApply && (
          <Section title="申請方法">{subsidy.howToApply}</Section>
        )}

        {/* Actions */}
        <div className="flex flex-col sm:flex-row gap-3 mt-8 pt-6 border-t border-gray-200">
          <a
            href={subsidy.sourceUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-primary"
          >
            <ExternalLink size={16} />
            公式サイトで確認する
          </a>
          <Link href="/consulting" className="btn-secondary">
            <FileText size={16} />
            申請サポートを依頼する
          </Link>
        </div>
      </div>

      {/* CTA */}
      <div className="mt-6 card p-6 bg-blue-50 border-brand-200">
        <h3 className="font-bold text-brand-800 mb-2">この補助金の申請でお困りですか？</h3>
        <p className="text-sm text-blue-700 mb-4">
          専門コンサルタントが申請書類の作成から提出まで全面サポートします。
          まずは無料でご相談ください。
        </p>
        <Link href="/consulting" className="btn-primary text-sm py-2">
          無料相談を申し込む
        </Link>
      </div>
    </div>
  );
}

function InfoRow({
  icon,
  label,
  value,
  highlight,
  highlightClass,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  highlight?: boolean;
  highlightClass?: string;
}) {
  return (
    <div className="flex items-start gap-2 bg-gray-50 rounded-lg p-3">
      <div className="mt-0.5 flex-shrink-0">{icon}</div>
      <div>
        <div className="text-xs text-gray-500 mb-0.5">{label}</div>
        <div className={`font-medium ${highlight ? (highlightClass || 'text-brand-700') : 'text-gray-800'}`}>
          {value}
        </div>
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: string }) {
  return (
    <div className="mb-6">
      <h2 className="font-bold text-gray-800 mb-2 text-lg">{title}</h2>
      <div className="text-gray-600 whitespace-pre-line leading-relaxed bg-gray-50 rounded-lg p-4 text-sm">
        {children}
      </div>
    </div>
  );
}
