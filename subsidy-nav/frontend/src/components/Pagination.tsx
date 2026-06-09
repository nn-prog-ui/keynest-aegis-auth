import Link from 'next/link';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface Props {
  total: number;
  page: number;
  totalPages: number;
  params: Record<string, string>;
}

export default function Pagination({ page, totalPages, params }: Props) {
  if (totalPages <= 1) return null;

  function buildUrl(p: number) {
    const q = new URLSearchParams(params);
    q.set('page', String(p));
    return `/subsidies?${q.toString()}`;
  }

  const pages: (number | '...')[] = [];
  for (let i = 1; i <= totalPages; i++) {
    if (i === 1 || i === totalPages || (i >= page - 2 && i <= page + 2)) {
      pages.push(i);
    } else if (pages[pages.length - 1] !== '...') {
      pages.push('...');
    }
  }

  return (
    <div className="flex items-center justify-center gap-1">
      {page > 1 && (
        <Link href={buildUrl(page - 1)} className="p-2 rounded-lg hover:bg-gray-100 text-gray-500">
          <ChevronLeft size={18} />
        </Link>
      )}
      {pages.map((p, i) =>
        p === '...' ? (
          <span key={`ellipsis-${i}`} className="px-3 py-2 text-gray-400">…</span>
        ) : (
          <Link
            key={p}
            href={buildUrl(p)}
            className={`w-9 h-9 flex items-center justify-center rounded-lg text-sm font-medium ${
              p === page
                ? 'bg-brand-600 text-white'
                : 'hover:bg-gray-100 text-gray-700'
            }`}
          >
            {p}
          </Link>
        )
      )}
      {page < totalPages && (
        <Link href={buildUrl(page + 1)} className="p-2 rounded-lg hover:bg-gray-100 text-gray-500">
          <ChevronRight size={18} />
        </Link>
      )}
    </div>
  );
}
