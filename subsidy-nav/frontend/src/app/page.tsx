import Link from 'next/link';

export default function HomePage() {
  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-br from-blue-700 to-blue-900 text-white py-20 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-4xl md:text-5xl font-bold mb-6">補助金ナビ</h1>
          <p className="text-xl md:text-2xl mb-4 text-blue-100">全国の補助金・助成金を、かんたん検索</p>
          <p className="text-blue-200 mb-10">国・都道府県・市区町村の補助金情報を一元化。あなたに合った補助金が見つかります。</p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link href="/subsidies" className="bg-white text-blue-700 px-8 py-3 rounded-lg font-semibold hover:bg-blue-50 transition">
              補助金を検索する
            </Link>
            <Link href="/matching" className="border-2 border-white text-white px-8 py-3 rounded-lg font-semibold hover:bg-white hover:text-blue-700 transition">
              マッチング診断（3問）
            </Link>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-16 px-4 bg-white">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-2xl font-bold text-center mb-12 text-gray-800">補助金ナビでできること</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[
              { icon: '🔍', title: '補助金を検索', desc: '地域・カテゴリ・対象者で絞り込み検索。締切間近の補助金も一目でわかります。', href: '/subsidies' },
              { icon: '🎯', title: 'マッチング診断', desc: '3つの質問に答えるだけで、あなたに合った補助金をAIが診断します。', href: '/matching' },
              { icon: '📄', title: '申請書テンプレート', desc: '7種類の申請書テンプレートをPDF形式で即時ダウンロード。', href: '/templates' },
              { icon: '🔔', title: 'アラート登録', desc: '新着・締切間近の補助金情報をメールでお知らせします。', href: '/alerts' },
              { icon: '💼', title: 'コンサルティング相談', desc: '補助金申請のプロが申請書作成から採択まで伴走支援します。', href: '/consulting' },
              { icon: '📊', title: '管理画面', desc: '補助金情報の管理、スクレイピング実行、お問い合わせ管理。', href: '/admin' },
            ].map(f => (
              <Link key={f.title} href={f.href} className="bg-gray-50 rounded-xl p-6 hover:shadow-md transition text-center">
                <div className="text-4xl mb-3">{f.icon}</div>
                <h3 className="font-semibold text-lg mb-2 text-gray-800">{f.title}</h3>
                <p className="text-gray-600 text-sm">{f.desc}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="py-12 bg-blue-50 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
            {[
              { num: '1,735', label: '市区町村' },
              { num: '47', label: '都道府県' },
              { num: '週次', label: '自動更新' },
              { num: '無料', label: '利用料金' },
            ].map(s => (
              <div key={s.label} className="bg-white rounded-xl p-5 shadow-sm">
                <div className="text-3xl font-bold text-blue-600 mb-1">{s.num}</div>
                <div className="text-gray-600 text-sm">{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-16 px-4 bg-white text-center">
        <h2 className="text-2xl font-bold mb-4 text-gray-800">今すぐアラート登録</h2>
        <p className="text-gray-600 mb-8">新着補助金情報をメールでお届けします。無料です。</p>
        <Link href="/alerts" className="bg-blue-600 text-white px-10 py-3 rounded-lg font-semibold hover:bg-blue-700 transition">
          無料で登録する
        </Link>
      </section>
    </div>
  );
}
