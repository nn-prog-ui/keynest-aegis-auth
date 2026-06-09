'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Menu, X, Bell, Search } from 'lucide-react';

const NAV_LINKS = [
  { href: '/subsidies', label: '補助金を探す' },
  { href: '/matching', label: '診断で探す' },
  { href: '/alerts', label: 'アラート登録' },
  { href: '/consulting', label: 'コンサルティング' },
];

export default function Header() {
  const [open, setOpen] = useState(false);

  return (
    <header className="bg-white border-b border-gray-200">
      <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2">
          <div className="w-8 h-8 bg-brand-600 rounded-lg flex items-center justify-center">
            <Search size={16} className="text-white" />
          </div>
          <span className="font-bold text-xl text-brand-800">補助金ナビ</span>
        </Link>

        <nav className="hidden md:flex items-center gap-6">
          {NAV_LINKS.map((l) => (
            <Link
              key={l.href}
              href={l.href}
              className="text-gray-600 hover:text-brand-700 font-medium text-sm transition-colors"
            >
              {l.label}
            </Link>
          ))}
          <Link href="/alerts" className="btn-primary text-sm py-2">
            <Bell size={15} />
            無料アラート登録
          </Link>
        </nav>

        <button
          className="md:hidden p-2 text-gray-600"
          onClick={() => setOpen(!open)}
          aria-label="メニュー"
        >
          {open ? <X size={22} /> : <Menu size={22} />}
        </button>
      </div>

      {open && (
        <div className="md:hidden bg-white border-t border-gray-100 py-4 px-4 space-y-3">
          {NAV_LINKS.map((l) => (
            <Link
              key={l.href}
              href={l.href}
              className="block py-2 text-gray-700 font-medium"
              onClick={() => setOpen(false)}
            >
              {l.label}
            </Link>
          ))}
          <Link href="/alerts" className="btn-primary w-full justify-center">
            <Bell size={15} />
            無料アラート登録
          </Link>
        </div>
      )}
    </header>
  );
}
