'use client';
import { useState } from 'react';

const INQUIRY_TYPES = [
  { value: 'GENERAL', label: '一般相談' },
  { value: 'MATCHING', label: '補助金マッチング' },
  { value: 'APPLICATION_SUPPORT', label: '申請サポート' },
  { value: 'DOCUMENT_CREATION', label: '書類作成代行' },
  { value: 'OTHER', label: 'その他' },
];

export default function ConsultingPage() {
  const [form, setForm] = useState({ name: '', company: '', email: '', phone: '', inquiryType: 'GENERAL', message: '' });
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await fetch('/api/consulting', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      if (res.ok) setSubmitted(true);
    } finally {
      setLoading(false);
    }
  };

  if (submitted) {
    return (
      <div className="max-w-lg mx-auto px-4 py-16 text-center">
        <div className="text-5xl mb-4">✅</div>
        <h1 className="text-2xl font-bold text-gray-800 mb-3">お問い合わせを受け付けました</h1>
        <p className="text-gray-600">内容を確認の上、2営業日以内にご連絡いたします。</p>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-12">
      <h1 className="text-2xl font-bold text-gray-800 mb-2">コンサルティング相談</h1>
      <p className="text-gray-600 mb-8">補助金申請のプロが、採択まで伴走支援します。まずはお気軽にご相談ください。</p>

      <form onSubmit={handleSubmit} className="bg-white rounded-xl border border-gray-200 p-8 space-y-5">
        {[
          { key: 'name', label: '氏名', required: true, type: 'text', placeholder: '山田 太郎' },
          { key: 'company', label: '会社名・屋号', required: false, type: 'text', placeholder: '株式会社〇〇' },
          { key: 'email', label: 'メールアドレス', required: true, type: 'email', placeholder: 'your@email.com' },
          { key: 'phone', label: '電話番号', required: false, type: 'tel', placeholder: '090-0000-0000' },
        ].map(f => (
          <div key={f.key}>
            <label className="block text-sm font-medium text-gray-700 mb-1">{f.label} {f.required && <span className="text-red-500">*</span>}</label>
            <input
              type={f.type}
              required={f.required}
              value={form[f.key as keyof typeof form]}
              onChange={e => setForm(prev => ({ ...prev, [f.key]: e.target.value }))}
              placeholder={f.placeholder}
              className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        ))}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">相談種別 <span className="text-red-500">*</span></label>
          <select value={form.inquiryType} onChange={e => setForm(prev => ({ ...prev, inquiryType: e.target.value }))} className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500">
            {INQUIRY_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">ご相談内容 <span className="text-red-500">*</span></label>
          <textarea
            required
            rows={5}
            value={form.message}
            onChange={e => setForm(prev => ({ ...prev, message: e.target.value }))}
            placeholder="ご相談内容をご記入ください"
            className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <button type="submit" disabled={loading} className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition disabled:opacity-60">
          {loading ? '送信中...' : '相談を申し込む'}
        </button>
      </form>
    </div>
  );
}
