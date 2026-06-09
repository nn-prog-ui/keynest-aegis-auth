import Link from 'next/link';
import { notFound } from 'next/navigation';

const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

async function getSubsidy(id: string) {
  const res = await fetch(`${API}/api/subsidies/${id}`, { next: { revalidate: 300 } });
  if (!res.ok) return null;
  return res.json();
}

export default async function SubsidyDetailPage({ params }: { params: { id: string } }) {
  const subsidy = await getSubsidy(params.id);
  if (!subsidy) notFound();

  const daysLeft = subsidy.applicationEnd
    ? Math.ceil((new Date(subsidy.applicationEnd).getTime() - Date.now()) / (1000 * 60 * 60 * 24))
    : null;

  const audienceMap: Record<string, string> = {
    INDIVIDUAL: '個人', CORPORATION: '法人・企業', FARMER: '農業者',
    NONPROFIT: 'NPO・非営利', STARTUP: 'スタートアップ', ELDERLY: '高齢者',
    CHILD: '子ども・子育て', DISABLED: '障害者',
  };

  return (
    <div className="max-w-3xl mx-auto px-4 py-8">
      <Link href="/subsidies" className="text-blue-600 text-sm hover:underline mb-4 inline-block">← 一覧に戻る</Link>

      <div className="bg-white rounded-xl border border-gray-200 p-8">
        <div className="flex items-start justify-between gap-3 mb-4">
          <h1 className="text-2xl font-bold text-gray-800">{subsidy.title}</h1>
          <span className={`shrink-0 text-sm px-3 py-1 rounded-full font-medium ${
            subsidy.status === 'ACTIVE' ? 'bg-green-100 text-green-700' :
            subsidy.status === 'UPCOMING' ? 'bg-yellow-100 text-yellow-700' :
            'bg-gray-100 text-gray-600'
          }`}>
            {subsidy.status === 'ACTIVE' ? '受付中' : subsidy.status === 'UPCOMING' ? '近日開始' : '終了'}
          </span>
        </div>

        <p className="text-gray-600 mb-6 leading-relaxed">{subsidy.description}</p>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          {subsidy.maxAmount && (
            <div className="bg-green-50 rounded-lg p-4">
              <div className="text-xs text-green-600 mb-1">補助上限額</div>
              <div className="text-xl font-bold text-green-700">{Number(subsidy.maxAmount).toLocaleString()}円</div>
            </div>
          )}
          {subsidy.subsidyRate && (
            <div className="bg-blue-50 rounded-lg p-4">
              <div className="text-xs text-blue-600 mb-1">補助率</div>
              <div className="text-xl font-bold text-blue-700">{Math.round(subsidy.subsidyRate * 100)}%</div>
            </div>
          )}
          {subsidy.applicationEnd && (
            <div className={`rounded-lg p-4 ${daysLeft && daysLeft <= 30 ? 'bg-red-50' : 'bg-gray-50'}`}>
              <div className={`text-xs mb-1 ${daysLeft && daysLeft <= 30 ? 'text-red-600' : 'text-gray-500'}`}>申請期限</div>
              <div className={`font-bold ${daysLeft && daysLeft <= 30 ? 'text-red-700' : 'text-gray-700'}`}>
                {new Date(subsidy.applicationEnd).toLocaleDateString('ja-JP')}
                {daysLeft !== null && daysLeft > 0 && <span className="text-sm ml-2">（残り{daysLeft}日）</span>}
              </div>
            </div>
          )}
          {subsidy.applicationStart && (
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="text-xs text-gray-500 mb-1">申請開始</div>
              <div className="font-bold text-gray-700">{new Date(subsidy.applicationStart).toLocaleDateString('ja-JP')}</div>
            </div>
          )}
        </div>

        {subsidy.targetAudiences?.length > 0 && (
          <div className="mb-4">
            <div className="text-xs text-gray-500 mb-2">対象者</div>
            <div className="flex flex-wrap gap-2">
              {subsidy.targetAudiences.map((a: string) => (
                <span key={a} className="bg-purple-50 text-purple-700 px-3 py-1 rounded-full text-sm">{audienceMap[a] || a}</span>
              ))}
            </div>
          </div>
        )}

        {subsidy.requirements && (
          <div className="mb-4">
            <div className="text-xs text-gray-500 mb-2">要件・条件</div>
            <p className="text-sm text-gray-700 bg-gray-50 rounded-lg p-4 leading-relaxed">{subsidy.requirements}</p>
          </div>
        )}

        {subsidy.municipality && (
          <div className="mb-4 text-sm text-gray-600">
            <span className="font-medium">対象地域：</span>{subsidy.municipality.prefecture.name} / {subsidy.municipality.name}
          </div>
        )}
        {subsidy.isNational && <div className="mb-4 text-sm text-blue-600 font-medium">全国対象</div>}

        {subsidy.sourceUrl && (
          <a href={subsidy.sourceUrl} target="_blank" rel="noopener noreferrer" className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition font-medium mr-3">
            公式サイトで詳細を見る →
          </a>
        )}
        <Link href="/templates" className="inline-block border border-blue-600 text-blue-600 px-6 py-3 rounded-lg hover:bg-blue-50 transition font-medium">
          申請書テンプレートを作成
        </Link>
      </div>
    </div>
  );
}
