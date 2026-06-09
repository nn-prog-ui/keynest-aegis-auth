export type SubsidyStatus = 'UPCOMING' | 'ACTIVE' | 'ENDED';

export type TargetAudience =
  | 'INDIVIDUAL'
  | 'CORPORATION'
  | 'FARMER'
  | 'NONPROFIT'
  | 'STARTUP'
  | 'ELDERLY'
  | 'CHILD'
  | 'DISABLED';

export type InquiryType =
  | 'SUBSIDY_SEARCH'
  | 'APPLICATION_HELP'
  | 'CONSULTING'
  | 'OTHER';

export interface Prefecture {
  id: number;
  code: string;
  name: string;
  nameKana: string;
  _count?: { municipalities: number; subsidies: number };
}

export interface Municipality {
  id: number;
  code: string;
  name: string;
  nameKana: string;
  type: 'CITY' | 'WARD' | 'TOWN' | 'VILLAGE';
  prefecture?: Prefecture;
}

export interface SubsidyCategory {
  id: number;
  slug: string;
  name: string;
  icon: string;
}

export interface Subsidy {
  id: number;
  title: string;
  description: string;
  detail?: string;
  category: SubsidyCategory;
  prefecture?: { code: string; name: string } | null;
  municipality?: { code: string; name: string } | null;
  isNational: boolean;
  maxAmount?: string | null;
  subsidyRate?: number | null;
  targetAudience: TargetAudience[];
  applicationStart?: string | null;
  applicationEnd?: string | null;
  announcedAt: string;
  status: SubsidyStatus;
  tags: string[];
  sourceUrl: string;
  requirements?: string | null;
  howToApply?: string | null;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

export interface SearchParams {
  keyword?: string;
  prefectureCode?: string;
  municipalityCode?: string;
  categoryId?: string;
  status?: SubsidyStatus;
  targetAudience?: TargetAudience;
  page?: number;
  limit?: number;
  sortBy?: 'newest' | 'deadline' | 'amount';
}
