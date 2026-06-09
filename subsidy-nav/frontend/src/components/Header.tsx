import Link from 'next/link';

export default function Header() {
  return (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-50">
      <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
        <Link href="/" className="text-xl font-bold text-blue-700">補助金ナビ</Link>
        <nav className="hidden md:flex items-center gap-6 text-sm text-gray-700">
          <Link href="/subsidies" className="hover:text-blue-600 transition">補助金検索</Link>
          <Link href="/matching" className="hover:text-blue-600 transition">マッチング診断</Link>
          <Link href="/templates" className="hover:text-blue-600 transition">申請書</Link>
          <Link href="/alerts" className="hover:text-blue-600 transition">アラート</Link>
          <Link href="/consulting" className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition">相談する</Link>
        </nav>
      </div>
    </header>
  );
}
