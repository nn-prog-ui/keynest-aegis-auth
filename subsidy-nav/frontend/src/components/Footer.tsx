import Link from 'next/link';

export default function Footer() {
  return (
    <footer className="bg-gray-800 text-gray-300 py-12 px-4">
      <div className="max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-4 gap-8">
        <div>
          <h3 className="text-white font-bold text-lg mb-3">補助金ナビ</h3>
          <p className="text-sm">全国の補助金・助成金情報を一元化したナビゲーションサービスです。</p>
        </div>
        <div>
          <h4 className="text-white font-semibold mb-3">サービス</h4>
          <ul className="space-y-2 text-sm">
            <li><Link href="/subsidies" className="hover:text-white transition">補助金検索</Link></li>
            <li><Link href="/matching" className="hover:text-white transition">マッチング診断</Link></li>
            <li><Link href="/templates" className="hover:text-white transition">申請書テンプレート</Link></li>
          </ul>
        </div>
        <div>
          <h4 className="text-white font-semibold mb-3">サポート</h4>
          <ul className="space-y-2 text-sm">
            <li><Link href="/alerts" className="hover:text-white transition">アラート登録</Link></li>
            <li><Link href="/consulting" className="hover:text-white transition">コンサルティング相談</Link></li>
          </ul>
        </div>
        <div>
          <h4 className="text-white font-semibold mb-3">管理</h4>
          <ul className="space-y-2 text-sm">
            <li><Link href="/admin" className="hover:text-white transition">管理画面</Link></li>
          </ul>
        </div>
      </div>
      <div className="max-w-6xl mx-auto mt-8 pt-8 border-t border-gray-700 text-center text-sm">
        <p>&copy; {new Date().getFullYear()} 補助金ナビ All rights reserved.</p>
      </div>
    </footer>
  );
}
