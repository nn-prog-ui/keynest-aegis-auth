import { PrismaClient, MunicipalityType, SubsidyStatus, TargetAudience } from '@prisma/client';
import { NATIONAL_SUBSIDIES } from './subsidies-master';
import { ALL_MUNICIPALITIES } from '../data/municipalities-all';

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

  // 全国主要市区町村（政令指定都市・県庁所在地・特別区を中心に）
  const prefMap: Record<string, number> = {};
  const allPrefs = await prisma.prefecture.findMany();
  for (const p of allPrefs) prefMap[p.code] = p.id;

  const municipalities = [
    // 北海道
    { prefectureId: prefMap['01'], code: '01100', name: '札幌市', nameKana: 'サッポロシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['01'], code: '01202', name: '函館市', nameKana: 'ハコダテシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['01'], code: '01204', name: '旭川市', nameKana: 'アサヒカワシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['01'], code: '01206', name: '釧路市', nameKana: 'クシロシ', type: MunicipalityType.CITY },
    // 東北
    { prefectureId: prefMap['02'], code: '02201', name: '青森市', nameKana: 'アオモリシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['02'], code: '02202', name: '弘前市', nameKana: 'ヒロサキシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['03'], code: '03201', name: '盛岡市', nameKana: 'モリオカシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['04'], code: '04100', name: '仙台市', nameKana: 'センダイシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['05'], code: '05201', name: '秋田市', nameKana: 'アキタシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['06'], code: '06201', name: '山形市', nameKana: 'ヤマガタシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['07'], code: '07201', name: '福島市', nameKana: 'フクシマシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['07'], code: '07204', name: 'いわき市', nameKana: 'イワキシ', type: MunicipalityType.CITY },
    // 関東
    { prefectureId: prefMap['08'], code: '08201', name: '水戸市', nameKana: 'ミトシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['08'], code: '08220', name: 'つくば市', nameKana: 'ツクバシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['09'], code: '09201', name: '宇都宮市', nameKana: 'ウツノミヤシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['10'], code: '10201', name: '前橋市', nameKana: 'マエバシシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['10'], code: '10202', name: '高崎市', nameKana: 'タカサキシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['11'], code: '11100', name: 'さいたま市', nameKana: 'サイタマシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['11'], code: '11202', name: '川越市', nameKana: 'カワゴエシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['11'], code: '11203', name: '熊谷市', nameKana: 'クマガヤシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['12'], code: '12100', name: '千葉市', nameKana: 'チバシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['12'], code: '12204', name: '船橋市', nameKana: 'フナバシシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['12'], code: '12217', name: '柏市', nameKana: 'カシワシ', type: MunicipalityType.CITY },
    // 東京23区
    { prefectureId: prefMap['13'], code: '13101', name: '千代田区', nameKana: 'チヨダク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13102', name: '中央区', nameKana: 'チュウオウク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13103', name: '港区', nameKana: 'ミナトク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13104', name: '新宿区', nameKana: 'シンジュクク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13105', name: '文京区', nameKana: 'ブンキョウク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13106', name: '台東区', nameKana: 'タイトウク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13107', name: '墨田区', nameKana: 'スミダク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13108', name: '江東区', nameKana: 'コウトウク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13109', name: '品川区', nameKana: 'シナガワク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13110', name: '目黒区', nameKana: 'メグロク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13111', name: '大田区', nameKana: 'オオタク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13112', name: '世田谷区', nameKana: 'セタガヤク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13113', name: '渋谷区', nameKana: 'シブヤク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13114', name: '中野区', nameKana: 'ナカノク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13115', name: '杉並区', nameKana: 'スギナミク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13116', name: '豊島区', nameKana: 'トシマク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13117', name: '北区', nameKana: 'キタク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13118', name: '荒川区', nameKana: 'アラカワク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13119', name: '板橋区', nameKana: 'イタバシク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13120', name: '練馬区', nameKana: 'ネリマク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13121', name: '足立区', nameKana: 'アダチク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13122', name: '葛飾区', nameKana: 'カツシカク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13123', name: '江戸川区', nameKana: 'エドガワク', type: MunicipalityType.WARD },
    { prefectureId: prefMap['13'], code: '13201', name: '八王子市', nameKana: 'ハチオウジシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['13'], code: '13202', name: '立川市', nameKana: 'タチカワシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['13'], code: '13206', name: '三鷹市', nameKana: 'ミタカシ', type: MunicipalityType.CITY },
    // 神奈川
    { prefectureId: prefMap['14'], code: '14100', name: '横浜市', nameKana: 'ヨコハマシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['14'], code: '14130', name: '川崎市', nameKana: 'カワサキシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['14'], code: '14150', name: '相模原市', nameKana: 'サガミハラシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['14'], code: '14201', name: '横須賀市', nameKana: 'ヨコスカシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['14'], code: '14203', name: '平塚市', nameKana: 'ヒラツカシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['14'], code: '14204', name: '鎌倉市', nameKana: 'カマクラシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['14'], code: '14210', name: '藤沢市', nameKana: 'フジサワシ', type: MunicipalityType.CITY },
    // 甲信越・北陸
    { prefectureId: prefMap['15'], code: '15100', name: '新潟市', nameKana: 'ニイガタシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['16'], code: '16201', name: '富山市', nameKana: 'トヤマシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['17'], code: '17201', name: '金沢市', nameKana: 'カナザワシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['18'], code: '18201', name: '福井市', nameKana: 'フクイシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['19'], code: '19201', name: '甲府市', nameKana: 'コウフシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['20'], code: '20201', name: '長野市', nameKana: 'ナガノシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['20'], code: '20202', name: '松本市', nameKana: 'マツモトシ', type: MunicipalityType.CITY },
    // 東海
    { prefectureId: prefMap['21'], code: '21201', name: '岐阜市', nameKana: 'ギフシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['22'], code: '22100', name: '静岡市', nameKana: 'シズオカシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['22'], code: '22130', name: '浜松市', nameKana: 'ハママツシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['23'], code: '23100', name: '名古屋市', nameKana: 'ナゴヤシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['23'], code: '23202', name: '豊橋市', nameKana: 'トヨハシシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['23'], code: '23204', name: '豊田市', nameKana: 'トヨタシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['24'], code: '24201', name: '津市', nameKana: 'ツシ', type: MunicipalityType.CITY },
    // 近畿
    { prefectureId: prefMap['25'], code: '25201', name: '大津市', nameKana: 'オオツシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['26'], code: '26100', name: '京都市', nameKana: 'キョウトシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['27'], code: '27100', name: '大阪市', nameKana: 'オオサカシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['27'], code: '27140', name: '堺市', nameKana: 'サカイシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['27'], code: '27203', name: '豊中市', nameKana: 'トヨナカシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['27'], code: '27207', name: '枚方市', nameKana: 'ヒラカタシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['28'], code: '28100', name: '神戸市', nameKana: 'コウベシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['28'], code: '28201', name: '姫路市', nameKana: 'ヒメジシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['28'], code: '28210', name: '尼崎市', nameKana: 'アマガサキシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['29'], code: '29201', name: '奈良市', nameKana: 'ナラシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['30'], code: '30201', name: '和歌山市', nameKana: 'ワカヤマシ', type: MunicipalityType.CITY },
    // 中国
    { prefectureId: prefMap['31'], code: '31201', name: '鳥取市', nameKana: 'トットリシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['32'], code: '32201', name: '松江市', nameKana: 'マツエシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['33'], code: '33100', name: '岡山市', nameKana: 'オカヤマシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['34'], code: '34100', name: '広島市', nameKana: 'ヒロシマシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['34'], code: '34202', name: '呉市', nameKana: 'クレシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['34'], code: '34207', name: '福山市', nameKana: 'フクヤマシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['35'], code: '35201', name: '下関市', nameKana: 'シモノセキシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['35'], code: '35203', name: '宇部市', nameKana: 'ウベシ', type: MunicipalityType.CITY },
    // 四国
    { prefectureId: prefMap['36'], code: '36201', name: '徳島市', nameKana: 'トクシマシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['37'], code: '37201', name: '高松市', nameKana: 'タカマツシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['38'], code: '38201', name: '松山市', nameKana: 'マツヤマシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['39'], code: '39201', name: '高知市', nameKana: 'コウチシ', type: MunicipalityType.CITY },
    // 九州
    { prefectureId: prefMap['40'], code: '40100', name: '北九州市', nameKana: 'キタキュウシュウシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['40'], code: '40130', name: '福岡市', nameKana: 'フクオカシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['40'], code: '40203', name: '久留米市', nameKana: 'クルメシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['41'], code: '41201', name: '佐賀市', nameKana: 'サガシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['42'], code: '42201', name: '長崎市', nameKana: 'ナガサキシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['43'], code: '43100', name: '熊本市', nameKana: 'クマモトシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['44'], code: '44201', name: '大分市', nameKana: 'オオイタシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['45'], code: '45201', name: '宮崎市', nameKana: 'ミヤザキシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['46'], code: '46201', name: '鹿児島市', nameKana: 'カゴシマシ', type: MunicipalityType.CITY },
    // 沖縄
    { prefectureId: prefMap['47'], code: '47201', name: '那覇市', nameKana: 'ナハシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['47'], code: '47205', name: '沖縄市', nameKana: 'オキナワシ', type: MunicipalityType.CITY },
    { prefectureId: prefMap['47'], code: '47207', name: '浦添市', nameKana: 'ウラソエシ', type: MunicipalityType.CITY },
  ];

  for (const muni of municipalities) {
    await prisma.municipality.upsert({
      where: { code: muni.code },
      update: {},
      create: muni,
    });
  }
  console.log(`主要市区町村 ${municipalities.length} 件登録完了`);

  // 全国1,741市区町村データの一括投入
  let fullMuniSaved = 0;
  let fullMuniSkipped = 0;
  for (const m of ALL_MUNICIPALITIES) {
    const prefId = prefMap[m.prefCode];
    if (!prefId) { fullMuniSkipped++; continue; }
    await prisma.municipality.upsert({
      where: { code: m.code },
      update: {},
      create: {
        prefectureId: prefId,
        code: m.code,
        name: m.name,
        nameKana: m.nameKana,
        type: m.type as MunicipalityType,
      },
    });
    fullMuniSaved++;
  }
  console.log(`全国市区町村 ${fullMuniSaved} 件登録完了（スキップ: ${fullMuniSkipped} 件）`);

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

  // 国の主要補助金・助成金マスターデータ
  const categories = await prisma.subsidyCategory.findMany();
  const catMap2 = Object.fromEntries(categories.map((c) => [c.slug, c.id]));

  let masterSaved = 0;
  for (const s of NATIONAL_SUBSIDIES) {
    const existing = await prisma.subsidy.findFirst({ where: { title: s.title } });
    if (!existing) {
      await prisma.subsidy.create({
        data: {
          title: s.title,
          description: s.description,
          detail: s.detail,
          categoryId: catMap2[s.categorySlug] ?? catMap2['business'],
          isNational: s.isNational,
          maxAmount: s.maxAmount ? BigInt(s.maxAmount) : undefined,
          subsidyRate: s.subsidyRate,
          targetAudience: s.targetAudience,
          applicationStart: s.applicationStart ? new Date(s.applicationStart) : undefined,
          applicationEnd: s.applicationEnd ? new Date(s.applicationEnd) : undefined,
          sourceUrl: s.sourceUrl,
          status: s.status,
          tags: s.tags,
          requirements: s.requirements,
          howToApply: s.howToApply,
        },
      });
      masterSaved++;
    }
  }
  console.log(`国の主要補助金・助成金 ${masterSaved} 件登録完了（合計 ${NATIONAL_SUBSIDIES.length} 件中）`);

  console.log('シードデータ投入完了！');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
