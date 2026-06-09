# 補助金ナビ (Subsidy Navigator)

全国1,700以上の市区町村・都道府県・国の補助金・助成金情報をタイムリーに届けるプラットフォーム。

## 概要

補助金・助成金は市区町村によって締め切りが異なり、新しく出ても気づかない人が多いという課題を解決します。  
本サービスは情報収集 → アラート通知 → コンサルティング申込 をワンストップで提供します。

## 主な機能

| 機能 | 説明 |
|------|------|
| 🔍 補助金検索 | キーワード・地域・カテゴリ・対象者で絞り込み |
| 🔔 アラート通知 | 新着・締め切り前にメールで自動通知 |
| 📋 詳細情報 | 申請要件・補助率・申請方法を一覧で確認 |
| 💼 コンサルティング | 申請サポート・書類作成・事業戦略の依頼 |
| 🗾 都道府県別 | 全47都道府県・1,700以上の市区町村対応 |

## 技術スタック

| レイヤー | 技術 |
|----------|------|
| フロントエンド | Next.js 14 (App Router), TypeScript, Tailwind CSS |
| バックエンド | Node.js, Express, TypeScript |
| データベース | PostgreSQL + Prisma ORM |
| 通知 | Nodemailer (SMTP) |
| スケジューラー | node-cron (毎日8時に締切通知) |
| コンテナ | Docker / docker-compose |

## ディレクトリ構成

```
subsidy-nav/
├── backend/           # Express API サーバー
│   ├── src/
│   │   ├── routes/    # API エンドポイント
│   │   ├── services/  # ビジネスロジック
│   │   ├── middleware/
│   │   └── seeds/     # 初期データ
│   └── prisma/        # DB スキーマ
└── frontend/          # Next.js フロントエンド
    └── src/
        ├── app/       # ページ
        ├── components/
        ├── lib/       # API クライアント・ユーティリティ
        └── types/
```

## セットアップ

### Docker を使う場合（推奨）

```bash
cd subsidy-nav
cp backend/.env.example backend/.env
docker-compose up -d
docker-compose exec backend npm run db:migrate
docker-compose exec backend npm run db:seed
```

### ローカル開発

**バックエンド:**
```bash
cd subsidy-nav/backend
npm install
cp .env.example .env
# .env の DATABASE_URL を設定
npm run db:generate
npm run db:migrate
npm run db:seed
npm run dev
```

**フロントエンド:**
```bash
cd subsidy-nav/frontend
npm install
npm run dev
```

## API エンドポイント

| メソッド | パス | 説明 |
|----------|------|------|
| GET | `/api/subsidies` | 補助金一覧・検索 |
| GET | `/api/subsidies/stats` | 統計情報 |
| GET | `/api/subsidies/:id` | 補助金詳細 |
| GET | `/api/municipalities/prefectures` | 都道府県一覧 |
| POST | `/api/alerts` | アラート登録 |
| GET | `/api/alerts/verify/:token` | メール確認 |
| POST | `/api/consulting` | コンサルティング相談 |
| POST | `/api/admin/subsidies` | 補助金登録（管理者） |

## データモデル

```
Prefecture (都道府県) → Municipality (市区町村) → Subsidy (補助金)
SubsidyCategory (カテゴリ)
AlertPreference (アラート設定)
ConsultingInquiry (コンサル問い合わせ)
```

## 今後のロードマップ

- [ ] 市区町村 Webサイト自動スクレイピング機能
- [ ] LINE通知対応
- [ ] 申請書類テンプレート提供
- [ ] AI による補助金マッチング提案
- [ ] 管理者ダッシュボード（申請件数・採択率の管理）
- [ ] 全国1,741市区町村データの完全収録
