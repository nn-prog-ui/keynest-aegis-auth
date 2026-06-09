'use client';

import { useState } from 'react';
import { Check, MessageSquare, Users, FileText, TrendingUp } from 'lucide-react';
import { submitConsulting } from '@/lib/api';

const INQUIRY_TYPES = [
  { value: 'SUBSIDY_SEARCH', label: '補助金・助成金の探し方を相談したい' },
  { value: 'APPLICATION_HELP', label: '申請書類の作成サポートを依頼したい' },
  { value: 'CONSULTING', label: '事業全般のコンサルティングを依頼したい' },
  { value: 'OTHER', label: 'その他' },
];

const SERVICES = [
  {
    icon: FileText,
    title: '補助金選定',
    desc: '事業内容・規模・地域に最適な補助金を選定。見落としがちな市区町村補助金も網羅。',
  },
  {
    icon: MessageSquare,
    title: '申請書類作成',
    desc: '採択率を高める事業計画書・申請書類の作成を全面サポート。過去の採択事例を参考に作成。',
  },
  {
    icon: Users,
    title: '申請代行',
    desc: '必要書類の収集から提出まで代行。複数の補助金を同時申請する場合も対応。',
  },
  {
    icon: TrendingUp,
    title: '事業戦略立案',
    desc: '補助金獲得を起点とした事業成長戦略を立案。中長期的な補助金活用ロードマップを策定。',
  },
];

export default function ConsultingPage() {
  const [form, setForm] = useState({
    name: '',
    email: '',
    phone: '',
    companyName: '',
    inquiryType: 'SUBSIDY_SEARCH',
    message: '',
  });
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');

  function update(key: string, value: string) {
    setForm((prev) => ({ ...prev, [key]: value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await submitConsulting(form);
      setSuccess(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : '送信に失敗しました');
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
          <h1 className="text-2xl font-bold mb-3">お問い合わせを受け付けました</h1>
          <p className="text-gray-600">
            2営業日以内に担当コンサルタントよりご連絡いたします。<br />
            お急ぎの場合はお電話でもお受けしています。
          </p>
        </div>
      </div>
    );
  }

  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-r from-brand-800 to-brand-600 text-white py-16">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <h1 className="text-3xl font-bold mb-4">補助金コンサルティングサービス</h1>
          <p className="text-blue-100 text-lg max-w-2xl mx-auto">
            補助金の選定から申請書類の作成、採択後のフォローまで。
            専門家チームがあなたの事業を全面バックアップします。
          </p>
        </div>
      </section>

      {/* Services */}
      <section className="max-w-5xl mx-auto px-4 py-12">
        <h2 className="text-xl font-bold text-center mb-8">サービス内容</h2>
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {SERVICES.map((s) => (
            <div key={s.title} className="card p-5">
              <div className="w-10 h-10 bg-brand-100 rounded-xl flex items-center justify-center mb-3">
                <s.icon size={20} className="text-brand-600" />
              </div>
              <h3 className="font-bold mb-1.5 text-sm">{s.title}</h3>
              <p className="text-xs text-gray-600 leading-relaxed">{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Form */}
      <section className="max-w-2xl mx-auto px-4 pb-16">
        <div className="card p-8">
          <h2 className="text-xl font-bold mb-6">無料相談フォーム</h2>

          <form onSubmit={handleSubmit} className="space-y-5">
            <div className="grid sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1.5">
                  お名前 <span className="text-red-500">*</span>
                </label>
                <input
                  required
                  value={form.name}
                  onChange={(e) => update('name', e.target.value)}
                  placeholder="山田 太郎"
                  className="w-full border border-gray-300 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-brand-500 text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5">
                  メールアドレス <span className="text-red-500">*</span>
                </label>
                <input
                  required
                  type="email"
                  value={form.email}
                  onChange={(e) => update('email', e.target.value)}
                  placeholder="example@mail.com"
                  className="w-full border border-gray-300 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-brand-500 text-sm"
                />
              </div>
            </div>

            <div className="grid sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1.5">電話番号</label>
                <input
                  value={form.phone}
                  onChange={(e) => update('phone', e.target.value)}
                  placeholder="090-0000-0000"
                  className="w-full border border-gray-300 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-brand-500 text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5">会社名・屋号</label>
                <input
                  value={form.companyName}
                  onChange={(e) => update('companyName', e.target.value)}
                  placeholder="株式会社〇〇"
                  className="w-full border border-gray-300 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-brand-500 text-sm"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium mb-1.5">
                ご相談の種類 <span className="text-red-500">*</span>
              </label>
              <div className="space-y-2">
                {INQUIRY_TYPES.map((t) => (
                  <label key={t.value} className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      name="inquiryType"
                      value={t.value}
                      checked={form.inquiryType === t.value}
                      onChange={() => update('inquiryType', t.value)}
                      className="accent-brand-600"
                    />
                    <span className="text-sm">{t.label}</span>
                  </label>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium mb-1.5">
                ご相談内容 <span className="text-red-500">*</span>
              </label>
              <textarea
                required
                rows={5}
                value={form.message}
                onChange={(e) => update('message', e.target.value)}
                placeholder="事業内容、規模、お悩みの点など、詳しくお聞かせください。"
                className="w-full border border-gray-300 rounded-lg px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-brand-500 text-sm resize-none"
              />
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
              {loading ? '送信中...' : '無料相談を申し込む'}
            </button>

            <p className="text-xs text-gray-500 text-center">
              送信後、2営業日以内にご連絡いたします。内容は厳重に管理します。
            </p>
          </form>
        </div>
      </section>
    </div>
  );
}
