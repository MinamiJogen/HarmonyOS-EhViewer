import { NativeGalleryImagePage } from '../ehviewer/EhNative';

export interface QuickLink {
  title: string;
  description: string;
  url: string;
}

export interface BookmarkItem {
  title: string;
  url: string;
}

export interface QuickSearchItem {
  id: string;
  label: string;
  query: string;
  site: string;
  mode: string;
  category: number;
  advancedEnabled: boolean;
  advancedFlags: number;
  minRating: string;
  pageFrom: string;
  pageTo: string;
  savedAt: string;
}

export interface FilterModeOption {
  label: string;
  mode: number;
  placeholder: string;
}

export interface LanguageFilterOption {
  label: string;
  tag: string;
  code: string;
}

export interface FilterRule {
  id: number;
  mode: number;
  text: string;
  enabled: boolean;
}

export interface BlacklistItem {
  id: number;
  name: string;
  reason: string;
  angryWith: string;
  addTime: string;
  mode: number;
}

export interface ParsedTag {
  namespace: string;
  name: string;
}

export interface ReaderPrefetchTask {
  pageUrl: string;
  priority: number;
  generation: number;
}

export interface ReaderImagePrefetchTask {
  page: NativeGalleryImagePage;
  priority: number;
  generation: number;
}

export interface ReaderImageCacheEntry {
  key: string;
  pageUrl: string;
  pageIndex: number;
  localPath: string;
  localUri: string;
  sourceUrl: string;
  cachedAt: number;
}

export interface ReaderAdjacentState {
  pageUrl: string;
  pageLabel: string;
  pageIndex: number;
  displayUrl: string;
  loading: boolean;
  error: string;
}

export interface GalleryImageCacheEntry {
  key: string;
  sourceUrl: string;
  localPath: string;
  localUri: string;
  cachedAt: number;
}

export interface CacheFileEntry {
  path: string;
  size: number;
  modifiedAt: number;
  category: string;
}

export interface CacheCleanupResult {
  scannedBytes: number;
  removedBytes: number;
  removedFiles: number;
}

export interface FavoriteFilterOption {
  filter: number;
  name: string;
  count: number;
}

export interface SearchModeOption {
  label: string;
  mode: string;
}

export interface SearchCategoryOption {
  label: string;
  bit: number;
}

export interface SearchAdvancedFlagOption {
  label: string;
  flag: string;
}

export type ReaderSelectChangeHandler = (index: number) => void;
export type ReaderToggleChangeHandler = (isOn: boolean) => void;
export type ReaderSliderChangeHandler = (value: number) => void;
export type ReaderCommandHandler = () => void;
