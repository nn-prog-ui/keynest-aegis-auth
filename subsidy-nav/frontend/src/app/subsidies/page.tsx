import { Suspense } from 'react';
import type { Metadata } from 'next';
import { getSubsidies, getPrefectures } from '@/lib/api';
import { SearchParams } from '@/types';
import SubsidyCard from '@/components/SubsidyCard';
import SearchFilters from '@/components/SearchFilters';
import Pagination from '@/components/Pagination';

export const metadata: Metadata = { title: '補助金を探す' };

interface PageProps {
  searchParams: Promise<Record<string, string>>;
}

export default async function SubsidiesPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const page = parseInt(params.page || '1');

  const searchQuery: SearchParams = {
    keyword: params.keyword,
    prefectureCode: params.prefectureCode,
    categoryId: params.categoryId,
    status: params.status as SearchParams['status'],
    targetAudience: params.targetAudience as SearchParams['targetAudience'],
    sortBy: (params.sortBy as SearchParams['sortBy']) || 'newest',
    page,
    limit: 18,
  };

  const [result, prefectures] = await Promise.allSettled([
    getSubsidies(searchQuery),
    getPrefectures(),
  ]);

  const data = result.status === 'fulfilled' ? result.value : null;
  const prefs = prefectures.status === 'fulfilled' ? prefectures.value : [];

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">補助金・助成金を探す</h1>
        {data && (
          <p className="text-gray-600 mt-1">
            <span className="font-medium text-brand-700">{data.pagination.total.toLocaleString()}件</span>
            の補助金が見つかりました
          </p>
        )}
      </div>

      <div className="flex flex-col lg:flex-row gap-6">
        <aside className="w-full lg:w-64 flex-shrink-0">
          <Suspense>
            <SearchFilters prefectures={prefs} currentParams={params} />
          </Suspense>
        </aside>

        <div className="flex-1">
          {!data || data.data.length === 0 ? (
            <div className="card p-12 text-center text-gray-500">
              <div className="text-4xl mb-3">🔍</div>
              <p className="font-medium">補助金が見つかりませんでした</p>
              <p className="text-sm mt-1">検索条件を変えてお試しください</p>
            </div>
          ) : (
            <>
              <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-4">
                {data.data.map((subsidy) => (
                  <SubsidyCard key={subsidy.id} subsidy={subsidy} />
                ))}
              </div>
              <div className="mt-8">
                <Pagination
                  total={data.pagination.total}
                  page={data.pagination.page}
                  totalPages={data.pagination.totalPages}
                  params={params}
                />
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
