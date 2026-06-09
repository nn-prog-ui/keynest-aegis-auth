'use client';
import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback } from 'react';

interface Prefecture { code: string; name: string; }
interface Category { slug: string; name: string; }

interface Props {
  prefectures: Prefecture[];
  categories: Category[];
}

export default function SearchFilters({ prefectures, categories }: Props) {
  const router = useRouter();
  const searchParams = useSearchParams();

  const updateParam = useCallback((key: string, value: string) => {
    const params = new URLSearchParams(searchParams.toString());
    if (value) params.set(key, value); else params.delete(key);
    params.delete('page');
    router.push(`/subsidies?${params.toString()}`);
  }, [router, searchParams]);

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5 space-y-4">
      <h2 className="font-semibold text-gray-700">絞り込み</h2>
      <div>
        <label className="block text-xs text-gray-500 mb-1">キーワード</label>
        <input
          type="text"
          defaultValue={searchParams.get('keyword') || ''}
          onBlur={e => updateParam('keyword', e.target.value)}
          onKeyDown={e => { if (e.key === 'Enter') updateParam('keyword', (e.target as HTMLInputElement).value); }}
          placeholder="補助金名・内容で検索"
          className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>
      <div>
        <label className="block text-xs text-gray-500 mb-1">都道府県</label>
        <select onChange={e => updateParam('prefecture', e.target.value)} defaultValue={searchParams.get('prefecture') || ''} className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
          <option value="">すべて</option>
          {prefectures.map(p => <option key={p.code} value={p.code}>{p.name}</option>)}
        </select>
      </div>
      <div>
        <label className="block text-xs text-gray-500 mb-1">カテゴリ</label>
        <select onChange={e => updateParam('category', e.target.value)} defaultValue={searchParams.get('category') || ''} className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
          <option value="">すべて</option>
          {categories.map(c => <option key={c.slug} value={c.slug}>{c.name}</option>)}
        </select>
      </div>
      <div>
        <label className="block text-xs text-gray-500 mb-1">対象者</label>
        <select onChange={e => updateParam('audience', e.target.value)} defaultValue={searchParams.get('audience') || ''} className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
          <option value="">すべて</option>
          <option value="CORPORATION">法人・企業</option>
          <option value="INDIVIDUAL">個人</option>
          <option value="STARTUP">スタートアップ</option>
          <option value="FARMER">農業者</option>
          <option value="NONPROFIT">NPO・非営利</option>
          <option value="ELDERLY">高齢者</option>
          <option value="CHILD">子ども・子育て</option>
          <option value="DISABLED">障害者</option>
        </select>
      </div>
      <div>
        <label className="block text-xs text-gray-500 mb-1">ステータス</label>
        <select onChange={e => updateParam('status', e.target.value)} defaultValue={searchParams.get('status') || 'ACTIVE'} className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
          <option value="ACTIVE">受付中</option>
          <option value="UPCOMING">近日開始</option>
          <option value="">すべて</option>
        </select>
      </div>
      <label className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
        <input type="checkbox" checked={searchParams.get('isNational') === 'true'} onChange={e => updateParam('isNational', e.target.checked ? 'true' : '')} className="rounded" />
        全国対象のみ
      </label>
    </div>
  );
}
