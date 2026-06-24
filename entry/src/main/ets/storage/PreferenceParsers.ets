import {
  CATEGORY_ALL,
  EMPTY_FAVORITE_CATEGORY_COUNTS,
  EXCLUDED_LANGUAGE_OPTIONS,
  FAVORITE_SLOT_NAMES,
  SEARCH_HISTORY_MAX_COUNT,
  SEARCH_MODE_NORMAL
} from '../constants/AppConstants';
import { GallerySite } from '../ehviewer/EhNative';
import {
  DOWNLOAD_DEFAULT_LABEL,
  DOWNLOAD_STATUS_QUEUED,
  DownloadLabelItem,
  DownloadPageError
} from '../download/DownloadModels';
import { BookmarkItem, QuickSearchItem } from '../models/AppModels';
import { LocalGalleryRecord } from '../models/LocalModels';
import { readObjectBoolean, readObjectNumber, readObjectString } from '../utils/RecordUtils';

export function parseBookmarks(raw: string): BookmarkItem[] {
  try {
    const parsed = JSON.parse(raw) as Array<Record<string, Object>>;
    if (!Array.isArray(parsed)) {
      return [];
    }
    return parsed
      .map((item: Record<string, Object>) => {
        const url = readObjectString(item, 'url', '');
        const title = readObjectString(item, 'title', url);
        const bookmark: BookmarkItem = { title, url };
        return bookmark;
      })
      .filter((item: BookmarkItem) => item.url.length > 0)
      .slice(0, 24);
  } catch (error) {
    return [];
  }
}

export function parseQuickSearches(raw: string, defaultAdvancedFlags: number): QuickSearchItem[] {
  try {
    const parsed = JSON.parse(raw) as Array<Record<string, Object>>;
    if (!Array.isArray(parsed)) {
      return [];
    }
    return parsed
      .map((item: Record<string, Object>) => {
        const quickSearch: QuickSearchItem = {
          id: readObjectString(item, 'id', ''),
          label: readObjectString(item, 'label', ''),
          query: readObjectString(item, 'query', ''),
          site: readObjectString(item, 'site', GallerySite.E),
          mode: readObjectString(item, 'mode', SEARCH_MODE_NORMAL),
          category: readObjectNumber(item, 'category', CATEGORY_ALL),
          advancedEnabled: readObjectBoolean(item, 'advancedEnabled', true),
          advancedFlags: readObjectNumber(item, 'advancedFlags', defaultAdvancedFlags),
          minRating: readObjectString(item, 'minRating', ''),
          pageFrom: readObjectString(item, 'pageFrom', ''),
          pageTo: readObjectString(item, 'pageTo', ''),
          savedAt: readObjectString(item, 'savedAt', '')
        };
        return quickSearch;
      })
      .filter((item: QuickSearchItem) => item.id.length > 0 && item.query.length > 0)
      .slice(0, 20);
  } catch (error) {
    return [];
  }
}

export function parseSearchHistoryQueries(raw: string): string[] {
  try {
    const parsed = JSON.parse(raw) as Array<string>;
    if (!Array.isArray(parsed)) {
      return [];
    }
    const values: string[] = [];
    for (const item of parsed) {
      if (typeof item !== 'string') {
        continue;
      }
      if (item.length === 0 || values.indexOf(item) >= 0) {
        continue;
      }
      values.push(item);
      if (values.length >= SEARCH_HISTORY_MAX_COUNT) {
        break;
      }
    }
    return values;
  } catch (error) {
    return [];
  }
}

export function isSupportedExcludedLanguageTag(tag: string): boolean {
  for (const option of EXCLUDED_LANGUAGE_OPTIONS) {
    if (option.tag === tag) {
      return true;
    }
  }
  return false;
}

export function parseExcludedLanguageTags(raw: string): string[] {
  try {
    const parsed = JSON.parse(raw) as Array<string>;
    if (!Array.isArray(parsed)) {
      return [];
    }
    const values: string[] = [];
    for (const item of parsed) {
      if (typeof item !== 'string') {
        continue;
      }
      const tag = item.trim().toLowerCase();
      if (tag.length === 0 || values.indexOf(tag) >= 0 || !isSupportedExcludedLanguageTag(tag)) {
        continue;
      }
      values.push(tag);
    }
    return values;
  } catch (error) {
    return [];
  }
}

export function emptyFavoriteCategoryCounts(): number[] {
  return EMPTY_FAVORITE_CATEGORY_COUNTS.slice();
}

export function parseFavoriteCategoryNames(raw: string): string[] {
  const names = FAVORITE_SLOT_NAMES.slice();
  try {
    const parsed = JSON.parse(raw) as Array<string>;
    if (!Array.isArray(parsed)) {
      return names;
    }
    for (let index = 0; index < FAVORITE_SLOT_NAMES.length; index++) {
      const value = parsed[index];
      if (typeof value === 'string' && value.trim().length > 0) {
        names[index] = value.trim();
      }
    }
    return names;
  } catch (error) {
    return names;
  }
}

export function parseFavoriteCategoryCounts(raw: string): number[] {
  const counts = emptyFavoriteCategoryCounts();
  try {
    const parsed = JSON.parse(raw) as Array<number | string>;
    if (!Array.isArray(parsed)) {
      return counts;
    }
    for (let index = 0; index < FAVORITE_SLOT_NAMES.length; index++) {
      const value = parsed[index];
      const count = typeof value === 'number' ? value : Number(value);
      counts[index] = Number.isFinite(count) && count > 0 ? Math.floor(count) : 0;
    }
    return counts;
  } catch (error) {
    return counts;
  }
}

export function parseLocalGalleryRecord(item: Record<string, Object>): LocalGalleryRecord | undefined {
  const gid = readObjectNumber(item, 'gid', 0);
  const detailUrl = readObjectString(item, 'detailUrl', '');
  if (!Number.isFinite(gid) || gid <= 0 || detailUrl.length === 0) {
    return undefined;
  }
  const record: LocalGalleryRecord = {
    gid,
    token: readObjectString(item, 'token', ''),
    title: readObjectString(item, 'title', ''),
    titleJpn: readObjectString(item, 'titleJpn', ''),
    cover: readObjectString(item, 'cover', ''),
    detailUrl,
    site: readObjectString(item, 'site', GallerySite.E),
    uploader: readObjectString(item, 'uploader', ''),
    categoryLabel: readObjectString(item, 'categoryLabel', ''),
    posted: readObjectString(item, 'posted', ''),
    pages: readObjectNumber(item, 'pages', 0),
    language: readObjectString(item, 'language', ''),
    rating: readObjectNumber(item, 'rating', -1)
  };
  return record;
}

export function normalizeDownloadPageErrors(parsed: Array<Record<string, Object>>): DownloadPageError[] {
  const errors: DownloadPageError[] = [];
  for (const item of parsed) {
    const page = readObjectNumber(item, 'page', 0);
    const message = readObjectString(item, 'message', '');
    if (page <= 0 || message.length === 0) {
      continue;
    }
    errors.push({
      page,
      message,
      updatedAt: readObjectString(item, 'updatedAt', '')
    });
  }
  return errors.slice(0, 200);
}

export function parseDownloadPageErrors(raw: string): DownloadPageError[] {
  try {
    const parsed = JSON.parse(raw) as Array<Record<string, Object>>;
    if (!Array.isArray(parsed)) {
      return [];
    }
    return normalizeDownloadPageErrors(parsed);
  } catch (error) {
    return [];
  }
}

export function parseDownloadPageErrorsFromObject(item: Record<string, Object>): DownloadPageError[] {
  const raw = item['pageErrors'];
  if (typeof raw === 'string') {
    return parseDownloadPageErrors(raw);
  }
  if (Array.isArray(raw)) {
    return normalizeDownloadPageErrors(raw as Array<Record<string, Object>>);
  }
  return [];
}

export function parseDownloadLabels(raw: string, nowLabel: string): DownloadLabelItem[] {
  try {
    const parsed = JSON.parse(raw) as Array<Record<string, Object>>;
    if (!Array.isArray(parsed)) {
      return [];
    }
    const labels: DownloadLabelItem[] = [];
    for (const item of parsed) {
      const label = readObjectString(item, 'label', '').trim();
      if (label.length === 0 || labels.some((entry: DownloadLabelItem) => entry.label === label)) {
        continue;
      }
      labels.push({
        label,
        createdAt: readObjectString(item, 'createdAt', nowLabel)
      });
    }
    return labels.slice(0, 40);
  } catch (error) {
    return [];
  }
}

export function ensureDownloadDefaultLabel(labels: DownloadLabelItem[], nowLabel: string): DownloadLabelItem[] {
  const normalized: DownloadLabelItem[] = [];
  normalized.push({ label: DOWNLOAD_DEFAULT_LABEL, createdAt: nowLabel });
  for (const label of labels) {
    const name = label.label.trim();
    if (name.length === 0 || name === DOWNLOAD_DEFAULT_LABEL ||
      normalized.some((entry: DownloadLabelItem) => entry.label === name)) {
      continue;
    }
    normalized.push({ label: name, createdAt: label.createdAt.length > 0 ? label.createdAt : nowLabel });
  }
  return normalized;
}
