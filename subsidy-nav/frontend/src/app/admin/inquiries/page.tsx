'use client';
import { useEffect, useState } from 'react';

interface Inquiry {
  id: number;
  name: string;
  company?: string;
  email: string;
  inquiryType: string;
  message: string;
  status: string;
  createdAt: string;
}

const TYPE_MAP: Record<string, string> = { GENERAL: '一般', MATCHING: 'マッチング', APPLICATION_SUPPORT: '申請サポート', DOCUMENT_CREATION: '書類作成', OTHER: 'その他' };
const STATUS_MAP: Record<string, string> = { NEW: '新規', IN_PROGRESS: '対応中', RESOLVED: '解決済', CLOSED: 'クローズ' };

export default function AdminInquiriesPage() {
  const [inquiries, setInquiries] = useState<Inquiry[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/admin/inquiries')
      .then(r => r.json())
      .then(setInquiries)
      .finally(() => setLoading(false));
  }, []);

  const updateStatus = async (id: number, status: string) => {
    await fetch(`/api/admin/inquiries/${id}`, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ status }) });
    setInquiries(prev => prev.map(i => i.id === id ? { ...i, status } : i));
  };

  if (loading) return <div className="max-w-5xl mx-auto px-4 py-8 text-gray-500">読み込み中...</div>;

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">お問い合わせ管理</h1>
      <div className="space-y-4">
        {inquiries.map(i => (
          <div key={i.id} className="bg-white rounded-xl border border-gray-200 p-5">
            <div className="flex items-start justify-between mb-3">
              <div>
                <span className="font-semibold text-gray-800">{i.name}</span>
                {i.company && <span className="text-gray-500 text-sm ml-2">（{i.company}）</span>}
                <span className="ml-2 text-xs bg-blue-50 text-blue-600 px-2 py-0.5 rounded">{TYPE_MAP[i.inquiryType]}</span>
              </div>
              <select value={i.status} onChange={e => updateStatus(i.id, e.target.value)} className="text-xs border border-gray-300 rounded px-2 py-1">
                {Object.entries(STATUS_MAP).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
              </select>
            </div>
            <p className="text-sm text-gray-600 mb-2">{i.message}</p>
            <div className="text-xs text-gray-400">{i.email} · {new Date(i.createdAt).toLocaleDateString('ja-JP')}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
