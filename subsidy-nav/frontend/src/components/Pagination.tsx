import Link from 'next/link';

interface Props {
  currentPage: number;
  totalPages: number;
  baseUrl: string;
}

export default function Pagination({ currentPage, totalPages, baseUrl }: Props) {
  if (totalPages <= 1) return null;

  const pages = Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
    const start = Math.max(1, Math.min(currentPage - 2, totalPages - 4));
    return start + i;
  });

  return (
    <div className="flex items-center justify-center gap-2 mt-8">
      {currentPage > 1 && (
        <Link href={`${baseUrl}&page=${currentPage - 1}`} className="px-3 py-2 rounded border border-gray-300 text-sm hover:bg-gray-50">前へ</Link>
      )}
      {pages.map(p => (
        <Link key={p} href={`${baseUrl}&page=${p}`} className={`px-3 py-2 rounded border text-sm ${p === currentPage ? 'bg-blue-600 text-white border-blue-600' : 'border-gray-300 hover:bg-gray-50'}`}>{p}</Link>
      ))}
      {currentPage < totalPages && (
        <Link href={`${baseUrl}&page=${currentPage + 1}`} className="px-3 py-2 rounded border border-gray-300 text-sm hover:bg-gray-50">次へ</Link>
      )}
    </div>
  );
}
