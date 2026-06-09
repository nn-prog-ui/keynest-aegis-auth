'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { ChevronLeft, RefreshCw, CheckCircle, XCircle } from 'lucide-react';

const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

interface ScrapeLog {
  id: number;
  municipalityCode: string;
  url: string;
  scrapedCount: number;
  savedCount: number;
  status: 'SUCCESS' | 'ERROR';
  errorMessage: string | null;
  createdAt: string;
}

interface ScraperStats {
  total: number;
  success: number;
  error: number;
  totalSaved: number;
  lastRun: string | null;
}

export default function AdminScraperPage() {
  const apiKey = typeof window !== 'undefined' ? localStorage.getItem('admin-key') || '' : '';
  const [logs, setLogs] = useState<ScrapeLog[]>([]);
  const [stats, setStats] = useState<ScraperStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [running, setRunning] = useState(false);

  async function load() {
    const [logsRes, statsRes] = await Promise.allSettled([
      fetch(`${API}/api/scraper/logs?limit=50`, {
        headers: { 'x-admin-key': apiKey },
      }).then((r) => r.json()),
      fetch(`${API}/api/scraper/stats`, {
        headers: { 'x-admin-key': apiKey },
      }).then((r) => r.json()),
    ]);
    if (logsRes.status === 'fulfilled') setLogs(logsRes.value);
    if (statsRes.status === 'fulfilled') setStats(statsRes.value);
    setLoading(false);
  }

  useEffect(() => { load(); }, []);

  async function runAll() {
    setRunning(true);
    await fetch(`${API}/api/scraper/run-all`, {
      method: 'POST',
      headers: { 'x-admin-key': apiKey },
    });
    setTimeout(() => {
      load();
      setRunning(false);
    }, 5000);
  }

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/admin" className="text-gray-500 hover:text-gray-800">
          <ChevronLeft size={20} />
        </Link>
        <h1 className="text-xl font-bold">スクレイピング管理</h1>
        <button
          onClick={runAll}
          disabled={running}
          className="ml-auto btn-primary text-sm"
        >
          <RefreshCw size={15} className={running ? 'animate-spin' : ''} />
          今すぐ実行
        </button>
      </div>

      {stats && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {[
            { label: '総実行数', value: stats.total },
            { label: '成功', value: stats.success, color: 'text-green-600' },
            { label: 'エラー', value: stats.error, color: 'text-red-600' },
            { label: '取得件数累計', value: `${stats.totalSaved}件` },
          ].map((s) => (
            <div key={s.label} className="card p-4">
              <div className="text-xs text-gray-500 mb-1">{s.label}</div>
              <div className={`text-xl font-bold ${s.color || ''}`}>{s.value}</div>
            </div>
          ))}
        </div>
      )}

      {stats?.lastRun && (
        <p className="text-sm text-gray-500 mb-4">
          最終実行: {new Date(stats.lastRun).toLocaleString('ja-JP')}（次回: 毎日 02:00）
        </p>
      )}

      <div className="card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-600">市区町村コード</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">URL</th>
              <th className="text-center px-4 py-3 font-medium text-gray-600">取得</th>
              <th className="text-center px-4 py-3 font-medium text-gray-600">保存</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">状態</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">実行日時</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={6} className="text-center py-10 text-gray-500">読み込み中...</td>
              </tr>
            ) : logs.length === 0 ? (
              <tr>
                <td colSpan={6} className="text-center py-10 text-gray-500">
                  ログがありません。スクレイピングを実行してください。
                </td>
              </tr>
            ) : (
              logs.map((log) => (
                <tr key={log.id} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-4 py-3 font-mono text-xs">{log.municipalityCode}</td>
                  <td className="px-4 py-3">
                    <a
                      href={log.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-brand-600 hover:underline truncate block max-w-xs text-xs"
                    >
                      {log.url}
                    </a>
                  </td>
                  <td className="px-4 py-3 text-center">{log.scrapedCount}</td>
                  <td className="px-4 py-3 text-center font-medium text-green-700">{log.savedCount}</td>
                  <td className="px-4 py-3">
                    {log.status === 'SUCCESS' ? (
                      <span className="flex items-center gap-1 text-green-700 text-xs">
                        <CheckCircle size={13} /> 成功
                      </span>
                    ) : (
                      <span className="flex items-center gap-1 text-red-600 text-xs" title={log.errorMessage || ''}>
                        <XCircle size={13} /> エラー
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-500">
                    {new Date(log.createdAt).toLocaleString('ja-JP')}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
