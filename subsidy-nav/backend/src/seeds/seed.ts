import { PrismaClient, MunicipalityType, SubsidyStatus, TargetAudience } from '@prisma/client';

const prisma = new PrismaClient();

const PREFECTURES = [
  { code: '01', name: '北海道', nameKana: 'ホッカイドウ' },
  { code: '02', name: '青森県', nameKana: 'アオモリケン' },
  { code: '03', name: '岩手県', nameKana: 'イワテケン' },
  { code: '04', name: '宮城県', nameKana: 'ミヤギケン' },
  { code: '05', name: '秋田県', nameKana: 'アキタケン' },
  { code: '06', name: '山形県', nameKana: 'ヤマガタケン' },
  { code: '07', name: '福島県', nameKana: 'フクシマケン' },
  { code: '08', name: '茨城県', nameKana: 'イバラキケン' },
  { code: '09', name: '栃木県', nameKana: 'トチギケン' },
  { code: '10', name: '群馬県', nameKana: 'グンマケン' },
  { code: '11', name: '埼玉県', nameKana: 'サイタマケン' },
  { code: '12', name: '千葉県', nameKana: 'チバケン' },
  { code: '13', name: '東京都', nameKana: 'トウキョウト' },
  { code: '14', name: '神奈川県', nameKana: 'カナガワケン' },
  { code: '15', name: '新潟県', nameKana: 'ニイガタケン' },
  { code: '16', name: '富山県', nameKana: 'トヤマケン' },
  { code: '17', name: '石川県', nameKana: 'イシカワケン' },
  { code: '18', name: '福井県', nameKana: 'フクイケン' },
  { code: '19', name: '山梨県', nameKana: 'ヤマナシケン' },
  { code: '20', name: '長野県', nameKana: 'ナガノケン' },
  { code: '21', name: '岐阜県', nameKana: 'ギフケン' },
  { code: '22', name: '静岡県', nameKana: 'シズオカケン' },
  { code: '23', name: '愛知県', nameKana: 'アイチケン' },
  { code: '24', name: '三重県', nameKana: 'ミエケン' },
  { code: '25', name: '滋賀県', nameKana: 'シガケン' },
  { code: '26', name: '京都府', nameKana: 'キョウトフ' },
  { code: '27', name: '大阪府', nameKana: 'オオサカフ' },
  { code: '28', name: '兵庫県', nameKana: 'ヒョウゴケン' },
  { code: '29', name: '奈良県', nameKana: 'ナラケン' },
  { code: '30', name: '和歌山県', nameKana: 'ワカヤマケン' },
  { code: '31', name: '鳥取県', nameKana: 'トットリケン' },
  { code: '32', name: '島根県', nameKana: 'シマネケン' },
  { code: '33', name: '岡山県', nameKana: 'オカヤマケン' },
  { code: '34', name: '広島県', nameKana: 'ヒロシマケン' },
  { code: '35', name: '山口県', nameKana: 'ヤマグチケン' },
  { code: '36', name: '徳島県', nameKana: 'トクシマケン' },
  { code: '37', name: '香川県', nameKana: 'カガワケン' },
  { code: '38', name: '愛媛県', nameKana: 'エヒメケン' },
  { code: '39', name: '高知県', nameKana: 'コウチケン' },
  { code: '40', name: '福岡県', nameKana: 'フクオカケン' },
  { code: '41', name: '佐賀県', nameKana: 'サガケン' },
  { code: '42', name: '長崎県', nameKana: 'ナガサキケン' },
  { code: '43', name: '熊本県', nameKana: 'クマモトケン' },
  { code: '44', name: '大分県', nameKana: 'オオイタケン' },
  { code: '45', name: '宮崎県', nameKana: 'ミヤザキケン' },
  { code: '46', name: '鹿児島県', nameKana: 'カゴシマケン' },
  { code: '47', name: '沖縄県', nameKana: 'オキナワケン' },
];

const CATEGORIES = [
  { slug: 'childcare', name: '子育て・教育支援', icon: '👶' },
  { slug: 'housing', name: '住宅・リフォーム', icon: '🏠' },
  { slug: 'business', name: '創業・事業拡大', icon: '💼' },
  { slug: 'agriculture', name: '農業・林業・水産業', icon: '🌾' },
  { slug: 'welfare', name: '福祉・障害者支援', icon: '♿' },
  { slug: 'environment', name: '省エネ・環境', icon: '🌿' },
  { slug: 'elderly', name: '高齢者支援', icon: '👴' },
  { slug: 'disaster', name: '防災・災害復興', icon: '🏔️' },
  { slug: 'tourism', name: '観光・地域活性化', icon: '🗾' },
  { slug: 'it', name: 'IT・デジタル化', icon: '💻' },
];

async function main() {
  console.log('シードデータ投入開始...');

  // 都道府県
  for (const pref of PREFECTURES) {
    await prisma.prefecture.upsert({
      where: { code: pref.code },
      update: {},
      create: pref,
    });
  }
  console.log(`都道府県 ${PREFECTURES.length} 件登録完了`);

  // 主要市区町村（東京・大阪・愛知のサンプル）
  const tokyo = await prisma.prefecture.findUnique({ where: { code: '13' } });
  const osaka = await prisma.prefecture.findUnique({ where: { code: '27' } });
  const aichi = await prisma.prefecture.findUnique({ where: { code: '23' } });

  const municipalities = [
    { prefectureId: tokyo!.id, code: '13101', name: '千代田区', nameKana: 'チヨダク', type: MunicipalityType.WARD },
    { prefectureId: tokyo!.id, code: '13102', name: '中央区', nameKana: 'チュウオウク', type: MunicipalityType.WARD },
    { prefectureId: tokyo!.id, code: '13113', name: '渋谷区', nameKana: 'シブヤク', type: MunicipalityType.WARD },
    { prefectureId: tokyo!.id, code: '13201', name: '八王子市', nameKana: 'ハチオウジシ', type: MunicipalityType.CITY },
    { prefectureId: osaka!.id, code: '27100', name: '大阪市', nameKana: 'オオサカシ', type: MunicipalityType.CITY },
    { prefectureId: osaka!.id, code: '27140', name: '堺市', nameKana: 'サカイシ', type: MunicipalityType.CITY },
    { prefectureId: aichi!.id, code: '23100', name: '名古屋市', nameKana: 'ナゴヤシ', type: MunicipalityType.CITY },
  ];

  for (const muni of municipalities) {
    await prisma.municipality.upsert({
      where: { code: muni.code },
      update: {},
      create: muni,
    });
  }
  console.log(`市区町村 ${municipalities.length} 件登録完了`);

  // カテゴリ
  for (const cat of CATEGORIES) {
    await prisma.subsidyCategory.upsert({
      where: { slug: cat.slug },
      update: {},
      create: cat,
    });
  }
  console.log(`カテゴリ ${CATEGORIES.length} 件登録完了`);

  // サンプル補助金データ
  const categories = await prisma.subsidyCategory.findMany();
  const catMap = Object.fromEntries(categories.map((c) => [c.slug, c.id]));
  const tokyoPref = await prisma.prefecture.findUnique({ where: { code: '13' } });
  const shibuyaWard = await prisma.municipality.findUnique({ where: { code: '13113' } });
  const osakaMuni = await prisma.municipality.findUnique({ where: { code: '27100' } });

  const sampleSubsidies = [
    {
      title: '中小企業デジタル化推進補助金',
      description: '中小企業・小規模事業者がITツール導入やデジタル化を推進するための費用を補助します。クラウドサービス、業務システム、EC構築などが対象です。',
      detail: '補助率は中小企業が1/2、小規模事業者が2/3。IT導入支援事業者を通じた申請が必要です。',
      categoryId: catMap['it'],
      isNational: true,
      maxAmount: BigInt(4500000),
      subsidyRate: 0.5,
      targetAudience: [TargetAudience.CORPORATION],
      applicationStart: new Date('2026-04-01'),
      applicationEnd: new Date('2026-09-30'),
      sourceUrl: 'https://www.it-hojo.jp/',
      status: SubsidyStatus.ACTIVE,
      tags: ['IT', 'デジタル化', '中小企業', 'クラウド'],
      requirements: '・中小企業・小規模事業者であること\n・IT導入支援事業者が提供するITツールの導入であること',
      howToApply: '1. IT導入支援事業者を選定\n2. ITツールの選定\n3. 申請マイページから申請\n4. 採択後に契約・導入',
    },
    {
      title: '渋谷区子育て支援給付金',
      description: '0〜2歳の子を持つ世帯を対象に、保育費用の一部を給付します。認可外保育施設の利用料も対象です。',
      categoryId: catMap['childcare'],
      municipalityId: shibuyaWard!.id,
      prefectureId: tokyoPref!.id,
      isNational: false,
      maxAmount: BigInt(60000),
      subsidyRate: 0.5,
      targetAudience: [TargetAudience.CHILD],
      applicationStart: new Date('2026-04-01'),
      applicationEnd: new Date('2027-03-31'),
      sourceUrl: 'https://www.city.shibuya.tokyo.jp/',
      status: SubsidyStatus.ACTIVE,
      tags: ['子育て', '保育', '給付金', '渋谷区'],
    },
    {
      title: '大阪市創業支援補助金',
      description: '大阪市内で新たに創業する方を対象に、起業にかかる費用（設備・広告・専門家費用など）を補助します。',
      categoryId: catMap['business'],
      municipalityId: osakaMuni!.id,
      isNational: false,
      maxAmount: BigInt(2000000),
      subsidyRate: 0.667,
      targetAudience: [TargetAudience.STARTUP],
      applicationStart: new Date('2026-05-01'),
      applicationEnd: new Date('2026-08-31'),
      sourceUrl: 'https://www.city.osaka.lg.jp/',
      status: SubsidyStatus.ACTIVE,
      tags: ['創業', 'スタートアップ', '大阪市'],
    },
    {
      title: '省エネ設備導入補助金（環境省）',
      description: '工場・事務所等における省エネ設備の更新・導入を支援します。高効率空調、LED照明、省エネ型コンプレッサーなどが対象。',
      categoryId: catMap['environment'],
      isNational: true,
      maxAmount: BigInt(150000000),
      subsidyRate: 0.333,
      targetAudience: [TargetAudience.CORPORATION],
      applicationStart: new Date('2026-03-15'),
      applicationEnd: new Date('2026-06-30'),
      sourceUrl: 'https://www.env.go.jp/',
      status: SubsidyStatus.ACTIVE,
      tags: ['省エネ', '環境', '設備更新', '工場'],
    },
    {
      title: '農業機械等導入支援事業',
      description: '農業の生産性向上を目的とした農業機械・施設の導入を支援します。スマート農業機器も対象。',
      categoryId: catMap['agriculture'],
      isNational: true,
      maxAmount: BigInt(5000000),
      subsidyRate: 0.5,
      targetAudience: [TargetAudience.FARMER],
      applicationStart: new Date('2026-06-01'),
      applicationEnd: new Date('2026-10-31'),
      sourceUrl: 'https://www.maff.go.jp/',
      status: SubsidyStatus.UPCOMING,
      tags: ['農業', '農機具', 'スマート農業'],
    },
  ];

  for (const subsidy of sampleSubsidies) {
    await prisma.subsidy.create({ data: subsidy });
  }
  console.log(`サンプル補助金 ${sampleSubsidies.length} 件登録完了`);

  console.log('シードデータ投入完了！');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
