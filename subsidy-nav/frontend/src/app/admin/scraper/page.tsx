'use client';
import { useEffect, useState } from 'react';

interface ScrapeLog {
  id: number;
  municipality: { name: string };
  startedAt: string;
  completedAt?: string;
  scraped: number;
  saved: number;
  errors: string[];
  success: boolean;
}

export default function AdminScraperPage() {
  const [logs, setLogs] = useState<ScrapeLog[]>([]);
  const [running, setRunning] = useState(false);
  const [loading, setLoading] = useState(true);

  const fetchLogs = () => {
    fetch('/api/admin/scrape-logs')
      .then(r => r.json())
      .then(setLogs)
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchLogs(); }, []);

  const runScraper = async () => {
    setRunning(true);
    try {
      await fetch('/api/scraper/run', { method: 'POST' });
      fetchLogs();
    } finally {
      setRunning(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800">スクレイパー管理</h1>
        <button onClick={runScraper} disabled={running} className="bg-blue-600 text-white px-5 py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 font-medium">
          {running ? '実行中...' : '全自治体をスクレイプ'}
        </button>
      </div>
      <div className="bg-gray-50 rounded-xl p-4 mb-6 text-sm text-gray-600">
        スクレイパーは毎週月曜日 AM 2:00 に自動実行されます。手動で実行する場合は上のボタンを押してください。
      </div>
      {loading ? <p className="text-gray-500">読み込み中...</p> : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="text-left px-4 py-3 text-gray-600">自治体</th>
                <th className="text-left px-4 py-3 text-gray-600">実行日時</th>
                <th className="text-right px-4 py-3 text-gray-600">取得</th>
                <th className="text-right px-4 py-3 text-gray-600">保存</th>
                <th className="text-center px-4 py-3 text-gray-600">結果</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {logs.map(log => (
                <tr key={log.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-800">{log.municipality.name}</td>
                  <td className="px-4 py-3 text-gray-500">{log.completedAt ? new Date(log.completedAt).toLocaleString('ja-JP') : '-'}</td>
                  <td className="px-4 py-3 text-right text-gray-700">{log.scraped}</td>
                  <td className="px-4 py-3 text-right text-gray-700">{log.saved}</td>
                  <td className="px-4 py-3 text-center">
                    <span className={`text-xs px-2 py-1 rounded-full ${log.success ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                      {log.success ? '成功' : '失敗'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
