import { Suspense } from 'react';
import SubsidyCard from '@/components/SubsidyCard';
import SearchFilters from '@/components/SearchFilters';
import Pagination from '@/components/Pagination';

const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

async function getSubsidies(params: Record<string, string>) {
  const q = new URLSearchParams({ ...params, limit: '20' });
  const res = await fetch(`${API}/api/subsidies?${q}`, { next: { revalidate: 60 } });
  if (!res.ok) return { subsidies: [], total: 0 };
  return res.json();
}

async function getMeta() {
  const [pRes, cRes] = await Promise.all([
    fetch(`${API}/api/subsidies/meta/prefectures`, { next: { revalidate: 3600 } }),
    fetch(`${API}/api/subsidies/meta/categories`, { next: { revalidate: 3600 } }),
  ]);
  const prefectures = pRes.ok ? await pRes.json() : [];
  const categories = cRes.ok ? await cRes.json() : [];
  return { prefectures, categories };
}

export default async function SubsidiesPage({ searchParams }: { searchParams: Record<string, string> }) {
  const page = parseInt(searchParams.page || '1');
  const [data, meta] = await Promise.all([
    getSubsidies({ ...searchParams, page: String(page) }),
    getMeta(),
  ]);

  const totalPages = Math.ceil(data.total / 20);
  const baseUrl = `/subsidies?${new URLSearchParams({ ...searchParams, page: '' }).toString()}`;

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">補助金・助成金を検索</h1>
      <div className="flex flex-col md:flex-row gap-6">
        <aside className="w-full md:w-64 shrink-0">
          <Suspense>
            <SearchFilters prefectures={meta.prefectures} categories={meta.categories} />
          </Suspense>
        </aside>
        <div className="flex-1">
          <div className="flex items-center justify-between mb-4">
            <p className="text-gray-600 text-sm"><span className="font-semibold text-gray-800">{data.total.toLocaleString()}</span>件の補助金</p>
          </div>
          {data.subsidies.length === 0 ? (
            <div className="bg-white rounded-xl border border-gray-200 p-12 text-center text-gray-500">
              該当する補助金が見つかりませんでした
            </div>
          ) : (
            <div className="space-y-4">
              {data.subsidies.map((s: { id: number; title: string; description: string; maxAmount?: number; subsidyRate?: number; applicationEnd?: string; status: string; isNational: boolean; municipality?: { name: string; prefecture: { name: string } }; category?: { name: string } }) => (
                <SubsidyCard key={s.id} subsidy={s} />
              ))}
            </div>
          )}
          <Pagination currentPage={page} totalPages={totalPages} baseUrl={baseUrl} />
        </div>
      </div>
    </div>
  );
}
