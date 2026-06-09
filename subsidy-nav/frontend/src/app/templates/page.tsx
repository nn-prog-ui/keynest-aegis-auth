'use client';

import { useState, useEffect } from 'react';
import { FileDown, ChevronRight, Check, Loader } from 'lucide-react';

const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

interface Template {
  type: string;
  name: string;
  description: string;
  icon: string;
  categories: string[];
}

const STEPS = ['テンプレート選択', '補助金情報', '申請者情報', '事業計画'];

export default function TemplatesPage() {
  const [templates, setTemplates] = useState<Template[]>([]);
  const [step, setStep] = useState(0);
  const [selectedType, setSelectedType] = useState('');
  const [generating, setGenerating] = useState(false);
  const [done, setDone] = useState(false);

  const [subsidy, setSubsidy] = useState({
    title: '',
    organization: '',
    maxAmount: '',
    applicationEnd: '',
    sourceUrl: 'https://www.mhlw.go.jp/',
    requirements: '',
  });

  const [applicant, setApplicant] = useState({
    companyName: '',
    representativeName: '',
    address: '',
    phone: '',
    email: '',
    businessDescription: '',
    employeeCount: '',
    established: '',
  });

  const [project, setProject] = useState({
    title: '',
    purpose: '',
    period: '',
    totalCost: '',
    subsidyAmount: '',
    expectedEffect: '',
  });

  useEffect(() => {
    fetch(`${API}/api/pdf/templates`)
      .then((r) => r.json())
      .then(setTemplates);
  }, []);

  async function generate() {
    setGenerating(true);
    try {
      const res = await fetch(`${API}/api/pdf/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          templateType: selectedType,
          subsidy: {
            ...subsidy,
            subsidyRate: undefined,
          },
          applicant: {
            ...applicant,
            employeeCount: applicant.employeeCount ? parseInt(applicant.employeeCount) : undefined,
          },
          project,
        }),
      });

      if (!res.ok) throw new Error('PDF生成に失敗しました');

      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `hojokin-shinsei-${selectedType}-${Date.now()}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
      setDone(true);
    } catch (err) {
      alert(err instanceof Error ? err.message : 'エラーが発生しました');
    } finally {
      setGenerating(false);
    }
  }

  function updateSubsidy(k: string, v: string) {
    setSubsidy((p) => ({ ...p, [k]: v }));
  }
  function updateApplicant(k: string, v: string) {
    setApplicant((p) => ({ ...p, [k]: v }));
  }
  function updateProject(k: string, v: string) {
    setProject((p) => ({ ...p, [k]: v }));
  }

  const selectedTemplate = templates.find((t) => t.type === selectedType);

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-brand-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <FileDown size={28} className="text-brand-600" />
        </div>
        <h1 className="text-2xl font-bold mb-2">申請書類テンプレート</h1>
        <p className="text-gray-600">
          補助金の種類に合わせた申請書の下書きをPDFで生成します。<br />
          情報を入力して、申請準備をスムーズに進めましょう。
        </p>
      </div>

      {/* ステップ表示 */}
      <div className="flex items-center justify-center gap-1 mb-8">
        {STEPS.map((s, i) => (
          <div key={s} className="flex items-center gap-1">
            <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold ${
              i < step ? 'bg-brand-600 text-white' :
              i === step ? 'bg-brand-100 text-brand-700 border-2 border-brand-600' :
              'bg-gray-100 text-gray-400'
            }`}>
              {i < step ? <Check size={12} /> : i + 1}
            </div>
            <span className={`text-xs hidden sm:inline ${i === step ? 'text-brand-700 font-medium' : 'text-gray-400'}`}>
              {s}
            </span>
            {i < STEPS.length - 1 && <ChevronRight size={14} className="text-gray-300" />}
          </div>
        ))}
      </div>

      {/* Step 0: テンプレート選択 */}
      {step === 0 && (
        <div>
          <h2 className="font-bold mb-4">申請したい補助金の種類を選んでください</h2>
          <div className="grid sm:grid-cols-2 gap-3 mb-6">
            {templates.map((t) => (
              <button
                key={t.type}
                onClick={() => setSelectedType(t.type)}
                className={`text-left p-4 rounded-xl border transition-all ${
                  selectedType === t.type
                    ? 'border-brand-500 bg-brand-50'
                    : 'border-gray-200 hover:border-gray-300 bg-white'
                }`}
              >
                <div className="text-2xl mb-2">{t.icon}</div>
                <div className="font-bold text-sm mb-1">{t.name}</div>
                <div className="text-xs text-gray-500">{t.description}</div>
                <div className="flex flex-wrap gap-1 mt-2">
                  {t.categories.map((c) => (
                    <span key={c} className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">{c}</span>
                  ))}
                </div>
                {selectedType === t.type && (
                  <div className="flex items-center gap-1 text-brand-700 text-xs font-medium mt-2">
                    <Check size={12} /> 選択中
                  </div>
                )}
              </button>
            ))}
          </div>
          <button
            onClick={() => setStep(1)}
            disabled={!selectedType}
            className="btn-primary w-full justify-center disabled:opacity-50"
          >
            次へ <ChevronRight size={16} />
          </button>
        </div>
      )}

      {/* Step 1: 補助金情報 */}
      {step === 1 && (
        <div className="card p-6">
          {selectedTemplate && (
            <div className="flex items-center gap-2 mb-5 bg-brand-50 rounded-lg px-4 py-2 text-sm text-brand-700">
              <span>{selectedTemplate.icon}</span>
              <span className="font-medium">{selectedTemplate.name}</span>
            </div>
          )}
          <h2 className="font-bold mb-4">申請する補助金の情報を入力</h2>
          <div className="space-y-4">
            <FormField label="補助金名 *" value={subsidy.title}
              onChange={(v) => updateSubsidy('title', v)}
              placeholder="例: IT導入補助金（通常枠）" />
            <FormField label="実施機関 *" value={subsidy.organization}
              onChange={(v) => updateSubsidy('organization', v)}
              placeholder="例: 経済産業省 / 中小企業庁" />
            <div className="grid sm:grid-cols-2 gap-4">
              <FormField label="最大補助額" value={subsidy.maxAmount}
                onChange={(v) => updateSubsidy('maxAmount', v)}
                placeholder="例: 最大450万円" />
              <FormField label="申請締切" value={subsidy.applicationEnd}
                onChange={(v) => updateSubsidy('applicationEnd', v)}
                placeholder="例: 2026年9月30日" />
            </div>
            <FormField label="公式サイトURL" value={subsidy.sourceUrl}
              onChange={(v) => updateSubsidy('sourceUrl', v)} />
          </div>
          <div className="flex gap-3 mt-6">
            <button onClick={() => setStep(0)} className="btn-secondary">戻る</button>
            <button onClick={() => setStep(2)} disabled={!subsidy.title || !subsidy.organization}
              className="btn-primary flex-1 justify-center disabled:opacity-50">
              次へ <ChevronRight size={16} />
            </button>
          </div>
        </div>
      )}

      {/* Step 2: 申請者情報 */}
      {step === 2 && (
        <div className="card p-6">
          <h2 className="font-bold mb-4">申請者情報を入力</h2>
          <div className="space-y-4">
            <FormField label="法人名・屋号" value={applicant.companyName}
              onChange={(v) => updateApplicant('companyName', v)}
              placeholder="例: 株式会社〇〇 / 個人の場合は空欄" />
            <div className="grid sm:grid-cols-2 gap-4">
              <FormField label="代表者氏名 *" value={applicant.representativeName}
                onChange={(v) => updateApplicant('representativeName', v)}
                placeholder="例: 山田 太郎" />
              <FormField label="設立・創業年月" value={applicant.established}
                onChange={(v) => updateApplicant('established', v)}
                placeholder="例: 2020年4月" />
            </div>
            <FormField label="住所 *" value={applicant.address}
              onChange={(v) => updateApplicant('address', v)}
              placeholder="例: 東京都渋谷区〇〇1-2-3" />
            <div className="grid sm:grid-cols-2 gap-4">
              <FormField label="電話番号 *" value={applicant.phone}
                onChange={(v) => updateApplicant('phone', v)}
                placeholder="例: 03-0000-0000" />
              <FormField label="メールアドレス *" value={applicant.email}
                onChange={(v) => updateApplicant('email', v)}
                placeholder="例: info@example.com" />
            </div>
            <div className="grid sm:grid-cols-2 gap-4">
              <FormField label="従業員数" value={applicant.employeeCount}
                onChange={(v) => updateApplicant('employeeCount', v)}
                placeholder="例: 10" />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5">事業内容</label>
              <textarea rows={3} value={applicant.businessDescription}
                onChange={(e) => updateApplicant('businessDescription', e.target.value)}
                placeholder="例: 飲食店の経営。ラーメン専門店を3店舗運営。従業員15名。"
                className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none" />
            </div>
          </div>
          <div className="flex gap-3 mt-6">
            <button onClick={() => setStep(1)} className="btn-secondary">戻る</button>
            <button onClick={() => setStep(3)}
              disabled={!applicant.representativeName || !applicant.address || !applicant.phone || !applicant.email}
              className="btn-primary flex-1 justify-center disabled:opacity-50">
              次へ <ChevronRight size={16} />
            </button>
          </div>
        </div>
      )}

      {/* Step 3: 事業計画 */}
      {step === 3 && (
        <div className="card p-6">
          <h2 className="font-bold mb-4">補助事業の計画を入力</h2>
          {!done ? (
            <div className="space-y-4">
              <FormField label="事業タイトル *" value={project.title}
                onChange={(v) => updateProject('title', v)}
                placeholder="例: POSシステム導入による受発注業務の自動化" />
              <div>
                <label className="block text-sm font-medium mb-1.5">事業の目的・背景 *</label>
                <textarea rows={3} value={project.purpose}
                  onChange={(e) => updateProject('purpose', e.target.value)}
                  placeholder="例: 現在手作業で行っている在庫管理・発注業務を自動化し、1日2時間分の業務削減と人的ミスの防止を実現する。"
                  className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none" />
              </div>
              <div className="grid sm:grid-cols-2 gap-4">
                <FormField label="実施期間" value={project.period}
                  onChange={(v) => updateProject('period', v)}
                  placeholder="例: 2026年7月〜2026年12月" />
                <FormField label="総事業費" value={project.totalCost}
                  onChange={(v) => updateProject('totalCost', v)}
                  placeholder="例: 2,000,000円" />
              </div>
              <FormField label="補助申請額" value={project.subsidyAmount}
                onChange={(v) => updateProject('subsidyAmount', v)}
                placeholder="例: 1,000,000円（総事業費の1/2）" />
              <div>
                <label className="block text-sm font-medium mb-1.5">期待される効果（数値目標）*</label>
                <textarea rows={3} value={project.expectedEffect}
                  onChange={(e) => updateProject('expectedEffect', e.target.value)}
                  placeholder="例: ①業務時間20%削減（月40時間→32時間）②売上高10%向上（前年比）③顧客満足度スコア向上"
                  className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none" />
              </div>

              <div className="bg-yellow-50 border border-yellow-200 rounded-lg px-4 py-3 text-sm text-yellow-800">
                <strong>注意:</strong> このPDFは申請書の「下書き」です。実際の申請には各制度の公式様式を使用してください。
              </div>

              <div className="flex gap-3">
                <button onClick={() => setStep(2)} className="btn-secondary">戻る</button>
                <button onClick={generate}
                  disabled={generating || !project.title || !project.purpose || !project.expectedEffect}
                  className="btn-primary flex-1 justify-center disabled:opacity-50">
                  {generating ? (
                    <><Loader size={15} className="animate-spin" /> 生成中...</>
                  ) : (
                    <><FileDown size={15} /> PDFをダウンロード</>
                  )}
                </button>
              </div>
            </div>
          ) : (
            <div className="text-center py-8">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Check size={32} className="text-green-600" />
              </div>
              <h3 className="text-xl font-bold mb-2">PDFを生成しました</h3>
              <p className="text-gray-600 mb-6">
                ダウンロードが開始されました。内容を確認し、必要に応じて修正してください。
              </p>
              <div className="flex gap-3 justify-center">
                <button onClick={generate} className="btn-secondary text-sm">
                  <FileDown size={14} /> 再ダウンロード
                </button>
                <button onClick={() => { setStep(0); setDone(false); setSelectedType(''); }}
                  className="btn-primary text-sm">
                  別のテンプレートを作成
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function FormField({
  label, value, onChange, placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
}) {
  return (
    <div>
      <label className="block text-sm font-medium mb-1.5">{label}</label>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
      />
    </div>
  );
}
