'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  FileText,
  MessageSquare,
  Bell,
  RefreshCw,
  TrendingUp,
  AlertCircle,
} from 'lucide-react';

const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

interface Stats {
  total: number;
  active: number;
  endingSoon: number;
}

interface ScraperStats {
  total: number;
  success: number;
  error: number;
  totalSaved: number;
  lastRun: string | null;
}

export default function AdminDashboard() {
  const [apiKey, setApiKey] = useState('');
  const [authenticated, setAuthenticated] = useState(false);
  const [stats, setStats] = useState<Stats | null>(null);
  const [scraperStats, setScraperStats] = useState<ScraperStats | null>(null);
  const [inquiryCount, setInquiryCount] = useState<number | null>(null);
  const [alertCount, setAlertCount] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [scraperRunning, setScraperRunning] = useState(false);

  async function login() {
    setLoading(true);
    try {
      const res = await fetch(`${API}/api/admin/subsidies`, {
        headers: { 'x-admin-key': apiKey },
      });
      if (res.ok) {
        setAuthenticated(true);
        localStorage.setItem('admin-key', apiKey);
        loadData(apiKey);
      } else {
        alert('APIキーが正しくありません');
      }
    } finally {
      setLoading(false);
    }
  }

  async function loadData(key: string) {
    const headers = { 'x-admin-key': key };
    const [statsRes, scraperRes, inquiriesRes, alertsRes] = await Promise.allSettled([
      fetch(`${API}/api/subsidies/stats`).then((r) => r.json()),
      fetch(`${API}/api/scraper/stats`, { headers }).then((r) => r.json()),
      fetch(`${API}/api/admin/inquiries`, { headers }).then((r) => r.json()),
      fetch(`${API}/api/admin/alerts`, { headers }).then((r) => r.json()),
    ]);

    if (statsRes.status === 'fulfilled') setStats(statsRes.value);
    if (scraperRes.status === 'fulfilled') setScraperStats(scraperRes.value);
    if (inquiriesRes.status === 'fulfilled') setInquiryCount(inquiriesRes.value.length);
    if (alertsRes.status === 'fulfilled') setAlertCount(alertsRes.value.length);
  }

  useEffect(() => {
    const saved = localStorage.getItem('admin-key');
    if (saved) {
      setApiKey(saved);
      setAuthenticated(true);
      loadData(saved);
    }
  }, []);

  async function runScraper() {
    setScraperRunning(true);
    try {
      await fetch(`${API}/api/scraper/run-all`, {
        method: 'POST',
        headers: { 'x-admin-key': apiKey },
      });
      alert('スクレイピングを開始しました（バックグラウンドで実行中）');
      setTimeout(() => loadData(apiKey), 5000);
    } finally {
      setScraperRunning(false);
    }
  }

  if (!authenticated) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="bg-white rounded-xl p-8 w-full max-w-sm shadow-xl">
          <h1 className="text-xl font-bold mb-6 text-center">管理者ログイン</h1>
          <input
            type="password"
            value={apiKey}
            onChange={(e) => setApiKey(e.target.value)}
            placeholder="管理者APIキー"
            onKeyDown={(e) => e.key === 'Enter' && login()}
            className="w-full border border-gray-300 rounded-lg px-3 py-2.5 mb-4 focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
          <button onClick={login} disabled={loading} className="btn-primary w-full justify-center">
            {loading ? 'ログイン中...' : 'ログイン'}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-2xl font-bold">管理ダッシュボード</h1>
        <div className="flex gap-3">
          <button
            onClick={runScraper}
            disabled={scraperRunning}
            className="btn-secondary text-sm"
          >
            <RefreshCw size={15} className={scraperRunning ? 'animate-spin' : ''} />
            スクレイピング実行
          </button>
          <button
            onClick={() => loadData(apiKey)}
            className="btn-secondary text-sm"
          >
            <RefreshCw size={15} />
            更新
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <StatCard
          icon={<FileText className="text-brand-600" size={22} />}
          label="補助金総数"
          value={stats?.total ?? '—'}
          sub="件登録"
        />
        <StatCard
          icon={<TrendingUp className="text-green-600" size={22} />}
          label="受付中"
          value={stats?.active ?? '—'}
          sub="件"
        />
        <StatCard
          icon={<MessageSquare className="text-orange-500" size={22} />}
          label="コンサル相談"
          value={inquiryCount ?? '—'}
          sub="件"
        />
        <StatCard
          icon={<Bell className="text-purple-600" size={22} />}
          label="アラート登録"
          value={alertCount ?? '—'}
          sub="人"
        />
      </div>

      {/* Nav Cards */}
      <div className="grid md:grid-cols-3 gap-4 mb-8">
        <Link href="/admin/subsidies" className="card p-5 hover:shadow-md hover:border-brand-300 transition-all">
          <FileText size={24} className="text-brand-600 mb-3" />
          <h2 className="font-bold mb-1">補助金管理</h2>
          <p className="text-sm text-gray-600">補助金の登録・編集・削除</p>
        </Link>
        <Link href="/admin/inquiries" className="card p-5 hover:shadow-md hover:border-brand-300 transition-all">
          <MessageSquare size={24} className="text-orange-500 mb-3" />
          <h2 className="font-bold mb-1">問い合わせ管理</h2>
          <p className="text-sm text-gray-600">コンサル相談・問い合わせの確認</p>
        </Link>
        <Link href="/admin/scraper" className="card p-5 hover:shadow-md hover:border-brand-300 transition-all">
          <RefreshCw size={24} className="text-green-600 mb-3" />
          <h2 className="font-bold mb-1">スクレイピング管理</h2>
          <p className="text-sm text-gray-600">自動収集の状況・ログ確認</p>
        </Link>
      </div>

      {/* Scraper Stats */}
      {scraperStats && (
        <div className="card p-5">
          <h2 className="font-bold mb-4">スクレイピング状況</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div>
              <div className="text-gray-500">総実行回数</div>
              <div className="font-bold text-lg">{scraperStats.total}</div>
            </div>
            <div>
              <div className="text-gray-500">成功</div>
              <div className="font-bold text-lg text-green-600">{scraperStats.success}</div>
            </div>
            <div>
              <div className="text-gray-500">エラー</div>
              <div className="font-bold text-lg text-red-600">{scraperStats.error}</div>
            </div>
            <div>
              <div className="text-gray-500">取得済み補助金</div>
              <div className="font-bold text-lg">{scraperStats.totalSaved}件</div>
            </div>
          </div>
          {scraperStats.lastRun && (
            <p className="text-xs text-gray-500 mt-3">
              最終実行: {new Date(scraperStats.lastRun).toLocaleString('ja-JP')}
            </p>
          )}
        </div>
      )}

      {stats?.endingSoon && stats.endingSoon > 0 ? (
        <div className="mt-4 flex items-center gap-2 bg-red-50 border border-red-200 rounded-lg px-4 py-3 text-sm text-red-700">
          <AlertCircle size={16} />
          <span>2週間以内に締め切りの補助金が <strong>{stats.endingSoon}件</strong> あります</span>
        </div>
      ) : null}
    </div>
  );
}

function StatCard({
  icon,
  label,
  value,
  sub,
}: {
  icon: React.ReactNode;
  label: string;
  value: number | string;
  sub: string;
}) {
  return (
    <div className="card p-5">
      <div className="flex items-center gap-3 mb-2">
        <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
          {icon}
        </div>
        <div className="text-sm text-gray-600">{label}</div>
      </div>
      <div className="text-2xl font-bold">
        {value}
        <span className="text-sm font-normal text-gray-500 ml-1">{sub}</span>
      </div>
    </div>
  );
}
