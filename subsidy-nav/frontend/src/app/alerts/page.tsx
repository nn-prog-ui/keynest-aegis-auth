'use client';

import { useState } from 'react';
import { Bell, Check, MapPin, Tag, Clock } from 'lucide-react';
import { registerAlert } from '@/lib/api';

const CATEGORIES = [
  { id: 1, name: '子育て・教育支援', icon: '👶' },
  { id: 2, name: '住宅・リフォーム', icon: '🏠' },
  { id: 3, name: '創業・事業拡大', icon: '💼' },
  { id: 4, name: '農業・林業・水産業', icon: '🌾' },
  { id: 5, name: '福祉・障害者支援', icon: '♿' },
  { id: 6, name: '省エネ・環境', icon: '🌿' },
  { id: 7, name: '高齢者支援', icon: '👴' },
  { id: 8, name: 'IT・デジタル化', icon: '💻' },
];

export default function AlertsPage() {
  const [email, setEmail] = useState('');
  const [selectedCategories, setSelectedCategories] = useState<number[]>([]);
  const [deadlineDays, setDeadlineDays] = useState(14);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');

  function toggleCategory(id: number) {
    setSelectedCategories((prev) =>
      prev.includes(id) ? prev.filter((c) => c !== id) : [...prev, id]
    );
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await registerAlert({
        email,
        prefectureIds: [],
        municipalityIds: [],
        categoryIds: selectedCategories,
        deadlineReminderDays: deadlineDays,
      });
      setSuccess(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : '登録に失敗しました');
    } finally {
      setLoading(false);
    }
  }

  if (success) {
    return (
      <div className="max-w-lg mx-auto px-4 py-16 text-center">
        <div className="card p-10">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <Check size={32} className="text-green-600" />
          </div>
          <h1 className="text-2xl font-bold mb-3">確認メールを送信しました</h1>
          <p className="text-gray-600">
            <strong>{email}</strong> 宛にメールを送りました。
            メール内のリンクをクリックして登録を完了してください。
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-10">
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-brand-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Bell size={28} className="text-brand-600" />
        </div>
        <h1 className="text-2xl font-bold mb-2">補助金アラートに登録する</h1>
        <p className="text-gray-600">
          新着補助金や締め切りが近づいたときにメールでお知らせします。<br />
          登録は無料です。
        </p>
      </div>

      <form onSubmit={handleSubmit} className="card p-6 space-y-6">
        <div>
          <label className="block font-medium mb-1.5">
            メールアドレス <span className="text-red-500">*</span>
          </label>
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="example@mail.com"
            className="w-full border border-gray-300 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>

        <div>
          <label className="flex items-center gap-2 font-medium mb-3">
            <Tag size={16} className="text-brand-500" />
            関心のあるカテゴリ（複数選択可）
          </label>
          <div className="grid grid-cols-2 gap-2">
            {CATEGORIES.map((cat) => (
              <label
                key={cat.id}
                className={`flex items-center gap-2 p-3 rounded-lg border cursor-pointer transition-all ${
                  selectedCategories.includes(cat.id)
                    ? 'border-brand-500 bg-brand-50 text-brand-700'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <input
                  type="checkbox"
                  className="sr-only"
                  checked={selectedCategories.includes(cat.id)}
                  onChange={() => toggleCategory(cat.id)}
                />
                <span>{cat.icon}</span>
                <span className="text-sm font-medium">{cat.name}</span>
                {selectedCategories.includes(cat.id) && (
                  <Check size={14} className="ml-auto text-brand-600" />
                )}
              </label>
            ))}
          </div>
          <p className="text-xs text-gray-500 mt-2">
            選択しない場合はすべてのカテゴリの通知を受け取ります
          </p>
        </div>

        <div>
          <label className="flex items-center gap-2 font-medium mb-3">
            <Clock size={16} className="text-brand-500" />
            締め切り通知のタイミング
          </label>
          <select
            value={deadlineDays}
            onChange={(e) => setDeadlineDays(parseInt(e.target.value))}
            className="w-full border border-gray-300 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-brand-500"
          >
            <option value={7}>締め切り7日前</option>
            <option value={14}>締め切り14日前（推奨）</option>
            <option value={30}>締め切り30日前</option>
          </select>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg px-4 py-3 text-sm">
            {error}
          </div>
        )}

        <button
          type="submit"
          disabled={loading}
          className="btn-primary w-full justify-center py-3 text-base disabled:opacity-60"
        >
          {loading ? '登録中...' : '無料でアラート登録する'}
        </button>

        <p className="text-xs text-gray-500 text-center">
          登録後に送られるメールのリンクで解除できます。スパムメールは送りません。
        </p>
      </form>
    </div>
  );
}
