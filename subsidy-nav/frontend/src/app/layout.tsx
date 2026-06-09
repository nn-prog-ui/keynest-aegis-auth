import type { Metadata } from 'next';
import './globals.css';
import Header from '@/components/Header';
import Footer from '@/components/Footer';

export const metadata: Metadata = {
  title: {
    default: '補助金ナビ | 全国の補助金・助成金情報をタイムリーに',
    template: '%s | 補助金ナビ',
  },
  description:
    '全国1,700以上の市区町村の補助金・助成金情報を一括検索。締め切り前に通知を受け取り、申請サポートまでワンストップで。',
  keywords: ['補助金', '助成金', '市区町村', '創業支援', '子育て支援', '省エネ'],
  openGraph: {
    siteName: '補助金ナビ',
    locale: 'ja_JP',
    type: 'website',
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ja">
      <body>
        <Header />
        <main className="min-h-screen">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
