import { PrismaClient, MunicipalityType } from '@prisma/client';
import { NATIONAL_SUBSIDIES } from './subsidies-master';

const prisma = new PrismaClient();

const PREFECTURES = [
  { code: '01', name: '北海道' }, { code: '02', name: '青森県' }, { code: '03', name: '岩手県' },
  { code: '04', name: '宮城県' }, { code: '05', name: '秋田県' }, { code: '06', name: '山形県' },
  { code: '07', name: '福島県' }, { code: '08', name: '茨城県' }, { code: '09', name: '栃木県' },
  { code: '10', name: '群馬県' }, { code: '11', name: '埼玉県' }, { code: '12', name: '千葉県' },
  { code: '13', name: '東京都' }, { code: '14', name: '神奈川県' }, { code: '15', name: '新潟県' },
  { code: '16', name: '富山県' }, { code: '17', name: '石川県' }, { code: '18', name: '福井県' },
  { code: '19', name: '山梨県' }, { code: '20', name: '長野県' }, { code: '21', name: '岐阜県' },
  { code: '22', name: '静岡県' }, { code: '23', name: '愛知県' }, { code: '24', name: '三重県' },
  { code: '25', name: '滋賀県' }, { code: '26', name: '京都府' }, { code: '27', name: '大阪府' },
  { code: '28', name: '兵庫県' }, { code: '29', name: '奈良県' }, { code: '30', name: '和歌山県' },
  { code: '31', name: '鳥取県' }, { code: '32', name: '島根県' }, { code: '33', name: '岡山県' },
  { code: '34', name: '広島県' }, { code: '35', name: '山口県' }, { code: '36', name: '徳島県' },
  { code: '37', name: '香川県' }, { code: '38', name: '愛媛県' }, { code: '39', name: '高知県' },
  { code: '40', name: '福岡県' }, { code: '41', name: '佐賀県' }, { code: '42', name: '長崎県' },
  { code: '43', name: '熊本県' }, { code: '44', name: '大分県' }, { code: '45', name: '宮崎県' },
  { code: '46', name: '鹿児島県' }, { code: '47', name: '沖縄県' },
];

const CATEGORIES = [
  { slug: 'business', name: '事業支援' },
  { slug: 'startup', name: '創業・起業' },
  { slug: 'it', name: 'IT・デジタル' },
  { slug: 'employment', name: '雇用・人材' },
  { slug: 'manufacturing', name: 'ものづくり' },
  { slug: 'agriculture', name: '農林水産' },
  { slug: 'environment', name: '環境・エネルギー' },
  { slug: 'housing', name: '住宅・建設' },
  { slug: 'welfare', name: '福祉・介護' },
  { slug: 'childcare', name: '子育て・教育' },
  { slug: 'tourism', name: '観光・地域振興' },
  { slug: 'culture', name: '文化・スポーツ' },
  { slug: 'infrastructure', name: 'インフラ・交通' },
];

const SAMPLE_MUNICIPALITIES = [
  { code: '13101', name: '千代田区', type: 'WARD' as MunicipalityType, prefCode: '13' },
  { code: '13102', name: '中央区', type: 'WARD' as MunicipalityType, prefCode: '13' },
  { code: '13103', name: '港区', type: 'WARD' as MunicipalityType, prefCode: '13' },
  { code: '13104', name: '新宿区', type: 'WARD' as MunicipalityType, prefCode: '13' },
  { code: '13113', name: '渋谷区', type: 'WARD' as MunicipalityType, prefCode: '13' },
  { code: '13201', name: '八王子市', type: 'CITY' as MunicipalityType, prefCode: '13' },
  { code: '14100', name: '横浜市', type: 'CITY' as MunicipalityType, prefCode: '14' },
  { code: '14130', name: '川崎市', type: 'CITY' as MunicipalityType, prefCode: '14' },
  { code: '27100', name: '大阪市', type: 'CITY' as MunicipalityType, prefCode: '27' },
  { code: '27140', name: '堺市', type: 'CITY' as MunicipalityType, prefCode: '27' },
  { code: '23100', name: '名古屋市', type: 'CITY' as MunicipalityType, prefCode: '23' },
  { code: '01100', name: '札幌市', type: 'CITY' as MunicipalityType, prefCode: '01' },
  { code: '04100', name: '仙台市', type: 'CITY' as MunicipalityType, prefCode: '04' },
  { code: '40130', name: '福岡市', type: 'CITY' as MunicipalityType, prefCode: '40' },
  { code: '34100', name: '広島市', type: 'CITY' as MunicipalityType, prefCode: '34' },
  { code: '26100', name: '京都市', type: 'CITY' as MunicipalityType, prefCode: '26' },
  { code: '28100', name: '神戸市', type: 'CITY' as MunicipalityType, prefCode: '28' },
  { code: '43100', name: '熊本市', type: 'CITY' as MunicipalityType, prefCode: '43' },
  { code: '11100', name: 'さいたま市', type: 'CITY' as MunicipalityType, prefCode: '11' },
  { code: '12100', name: '千葉市', type: 'CITY' as MunicipalityType, prefCode: '12' },
];

async function main() {
  console.log('Seeding database...');

  for (const pref of PREFECTURES) {
    await prisma.prefecture.upsert({ where: { code: pref.code }, update: { name: pref.name }, create: pref });
  }
  console.log('Prefectures seeded');

  for (const cat of CATEGORIES) {
    await prisma.subsidyCategory.upsert({ where: { slug: cat.slug }, update: { name: cat.name }, create: cat });
  }
  console.log('Categories seeded');

  for (const m of SAMPLE_MUNICIPALITIES) {
    const pref = await prisma.prefecture.findUnique({ where: { code: m.prefCode } });
    if (!pref) continue;
    await prisma.municipality.upsert({
      where: { code: m.code },
      update: { name: m.name, type: m.type },
      create: { code: m.code, name: m.name, type: m.type, prefectureId: pref.id },
    });
  }
  console.log('Municipalities seeded');

  for (const ns of NATIONAL_SUBSIDIES) {
    const category = await prisma.subsidyCategory.findUnique({ where: { slug: ns.categorySlug } });
    const existing = await prisma.subsidy.findFirst({ where: { title: ns.title, isNational: true } });
    if (!existing) {
      await prisma.subsidy.create({
        data: {
          title: ns.title,
          description: ns.description,
          maxAmount: BigInt(ns.maxAmount),
          subsidyRate: ns.subsidyRate,
          targetAudiences: ns.targetAudiences as any,
          status: 'ACTIVE',
          categoryId: category?.id,
          requirements: ns.requirements,
          sourceUrl: ns.sourceUrl,
          isNational: ns.isNational,
          isStartupFriendly: ns.isStartupFriendly,
        },
      });
    }
  }
  console.log('National subsidies seeded');

  console.log('Seeding complete!');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
