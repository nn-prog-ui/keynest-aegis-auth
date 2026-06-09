import Link from 'next/link';
import { Search, Bell, FileText, TrendingUp, MapPin, ChevronRight } from 'lucide-react';
import { getSubsidyStats, getSubsidies } from '@/lib/api';
import SubsidyCard from '@/components/SubsidyCard';

const FEATURES = [
  {
    icon: Search,
    title: '全国1,700以上の市区町村を網羅',
    desc: '都道府県・市区町村・カテゴリ・対象者で絞り込み。あなたに関係する補助金をすぐに発見。',
  },
  {
    icon: Bell,
    title: '締め切り前に自動通知',
    desc: 'メールアドレスを登録するだけ。新着補助金や締め切り14日前に自動でお知らせします。',
  },
  {
    icon: FileText,
    title: '申請サポート・コンサルティング',
    desc: '補助金の選定から書類作成まで専門家がサポート。採択率を最大化します。',
  },
  {
    icon: TrendingUp,
    title: 'リアルタイム更新',
    desc: '各市区町村の公式サイトを定期巡回。新しい補助金情報をいち早く届けます。',
  },
];

const CATEGORIES = [
  { slug: 'business', name: '創業・事業拡大', icon: '💼', count: 324 },
  { slug: 'childcare', name: '子育て・教育', icon: '👶', count: 891 },
  { slug: 'housing', name: '住宅・リフォーム', icon: '🏠', count: 567 },
  { slug: 'environment', name: '省エネ・環境', icon: '🌿', count: 412 },
  { slug: 'agriculture', name: '農業・林業', icon: '🌾', count: 298 },
  { slug: 'it', name: 'IT・デジタル化', icon: '💻', count: 203 },
  { slug: 'welfare', name: '福祉・障害者支援', icon: '♿', count: 445 },
  { slug: 'elderly', name: '高齢者支援', icon: '👴', count: 334 },
];

export default async function HomePage() {
  const [stats, recent] = await Promise.allSettled([
    getSubsidyStats(),
    getSubsidies({ status: 'ACTIVE', sortBy: 'newest', limit: 6 }),
  ]);

  const statsData = stats.status === 'fulfilled' ? stats.value : null;
  const recentData = recent.status === 'fulfilled' ? recent.value.data : [];

  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-br from-brand-800 via-brand-700 to-brand-600 text-white">
        <div className="max-w-6xl mx-auto px-4 py-20 text-center">
          <div className="inline-flex items-center gap-2 bg-white/10 rounded-full px-4 py-1.5 text-sm mb-6">
            <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
            毎日更新 — 全国の補助金をリアルタイムで配信
          </div>
          <h1 className="text-4xl md:text-5xl font-bold mb-6 leading-tight">
            あなたの市区町村の補助金を
            <br />
            <span className="text-yellow-300">見逃さない</span>
          </h1>
          <p className="text-xl text-blue-100 mb-10 max-w-2xl mx-auto">
            全国1,700以上の市区町村・国・都道府県の補助金・助成金情報を一括検索。
            締め切り前に自動通知、申請サポートまでワンストップで対応します。
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/subsidies"
              className="btn-primary bg-white text-brand-700 hover:bg-blue-50 text-base px-8 py-3"
            >
              <Search size={18} />
              補助金を検索する
            </Link>
            <Link
              href="/alerts"
              className="btn-secondary border-white/30 text-white hover:bg-white/10 text-base px-8 py-3"
            >
              <Bell size={18} />
              無料でアラート登録
            </Link>
          </div>

          {statsData && (
            <div className="flex justify-center gap-8 mt-14 text-center">
              <div>
                <div className="text-3xl font-bold text-yellow-300">
                  {statsData.total.toLocaleString()}
                </div>
                <div className="text-blue-200 text-sm mt-1">登録補助金数</div>
              </div>
              <div className="w-px bg-white/20" />
              <div>
                <div className="text-3xl font-bold text-green-300">
                  {statsData.active.toLocaleString()}
                </div>
                <div className="text-blue-200 text-sm mt-1">現在受付中</div>
              </div>
              <div className="w-px bg-white/20" />
              <div>
                <div className="text-3xl font-bold text-red-300">
                  {statsData.endingSoon.toLocaleString()}
                </div>
                <div className="text-blue-200 text-sm mt-1">2週間以内に締切</div>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* Search Bar */}
      <section className="bg-white border-b border-gray-200 sticky top-0 z-10 shadow-sm">
        <div className="max-w-4xl mx-auto px-4 py-3">
          <form action="/subsidies" method="get">
            <div className="flex gap-2">
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                <input
                  name="keyword"
                  type="text"
                  placeholder="補助金名・キーワードで検索（例：太陽光、創業、子育て）"
                  className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
              </div>
              <button type="submit" className="btn-primary">
                検索
              </button>
            </div>
          </form>
        </div>
      </section>

      {/* Categories */}
      <section className="max-w-6xl mx-auto px-4 py-12">
        <h2 className="text-2xl font-bold mb-6">カテゴリから探す</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {CATEGORIES.map((cat) => (
            <Link
              key={cat.slug}
              href={`/subsidies?categorySlug=${cat.slug}`}
              className="card p-4 hover:border-brand-300 hover:shadow-md transition-all group"
            >
              <div className="text-3xl mb-2">{cat.icon}</div>
              <div className="font-medium text-sm group-hover:text-brand-700">
                {cat.name}
              </div>
              <div className="text-xs text-gray-500 mt-0.5">{cat.count}件以上</div>
            </Link>
          ))}
        </div>
      </section>

      {/* Recent Subsidies */}
      {recentData.length > 0 && (
        <section className="max-w-6xl mx-auto px-4 py-8">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold">新着補助金情報</h2>
            <Link href="/subsidies" className="text-brand-600 hover:text-brand-800 text-sm flex items-center gap-1">
              すべて見る <ChevronRight size={16} />
            </Link>
          </div>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
            {recentData.map((subsidy) => (
              <SubsidyCard key={subsidy.id} subsidy={subsidy} />
            ))}
          </div>
        </section>
      )}

      {/* Features */}
      <section className="bg-gray-100 py-16">
        <div className="max-w-6xl mx-auto px-4">
          <h2 className="text-2xl font-bold text-center mb-10">
            補助金ナビが選ばれる理由
          </h2>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {FEATURES.map((f) => (
              <div key={f.title} className="card p-6">
                <div className="w-12 h-12 bg-brand-100 rounded-xl flex items-center justify-center mb-4">
                  <f.icon className="text-brand-600" size={24} />
                </div>
                <h3 className="font-bold mb-2">{f.title}</h3>
                <p className="text-sm text-gray-600">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Map section */}
      <section className="max-w-6xl mx-auto px-4 py-16">
        <div className="text-center mb-10">
          <h2 className="text-2xl font-bold mb-3">都道府県から探す</h2>
          <p className="text-gray-600">お住まいの地域の補助金情報を確認しましょう</p>
        </div>
        <div className="grid grid-cols-3 sm:grid-cols-5 md:grid-cols-8 gap-2">
          {[
            '北海道', '青森', '岩手', '宮城', '秋田', '山形', '福島',
            '茨城', '栃木', '群馬', '埼玉', '千葉', '東京', '神奈川',
            '新潟', '富山', '石川', '福井', '山梨', '長野', '岐阜',
            '静岡', '愛知', '三重', '滋賀', '京都', '大阪', '兵庫',
            '奈良', '和歌山', '鳥取', '島根', '岡山', '広島', '山口',
            '徳島', '香川', '愛媛', '高知', '福岡', '佐賀', '長崎',
            '熊本', '大分', '宮崎', '鹿児島', '沖縄',
          ].map((pref) => (
            <Link
              key={pref}
              href={`/subsidies?keyword=${pref}`}
              className="text-center py-2 px-1 text-xs rounded-lg bg-white border border-gray-200 hover:border-brand-400 hover:text-brand-700 hover:bg-brand-50 transition-all"
            >
              <MapPin size={12} className="mx-auto mb-0.5 text-gray-400" />
              {pref}
            </Link>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="bg-brand-700 text-white py-16">
        <div className="max-w-3xl mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold mb-4">
            補助金申請、プロに任せませんか？
          </h2>
          <p className="text-blue-100 mb-8 text-lg">
            補助金の選定から申請書類の作成まで、専門コンサルタントが全面サポート。
            採択率を最大化し、事業成長を加速させます。
          </p>
          <Link href="/consulting" className="btn-primary bg-white text-brand-700 hover:bg-blue-50 text-base px-8 py-3">
            <FileText size={18} />
            無料相談を申し込む
          </Link>
        </div>
      </section>
    </div>
  );
}
