export interface ScrapeTarget {
  municipalityCode: string;
  name: string;
  prefecture: string;
  urls: string[];
  categoryHints: string[];
  priority: 'HIGH' | 'MEDIUM' | 'LOW';
}

export const SCRAPE_TARGETS: ScrapeTarget[] = [
  { municipalityCode: '13101', name: '千代田区', prefecture: '東京都', urls: ['https://www.city.chiyoda.lg.jp/koho/machizukuri/sangyo/index.html'], categoryHints: ['business', 'startup'], priority: 'HIGH' },
  { municipalityCode: '13102', name: '中央区', prefecture: '東京都', urls: ['https://www.city.chuo.lg.jp/a0020/sangyo/index.html'], categoryHints: ['business'], priority: 'HIGH' },
  { municipalityCode: '13103', name: '港区', prefecture: '東京都', urls: ['https://www.city.minato.tokyo.jp/sangyo/shien/index.html'], categoryHints: ['business', 'startup'], priority: 'HIGH' },
  { municipalityCode: '13104', name: '新宿区', prefecture: '東京都', urls: ['https://www.city.shinjuku.lg.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'HIGH' },
  { municipalityCode: '13113', name: '渋谷区', prefecture: '東京都', urls: ['https://www.city.shibuya.tokyo.jp/sangyo/index.html'], categoryHints: ['business', 'startup'], priority: 'HIGH' },
  { municipalityCode: '13201', name: '八王子市', prefecture: '東京都', urls: ['https://www.city.hachioji.tokyo.jp/kurashi/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'MEDIUM' },
  { municipalityCode: '27100', name: '大阪市', prefecture: '大阪府', urls: ['https://www.city.osaka.lg.jp/keizaisenryaku/category/3272-0-0-0-0-0-0-0-0-0.html'], categoryHints: ['business', 'startup'], priority: 'HIGH' },
  { municipalityCode: '27140', name: '堺市', prefecture: '大阪府', urls: ['https://www.city.sakai.lg.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'MEDIUM' },
  { municipalityCode: '14100', name: '横浜市', prefecture: '神奈川県', urls: ['https://www.city.yokohama.lg.jp/business/kigyoshien/index.html'], categoryHints: ['business', 'startup'], priority: 'HIGH' },
  { municipalityCode: '14130', name: '川崎市', prefecture: '神奈川県', urls: ['https://www.city.kawasaki.jp/280/category/30-3-0-0-0-0-0-0-0-0.html'], categoryHints: ['business'], priority: 'HIGH' },
  { municipalityCode: '23100', name: '名古屋市', prefecture: '愛知県', urls: ['https://www.city.nagoya.jp/keizai/category/35-6-0-0-0-0-0-0-0-0.html'], categoryHints: ['business', 'startup'], priority: 'HIGH' },
  { municipalityCode: '01100', name: '札幌市', prefecture: '北海道', urls: ['https://www.city.sapporo.jp/keizai/top/index.html'], categoryHints: ['business', 'agriculture'], priority: 'HIGH' },
  { municipalityCode: '04100', name: '仙台市', prefecture: '宮城県', urls: ['https://www.city.sendai.jp/keizai-shien/index.html'], categoryHints: ['business'], priority: 'HIGH' },
  { municipalityCode: '40130', name: '福岡市', prefecture: '福岡県', urls: ['https://www.city.fukuoka.lg.jp/keizai/r-support/index.html'], categoryHints: ['business', 'startup'], priority: 'HIGH' },
  { municipalityCode: '34100', name: '広島市', prefecture: '広島県', urls: ['https://www.city.hiroshima.lg.jp/soshiki/39/index.html'], categoryHints: ['business'], priority: 'HIGH' },
  { municipalityCode: '38201', name: '松山市', prefecture: '愛媛県', urls: ['https://www.city.matsuyama.ehime.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'MEDIUM' },
  { municipalityCode: '17201', name: '金沢市', prefecture: '石川県', urls: ['https://www4.city.kanazawa.lg.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'MEDIUM' },
  { municipalityCode: '20201', name: '長野市', prefecture: '長野県', urls: ['https://www.city.nagano.nagano.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'MEDIUM' },
  { municipalityCode: '22100', name: '静岡市', prefecture: '静岡県', urls: ['https://www.city.shizuoka.lg.jp/san_index.html'], categoryHints: ['business'], priority: 'MEDIUM' },
  { municipalityCode: '26100', name: '京都市', prefecture: '京都府', urls: ['https://www.city.kyoto.lg.jp/sankan/category/3899-0-0-0-0-0-0-0-0-0.html'], categoryHints: ['business', 'startup'], priority: 'HIGH' },
  { municipalityCode: '28100', name: '神戸市', prefecture: '兵庫県', urls: ['https://www.city.kobe.lg.jp/a56773/shise/kekaku/sangyo/index.html'], categoryHints: ['business', 'startup'], priority: 'HIGH' },
  { municipalityCode: '33100', name: '岡山市', prefecture: '岡山県', urls: ['https://www.city.okayama.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'MEDIUM' },
  { municipalityCode: '47201', name: '那覇市', prefecture: '沖縄県', urls: ['https://www.city.naha.okinawa.jp/kurashi/sangyo/index.html'], categoryHints: ['business', 'startup'], priority: 'MEDIUM' },
  { municipalityCode: '02201', name: '青森市', prefecture: '青森県', urls: ['https://www.city.aomori.aomori.jp/sangyo-rodo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '03201', name: '盛岡市', prefecture: '岩手県', urls: ['https://www.city.morioka.iwate.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'LOW' },
  { municipalityCode: '05201', name: '秋田市', prefecture: '秋田県', urls: ['https://www.city.akita.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '06201', name: '山形市', prefecture: '山形県', urls: ['https://www.city.yamagata.yamagata.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '07201', name: '福島市', prefecture: '福島県', urls: ['https://www.city.fukushima.fukushima.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'LOW' },
  { municipalityCode: '08201', name: '水戸市', prefecture: '茨城県', urls: ['https://www.city.mito.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '09201', name: '宇都宮市', prefecture: '栃木県', urls: ['https://www.city.utsunomiya.tochigi.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'LOW' },
  { municipalityCode: '10201', name: '前橋市', prefecture: '群馬県', urls: ['https://www.city.maebashi.gunma.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '11100', name: 'さいたま市', prefecture: '埼玉県', urls: ['https://www.city.saitama.lg.jp/006/index.html'], categoryHints: ['business'], priority: 'MEDIUM' },
  { municipalityCode: '12100', name: '千葉市', prefecture: '千葉県', urls: ['https://www.city.chiba.jp/keizainosei/index.html'], categoryHints: ['business'], priority: 'MEDIUM' },
  { municipalityCode: '15100', name: '新潟市', prefecture: '新潟県', urls: ['https://www.city.niigata.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'MEDIUM' },
  { municipalityCode: '16201', name: '富山市', prefecture: '富山県', urls: ['https://www.city.toyama.lg.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'LOW' },
  { municipalityCode: '18201', name: '福井市', prefecture: '福井県', urls: ['https://www.city.fukui.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '19201', name: '甲府市', prefecture: '山梨県', urls: ['https://www.city.kofu.yamanashi.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '21201', name: '岐阜市', prefecture: '岐阜県', urls: ['https://www.city.gifu.lg.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'LOW' },
  { municipalityCode: '24201', name: '津市', prefecture: '三重県', urls: ['https://www.city.tsu.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '25201', name: '大津市', prefecture: '滋賀県', urls: ['https://www.city.otsu.lg.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'LOW' },
  { municipalityCode: '29201', name: '奈良市', prefecture: '奈良県', urls: ['https://www.city.nara.lg.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'LOW' },
  { municipalityCode: '30201', name: '和歌山市', prefecture: '和歌山県', urls: ['https://www.city.wakayama.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '31201', name: '鳥取市', prefecture: '鳥取県', urls: ['https://www.city.tottori.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '32201', name: '松江市', prefecture: '島根県', urls: ['https://www.city.matsue.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '35201', name: '下関市', prefecture: '山口県', urls: ['https://www.city.shimonoseki.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '36201', name: '徳島市', prefecture: '徳島県', urls: ['https://www.city.tokushima.tokushima.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'LOW' },
  { municipalityCode: '37201', name: '高松市', prefecture: '香川県', urls: ['https://www.city.takamatsu.kagawa.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '39201', name: '高知市', prefecture: '高知県', urls: ['https://www.city.kochi.kochi.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '41201', name: '佐賀市', prefecture: '佐賀県', urls: ['https://www.city.saga.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '42201', name: '長崎市', prefecture: '長崎県', urls: ['https://www.city.nagasaki.lg.jp/sangyo/index.html'], categoryHints: ['business'], priority: 'LOW' },
  { municipalityCode: '43100', name: '熊本市', prefecture: '熊本県', urls: ['https://www.city.kumamoto.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'MEDIUM' },
  { municipalityCode: '44201', name: '大分市', prefecture: '大分県', urls: ['https://www.city.oita.oita.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '45201', name: '宮崎市', prefecture: '宮崎県', urls: ['https://www.city.miyazaki.miyazaki.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
  { municipalityCode: '46201', name: '鹿児島市', prefecture: '鹿児島県', urls: ['https://www.city.kagoshima.lg.jp/sangyo/index.html'], categoryHints: ['business', 'agriculture'], priority: 'LOW' },
];

export function getTargetByCode(code: string): ScrapeTarget | undefined {
  return SCRAPE_TARGETS.find(t => t.municipalityCode === code);
}

export function getHighPriorityTargets(): ScrapeTarget[] {
  return SCRAPE_TARGETS.filter(t => t.priority === 'HIGH');
}

export function getTargetsByCategory(slug: string): ScrapeTarget[] {
  return SCRAPE_TARGETS.filter(t => t.categoryHints.includes(slug));
}
