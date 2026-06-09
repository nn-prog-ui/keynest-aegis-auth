'use client';

import { useRouter } from 'next/navigation';
import { Prefecture } from '@/types';

const CATEGORIES = [
  { id: '1', name: '子育て・教育支援' },
  { id: '2', name: '住宅・リフォーム' },
  { id: '3', name: '創業・事業拡大' },
  { id: '4', name: '農業・林業・水産業' },
  { id: '5', name: '福祉・障害者支援' },
  { id: '6', name: '省エネ・環境' },
  { id: '7', name: '高齢者支援' },
  { id: '8', name: '防災・災害復興' },
  { id: '9', name: '観光・地域活性化' },
  { id: '10', name: 'IT・デジタル化' },
];

const AUDIENCES = [
  { value: 'INDIVIDUAL', label: '個人' },
  { value: 'CORPORATION', label: '法人・中小企業' },
  { value: 'STARTUP', label: '創業者' },
  { value: 'FARMER', label: '農業者' },
  { value: 'CHILD', label: '子育て世帯' },
  { value: 'ELDERLY', label: '高齢者' },
];

interface Props {
  prefectures: Prefecture[];
  currentParams: Record<string, string>;
}

export default function SearchFilters({ prefectures, currentParams }: Props) {
  const router = useRouter();

  function update(key: string, value: string) {
    const p = new URLSearchParams(currentParams);
    if (value) p.set(key, value);
    else p.delete(key);
    p.set('page', '1');
    router.push(`/subsidies?${p.toString()}`);
  }

  return (
    <div className="space-y-5">
      <div className="card p-4">
        <h3 className="font-bold text-sm mb-3 text-gray-700">ステータス</h3>
        <div className="space-y-1">
          {[
            { value: '', label: 'すべて' },
            { value: 'ACTIVE', label: '受付中' },
            { value: 'UPCOMING', label: '公募前' },
          ].map((opt) => (
            <label key={opt.value} className="flex items-center gap-2 cursor-pointer py-1">
              <input
                type="radio"
                name="status"
                value={opt.value}
                checked={(currentParams.status || '') === opt.value}
                onChange={() => update('status', opt.value)}
                className="accent-brand-600"
              />
              <span className="text-sm">{opt.label}</span>
            </label>
          ))}
        </div>
      </div>

      <div className="card p-4">
        <h3 className="font-bold text-sm mb-3 text-gray-700">都道府県</h3>
        <select
          className="w-full text-sm border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-500"
          value={currentParams.prefectureCode || ''}
          onChange={(e) => update('prefectureCode', e.target.value)}
        >
          <option value="">全ての都道府県</option>
          {prefectures.map((p) => (
            <option key={p.code} value={p.code}>{p.name}</option>
          ))}
        </select>
      </div>

      <div className="card p-4">
        <h3 className="font-bold text-sm mb-3 text-gray-700">カテゴリ</h3>
        <div className="space-y-1">
          <label className="flex items-center gap-2 cursor-pointer py-1">
            <input
              type="radio"
              name="categoryId"
              value=""
              checked={!currentParams.categoryId}
              onChange={() => update('categoryId', '')}
              className="accent-brand-600"
            />
            <span className="text-sm">すべて</span>
          </label>
          {CATEGORIES.map((cat) => (
            <label key={cat.id} className="flex items-center gap-2 cursor-pointer py-1">
              <input
                type="radio"
                name="categoryId"
                value={cat.id}
                checked={currentParams.categoryId === cat.id}
                onChange={() => update('categoryId', cat.id)}
                className="accent-brand-600"
              />
              <span className="text-sm">{cat.name}</span>
            </label>
          ))}
        </div>
      </div>

      <div className="card p-4">
        <h3 className="font-bold text-sm mb-3 text-gray-700">対象者</h3>
        <div className="space-y-1">
          <label className="flex items-center gap-2 cursor-pointer py-1">
            <input
              type="radio"
              name="targetAudience"
              value=""
              checked={!currentParams.targetAudience}
              onChange={() => update('targetAudience', '')}
              className="accent-brand-600"
            />
            <span className="text-sm">すべて</span>
          </label>
          {AUDIENCES.map((a) => (
            <label key={a.value} className="flex items-center gap-2 cursor-pointer py-1">
              <input
                type="radio"
                name="targetAudience"
                value={a.value}
                checked={currentParams.targetAudience === a.value}
                onChange={() => update('targetAudience', a.value)}
                className="accent-brand-600"
              />
              <span className="text-sm">{a.label}</span>
            </label>
          ))}
        </div>
      </div>

      <div className="card p-4">
        <h3 className="font-bold text-sm mb-3 text-gray-700">並び順</h3>
        <select
          className="w-full text-sm border border-gray-300 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-500"
          value={currentParams.sortBy || 'newest'}
          onChange={(e) => update('sortBy', e.target.value)}
        >
          <option value="newest">新着順</option>
          <option value="deadline">締め切りが近い順</option>
          <option value="amount">補助額が多い順</option>
        </select>
      </div>

      <div className="card p-4">
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={currentParams.isNational === 'true'}
            onChange={(e) => update('isNational', e.target.checked ? 'true' : '')}
            className="accent-brand-600"
          />
          <span className="text-sm font-medium">国の補助金のみ</span>
        </label>
      </div>
    </div>
  );
}
