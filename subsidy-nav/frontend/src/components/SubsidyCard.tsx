import Link from 'next/link';

interface Subsidy {
  id: number;
  title: string;
  description: string;
  maxAmount?: bigint | number | null;
  subsidyRate?: number | null;
  applicationEnd?: string | null;
  status: string;
  isNational: boolean;
  municipality?: { name: string; prefecture: { name: string } } | null;
  category?: { name: string } | null;
}

export default function SubsidyCard({ subsidy }: { subsidy: Subsidy }) {
  const daysLeft = subsidy.applicationEnd
    ? Math.ceil((new Date(subsidy.applicationEnd).getTime() - Date.now()) / (1000 * 60 * 60 * 24))
    : null;

  return (
    <Link href={`/subsidies/${subsidy.id}`} className="block bg-white rounded-xl border border-gray-200 p-5 hover:shadow-md hover:border-blue-300 transition">
      <div className="flex items-start justify-between gap-3 mb-3">
        <h3 className="font-semibold text-gray-800 leading-snug line-clamp-2">{subsidy.title}</h3>
        <span className={`shrink-0 text-xs px-2 py-1 rounded-full font-medium ${
          subsidy.status === 'ACTIVE' ? 'bg-green-100 text-green-700' :
          subsidy.status === 'UPCOMING' ? 'bg-yellow-100 text-yellow-700' :
          'bg-gray-100 text-gray-600'
        }`}>
          {subsidy.status === 'ACTIVE' ? '受付中' : subsidy.status === 'UPCOMING' ? '近日開始' : '終了'}
        </span>
      </div>
      <p className="text-gray-500 text-sm line-clamp-2 mb-3">{subsidy.description}</p>
      <div className="flex flex-wrap gap-2 text-xs">
        {subsidy.isNational && <span className="bg-blue-50 text-blue-600 px-2 py-1 rounded">全国対象</span>}
        {subsidy.municipality && (
          <span className="bg-gray-100 text-gray-600 px-2 py-1 rounded">
            {subsidy.municipality.prefecture.name} / {subsidy.municipality.name}
          </span>
        )}
        {subsidy.category && <span className="bg-purple-50 text-purple-600 px-2 py-1 rounded">{subsidy.category.name}</span>}
        {subsidy.maxAmount && (
          <span className="bg-green-50 text-green-700 px-2 py-1 rounded font-medium">
            最大 {Number(subsidy.maxAmount).toLocaleString()}円
          </span>
        )}
        {daysLeft !== null && daysLeft <= 30 && daysLeft > 0 && (
          <span className="bg-red-50 text-red-600 px-2 py-1 rounded font-medium">
            残り{daysLeft}日
          </span>
        )}
      </div>
    </Link>
  );
}
