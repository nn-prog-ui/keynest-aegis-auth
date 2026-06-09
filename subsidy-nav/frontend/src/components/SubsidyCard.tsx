import Link from 'next/link';
import { MapPin, Calendar, Banknote, ExternalLink } from 'lucide-react';
import { Subsidy } from '@/types';
import { formatDeadline, formatAmount, getStatusLabel } from '@/lib/utils';

interface Props {
  subsidy: Subsidy;
}

export default function SubsidyCard({ subsidy }: Props) {
  const statusClass =
    subsidy.status === 'ACTIVE'
      ? 'badge-active'
      : subsidy.status === 'UPCOMING'
      ? 'badge-upcoming'
      : 'badge-ended';

  const deadline = subsidy.applicationEnd ? formatDeadline(subsidy.applicationEnd) : null;
  const isUrgent =
    deadline?.daysLeft !== undefined &&
    deadline.daysLeft >= 0 &&
    deadline.daysLeft <= 14;

  return (
    <Link href={`/subsidies/${subsidy.id}`} className="card p-5 hover:shadow-md hover:border-brand-300 transition-all block">
      <div className="flex items-start justify-between gap-2 mb-3">
        <span className={statusClass}>{getStatusLabel(subsidy.status)}</span>
        {isUrgent && (
          <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700">
            残り{deadline!.daysLeft}日
          </span>
        )}
      </div>

      <div className="text-xs text-brand-600 font-medium mb-1">
        {subsidy.category.icon} {subsidy.category.name}
      </div>

      <h3 className="font-bold text-gray-900 mb-2 line-clamp-2 leading-snug">
        {subsidy.title}
      </h3>

      <p className="text-sm text-gray-600 line-clamp-2 mb-4">
        {subsidy.description}
      </p>

      <div className="space-y-1.5 text-sm text-gray-500">
        <div className="flex items-center gap-1.5">
          <MapPin size={13} className="text-gray-400 flex-shrink-0" />
          <span>
            {subsidy.isNational
              ? '国（全国）'
              : subsidy.municipality
              ? `${subsidy.prefecture?.name} ${subsidy.municipality.name}`
              : subsidy.prefecture?.name || '—'}
          </span>
        </div>

        {subsidy.maxAmount && (
          <div className="flex items-center gap-1.5">
            <Banknote size={13} className="text-gray-400 flex-shrink-0" />
            <span className="font-medium text-gray-700">
              最大 {formatAmount(subsidy.maxAmount)}
            </span>
          </div>
        )}

        {deadline && (
          <div className={`flex items-center gap-1.5 ${isUrgent ? 'text-red-600 font-medium' : ''}`}>
            <Calendar size={13} className="flex-shrink-0" />
            <span>締切: {deadline.label}</span>
          </div>
        )}
      </div>
    </Link>
  );
}
