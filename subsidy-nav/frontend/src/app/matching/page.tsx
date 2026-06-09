'use client';
import { useState } from 'react';
import Link from 'next/link';

const STEPS = [
  {
    question: 'あなたの属性は？',
    key: 'audiences',
    options: [
      { value: 'CORPORATION', label: '法人・企業' },
      { value: 'STARTUP', label: 'スタートアップ' },
      { value: 'INDIVIDUAL', label: '個人・フリーランス' },
      { value: 'FARMER', label: '農業者' },
      { value: 'NONPROFIT', label: 'NPO・非営利団体' },
    ],
  },
  {
    question: '関心のあるカテゴリは？',
    key: 'categorySlugs',
    options: [
      { value: 'business', label: '事業支援・経営' },
      { value: 'it', label: 'IT・デジタル化' },
      { value: 'startup', label: '創業・起業' },
      { value: 'employment', label: '雇用・人材' },
      { value: 'agriculture', label: '農林水産' },
      { value: 'environment', label: '環境・エネルギー' },
      { value: 'housing', label: '住宅・建設' },
      { value: 'welfare', label: '福祉・介護' },
    ],
  },
  {
    question: 'お住まい・事業所の都道府県は？',
    key: 'prefectureCode',
    options: [
      { value: '13', label: '東京都' },
      { value: '27', label: '大阪府' },
      { value: '14', label: '神奈川県' },
      { value: '23', label: '愛知県' },
      { value: '11', label: '埼玉県' },
      { value: '12', label: '千葉県' },
      { value: '01', label: '北海道' },
      { value: '40', label: '福岡県' },
      { value: 'other', label: 'その他' },
    ],
  },
];

interface MatchResult {
  subsidy: { id: number; title: string; description: string; maxAmount?: number; applicationEnd?: string; status: string; isNational: boolean; municipality?: { name: string; prefecture: { name: string } }; category?: { name: string } };
  score: number;
  reasons: string[];
}

export default function MatchingPage() {
  const [step, setStep] = useState(0);
  const [answers, setAnswers] = useState<Record<string, string | string[]>>({});
  const [results, setResults] = useState<MatchResult[] | null>(null);
  const [loading, setLoading] = useState(false);

  const current = STEPS[step];

  const select = (value: string) => {
    const isMulti = current.key === 'audiences' || current.key === 'categorySlugs';
    if (isMulti) {
      const prev = (answers[current.key] as string[]) || [];
      const next = prev.includes(value) ? prev.filter(v => v !== value) : [...prev, value];
      setAnswers(a => ({ ...a, [current.key]: next }));
    } else {
      setAnswers(a => ({ ...a, [current.key]: value }));
    }
  };

  const next = async () => {
    if (step < STEPS.length - 1) {
      setStep(s => s + 1);
    } else {
      setLoading(true);
      try {
        const body = {
          audiences: answers.audiences || [],
          categorySlugs: answers.categorySlugs || [],
          prefectureCode: answers.prefectureCode === 'other' ? undefined : answers.prefectureCode,
        };
        const res = await fetch('/api/matching', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body),
        });
        const data = await res.json();
        setResults(data);
      } finally {
        setLoading(false);
      }
    }
  };

  if (results !== null) {
    return (
      <div className="max-w-3xl mx-auto px-4 py-12">
        <h1 className="text-2xl font-bold text-gray-800 mb-2">マッチング結果</h1>
        <p className="text-gray-600 mb-6">あなたに合った補助金 {results.length}件が見つかりました</p>
        {results.length === 0 ? (
          <p className="text-gray-500">条件に合う補助金が見つかりませんでした。</p>
        ) : (
          <div className="space-y-4">
            {results.map(r => (
              <Link key={r.subsidy.id} href={`/subsidies/${r.subsidy.id}`} className="block bg-white rounded-xl border border-gray-200 p-5 hover:shadow-md transition">
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-semibold text-gray-800">{r.subsidy.title}</h3>
                  <span className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded font-medium">スコア {r.score}</span>
                </div>
                <p className="text-sm text-gray-500 mb-3 line-clamp-2">{r.subsidy.description}</p>
                <div className="flex flex-wrap gap-1">
                  {r.reasons.map(reason => <span key={reason} className="text-xs bg-green-50 text-green-700 px-2 py-0.5 rounded">{reason}</span>)}
                </div>
              </Link>
            ))}
          </div>
        )}
        <button onClick={() => { setStep(0); setAnswers({}); setResults(null); }} className="mt-8 text-blue-600 hover:underline text-sm">
          もう一度診断する
        </button>
      </div>
    );
  }

  const isMulti = current.key === 'audiences' || current.key === 'categorySlugs';
  const selected = isMulti ? ((answers[current.key] as string[]) || []) : answers[current.key];
  const canNext = isMulti ? ((selected as string[]).length > 0) : !!selected;

  return (
    <div className="max-w-xl mx-auto px-4 py-12">
      <div className="flex items-center gap-2 mb-8">
        {STEPS.map((_, i) => (
          <div key={i} className={`h-2 flex-1 rounded-full ${i <= step ? 'bg-blue-600' : 'bg-gray-200'}`} />
        ))}
      </div>
      <h1 className="text-xl font-bold text-gray-800 mb-6">Q{step + 1}. {current.question}</h1>
      <div className="space-y-3 mb-8">
        {current.options.map(o => {
          const isSelected = isMulti ? (selected as string[]).includes(o.value) : selected === o.value;
          return (
            <button key={o.value} onClick={() => select(o.value)} className={`w-full text-left px-5 py-3 rounded-xl border-2 transition font-medium ${isSelected ? 'border-blue-600 bg-blue-50 text-blue-700' : 'border-gray-200 bg-white text-gray-700 hover:border-gray-300'}`}>
              {o.label}
            </button>
          );
        })}
      </div>
      <button onClick={next} disabled={!canNext || loading} className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition disabled:opacity-40">
        {loading ? '診断中...' : step < STEPS.length - 1 ? '次へ →' : '診断結果を見る'}
      </button>
    </div>
  );
}
