import Link from 'next/link';

export default function Footer() {
  return (
    <footer className="bg-gray-900 text-gray-400 py-12">
      <div className="max-w-6xl mx-auto px-4">
        <div className="grid md:grid-cols-4 gap-8 mb-8">
          <div>
            <div className="text-white font-bold text-lg mb-3">補助金ナビ</div>
            <p className="text-sm leading-relaxed">
              全国の補助金・助成金情報をタイムリーに届ける情報プラットフォーム。
            </p>
          </div>
          <div>
            <div className="text-white font-medium mb-3">補助金を探す</div>
            <ul className="space-y-2 text-sm">
              <li><Link href="/subsidies" className="hover:text-white">全ての補助金</Link></li>
              <li><Link href="/subsidies?status=ACTIVE" className="hover:text-white">受付中の補助金</Link></li>
              <li><Link href="/subsidies?sortBy=deadline" className="hover:text-white">締め切り間近</Link></li>
              <li><Link href="/subsidies?isNational=true" className="hover:text-white">国の補助金</Link></li>
            </ul>
          </div>
          <div>
            <div className="text-white font-medium mb-3">サービス</div>
            <ul className="space-y-2 text-sm">
              <li><Link href="/alerts" className="hover:text-white">アラート登録</Link></li>
              <li><Link href="/consulting" className="hover:text-white">コンサルティング</Link></li>
              <li><Link href="/consulting" className="hover:text-white">申請サポート</Link></li>
            </ul>
          </div>
          <div>
            <div className="text-white font-medium mb-3">カテゴリ</div>
            <ul className="space-y-2 text-sm">
              <li><Link href="/subsidies?categorySlug=business" className="hover:text-white">創業・事業拡大</Link></li>
              <li><Link href="/subsidies?categorySlug=childcare" className="hover:text-white">子育て・教育</Link></li>
              <li><Link href="/subsidies?categorySlug=environment" className="hover:text-white">省エネ・環境</Link></li>
              <li><Link href="/subsidies?categorySlug=it" className="hover:text-white">IT・デジタル化</Link></li>
            </ul>
          </div>
        </div>
        <div className="border-t border-gray-800 pt-6 text-sm flex flex-col sm:flex-row justify-between gap-3">
          <div>© 2026 補助金ナビ. All rights reserved.</div>
          <div className="flex gap-4">
            <Link href="/privacy" className="hover:text-white">プライバシーポリシー</Link>
            <Link href="/terms" className="hover:text-white">利用規約</Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
