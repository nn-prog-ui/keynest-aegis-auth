import { Subsidy, PaginatedResponse, Prefecture, SearchParams } from '@/types';

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

async function fetcher<T>(path: string): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, { next: { revalidate: 60 } });
  if (!res.ok) throw new Error(`API error: ${res.status}`);
  return res.json();
}

export async function getSubsidies(
  params: SearchParams = {}
): Promise<PaginatedResponse<Subsidy>> {
  const query = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== '') query.set(k, String(v));
  });
  return fetcher(`/api/subsidies?${query}`);
}

export async function getSubsidy(id: number): Promise<Subsidy> {
  return fetcher(`/api/subsidies/${id}`);
}

export async function getSubsidyStats() {
  return fetcher<{ total: number; active: number; endingSoon: number }>(
    '/api/subsidies/stats'
  );
}

export async function getPrefectures(): Promise<Prefecture[]> {
  return fetcher('/api/municipalities/prefectures');
}

export async function getCategories() {
  return fetcher<{ id: number; slug: string; name: string; icon: string }[]>(
    '/api/subsidies/categories'
  );
}

export async function registerAlert(data: {
  email: string;
  prefectureIds: number[];
  municipalityIds: number[];
  categoryIds: number[];
  deadlineReminderDays: number;
}) {
  const res = await fetch(`${BASE_URL}/api/alerts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.error || '登録に失敗しました');
  }
  return res.json();
}

export async function submitConsulting(data: {
  name: string;
  email: string;
  phone?: string;
  companyName?: string;
  inquiryType: string;
  message: string;
}) {
  const res = await fetch(`${BASE_URL}/api/consulting`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.error || '送信に失敗しました');
  }
  return res.json();
}
