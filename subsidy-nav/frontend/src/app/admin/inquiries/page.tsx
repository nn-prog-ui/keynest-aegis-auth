'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { ChevronLeft, Mail, Phone, Building, Clock } from 'lucide-react';

const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

const INQUIRY_LABELS: Record<string, string> = {
  SUBSIDY_SEARCH: '補助金の探し方',
  APPLICATION_HELP: '申請サポート',
  CONSULTING: 'コンサルティング',
  OTHER: 'その他',
};

const STATUS_LABELS: Record<string, string> = {
  NEW: '新規',
  IN_PROGRESS: '対応中',
  RESOLVED: '完了',
};

const STATUS_COLORS: Record<string, string> = {
  NEW: 'bg-red-100 text-red-700',
  IN_PROGRESS: 'bg-yellow-100 text-yellow-700',
  RESOLVED: 'bg-green-100 text-green-700',
};

interface Inquiry {
  id: number;
  name: string;
  email: string;
  phone: string | null;
  companyName: string | null;
  inquiryType: string;
  message: string;
  status: string;
  createdAt: string;
}

export default function AdminInquiriesPage() {
  const apiKey = typeof window !== 'undefined' ? localStorage.getItem('admin-key') || '' : '';
  const [inquiries, setInquiries] = useState<Inquiry[]>([]);
  const [selected, setSelected] = useState<Inquiry | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`${API}/api/admin/inquiries`, {
      headers: { 'x-admin-key': apiKey },
    })
      .then((r) => r.json())
      .then((data) => {
        setInquiries(data);
        setLoading(false);
      });
  }, []);

  async function updateStatus(id: number, status: string) {
    // 管理者エンドポイントでステータス更新（PUTを使用）
    // 簡易実装: ローカルステートのみ更新
    setInquiries((prev) =>
      prev.map((i) => (i.id === id ? { ...i, status } : i))
    );
    if (selected?.id === id) setSelected((prev) => prev ? { ...prev, status } : null);
  }

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/admin" className="text-gray-500 hover:text-gray-800">
          <ChevronLeft size={20} />
        </Link>
        <h1 className="text-xl font-bold">問い合わせ管理</h1>
        <span className="text-sm text-gray-500 ml-auto">{inquiries.length}件</span>
      </div>

      <div className="flex gap-4">
        {/* List */}
        <div className="w-80 flex-shrink-0 space-y-2">
          {loading ? (
            <div className="text-center py-8 text-gray-500 text-sm">読み込み中...</div>
          ) : (
            inquiries.map((inq) => (
              <button
                key={inq.id}
                onClick={() => setSelected(inq)}
                className={`w-full text-left card p-4 hover:border-brand-300 transition-all ${
                  selected?.id === inq.id ? 'border-brand-400 bg-blue-50' : ''
                }`}
              >
                <div className="flex items-start justify-between mb-1">
                  <span className="font-medium text-sm">{inq.name}</span>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${STATUS_COLORS[inq.status]}`}>
                    {STATUS_LABELS[inq.status]}
                  </span>
                </div>
                <div className="text-xs text-gray-500">
                  {INQUIRY_LABELS[inq.inquiryType]}
                </div>
                <div className="text-xs text-gray-400 mt-1">
                  {new Date(inq.createdAt).toLocaleDateString('ja-JP')}
                </div>
              </button>
            ))
          )}
        </div>

        {/* Detail */}
        {selected ? (
          <div className="flex-1 card p-6">
            <div className="flex items-start justify-between mb-5">
              <div>
                <h2 className="text-lg font-bold">{selected.name}</h2>
                <div className="text-sm text-gray-500 mt-0.5">
                  {INQUIRY_LABELS[selected.inquiryType]}
                </div>
              </div>
              <select
                value={selected.status}
                onChange={(e) => updateStatus(selected.id, e.target.value)}
                className="text-sm border border-gray-300 rounded-lg px-3 py-1.5"
              >
                {Object.entries(STATUS_LABELS).map(([v, l]) => (
                  <option key={v} value={v}>{l}</option>
                ))}
              </select>
            </div>

            <div className="space-y-3 mb-5">
              <InfoLine icon={<Mail size={14} />} label={selected.email} />
              {selected.phone && <InfoLine icon={<Phone size={14} />} label={selected.phone} />}
              {selected.companyName && (
                <InfoLine icon={<Building size={14} />} label={selected.companyName} />
              )}
              <InfoLine
                icon={<Clock size={14} />}
                label={new Date(selected.createdAt).toLocaleString('ja-JP')}
              />
            </div>

            <div className="bg-gray-50 rounded-lg p-4 text-sm text-gray-700 whitespace-pre-wrap leading-relaxed">
              {selected.message}
            </div>

            <div className="flex gap-3 mt-5">
              <a
                href={`mailto:${selected.email}`}
                className="btn-primary text-sm py-2"
              >
                <Mail size={14} />
                メールで返信
              </a>
            </div>
          </div>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            左のリストから問い合わせを選択してください
          </div>
        )}
      </div>
    </div>
  );
}

function InfoLine({ icon, label }: { icon: React.ReactNode; label: string }) {
  return (
    <div className="flex items-center gap-2 text-sm text-gray-600">
      <span className="text-gray-400">{icon}</span>
      {label}
    </div>
  );
}
