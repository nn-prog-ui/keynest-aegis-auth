// 全国市区町村 補助金ページ スクレイピング対象URL
// 各自治体の補助金・助成金掲載ページを定義
// 優先度: HIGH=政令市・主要都市、MEDIUM=中規模市、LOW=町村

export interface ScrapeTarget {
  municipalityCode: string;
  name: string;
  prefecture: string;
  urls: string[];           // 複数パターンで試みる
  categoryHints: string[];  // このページで主に扱うカテゴリのslug
  priority: 'HIGH' | 'MEDIUM' | 'LOW';
}

export const SCRAPE_TARGETS: ScrapeTarget[] = [

  // ===== 北海道 =====
  {
    municipalityCode: '01100', name: '札幌市', prefecture: '北海道',
    urls: [
      'https://www.city.sapporo.jp/keizai/shoko/hojokin/',
      'https://www.city.sapporo.jp/shigoto/kigyoshien/',
    ],
    categoryHints: ['business', 'it'], priority: 'HIGH',
  },
  {
    municipalityCode: '01202', name: '函館市', prefecture: '北海道',
    urls: ['https://www.city.hakodate.hokkaido.jp/docs/hojokin/'],
    categoryHints: ['business'], priority: 'MEDIUM',
  },
  {
    municipalityCode: '01204', name: '旭川市', prefecture: '北海道',
    urls: ['https://www.city.asahikawa.hokkaido.jp/sangyo/hojokin/'],
    categoryHints: ['business', 'agriculture'], priority: 'MEDIUM',
  },

  // ===== 宮城県 =====
  {
    municipalityCode: '04100', name: '仙台市', prefecture: '宮城県',
    urls: [
      'https://www.city.sendai.jp/keizai/business/hojokin/',
      'https://www.city.sendai.jp/sangyo/index.html',
    ],
    categoryHints: ['business', 'it', 'startup'], priority: 'HIGH',
  },

  // ===== 埼玉県 =====
  {
    municipalityCode: '11100', name: 'さいたま市', prefecture: '埼玉県',
    urls: [
      'https://www.city.saitama.jp/002/001/004/hojokin.html',
      'https://www.city.saitama.jp/sangyo/',
    ],
    categoryHints: ['business', 'childcare', 'housing'], priority: 'HIGH',
  },

  // ===== 千葉県 =====
  {
    municipalityCode: '12100', name: '千葉市', prefecture: '千葉県',
    urls: [
      'https://www.city.chiba.jp/keizai/hojokin/',
      'https://www.city.chiba.jp/kosodate/josekin/',
    ],
    categoryHints: ['business', 'childcare'], priority: 'HIGH',
  },

  // ===== 東京都 =====
  {
    municipalityCode: '13101', name: '千代田区', prefecture: '東京都',
    urls: [
      'https://www.city.chiyoda.lg.jp/koho/shigoto/hojokin/',
      'https://www.city.chiyoda.lg.jp/koho/kosodate/josei.html',
    ],
    categoryHints: ['business', 'childcare'], priority: 'HIGH',
  },
  {
    municipalityCode: '13104', name: '新宿区', prefecture: '東京都',
    urls: ['https://www.city.shinjuku.lg.jp/sangyo/hojokin.html'],
    categoryHints: ['business', 'childcare'], priority: 'HIGH',
  },
  {
    municipalityCode: '13111', name: '大田区', prefecture: '東京都',
    urls: [
      'https://www.city.ota.tokyo.jp/sangyo/hojokin/',
      'https://www.city.ota.tokyo.jp/seikatsu/kosodate/josei.html',
    ],
    categoryHints: ['business', 'childcare'], priority: 'HIGH',
  },
  {
    municipalityCode: '13112', name: '世田谷区', prefecture: '東京都',
    urls: ['https://www.city.setagaya.lg.jp/mokuji/sangyo/hojokin.html'],
    categoryHints: ['business', 'childcare'], priority: 'HIGH',
  },
  {
    municipalityCode: '13113', name: '渋谷区', prefecture: '東京都',
    urls: [
      'https://www.city.shibuya.tokyo.jp/sangyo/hojokin/',
      'https://www.city.shibuya.tokyo.jp/kosodate/josei/',
    ],
    categoryHints: ['business', 'childcare'], priority: 'HIGH',
  },
  {
    municipalityCode: '13116', name: '豊島区', prefecture: '東京都',
    urls: ['https://www.city.toshima.lg.jp/sangyo/hojokin/'],
    categoryHints: ['business'], priority: 'HIGH',
  },
  {
    municipalityCode: '13120', name: '練馬区', prefecture: '東京都',
    urls: ['https://www.city.nerima.tokyo.jp/sangyo/hojokin.html'],
    categoryHints: ['business', 'childcare'], priority: 'MEDIUM',
  },
  {
    municipalityCode: '13121', name: '足立区', prefecture: '東京都',
    urls: ['https://www.city.adachi.tokyo.jp/sangyo/shigoto/hojokin.html'],
    categoryHints: ['business'], priority: 'MEDIUM',
  },
  {
    municipalityCode: '13201', name: '八王子市', prefecture: '東京都',
    urls: ['https://www.city.hachioji.tokyo.jp/sangyo/hojokin/'],
    categoryHints: ['business', 'agriculture'], priority: 'MEDIUM',
  },

  // ===== 神奈川県 =====
  {
    municipalityCode: '14100', name: '横浜市', prefecture: '神奈川県',
    urls: [
      'https://www.city.yokohama.lg.jp/business/kigyoshien/hojokin/',
      'https://www.city.yokohama.lg.jp/kosodate/hojokin/',
    ],
    categoryHints: ['business', 'childcare', 'it'], priority: 'HIGH',
  },
  {
    municipalityCode: '14130', name: '川崎市', prefecture: '神奈川県',
    urls: [
      'https://www.city.kawasaki.jp/280/hojokin.html',
      'https://www.city.kawasaki.jp/kosodate/hojokin/',
    ],
    categoryHints: ['business', 'childcare'], priority: 'HIGH',
  },
  {
    municipalityCode: '14204', name: '鎌倉市', prefecture: '神奈川県',
    urls: ['https://www.city.kamakura.kanagawa.jp/sangyo/hojokin.html'],
    categoryHints: ['business', 'tourism'], priority: 'MEDIUM',
  },

  // ===== 新潟県 =====
  {
    municipalityCode: '15100', name: '新潟市', prefecture: '新潟県',
    urls: [
      'https://www.city.niigata.lg.jp/business/hojokin/',
      'https://www.city.niigata.lg.jp/kosodate/josei/',
    ],
    categoryHints: ['business', 'agriculture', 'childcare'], priority: 'HIGH',
  },

  // ===== 石川県 =====
  {
    municipalityCode: '17201', name: '金沢市', prefecture: '石川県',
    urls: ['https://www4.city.kanazawa.lg.jp/sangyo/hojokin/'],
    categoryHints: ['business', 'tourism'], priority: 'MEDIUM',
  },

  // ===== 静岡県 =====
  {
    municipalityCode: '22100', name: '静岡市', prefecture: '静岡県',
    urls: ['https://www.city.shizuoka.lg.jp/sangyo_keizai/hojokin/'],
    categoryHints: ['business', 'agriculture'], priority: 'HIGH',
  },
  {
    municipalityCode: '22130', name: '浜松市', prefecture: '静岡県',
    urls: ['https://www.city.hamamatsu.shizuoka.jp/sangyo/hojokin/'],
    categoryHints: ['business', 'agriculture'], priority: 'HIGH',
  },

  // ===== 愛知県 =====
  {
    municipalityCode: '23100', name: '名古屋市', prefecture: '愛知県',
    urls: [
      'https://www.city.nagoya.jp/keizai/page/hojokin.html',
      'https://www.city.nagoya.jp/kosodate/josei/',
    ],
    categoryHints: ['business', 'childcare', 'it'], priority: 'HIGH',
  },
  {
    municipalityCode: '23204', name: '豊田市', prefecture: '愛知県',
    urls: ['https://www.city.toyota.aichi.jp/sangyo/hojokin.html'],
    categoryHints: ['business', 'environment'], priority: 'MEDIUM',
  },

  // ===== 京都府 =====
  {
    municipalityCode: '26100', name: '京都市', prefecture: '京都府',
    urls: [
      'https://www.city.kyoto.lg.jp/sankan/hojokin/',
      'https://www.city.kyoto.lg.jp/hagukumi/josei/',
    ],
    categoryHints: ['business', 'childcare', 'tourism'], priority: 'HIGH',
  },

  // ===== 大阪府 =====
  {
    municipalityCode: '27100', name: '大阪市', prefecture: '大阪府',
    urls: [
      'https://www.city.osaka.lg.jp/keizaisenryaku/page/hojokin.html',
      'https://www.city.osaka.lg.jp/kodomo/josei/',
    ],
    categoryHints: ['business', 'startup', 'childcare'], priority: 'HIGH',
  },
  {
    municipalityCode: '27140', name: '堺市', prefecture: '大阪府',
    urls: ['https://www.city.sakai.lg.jp/sangyo/hojokin/'],
    categoryHints: ['business'], priority: 'MEDIUM',
  },
  {
    municipalityCode: '27207', name: '枚方市', prefecture: '大阪府',
    urls: ['https://www.city.hirakata.osaka.jp/sangyo/hojokin.html'],
    categoryHints: ['business', 'childcare'], priority: 'MEDIUM',
  },

  // ===== 兵庫県 =====
  {
    municipalityCode: '28100', name: '神戸市', prefecture: '兵庫県',
    urls: [
      'https://www.city.kobe.lg.jp/a39447/shigoto/hojokin/',
      'https://www.city.kobe.lg.jp/a46286/kosodate/josei/',
    ],
    categoryHints: ['business', 'childcare', 'it'], priority: 'HIGH',
  },
  {
    municipalityCode: '28201', name: '姫路市', prefecture: '兵庫県',
    urls: ['https://www.city.himeji.lg.jp/sangyo/hojokin/'],
    categoryHints: ['business', 'agriculture'], priority: 'MEDIUM',
  },

  // ===== 広島県 =====
  {
    municipalityCode: '34100', name: '広島市', prefecture: '広島県',
    urls: [
      'https://www.city.hiroshima.lg.jp/site/business/hojokin.html',
      'https://www.city.hiroshima.lg.jp/site/kosodate/josei.html',
    ],
    categoryHints: ['business', 'childcare'], priority: 'HIGH',
  },

  // ===== 福岡県 =====
  {
    municipalityCode: '40130', name: '福岡市', prefecture: '福岡県',
    urls: [
      'https://www.city.fukuoka.lg.jp/keizai/hojokin/',
      'https://www.city.fukuoka.lg.jp/kosodate/josei/',
    ],
    categoryHints: ['business', 'startup', 'childcare', 'it'], priority: 'HIGH',
  },
  {
    municipalityCode: '40100', name: '北九州市', prefecture: '福岡県',
    urls: ['https://www.city.kitakyushu.lg.jp/san-keizai/hojokin.html'],
    categoryHints: ['business', 'environment'], priority: 'HIGH',
  },

  // ===== 熊本県 =====
  {
    municipalityCode: '43100', name: '熊本市', prefecture: '熊本県',
    urls: ['https://www.city.kumamoto.jp/hpKiji/pub/hojokin/'],
    categoryHints: ['business', 'agriculture'], priority: 'HIGH',
  },

  // ===== 沖縄県 =====
  {
    municipalityCode: '47201', name: '那覇市', prefecture: '沖縄県',
    urls: [
      'https://www.city.naha.okinawa.jp/sangyo/hojokin/',
      'https://www.city.naha.okinawa.jp/kosodate/josei/',
    ],
    categoryHints: ['business', 'childcare', 'tourism'], priority: 'HIGH',
  },

  // ===== 都道府県レベル（補助金情報が豊富） =====
  {
    municipalityCode: '01000', name: '北海道（道庁）', prefecture: '北海道',
    urls: ['https://www.pref.hokkaido.lg.jp/kz/chz/hojokin.html'],
    categoryHints: ['business', 'agriculture', 'environment'], priority: 'HIGH',
  },
  {
    municipalityCode: '13000', name: '東京都（都庁）', prefecture: '東京都',
    urls: [
      'https://www.sangyo-rodo.metro.tokyo.lg.jp/support/hojokin/',
      'https://www.tokyo-kosodate.metro.tokyo.lg.jp/josei/',
    ],
    categoryHints: ['business', 'startup', 'childcare', 'it'], priority: 'HIGH',
  },
  {
    municipalityCode: '27000', name: '大阪府（府庁）', prefecture: '大阪府',
    urls: ['https://www.pref.osaka.lg.jp/keizaikoryu/hojokin/'],
    categoryHints: ['business', 'it', 'startup'], priority: 'HIGH',
  },
  {
    municipalityCode: '23000', name: '愛知県（県庁）', prefecture: '愛知県',
    urls: ['https://www.pref.aichi.jp/sangyo-rodo/hojokin/'],
    categoryHints: ['business', 'agriculture', 'it'], priority: 'HIGH',
  },
  {
    municipalityCode: '40000', name: '福岡県（県庁）', prefecture: '福岡県',
    urls: ['https://www.pref.fukuoka.lg.jp/contents/hojokin.html'],
    categoryHints: ['business', 'agriculture'], priority: 'HIGH',
  },
];

// 市区町村コードから対象を取得するヘルパー
export function getTargetByCode(code: string): ScrapeTarget | undefined {
  return SCRAPE_TARGETS.find((t) => t.municipalityCode === code);
}

// 優先度の高いターゲットのみ取得
export function getHighPriorityTargets(): ScrapeTarget[] {
  return SCRAPE_TARGETS.filter((t) => t.priority === 'HIGH');
}

// カテゴリでフィルタ
export function getTargetsByCategory(slug: string): ScrapeTarget[] {
  return SCRAPE_TARGETS.filter((t) => t.categoryHints.includes(slug));
}
