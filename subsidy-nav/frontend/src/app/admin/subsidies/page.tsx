'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Plus, Edit, Trash2, ExternalLink, ChevronLeft, Search } from 'lucide-react';
import { formatAmount, getStatusLabel } from '@/lib/utils';

const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

interface SubsidyRow {
  id: number;
  title: string;
  status: string;
  maxAmount: string | null;
  applicationEnd: string | null;
  category: { name: string; icon: string };
  prefecture: { name: string } | null;
  municipality: { name: string } | null;
  isNational: boolean;
  sourceUrl: string;
}

export default function AdminSubsidiesPage() {
  const apiKey = typeof window !== 'undefined' ? localStorage.getItem('admin-key') || '' : '';
  const [subsidies, setSubsidies] = useState<SubsidyRow[]>([]);
  const [filtered, setFiltered] = useState<SubsidyRow[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [deleteId, setDeleteId] = useState<number | null>(null);

  async function load() {
    setLoading(true);
    try {
      const res = await fetch(`${API}/api/admin/subsidies`, {
        headers: { 'x-admin-key': apiKey },
      });
      const data = await res.json();
      setSubsidies(data);
      setFiltered(data);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  useEffect(() => {
    if (!search) {
      setFiltered(subsidies);
    } else {
      const q = search.toLowerCase();
      setFiltered(
        subsidies.filter(
          (s) =>
            s.title.toLowerCase().includes(q) ||
            s.category.name.includes(q) ||
            (s.prefecture?.name.includes(q)) ||
            (s.municipality?.name.includes(q))
        )
      );
    }
  }, [search, subsidies]);

  async function handleDelete(id: number) {
    if (!confirm('この補助金を削除しますか？')) return;
    await fetch(`${API}/api/admin/subsidies/${id}`, {
      method: 'DELETE',
      headers: { 'x-admin-key': apiKey },
    });
    setDeleteId(null);
    load();
  }

  async function updateStatus(id: number, status: string) {
    await fetch(`${API}/api/admin/subsidies/${id}`, {
      method: 'PUT',
      headers: { 'x-admin-key': apiKey, 'Content-Type': 'application/json' },
      body: JSON.stringify({ status }),
    });
    load();
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/admin" className="text-gray-500 hover:text-gray-800">
          <ChevronLeft size={20} />
        </Link>
        <h1 className="text-xl font-bold">補助金管理</h1>
        <span className="text-sm text-gray-500 ml-auto">{filtered.length}件</span>
      </div>

      <div className="flex gap-3 mb-5">
        <div className="flex-1 relative">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="タイトル・カテゴリ・地域で絞り込み"
            className="w-full pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>
        <Link href="/admin/subsidies/new" className="btn-primary text-sm">
          <Plus size={15} />
          新規登録
        </Link>
      </div>

      {loading ? (
        <div className="text-center py-12 text-gray-500">読み込み中...</div>
      ) : (
        <div className="card overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-4 py-3 font-medium text-gray-600">補助金名</th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">カテゴリ</th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">地域</th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">補助額</th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">締切</th>
                <th className="text-left px-4 py-3 font-medium text-gray-600">ステータス</th>
                <th className="px-4 py-3" />
              </tr>
            </thead>
            <tbody>
              {filtered.map((s) => (
                <tr key={s.id} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <div className="font-medium max-w-xs truncate">{s.title}</div>
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {s.category.icon} {s.category.name}
                  </td>
                  <td className="px-4 py-3 text-gray-600 text-xs">
                    {s.isNational ? '全国' : s.municipality?.name || s.prefecture?.name || '—'}
                  </td>
                  <td className="px-4 py-3 text-gray-700 font-medium">
                    {s.maxAmount ? formatAmount(s.maxAmount) : '—'}
                  </td>
                  <td className="px-4 py-3 text-gray-600 text-xs">
                    {s.applicationEnd
                      ? new Date(s.applicationEnd).toLocaleDateString('ja-JP')
                      : '—'}
                  </td>
                  <td className="px-4 py-3">
                    <select
                      value={s.status}
                      onChange={(e) => updateStatus(s.id, e.target.value)}
                      className="text-xs border border-gray-300 rounded px-2 py-1"
                    >
                      <option value="UPCOMING">公募前</option>
                      <option value="ACTIVE">受付中</option>
                      <option value="ENDED">終了</option>
                    </select>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <a
                        href={s.sourceUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-gray-400 hover:text-brand-600"
                      >
                        <ExternalLink size={14} />
                      </a>
                      <button
                        onClick={() => handleDelete(s.id)}
                        className="text-gray-400 hover:text-red-600"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {filtered.length === 0 && (
            <div className="text-center py-10 text-gray-500">補助金が見つかりません</div>
          )}
        </div>
      )}
    </div>
  );
}
