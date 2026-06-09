'use client';

import { useState } from 'react';
import type { Metadata } from 'next';
import Link from 'next/link';
import { ChevronRight, ChevronLeft, Sparkles, MapPin, Banknote, Calendar, Check } from 'lucide-react';
import { formatAmount, formatDeadline, getStatusLabel } from '@/lib/utils';

const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

const PREFECTURES = [
  '北海道','青森県','岩手県','宮城県','秋田県','山形県','福島県',
  '茨城県','栃木県','群馬県','埼玉県','千葉県','東京都','神奈川県',
  '新潟県','富山県','石川県','福井県','山梨県','長野県','岐阜県',
  '静岡県','愛知県','三重県','滋賀県','京都府','大阪府','兵庫県',
  '奈良県','和歌山県','鳥取県','島根県','岡山県','広島県','山口県',
  '徳島県','香川県','愛媛県','高知県','福岡県','佐賀県','長崎県',
  '熊本県','大分県','宮崎県','鹿児島県','沖縄県',
];

const PREF_CODES: Record<string, string> = {
  '北海道':'01','青森県':'02','岩手県':'03','宮城県':'04','秋田県':'05',
  '山形県':'06','福島県':'07','茨城県':'08','栃木県':'09','群馬県':'10',
  '埼玉県':'11','千葉県':'12','東京都':'13','神奈川県':'14','新潟県':'15',
  '富山県':'16','石川県':'17','福井県':'18','山梨県':'19','長野県':'20',
  '岐阜県':'21','静岡県':'22','愛知県':'23','三重県':'24','滋賀県':'25',
  '京都府':'26','大阪府':'27','兵庫県':'28','奈良県':'29','和歌山県':'30',
  '鳥取県':'31','島根県':'32','岡山県':'33','広島県':'34','山口県':'35',
  '徳島県':'36','香川県':'37','愛媛県':'38','高知県':'39','福岡県':'40',
  '佐賀県':'41','長崎県':'42','熊本県':'43','大分県':'44','宮崎県':'45',
  '鹿児島県':'46','沖縄県':'47',
};

const AUDIENCE_OPTIONS = [
  { value: 'INDIVIDUAL', label: '個人・一般市民', icon: '👤' },
  { value: 'CORPORATION', label: '法人・中小企業', icon: '🏢' },
  { value: 'STARTUP', label: '創業者・これから起業', icon: '🚀' },
  { value: 'FARMER', label: '農業者・林業者', icon: '🌾' },
  { value: 'CHILD', label: '子育て世帯', icon: '👶' },
  { value: 'ELDERLY', label: '高齢者・高齢者施設', icon: '👴' },
  { value: 'NONPROFIT', label: 'NPO・非営利団体', icon: '🤝' },
  { value: 'DISABLED', label: '障害者・障害者雇用', icon: '♿' },
];

const CATEGORY_OPTIONS = [
  { id: 1, name: '子育て・教育', icon: '👶' },
  { id: 2, name: '住宅・リフォーム', icon: '🏠' },
  { id: 3, name: '創業・事業拡大', icon: '💼' },
  { id: 4, name: '農業・林業', icon: '🌾' },
  { id: 5, name: '福祉・障害者支援', icon: '♿' },
  { id: 6, name: '省エネ・環境', icon: '🌿' },
  { id: 7, name: '高齢者支援', icon: '👴' },
  { id: 10, name: 'IT・デジタル化', icon: '💻' },
];

interface MatchResult {
  id: number;
  title: string;
  description: string;
  score: number;
  reasons: string[];
  category: { name: string; icon: string };
  maxAmount: string | null;
  applicationEnd: string | null;
  status: string;
  prefecture: { name: string } | null;
  municipality: { name: string } | null;
  isNational: boolean;
}

const STEPS = ['地域', '対象者', '関心分野', '結果'];

export default function MatchingPage() {
  const [step, setStep] = useState(0);
  const [prefecture, setPrefecture] = useState('');
  const [audience, setAudience] = useState('');
  const [categories, setCategories] = useState<number[]>([]);
  const [keywords, setKeywords] = useState('');
  const [results, setResults] = useState<MatchResult[]>([]);
  const [loading, setLoading] = useState(false);

  function toggleCategory(id: number) {
    setCategories((prev) =>
      prev.includes(id) ? prev.filter((c) => c !== id) : [...prev, id]
    );
  }

  async function runMatch() {
    setLoading(true);
    try {
      const prefCode = PREF_CODES[prefecture];
      const res = await fetch(`${API}/api/matching`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          prefectureCode: prefCode,
          targetAudience: audience,
          categoryIds: categories.length > 0 ? categories : undefined,
          keywords: keywords || undefined,
        }),
      });
      const data = await res.json();
      setResults(data.matches || []);
    } catch {
      setResults([]);
    } finally {
      setLoading(false);
      setStep(3);
    }
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-10">
      {/* Header */}
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-brand-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Sparkles size={28} className="text-brand-600" />
        </div>
        <h1 className="text-2xl font-bold mb-2">補助金マッチング診断</h1>
        <p className="text-gray-600">
          3つの質問に答えるだけで、あなたに合った補助金を自動で探します
        </p>
      </div>

      {/* Step indicator */}
      <div className="flex items-center justify-center gap-2 mb-8">
        {STEPS.map((s, i) => (
          <div key={s} className="flex items-center gap-2">
            <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-colors ${
              i < step
                ? 'bg-brand-600 text-white'
                : i === step
                ? 'bg-brand-100 text-brand-700 border-2 border-brand-600'
                : 'bg-gray-100 text-gray-400'
            }`}>
              {i < step ? <Check size={14} /> : i + 1}
            </div>
            <span className={`text-xs ${i === step ? 'text-brand-700 font-medium' : 'text-gray-400'}`}>
              {s}
            </span>
            {i < STEPS.length - 1 && <div className="w-6 h-px bg-gray-200" />}
          </div>
        ))}
      </div>

      {/* Step 0: 地域 */}
      {step === 0 && (
        <div className="card p-6">
          <h2 className="font-bold text-lg mb-4">お住まいの都道府県を選んでください</h2>
          <div className="grid grid-cols-4 sm:grid-cols-6 gap-1.5 mb-6">
            {PREFECTURES.map((pref) => (
              <button
                key={pref}
                onClick={() => setPrefecture(pref)}
                className={`text-xs py-2 px-1 rounded-lg border transition-all ${
                  prefecture === pref
                    ? 'border-brand-500 bg-brand-50 text-brand-700 font-medium'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                {pref.replace(/[都道府県]$/, '')}
              </button>
            ))}
          </div>
          <button
            onClick={() => setStep(1)}
            disabled={!prefecture}
            className="btn-primary w-full justify-center disabled:opacity-50"
          >
            次へ <ChevronRight size={16} />
          </button>
        </div>
      )}

      {/* Step 1: 対象者 */}
      {step === 1 && (
        <div className="card p-6">
          <h2 className="font-bold text-lg mb-4">あなたに当てはまるものを選んでください</h2>
          <div className="grid grid-cols-2 gap-3 mb-6">
            {AUDIENCE_OPTIONS.map((opt) => (
              <button
                key={opt.value}
                onClick={() => setAudience(opt.value)}
                className={`flex items-center gap-3 p-4 rounded-xl border text-left transition-all ${
                  audience === opt.value
                    ? 'border-brand-500 bg-brand-50'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <span className="text-2xl">{opt.icon}</span>
                <span className="text-sm font-medium">{opt.label}</span>
                {audience === opt.value && (
                  <Check size={14} className="ml-auto text-brand-600 flex-shrink-0" />
                )}
              </button>
            ))}
          </div>
          <div className="flex gap-3">
            <button onClick={() => setStep(0)} className="btn-secondary">
              <ChevronLeft size={16} /> 戻る
            </button>
            <button
              onClick={() => setStep(2)}
              disabled={!audience}
              className="btn-primary flex-1 justify-center disabled:opacity-50"
            >
              次へ <ChevronRight size={16} />
            </button>
          </div>
        </div>
      )}

      {/* Step 2: 関心分野 */}
      {step === 2 && (
        <div className="card p-6">
          <h2 className="font-bold text-lg mb-1">関心のある分野を選んでください</h2>
          <p className="text-sm text-gray-500 mb-4">複数選択可（スキップ可）</p>
          <div className="grid grid-cols-2 gap-2 mb-4">
            {CATEGORY_OPTIONS.map((cat) => (
              <button
                key={cat.id}
                onClick={() => toggleCategory(cat.id)}
                className={`flex items-center gap-2 p-3 rounded-lg border text-left transition-all ${
                  categories.includes(cat.id)
                    ? 'border-brand-500 bg-brand-50 text-brand-700'
                    : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <span>{cat.icon}</span>
                <span className="text-sm">{cat.name}</span>
                {categories.includes(cat.id) && (
                  <Check size={12} className="ml-auto text-brand-600 flex-shrink-0" />
                )}
              </button>
            ))}
          </div>
          <input
            value={keywords}
            onChange={(e) => setKeywords(e.target.value)}
            placeholder="キーワードで絞り込む（任意）例: 太陽光、リフォーム"
            className="w-full border border-gray-300 rounded-lg px-3 py-2.5 text-sm mb-5 focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
          <div className="flex gap-3">
            <button onClick={() => setStep(1)} className="btn-secondary">
              <ChevronLeft size={16} /> 戻る
            </button>
            <button
              onClick={runMatch}
              disabled={loading}
              className="btn-primary flex-1 justify-center"
            >
              <Sparkles size={15} />
              {loading ? '診断中...' : '診断する'}
            </button>
          </div>
        </div>
      )}

      {/* Step 3: 結果 */}
      {step === 3 && (
        <div>
          <div className="text-center mb-6">
            <h2 className="text-xl font-bold">
              {results.length > 0
                ? `${results.length}件の補助金が見つかりました`
                : '該当する補助金が見つかりませんでした'}
            </h2>
            <p className="text-gray-500 text-sm mt-1">
              {prefecture} · {AUDIENCE_OPTIONS.find((a) => a.value === audience)?.label}
            </p>
          </div>

          {results.length === 0 ? (
            <div className="card p-10 text-center">
              <div className="text-4xl mb-3">🔍</div>
              <p className="text-gray-600 mb-4">
                条件を変えてもう一度試すか、コンサルタントにご相談ください。
              </p>
              <Link href="/consulting" className="btn-primary">
                無料相談を申し込む
              </Link>
            </div>
          ) : (
            <div className="space-y-3">
              {results.map((r, i) => {
                const deadline = r.applicationEnd ? formatDeadline(r.applicationEnd) : null;
                const isUrgent = deadline && deadline.daysLeft >= 0 && deadline.daysLeft <= 14;
                return (
                  <Link
                    key={r.id}
                    href={`/subsidies/${r.id}`}
                    className="card p-5 hover:border-brand-300 hover:shadow-md transition-all block"
                  >
                    <div className="flex items-start gap-3">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold flex-shrink-0 ${
                        i === 0 ? 'bg-yellow-400 text-white' :
                        i === 1 ? 'bg-gray-300 text-gray-700' :
                        i === 2 ? 'bg-amber-600 text-white' :
                        'bg-gray-100 text-gray-500'
                      }`}>
                        {i + 1}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-xs text-brand-600 font-medium">
                            {r.category.icon} {r.category.name}
                          </span>
                          <span className={`text-xs px-2 py-0.5 rounded-full ${
                            r.status === 'ACTIVE' ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'
                          }`}>
                            {getStatusLabel(r.status as 'ACTIVE' | 'UPCOMING' | 'ENDED')}
                          </span>
                        </div>
                        <h3 className="font-bold text-sm mb-1 leading-snug">{r.title}</h3>
                        <p className="text-xs text-gray-500 line-clamp-2 mb-2">{r.description}</p>
                        <div className="flex flex-wrap gap-3 text-xs text-gray-500">
                          <span className="flex items-center gap-1">
                            <MapPin size={11} />
                            {r.isNational ? '全国' : r.municipality?.name || r.prefecture?.name}
                          </span>
                          {r.maxAmount && (
                            <span className="flex items-center gap-1 font-medium text-gray-700">
                              <Banknote size={11} />
                              最大{formatAmount(r.maxAmount)}
                            </span>
                          )}
                          {deadline && (
                            <span className={`flex items-center gap-1 ${isUrgent ? 'text-red-600 font-medium' : ''}`}>
                              <Calendar size={11} />
                              締切 {deadline.label}
                            </span>
                          )}
                        </div>
                        {r.reasons.length > 0 && (
                          <div className="flex flex-wrap gap-1 mt-2">
                            {r.reasons.map((reason) => (
                              <span key={reason} className="bg-brand-50 text-brand-700 text-xs px-2 py-0.5 rounded-full">
                                ✓ {reason}
                              </span>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  </Link>
                );
              })}
            </div>
          )}

          <div className="mt-6 flex gap-3">
            <button
              onClick={() => { setStep(0); setResults([]); setAudience(''); setCategories([]); }}
              className="btn-secondary flex-1 justify-center"
            >
              もう一度診断する
            </button>
            <Link href="/consulting" className="btn-primary flex-1 justify-center">
              申請サポートを依頼
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}
