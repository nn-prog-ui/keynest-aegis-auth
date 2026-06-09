'use client';
import { useState } from 'react';

const TEMPLATE_TYPES = [
  { value: 'general', label: '汎用申請書', desc: '一般的な補助金申請に使えるテンプレート' },
  { value: 'startup', label: '創業支援', desc: '創業・起業向け補助金申請書' },
  { value: 'it', label: 'IT導入', desc: 'IT導入補助金向け申請書' },
  { value: 'wage_increase', label: '賃上げ促進', desc: '賃上げ関連補助金申請書' },
  { value: 'employment', label: '雇用促進', desc: '雇用・採用関連補助金申請書' },
  { value: 'housing', label: '住宅改修', desc: '住宅リフォーム・改修補助申請書' },
  { value: 'agriculture', label: '農業振興', desc: '農業・農村振興補助金申請書' },
];

const STEPS = ['テンプレート選択', '申請者情報', '事業情報', '確認・ダウンロード'];

export default function TemplatesPage() {
  const [step, setStep] = useState(0);
  const [templateType, setTemplateType] = useState('general');
  const [applicant, setApplicant] = useState({ name: '', company: '', address: '', phone: '', email: '' });
  const [project, setProject] = useState({ title: '', description: '', budget: '', period: '' });
  const [loading, setLoading] = useState(false);
  const [downloaded, setDownloaded] = useState(false);

  const download = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/pdf/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          templateType,
          subsidy: { title: TEMPLATE_TYPES.find(t => t.value === templateType)?.label || '' },
          applicant,
          project: { ...project, budget: project.budget ? parseInt(project.budget) : undefined },
        }),
      });
      if (!res.ok) throw new Error('PDF生成に失敗しました');
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `subsidy-template-${templateType}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
      setDownloaded(true);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'エラーが発生しました');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto px-4 py-12">
      <h1 className="text-2xl font-bold text-gray-800 mb-2">申請書テンプレート</h1>
      <p className="text-gray-600 mb-8">必要事項を入力してPDFをダウンロードしてください。</p>

      <div className="flex gap-1 mb-8">
        {STEPS.map((s, i) => (
          <div key={i} className={`flex-1 text-center text-xs py-2 rounded ${i === step ? 'bg-blue-600 text-white' : i < step ? 'bg-blue-100 text-blue-700' : 'bg-gray-100 text-gray-500'}`}>{s}</div>
        ))}
      </div>

      {step === 0 && (
        <div className="space-y-3">
          {TEMPLATE_TYPES.map(t => (
            <button key={t.value} onClick={() => setTemplateType(t.value)} className={`w-full text-left p-4 rounded-xl border-2 transition ${templateType === t.value ? 'border-blue-600 bg-blue-50' : 'border-gray-200 bg-white hover:border-gray-300'}`}>
              <div className="font-semibold text-gray-800">{t.label}</div>
              <div className="text-sm text-gray-500">{t.desc}</div>
            </button>
          ))}
          <button onClick={() => setStep(1)} className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 mt-4">次へ →</button>
        </div>
      )}

      {step === 1 && (
        <div className="bg-white rounded-xl border border-gray-200 p-6 space-y-4">
          {[
            { key: 'name', label: '氏名', required: true },
            { key: 'company', label: '会社名・屋号', required: false },
            { key: 'address', label: '住所', required: false },
            { key: 'phone', label: '電話番号', required: false },
            { key: 'email', label: 'メールアドレス', required: false },
          ].map(f => (
            <div key={f.key}>
              <label className="block text-sm font-medium text-gray-700 mb-1">{f.label} {f.required && <span className="text-red-500">*</span>}</label>
              <input value={applicant[f.key as keyof typeof applicant]} onChange={e => setApplicant(p => ({ ...p, [f.key]: e.target.value }))} className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required={f.required} />
            </div>
          ))}
          <div className="flex gap-3">
            <button onClick={() => setStep(0)} className="flex-1 border border-gray-300 py-3 rounded-lg text-gray-700 hover:bg-gray-50">← 戻る</button>
            <button onClick={() => setStep(2)} disabled={!applicant.name} className="flex-1 bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 disabled:opacity-40">次へ →</button>
          </div>
        </div>
      )}

      {step === 2 && (
        <div className="bg-white rounded-xl border border-gray-200 p-6 space-y-4">
          {[
            { key: 'title', label: '事業名', required: true, type: 'text' },
            { key: 'period', label: '実施期間', required: false, type: 'text' },
            { key: 'budget', label: '事業費（円）', required: false, type: 'number' },
          ].map(f => (
            <div key={f.key}>
              <label className="block text-sm font-medium text-gray-700 mb-1">{f.label} {f.required && <span className="text-red-500">*</span>}</label>
              <input type={f.type} value={project[f.key as keyof typeof project]} onChange={e => setProject(p => ({ ...p, [f.key]: e.target.value }))} className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required={f.required} />
            </div>
          ))}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">事業概要 <span className="text-red-500">*</span></label>
            <textarea rows={4} value={project.description} onChange={e => setProject(p => ({ ...p, description: e.target.value }))} className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500" required />
          </div>
          <div className="flex gap-3">
            <button onClick={() => setStep(1)} className="flex-1 border border-gray-300 py-3 rounded-lg text-gray-700 hover:bg-gray-50">← 戻る</button>
            <button onClick={() => setStep(3)} disabled={!project.title || !project.description} className="flex-1 bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 disabled:opacity-40">次へ →</button>
          </div>
        </div>
      )}

      {step === 3 && (
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="font-semibold mb-4">確認</h2>
          <dl className="space-y-2 text-sm mb-6">
            <div className="flex gap-3"><dt className="text-gray-500 w-32">テンプレート</dt><dd className="text-gray-800">{TEMPLATE_TYPES.find(t => t.value === templateType)?.label}</dd></div>
            <div className="flex gap-3"><dt className="text-gray-500 w-32">氏名</dt><dd className="text-gray-800">{applicant.name}</dd></div>
            <div className="flex gap-3"><dt className="text-gray-500 w-32">事業名</dt><dd className="text-gray-800">{project.title}</dd></div>
          </dl>
          {downloaded && <p className="text-green-600 text-sm mb-4">✓ PDFをダウンロードしました</p>}
          <div className="flex gap-3">
            <button onClick={() => setStep(2)} className="flex-1 border border-gray-300 py-3 rounded-lg text-gray-700 hover:bg-gray-50">← 戻る</button>
            <button onClick={download} disabled={loading} className="flex-1 bg-green-600 text-white py-3 rounded-lg hover:bg-green-700 disabled:opacity-40">
              {loading ? '生成中...' : '📄 PDFをダウンロード'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
