'use client';
import { useState } from 'react';

export default function AlertsPage() {
  const [email, setEmail] = useState('');
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await fetch('/api/alerts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      if (!res.ok) throw new Error('登録に失敗しました');
      setSubmitted(true);
    } catch {
      setError('登録に失敗しました。もう一度お試しください。');
    } finally {
      setLoading(false);
    }
  };

  if (submitted) {
    return (
      <div className="max-w-lg mx-auto px-4 py-16 text-center">
        <div className="text-5xl mb-4">📧</div>
        <h1 className="text-2xl font-bold text-gray-800 mb-3">確認メールを送信しました</h1>
        <p className="text-gray-600">
          <strong>{email}</strong> 宛に確認メールを送りました。<br />
          メール内のリンクをクリックして登録を完了してください。
        </p>
      </div>
    );
  }

  return (
    <div className="max-w-lg mx-auto px-4 py-12">
      <h1 className="text-2xl font-bold text-gray-800 mb-2">補助金アラート登録</h1>
      <p className="text-gray-600 mb-8">新着・締切間近の補助金情報をメールでお届けします。</p>

      <form onSubmit={handleSubmit} className="bg-white rounded-xl border border-gray-200 p-8 space-y-5">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">メールアドレス <span className="text-red-500">*</span></label>
          <input
            type="email"
            required
            value={email}
            onChange={e => setEmail(e.target.value)}
            className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="your@email.com"
          />
        </div>
        {error && <p className="text-red-600 text-sm">{error}</p>}
        <button type="submit" disabled={loading} className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition disabled:opacity-60">
          {loading ? '登録中...' : '無料で登録する'}
        </button>
        <p className="text-xs text-gray-400 text-center">登録後、確認メールが届きます。いつでも解除できます。</p>
      </form>
    </div>
  );
}
