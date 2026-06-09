import { PrismaClient, SubsidyStatus, TargetAudience } from '@prisma/client';

const prisma = new PrismaClient();

interface SubsidyEntry {
  title: string;
  description: string;
  detail: string;
  categorySlug: string;
  isNational: boolean;
  maxAmount?: number;
  subsidyRate?: number;
  targetAudience: TargetAudience[];
  applicationStart?: string;
  applicationEnd?: string;
  sourceUrl: string;
  status: SubsidyStatus;
  tags: string[];
  requirements?: string;
  howToApply?: string;
}

export const NATIONAL_SUBSIDIES: SubsidyEntry[] = [

  // ===== 賃上げ・雇用・人材系 =====

  {
    title: '業務改善助成金',
    description: '最低賃金を30円以上引き上げた中小企業・小規模事業者が、生産性向上のための設備投資（機械設備、POSレジ、人材育成など）を行った場合、その費用の一部を助成します。',
    detail: '賃金引上げ額によって助成上限が異なります。\n・30円以上：最大30万円（1人）〜最大600万円（10人以上）\n・45円以上：最大45万円〜最大800万円\n・60円以上：最大60万円〜最大1,000万円\n・90円以上：最大90万円〜最大1,500万円\n\n補助率：3/4（生産性要件を満たす場合4/5）\n\n受け取れる人の例：パート・アルバイトの時給を30円上げて、同時に業務効率化のためのタブレットやPOSシステムを導入した飲食店・小売業など。',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 15000000,
    subsidyRate: 0.75,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/koyou_roudou/roudoukijun/zigyonushi/minimum-wage/gyomu-kaizen.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['賃上げ', '最低賃金', '設備投資', '中小企業', '厚生労働省'],
    requirements: '・中小企業・小規模事業者（業種ごとに資本金・従業員数の上限あり）\n・事業場内最低賃金が地域別最低賃金＋50円以内\n・解雇・賃金引き下げ等を行っていないこと',
    howToApply: '1. 都道府県労働局またはハローワークへ交付申請\n2. 設備投資等の実施\n3. 事業場内最低賃金の引き上げ\n4. 支給申請',
  },

  {
    title: 'キャリアアップ助成金（正社員化コース）',
    description: '有期雇用労働者（パート・アルバイト・派遣社員など）を正社員に転換した場合に、一人当たり最大80万円が支給されます。非正規から正規化を促進する国の制度です。',
    detail: '支給額（1人あたり）:\n・有期→正規：57.4万円（中小企業）/ 42.9万円（大企業）\n・無期→正規：28.5万円（中小企業）/ 23.0万円（大企業）\n・有期→無期：28.5万円（中小企業）/ 23.0万円（大企業）\n\n加算措置（複数適用可）:\n・母子家庭・父子家庭の親等：9.5万円加算\n・勤続3年以上の有期→正規：9.5万円加算\n・賞与・退職金制度導入：最大31.5万円加算\n\n1年度1事業所あたりの支給申請上限：20人',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 800000,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/koyou_roudou/part_haken/jigyounushi/career.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['正社員化', '非正規', 'パート', 'アルバイト', '厚生労働省', '賃上げ'],
    requirements: '・雇用保険の適用事業主\n・キャリアアップ計画を作成・提出済み\n・対象労働者を6ヶ月以上継続して雇用\n・転換後6ヶ月間、転換前の基本給より3%以上増額',
    howToApply: '1. キャリアアップ管理者の選任\n2. キャリアアップ計画書の作成・提出\n3. 正社員への転換実施\n4. 転換後6ヶ月後に支給申請',
  },

  {
    title: 'キャリアアップ助成金（賃金規定等改定コース）',
    description: '有期雇用労働者等の賃金規定等を3%以上増額改定し、実際に賃金を引き上げた事業主に支給される助成金です。賃上げした人数に応じて最大96万円が受け取れます。',
    detail: '支給額:\n・3%以上5%未満の引き上げ：1.5万円/人（中小企業）\n・5%以上の引き上げ：3万円/人（中小企業）\n・上限：1年度1事業所あたり20人×合計最大96万円\n\n具体例：パート10人を3%賃上げ → 15万円受け取れる',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 960000,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/koyou_roudou/part_haken/jigyounushi/career.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['賃上げ', '賃金規定', '非正規', '厚生労働省'],
    requirements: '・雇用保険の適用事業主\n・有期雇用等労働者の賃金規定等を3%以上増額改定\n・改定後6ヶ月以上継続雇用',
    howToApply: '1. キャリアアップ計画書の提出\n2. 賃金規定等の改定（就業規則等の変更）\n3. 改定後6ヶ月以内に支給申請',
  },

  {
    title: '人材確保等支援助成金（雇用管理制度助成コース）',
    description: '評価・処遇制度、研修制度、健康づくり制度、メンター制度などの雇用管理制度を導入し、離職率の低下目標を達成した事業主に最大130万円が支給されます。',
    detail: '支給額:\n・目標達成助成：57万円（生産性要件を満たす場合72万円）\n\n離職率低下目標:\n・雇用保険被保険者数30人以下：介入前1年間の離職率より15P以上低下\n・31人以上：介入前より15P以上低下、かつ30%以下\n\n実施した制度の計画認定助成（一部制度）は廃止済み。現在は目標達成助成のみ。',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 1300000,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000158879_00001.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['雇用管理', '離職率', '人材確保', '厚生労働省', '研修'],
    requirements: '・雇用保険適用事業主\n・雇用管理制度整備計画の認定を受けること\n・離職率低下の目標を設定',
    howToApply: '1. 都道府県労働局へ雇用管理制度整備計画を提出・認定\n2. 制度を導入・実施\n3. 計画期間終了後に申請',
  },

  {
    title: '働き方改革推進支援助成金（勤務間インターバル導入コース）',
    description: '勤務終了から次の勤務開始まで一定時間（インターバル）を設ける制度を導入した中小企業に、環境整備費用を助成します。最大100万円。',
    detail: '支給上限額:\n・9時間以上11時間未満の休息：40万円\n・11時間以上：80万円（生産性向上：100万円）\n補助率：3/4\n\n導入できる取組例: 労務管理用ソフト、社内周知の研修費用、就業規則の変更にかかる社会保険労務士費用など',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 1000000,
    subsidyRate: 0.75,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/0000090638.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['働き方改革', 'インターバル', '残業削減', '厚生労働省'],
  },

  {
    title: '特定求職者雇用開発助成金（特定就職困難者コース）',
    description: '高齢者（60歳以上）、障害者、母子家庭の母など、就職が困難な方を継続して雇い入れた事業主に助成金が支給されます。最大240万円。',
    detail: '支給額（1人あたり）:\n・高齢者（60〜64歳）：60万円（中小）/ 50万円（大企業）\n・障害者：最大240万円（重度身体・知的障害者）\n・母子家庭の母等：60万円（中小）/ 50万円（大企業）\n\n分割払い：最大2年間にわたって6ヶ月ごとに支給',
    categorySlug: 'welfare',
    isNational: true,
    maxAmount: 2400000,
    targetAudience: [TargetAudience.CORPORATION, TargetAudience.DISABLED],
    sourceUrl: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/koyou_roudou/koyou/kyufukin/tokutei_konnan.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['雇用', '障害者', '高齢者', 'ひとり親', '厚生労働省'],
  },

  {
    title: '人材開発支援助成金（人材育成支援コース）',
    description: '従業員のOFF-JT（事業所外の訓練）やOJTに要した費用・賃金の一部を助成します。資格取得・スキルアップに使えます。最大1,000万円。',
    detail: '訓練経費助成（補助率）:\n・中小企業：45〜70%\n・大企業：30〜45%\n\n賃金助成（1人1時間あたり）:\n・中小企業：960円\n・大企業：480円\n\n対象訓練: Off-JT（外部研修・e-learning含む）、OJT（実習）など\n申請単位: 訓練計画ごと',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 10000000,
    subsidyRate: 0.7,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/koyou_roudou/koyou/kyufukin/d01-1.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['人材育成', '研修', 'OJT', '資格取得', '厚生労働省'],
  },

  // ===== IT・デジタル化 =====

  {
    title: 'IT導入補助金（通常枠）',
    description: '中小企業・小規模事業者がITツール（ソフトウェア、クラウドサービス等）を導入する際の費用を補助します。業務効率化・売上向上に活用できます。最大450万円。',
    detail: '補助額:\n・通常枠：5万円〜150万円（補助率1/2以内）\n・インボイス対応類型：50万円〜350万円（補助率2/3〜3/4）\n・複数社連携IT導入類型：最大4,500万円\n\n対象ツール例:\n・会計・受発注・在庫管理システム\n・ECサイト構築・運営\n・テレワーク・Web会議ツール\n・RPAツール\n・業界特化型ソフトウェア\n\nIT導入支援事業者を通じた申請が必要。',
    categorySlug: 'it',
    isNational: true,
    maxAmount: 4500000,
    subsidyRate: 0.5,
    targetAudience: [TargetAudience.CORPORATION],
    applicationStart: '2026-04-01',
    applicationEnd: '2026-09-30',
    sourceUrl: 'https://www.it-hojo.jp/',
    status: SubsidyStatus.ACTIVE,
    tags: ['IT', 'デジタル化', 'クラウド', 'インボイス', '中小企業', '経済産業省'],
    requirements: '・中小企業・小規模事業者であること\n・IT導入支援事業者（登録済み）が提供するITツールであること\n・gBizIDプライムアカウントの取得',
    howToApply: '1. gBizIDプライムの取得\n2. IT導入支援事業者の選定\n3. ITツールの選定\n4. 申請マイページから申請\n5. 採択後に契約・導入・支払い\n6. 実績報告',
  },

  {
    title: 'ものづくり・商業・サービス補助金（一般型）',
    description: '中小企業・小規模事業者の革新的サービス開発・試作品開発・生産プロセスの改善等に必要な設備投資を支援します。最大1,250万円（デジタル枠・グリーン枠はさらに高額）。',
    detail: '補助額・補助率:\n・通常枠：100万円〜1,250万円（補助率1/2）\n・小規模事業者：補助率2/3\n・デジタル枠：100万円〜1,250万円（補助率2/3）\n・グリーン枠：100万円〜4,000万円（補助率1/2〜2/3）\n・グローバル市場開拓枠：100万円〜3,000万円\n\n対象経費: 機械装置・システム構築費、技術導入費、外注費、専門家経費等\n\n公募は年複数回。審査により採択。',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 40000000,
    subsidyRate: 0.5,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://portal.monodukuri-hojo.jp/',
    status: SubsidyStatus.ACTIVE,
    tags: ['ものづくり', '設備投資', '生産性向上', '中小企業', '経済産業省', '革新'],
    requirements: '・中小企業・小規模事業者\n・革新的な取り組みであること\n・付加価値額を年率3%以上向上させる計画',
    howToApply: '1. 公募要領の確認\n2. 事業計画書の作成（審査あり）\n3. 電子申請（jGrants）\n4. 採択後に補助事業の実施',
  },

  {
    title: '小規模事業者持続化補助金（一般型）',
    description: '小規模事業者（従業員20人以下）が取り組む販路開拓や業務効率化の費用を補助します。チラシ作成・ウェブサイト構築・展示会出展など幅広く使えます。最大200万円。',
    detail: '補助額・補助率:\n・通常枠：50万円（補助率2/3）\n・特別枠（賃金引上げ・インボイス等）：200万円（補助率2/3〜3/4）\n・創業枠：200万円（補助率2/3）\n\n対象経費例:\n・機械装置等費（5万円以上）\n・広報費（チラシ・HP制作等）\n・店舗改装費\n・展示会出展費\n・外注費\n\n年4回程度の公募。採択率40〜60%程度。',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 2000000,
    subsidyRate: 0.667,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://s23.jizokukahojokin.info/',
    status: SubsidyStatus.ACTIVE,
    tags: ['小規模事業者', '販路開拓', 'HP制作', 'チラシ', '商工会'],
    requirements: '・小規模事業者（商業・サービス業5人以下、製造業等20人以下）\n・商工会・商工会議所の支援を受けること（事業支援計画書が必要）',
    howToApply: '1. 最寄りの商工会・商工会議所に相談\n2. 事業支援計画書の発行を受ける\n3. 申請書類の作成・提出\n4. 採択後に補助事業の実施\n5. 実績報告・補助金受領',
  },

  {
    title: '事業再構築補助金（成長枠）',
    description: '市場縮小・競争激化に対応するため、新たな分野への事業転換・業態転換・事業再編を行う中小企業を最大7,000万円で支援します。コロナ後の回復・成長を後押し。',
    detail: '補助額・補助率（成長枠）:\n・中小企業：100万円〜7,000万円（補助率1/2）\n・中堅企業：100万円〜1億円（補助率1/3）\n\n他の枠:\n・産業構造転換枠：最大7,000万円（補助率2/3）\n・サプライチェーン強靱化枠：最大5億円\n・最低賃金枠：100万円〜1,500万円（補助率3/4）\n\n対象経費: 建物費、機械装置費、システム構築費、外注費等\n\n認定経営革新等支援機関との連携が必要。',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 100000000,
    subsidyRate: 0.5,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://jigyou-saikouchiku.go.jp/',
    status: SubsidyStatus.ACTIVE,
    tags: ['事業再構築', '業態転換', '新分野展開', '中小企業', '経済産業省'],
    requirements: '・中小企業・中堅企業\n・認定経営革新等支援機関（認定支援機関）の確認書\n・売上高等の要件を満たすこと\n・「事業再構築」の定義を満たす取り組み',
    howToApply: '1. 認定支援機関（税理士・中小企業診断士等）への相談\n2. 事業計画書の作成\n3. gGrantsから電子申請\n4. 採択後に補助事業の実施',
  },

  {
    title: '事業承継・引継ぎ補助金',
    description: '事業承継・M&Aを行う中小企業に対して、承継後の経営革新や廃業・清算にかかる費用を補助します。後継者不在の問題解決と事業継続を支援。最大600万円。',
    detail: '補助額:\n・経営革新枠：100万円〜600万円（補助率1/2〜2/3）\n・専門家活用枠：最大600万円（補助率1/2〜2/3）\n・廃業・再チャレンジ枠：最大150万円（補助率2/3）\n\n対象となる取り組み:\n・承継後の新事業展開・業態転換\n・M&Aマッチングへの専門家活用\n・廃業にかかる建物解体・在庫処分費など',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 6000000,
    subsidyRate: 0.667,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://jsh.go.jp/r5h/',
    status: SubsidyStatus.ACTIVE,
    tags: ['事業承継', 'M&A', '後継者', '廃業', '引継ぎ'],
  },

  // ===== 省エネ・環境・住宅 =====

  {
    title: '住宅省エネ2024キャンペーン（ZEH補助金）',
    description: 'ネット・ゼロ・エネルギー・ハウス（ZEH）の新築・改修に最大160万円の補助金が受けられます。太陽光発電＋断熱＋高効率設備の組み合わせが対象。',
    detail: '補助額:\n・ZEH（標準）：55万円/戸\n・ZEH＋：100万円/戸\n・ZEH Oriented（都市部狭小地等）：40万円/戸\n\n蓄電システム加算：最大20万円\nV2H充放電設備加算：最大40万円\n\n対象: 建築物省エネ法に基づくZEH基準を満たす新築住宅',
    categorySlug: 'environment',
    isNational: true,
    maxAmount: 1600000,
    targetAudience: [TargetAudience.INDIVIDUAL, TargetAudience.CORPORATION],
    sourceUrl: 'https://zeh.env.go.jp/',
    status: SubsidyStatus.ACTIVE,
    tags: ['ZEH', '省エネ', '住宅', '太陽光', '断熱', '環境省'],
    requirements: '・ZEH基準（断熱性能等級5以上・一次エネルギー消費量20%削減以上）を満たす新築住宅\n・ZEHビルダー・プランナー登録事業者が施工',
    howToApply: '1. ZEHビルダー（ハウスメーカー・工務店）に相談\n2. ZEH仕様での設計\n3. SIIの公募期間中に申請\n4. 交付決定後に着工→完成→完了報告',
  },

  {
    title: '先進的窓リノベ2024事業',
    description: '既存住宅の窓・ガラスを高断熱仕様に改修した場合に最大200万円の補助金が受けられます。夏の冷房費・冬の暖房費の削減が期待できます。',
    detail: '補助額:\n・内窓設置: 4万円〜12万円（窓サイズにより変動）\n・外窓交換（ガラス含む）: 4万円〜13万円\n・1戸あたり上限：200万円\n\n補助率: 工事費の1/3〜1/2程度（商品・工法による）\n\n対象: 既存住宅（持ち家・賃貸住宅どちらも可、賃貸は家主申請）',
    categorySlug: 'housing',
    isNational: true,
    maxAmount: 2000000,
    targetAudience: [TargetAudience.INDIVIDUAL],
    sourceUrl: 'https://window-renovation.env.go.jp/',
    status: SubsidyStatus.ACTIVE,
    tags: ['窓', '断熱', 'リノベーション', '省エネ', '環境省', '住宅'],
    requirements: '・既存住宅（戸建て・集合住宅）の窓・ガラス改修\n・登録施工業者による施工\n・性能基準を満たす製品の使用',
    howToApply: '1. 登録施工業者に相談\n2. 見積もり・発注\n3. 施工後に業者が代理申請\n4. 補助金は業者経由で受領',
  },

  {
    title: '給湯省エネ2024事業（高効率給湯器補助金）',
    description: '既存の給湯器を高効率給湯器（ヒートポンプ給湯器・ガスハイブリッド給湯器等）に交換した場合に、1台あたり最大13万円の補助金が受けられます。',
    detail: '補助額（1台あたり）:\n・ヒートポンプ給湯器（エコキュート）：8万円（基本）＋撤去費加算2万円\n・ガスハイブリッド給湯器：10万円\n・家庭用燃料電池（エネファーム）：13万円\n\n1戸あたり複数台可\n補助率: 定額（商品代・工事費の一部補填）',
    categorySlug: 'environment',
    isNational: true,
    maxAmount: 130000,
    targetAudience: [TargetAudience.INDIVIDUAL],
    sourceUrl: 'https://kyutou-shoene2024.meti.go.jp/',
    status: SubsidyStatus.ACTIVE,
    tags: ['給湯器', 'エコキュート', '省エネ', '経済産業省', '住宅'],
    requirements: '・既設給湯器を撤去し対象製品に交換\n・登録事業者（メーカー）による申請\n・本事業の対象製品（SII登録製品）',
  },

  {
    title: '省エネルギー設備導入支援補助金（産業・業務部門）',
    description: '工場・事務所・店舗等における省エネ設備（高効率空調・LED・変圧器・コンプレッサー等）の更新に、設備費の最大1/3〜1/2を補助します。最大15億円。',
    detail: '補助率・補助額:\n・中小企業：1/2（上限15億円）\n・大企業：1/3（上限15億円）\n・SIIが示すエネルギー削減効果の基準（原油換算1kL/年以上の省エネ効果）を満たすこと\n\n対象設備:\n・高効率空調（ビル用マルチ等）\n・高効率照明（LED化）\n・高効率変圧器・電動機\n・コージェネレーション\n・業務用省エネ機器など',
    categorySlug: 'environment',
    isNational: true,
    maxAmount: 1500000000,
    subsidyRate: 0.5,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://sii.or.jp/shoene_setsubi/',
    status: SubsidyStatus.ACTIVE,
    tags: ['省エネ', '設備更新', '工場', '空調', 'LED', '環境省'],
  },

  {
    title: 'J-クレジット制度（省エネ・再エネ・農業系）',
    description: '省エネルギー機器の導入や再生可能エネルギーの活用、農業分野での温室効果ガス削減に取り組んだ企業・農業者が、その削減量をクレジットとして売却できる制度。年間数万円〜数百万円の収益に。',
    detail: 'J-クレジットの売却価格目安:\n・省エネ：1,000円〜3,000円/t-CO2\n・再エネ（太陽光・風力）：800円〜2,000円/t-CO2\n・農業（水稲栽培）：1,000円〜2,500円/t-CO2\n\n主な対象取り組み:\n・工場・ビルの省エネ設備更新\n・太陽光・バイオマス発電\n・水稲の水管理改善（メタン発生抑制）\n・家畜排せつ物管理の改善',
    categorySlug: 'environment',
    isNational: true,
    targetAudience: [TargetAudience.CORPORATION, TargetAudience.FARMER],
    sourceUrl: 'https://j-credit.go.jp/',
    status: SubsidyStatus.ACTIVE,
    tags: ['J-クレジット', '脱炭素', 'カーボンニュートラル', '農業', '環境省'],
  },

  // ===== 農業・林業・水産 =====

  {
    title: '強い農業・担い手づくり総合支援交付金（先進的農業経営確立支援タイプ）',
    description: '農業の競争力強化のため、農業機械・施設・装置の導入に1/2の補助が受けられます。スマート農機（ドローン・自動走行トラクター等）も対象。最大1,000万円。',
    detail: '補助率・補助上限:\n・農業機械（スマート農機等）：1/2（上限1,000万円）\n・農業用施設：1/2（上限1,000万円）\n\n対象者:\n・認定農業者\n・認定新規就農者\n・集落営農\n・農業法人（農地所有適格法人）\n\n対象例:\n・ドローン（農薬散布用）\n・自動走行トラクター・田植え機\n・低コスト耐候性ハウス\n・農産物調製・選別機械',
    categorySlug: 'agriculture',
    isNational: true,
    maxAmount: 10000000,
    subsidyRate: 0.5,
    targetAudience: [TargetAudience.FARMER],
    sourceUrl: 'https://www.maff.go.jp/j/kobetu_ninaite/n_seisaku/strong_nougyou.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['農業', '農機具', 'スマート農業', 'ドローン', '農水省'],
    requirements: '・認定農業者または認定新規就農者\n・都道府県・市町村へ事業計画を提出\n・補助事業後も経営指標の達成が必要',
  },

  {
    title: '有機農業推進対策（有機農業産地づくり推進事業）',
    description: '有機農業への転換・有機農産物の産地化に取り組む農業者・団体に対して、初期投資・実証経費を補助します。最大100万円（個人農家の場合）。',
    detail: '支援対象:\n・有機JAS認証取得\n・有機農業の実証・普及活動\n・カバークロップ・堆肥製造等の資材費\n\n補助率: 定額または1/2\n補助対象上限: 個人50万円、団体最大数千万円規模',
    categorySlug: 'agriculture',
    isNational: true,
    maxAmount: 1000000,
    subsidyRate: 0.5,
    targetAudience: [TargetAudience.FARMER],
    sourceUrl: 'https://www.maff.go.jp/j/seisan/kankyo/yuuki/',
    status: SubsidyStatus.ACTIVE,
    tags: ['有機農業', 'オーガニック', '農水省', '環境保全'],
  },

  {
    title: '農業次世代人材投資資金（就農準備資金・経営開始資金）',
    description: '農業を始める49歳以下の方を対象に、農業大学校等での研修中（年間最大150万円）と就農直後の経営安定期（年間最大150万円・最長3年間）に資金を交付します。',
    detail: '就農準備資金（研修中）:\n・農業次世代人材投資資金：年間最大150万円\n・対象：農業大学校・先進農家での研修（2年間まで）\n\n経営開始資金（就農直後）:\n・年間最大150万円を最長3年間\n・対象：就農後5年以内の認定新規就農者\n\n累計最大750万円のサポート。返還不要。',
    categorySlug: 'agriculture',
    isNational: true,
    maxAmount: 7500000,
    targetAudience: [TargetAudience.INDIVIDUAL, TargetAudience.FARMER],
    sourceUrl: 'https://www.maff.go.jp/j/new_farmer/n_syunou/roudou.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['新規就農', '農業', '若手', '農水省', '返済不要'],
    requirements: '・49歳以下\n・農業次世代人材投資事業の採択を受けること\n・市町村の基本構想に定める農業経営の目標を達成する見込み',
  },

  // ===== 子育て・教育（個人向け） =====

  {
    title: '出産・子育て応援交付金（出産応援給付金・子育て応援給付金）',
    description: '妊婦・出産後の子育て家庭に給付金を交付します。妊娠届出時に5万円、出産後の赤ちゃん1人あたり5万円、合計最大10万円。',
    detail: '給付額:\n・妊娠届出時（出産応援給付金）：5万円\n・出産後（子育て応援給付金）：こども1人につき5万円\n\n申請先: お住まいの市区町村\n\n面談（伴走型相談支援）とセットでの給付が基本。ギフトカード・クーポン等での給付の自治体もあり。',
    categorySlug: 'childcare',
    isNational: true,
    maxAmount: 100000,
    targetAudience: [TargetAudience.CHILD],
    sourceUrl: 'https://www.cfa.go.jp/policies/shussan-kosodate/',
    status: SubsidyStatus.ACTIVE,
    tags: ['出産', '子育て', '給付金', '妊娠', '内閣府'],
    requirements: '・妊娠届出をした妊婦または出産後の保護者\n・住民登録をしている市区町村に申請',
    howToApply: '1. 妊娠届出時に市区町村窓口で案内を受ける\n2. 面談（伴走型相談支援）の実施\n3. 給付金の受領（振込またはギフト）',
  },

  {
    title: '幼児教育・保育の無償化',
    description: '3〜5歳すべての子ども（認可保育所・認定こども園・幼稚園等）の保育料が無償になります。0〜2歳は住民税非課税世帯が無償対象。月2.57〜3.7万円程度の負担軽減。',
    detail: '無償化の対象:\n・3〜5歳：認可保育所・認定こども園・幼稚園（月上限2.57万円）\n・3〜5歳：認可外保育施設（月上限2.37万円）\n・0〜2歳：住民税非課税世帯の子ども（認可保育所）\n\n食費・行事費等は引き続き実費負担。幼稚園の預かり保育も月1.13万円まで補助あり。',
    categorySlug: 'childcare',
    isNational: true,
    maxAmount: 444000,
    targetAudience: [TargetAudience.CHILD],
    sourceUrl: 'https://www.cfa.go.jp/policies/hoiku/',
    status: SubsidyStatus.ACTIVE,
    tags: ['保育', '幼稚園', '無償化', '子育て', '認定こども園'],
    requirements: '・3〜5歳（または0〜2歳の住民税非課税世帯）\n・保育の必要性の認定（0〜2歳・認可外の場合）',
    howToApply: '保育所・幼稚園等の入所手続きの際に自動的に適用（申請不要な場合が多い）',
  },

  {
    title: '高等教育無償化（修学支援新制度）',
    description: '低所得世帯（世帯年収の目安：270万円未満が全額対象）の学生に対して、大学・短大・高専・専門学校の授業料減免と返還不要の給付型奨学金を提供します。最大年間約91万円。',
    detail: '支援内容:\n・授業料等減免（大学・公立）：上限約54万円/年\n・給付型奨学金（自宅外通学）：約91万円/年\n・給付型奨学金（自宅通学）：約46万円/年\n\n2024年度から多子世帯（扶養する子3人以上）の世帯年収制限撤廃\n2025年度から中間層（年収600万円以下）にも給付型を拡大',
    categorySlug: 'childcare',
    isNational: true,
    maxAmount: 910000,
    targetAudience: [TargetAudience.INDIVIDUAL, TargetAudience.CHILD],
    sourceUrl: 'https://www.jasso.go.jp/shogakukin/about/kyufu/index.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['大学', '奨学金', '無償化', '返済不要', '低所得', '文科省'],
    requirements: '・世帯収入の基準を満たすこと（目安：270万円未満が全額対象）\n・学力基準を満たすこと（高校の学習成績等）\n・対象校（確認大学等）に在籍または入学予定',
    howToApply: '1. 進学資金シミュレーターで確認（JASSO）\n2. 在籍の高校またはJASSO奨学金に申込\n3. 大学入学後に在籍大学へ授業料減免を申請',
  },

  {
    title: '教育訓練給付金（専門実践教育訓練）',
    description: 'キャリアアップや資格取得のための専門的な訓練（看護師・社会福祉士・保育士・ITエンジニア等の養成課程）の受講費用を最大168万円補助します。ハローワーク経由で申請。',
    detail: '給付率・上限:\n・受講中：受講費用の50%（年間上限40万円）\n・資格取得かつ就職等で70%（年間上限56万円）\n・訓練期間最大3年間で最大168万円\n\n一般教育訓練給付（TOEIC・CAD・簿記等）: 20%（上限10万円）\n特定一般教育訓練（介護職員初任者研修等）: 40%（上限20万円）\n\n対象：在職者（雇用保険3年以上加入）または離職者（1年以内）',
    categorySlug: 'childcare',
    isNational: true,
    maxAmount: 1680000,
    subsidyRate: 0.7,
    targetAudience: [TargetAudience.INDIVIDUAL],
    sourceUrl: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/koyou_roudou/koyou/kyufukin/kyouiku.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['資格取得', '教育訓練', '看護師', '保育士', 'IT', 'ハローワーク', '厚生労働省'],
    requirements: '・雇用保険被保険者（在職者3年以上または離職1年以内）\n・ハローワークから受給資格確認を受けること',
    howToApply: '1. ハローワークで受給資格確認\n2. 受講前にジョブ・カード作成（キャリアコンサルタント相談）\n3. 受講開始後・終了後に給付申請',
  },

  // ===== 創業・スタートアップ =====

  {
    title: '創業補助金（地域創業助成事業・プロフェッショナル人材戦略）',
    description: '地域で新たに創業する方・第二創業を行う中小企業に、創業にかかる経費の一部を補助します。店舗改装費・設備費・広告費など幅広い費用に使えます。最大200万円。',
    detail: '補助額:\n・創業枠（小規模持続化補助金）：最大200万円（補助率2/3）\n・地域創業補助金（自治体独自）：最大500万円〜数千万円（地域差大）\n\n対象経費:\n・店舗借入費・改装費\n・設備費（機械・システム等）\n・広報費（HP・チラシ等）\n・外注費（デザイン・コンサル等）\n\n各都道府県・市区町村でも独自の創業補助金あり（別途確認推奨）',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 2000000,
    subsidyRate: 0.667,
    targetAudience: [TargetAudience.STARTUP],
    sourceUrl: 'https://www.chusho.meti.go.jp/keiei/sogyo/',
    status: SubsidyStatus.ACTIVE,
    tags: ['創業', '起業', 'スタートアップ', '店舗', '開業', '中小企業庁'],
    requirements: '・創業予定または創業後5年以内\n・都道府県等中小企業支援機関に認定される',
    howToApply: '1. 創業支援機関（商工会・よろず支援拠点・日本政策金融公庫等）に相談\n2. 事業計画書の作成\n3. 申請・採択後に補助事業の実施',
  },

  // ===== 観光・地域 =====

  {
    title: '農泊推進対策（農山漁村振興交付金）',
    description: '農山漁村の活性化を目的に、農林漁業体験と滞在サービスを提供する「農泊」の施設整備や人材育成に最大1,000万円の補助が受けられます。',
    detail: '補助内容:\n・農泊地域づくり：定額（上限1,000万円/地域）\n・古民家等の改修費、Wi-Fi整備、農機具等の購入\n\n対象：農山漁村地域での農泊推進組織',
    categorySlug: 'tourism',
    isNational: true,
    maxAmount: 10000000,
    subsidyRate: 0.5,
    targetAudience: [TargetAudience.CORPORATION, TargetAudience.FARMER],
    sourceUrl: 'https://www.maff.go.jp/j/nousin/kouryu/nouhakusuishin/',
    status: SubsidyStatus.ACTIVE,
    tags: ['農泊', '農村', '観光', '古民家', '農水省'],
  },

  // ===== 福祉・障害 =====

  {
    title: '障害者雇用調整金・報奨金（障害者雇用納付金制度）',
    description: '障害者を法定雇用率（2.5%）以上雇用した事業主に対して、超過人数1人あたり月2.7万円の調整金が支給されます。中小企業（100人以下）には別途報奨金。',
    detail: '調整金（101人以上の事業主）:\n・超過1人あたり月2.7万円（年32.4万円）\n\n報奨金（100人以下の事業主）:\n・一定割合を超えた障害者1人あたり月2.1万円（年25.2万円）\n\n加算特例調整金（重度障害者・精神障害者雇用促進）: 月額加算あり',
    categorySlug: 'welfare',
    isNational: true,
    maxAmount: 3240000,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://www.jeed.go.jp/disability/employer/employer05.html',
    status: SubsidyStatus.ACTIVE,
    tags: ['障害者雇用', '法定雇用率', '調整金', 'JEED'],
    requirements: '・障害者雇用促進法の法定雇用率（2.5%）を超えて障害者を雇用\n・毎年6月1日時点の雇用状況を届け出',
  },

  // ===== BCP・DX・輸出 =====

  {
    title: '中小企業強靱化対策事業費補助金（BCP策定支援）',
    description: '自然災害や感染症等のリスクに対して事業継続計画（BCP）を策定・見直しした中小企業に、策定費用や設備投資を補助します。最大100万円。',
    detail: '補助内容:\n・BCP策定支援（専門家費用）：定額補助\n・設備投資（自家発電機・衛星電話等）：1/2補助（上限100万円）\n\n都道府県・市区町村によって独自の上乗せ補助あり',
    categorySlug: 'disaster',
    isNational: true,
    maxAmount: 1000000,
    subsidyRate: 0.5,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://www.chusho.meti.go.jp/bcp/',
    status: SubsidyStatus.ACTIVE,
    tags: ['BCP', '防災', '事業継続', '中小企業', '自然災害'],
  },

  {
    title: 'DX推進補助金（デジタル田園都市国家構想推進交付金）',
    description: '地域のデジタル化・DXを推進する市区町村・事業者を支援します。スマートシティ推進、行政DX、地域産業DXなど幅広い取り組みが対象。最大数億円。',
    detail: '対象取り組み:\n・スマートシティ（交通・医療・農業のデジタル化）\n・行政手続のオンライン化\n・地域産業のDX（製造業・農業・観光等）\n・テレワーク推進、5G整備\n\n事業者向け:\n・IT導入補助金と組み合わせて活用可能',
    categorySlug: 'it',
    isNational: true,
    maxAmount: 500000000,
    subsidyRate: 0.5,
    targetAudience: [TargetAudience.CORPORATION, TargetAudience.NONPROFIT],
    sourceUrl: 'https://www.chisou.go.jp/sousei/about/mirai/',
    status: SubsidyStatus.ACTIVE,
    tags: ['DX', 'デジタル', 'スマートシティ', '地方創生', '内閣府'],
  },

  {
    title: '輸出拡大支援事業（中小企業海外展開支援補助金）',
    description: '海外市場への販路開拓・輸出拡大に取り組む中小企業に、展示会出展費・翻訳費・現地調査費などを補助します。最大500万円。',
    detail: '補助額: 50万円〜500万円（補助率1/2）\n\n対象経費:\n・海外展示会・見本市への出展費\n・輸出可能性調査（現地調査・専門家費用）\n・外国語版パンフレット・Webサイト制作\n・認証取得費（CE・FDA等）\n\nジェトロ（JETRO）の支援とも組み合わせ可',
    categorySlug: 'business',
    isNational: true,
    maxAmount: 5000000,
    subsidyRate: 0.5,
    targetAudience: [TargetAudience.CORPORATION],
    sourceUrl: 'https://www.jetro.go.jp/services/assistance/',
    status: SubsidyStatus.ACTIVE,
    tags: ['輸出', '海外展開', '展示会', 'JETRO', '中小企業庁'],
  },

  // ===== 高齢者・介護 =====

  {
    title: '介護事業所処遇改善加算（介護職員処遇改善支援補助金）',
    description: '介護職員の賃金を引き上げた介護事業者に、1人あたり月最大9,000円相当の補助金が支給されます。介護人材の確保・定着を支援。',
    detail: '補助額の目安:\n・月9,000円×対象職員数の補助（介護職員に配分義務）\n・加算（Ⅰ〜Ⅳ）ランクに応じて補助率が異なる\n\n原資: 介護報酬の加算として事業者に支払われ、職員に配分義務\n\n2024年度から処遇改善・特定処遇改善・ベースアップ等の3加算が一本化',
    categorySlug: 'elderly',
    isNational: true,
    maxAmount: 1080000,
    targetAudience: [TargetAudience.ELDERLY, TargetAudience.CORPORATION],
    sourceUrl: 'https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/hukushi_kaigo/kaigo_koureisha/shogu/',
    status: SubsidyStatus.ACTIVE,
    tags: ['介護', '処遇改善', '賃上げ', '福祉', '厚生労働省'],
  },
];
