import common from '@ohos.app.ability.common';
import relationalStore from '@ohos.data.relationalStore';
import { GallerySite } from '../ehviewer/EhNative';
import { HistoryItem, LocalGalleryRecord } from '../models/LocalModels';
import {
  DOWNLOAD_DATABASE_NAME,
  DOWNLOAD_DEFAULT_LABEL,
  DOWNLOAD_LABEL_TABLE,
  DOWNLOAD_STATUS_DELETED,
  DOWNLOAD_STATUS_DONE,
  DOWNLOAD_STATUS_DOWNLOADING,
  DOWNLOAD_STATUS_FAILED,
  DOWNLOAD_STATUS_PAUSED,
  DOWNLOAD_STATUS_QUEUED,
  DOWNLOAD_STATUS_READING,
  DOWNLOAD_TABLE,
  DownloadLabelItem,
  DownloadPageError,
  DownloadQueueItem
} from '../download/DownloadModels';
import {
  BLACKLIST_TABLE,
  BOOKMARKS_TABLE,
  CATEGORY_ALL,
  FILTER_MODE_TITLE,
  FILTER_TABLE,
  GALLERY_TAGS_TABLE,
  HISTORY_TABLE,
  LOCAL_FAVORITES_TABLE,
  LOCAL_LIST_LOAD_LIMIT,
  QUICK_SEARCH_TABLE,
  SEARCH_HISTORY_MAX_COUNT,
  SEARCH_HISTORY_TABLE,
  SEARCH_MODE_NORMAL
} from '../constants/AppConstants';
import {
  BlacklistItem,
  BookmarkItem,
  FilterRule,
  QuickSearchItem
} from '../models/AppModels';

export class EhLocalDataDao {
  private readonly store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  static async open(context: common.UIAbilityContext): Promise<EhLocalDataDao> {
    const config: relationalStore.StoreConfig = {
      name: DOWNLOAD_DATABASE_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    const store = await relationalStore.getRdbStore(context, config);
    const dao = new EhLocalDataDao(store);
    await dao.ensureSchema();
    return dao;
  }

  private async ensureSchema(): Promise<void> {
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${DOWNLOAD_LABEL_TABLE} (` +
        'label TEXT PRIMARY KEY, ' +
        'created_at TEXT NOT NULL)'
    );
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${DOWNLOAD_TABLE} (` +
        'download_key TEXT PRIMARY KEY, ' +
        'gid INTEGER NOT NULL, ' +
        'token TEXT, title TEXT, title_jpn TEXT, cover TEXT, detail_url TEXT, site TEXT NOT NULL, ' +
        'uploader TEXT, category_label TEXT, posted TEXT, pages INTEGER, language TEXT, rating REAL, ' +
        'status TEXT NOT NULL, label TEXT NOT NULL, queued_at TEXT, last_action TEXT, ' +
        'downloaded INTEGER, total INTEGER, failed_count INTEGER, archive_uri TEXT, created_at TEXT, updated_at TEXT, ' +
        'current_page INTEGER, current_page_label TEXT, speed_bps REAL, remaining_seconds INTEGER, ' +
        'download_dir TEXT, error TEXT, page_errors TEXT)'
    );
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${QUICK_SEARCH_TABLE} (` +
        'quick_key TEXT PRIMARY KEY, ' +
        'label TEXT NOT NULL, keyword TEXT NOT NULL, site TEXT NOT NULL, mode TEXT NOT NULL, ' +
        'category INTEGER NOT NULL, advanced_enabled INTEGER NOT NULL, advanced_flags INTEGER NOT NULL, ' +
        'min_rating TEXT, page_from TEXT, page_to TEXT, saved_at TEXT NOT NULL, time INTEGER NOT NULL)'
    );
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${SEARCH_HISTORY_TABLE} (` +
        'keyword TEXT PRIMARY KEY, ' +
        'time INTEGER NOT NULL)'
    );
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${HISTORY_TABLE} (` +
        'history_key TEXT PRIMARY KEY, ' +
        'gid INTEGER NOT NULL, token TEXT, title TEXT, title_jpn TEXT, cover TEXT, detail_url TEXT, site TEXT NOT NULL, ' +
        'uploader TEXT, category_label TEXT, posted TEXT, pages INTEGER, language TEXT, rating REAL, ' +
        'visited_at TEXT NOT NULL, time INTEGER NOT NULL)'
    );
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${BOOKMARKS_TABLE} (` +
        'bookmark_key TEXT PRIMARY KEY, ' +
        'title TEXT NOT NULL, url TEXT NOT NULL, site TEXT, gid INTEGER, saved_at TEXT NOT NULL, time INTEGER NOT NULL)'
    );
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${LOCAL_FAVORITES_TABLE} (` +
        'favorite_key TEXT PRIMARY KEY, ' +
        'gid INTEGER NOT NULL, token TEXT, title TEXT, title_jpn TEXT, cover TEXT, detail_url TEXT, site TEXT NOT NULL, ' +
        'uploader TEXT, category_label TEXT, posted TEXT, pages INTEGER, language TEXT, rating REAL, ' +
        'time INTEGER NOT NULL)'
    );
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${FILTER_TABLE} (` +
        'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'mode INTEGER NOT NULL, text TEXT NOT NULL, enable INTEGER NOT NULL)'
    );
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${BLACKLIST_TABLE} (` +
        'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'badgayname TEXT NOT NULL, reason TEXT, angrywith TEXT, add_time TEXT, mode INTEGER)'
    );
    await this.store.executeSql(
      `CREATE TABLE IF NOT EXISTS ${GALLERY_TAGS_TABLE} (` +
        'gid INTEGER PRIMARY KEY, rows TEXT, artist TEXT, cosplayer TEXT, character TEXT, female TEXT, ' +
        'group_name TEXT, language TEXT, male TEXT, misc TEXT, mixed TEXT, other TEXT, parody TEXT, reclass TEXT, ' +
        'create_time INTEGER, update_time INTEGER)'
    );

    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_downloads_label ON ${DOWNLOAD_TABLE}(label)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_downloads_site_gid ON ${DOWNLOAD_TABLE}(site, gid)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_downloads_updated ON ${DOWNLOAD_TABLE}(updated_at)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_quick_search_keyword ON ${QUICK_SEARCH_TABLE}(keyword)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_quick_search_site ON ${QUICK_SEARCH_TABLE}(site)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_quick_search_time ON ${QUICK_SEARCH_TABLE}(time)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_search_history_keyword ON ${SEARCH_HISTORY_TABLE}(keyword)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_search_history_time ON ${SEARCH_HISTORY_TABLE}(time)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_history_gid ON ${HISTORY_TABLE}(gid)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_history_site_gid ON ${HISTORY_TABLE}(site, gid)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_history_time ON ${HISTORY_TABLE}(time)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_bookmarks_url ON ${BOOKMARKS_TABLE}(url)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_bookmarks_time ON ${BOOKMARKS_TABLE}(time)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_local_favorites_gid ON ${LOCAL_FAVORITES_TABLE}(gid)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_local_favorites_time ON ${LOCAL_FAVORITES_TABLE}(time)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_filter_text ON ${FILTER_TABLE}(text)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_blacklist_name ON ${BLACKLIST_TABLE}(badgayname)`);
    await this.store.executeSql(`CREATE INDEX IF NOT EXISTS idx_gallery_tags_gid ON ${GALLERY_TAGS_TABLE}(gid)`);

    await this.store.insert(
      DOWNLOAD_LABEL_TABLE,
      this.downloadLabelToBucket({ label: DOWNLOAD_DEFAULT_LABEL, createdAt: this.nowLabel() }),
      relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
    );
  }

  private nowLabel(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');
    const hour = `${date.getHours()}`.padStart(2, '0');
    const minute = `${date.getMinutes()}`.padStart(2, '0');
    return `${year}-${month}-${day} ${hour}:${minute}`;
  }

  private labelToTime(label: string): number {
    const normalized = label.replace(' ', 'T');
    const parsed = Date.parse(normalized);
    return Number.isFinite(parsed) ? parsed : Date.now();
  }

  private resultString(resultSet: relationalStore.ResultSet, column: string, fallback: string = ''): string {
    try {
      const index = resultSet.getColumnIndex(column);
      return index >= 0 ? resultSet.getString(index) : fallback;
    } catch (error) {
      return fallback;
    }
  }

  private resultNumber(resultSet: relationalStore.ResultSet, column: string, fallback: number = 0): number {
    try {
      const index = resultSet.getColumnIndex(column);
      if (index < 0) {
        return fallback;
      }
      const value = resultSet.getDouble(index);
      return Number.isFinite(value) ? value : fallback;
    } catch (error) {
      return fallback;
    }
  }

  private readObjectString(item: Record<string, Object>, key: string, fallback: string = ''): string {
    const value = item[key];
    if (typeof value === 'string') {
      return value;
    }
    if (typeof value === 'number') {
      return `${value}`;
    }
    return fallback;
  }

  private readObjectNumber(item: Record<string, Object>, key: string, fallback: number = 0): number {
    const value = item[key];
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      const numericValue = Number(value);
      return Number.isFinite(numericValue) ? numericValue : fallback;
    }
    return fallback;
  }

  private readObjectBoolean(item: Record<string, Object>, key: string, fallback: boolean = false): boolean {
    const value = item[key];
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'number') {
      return value !== 0;
    }
    if (typeof value === 'string') {
      return value === 'true' || value === '1';
    }
    return fallback;
  }

  private normalizeDownloadStatus(status: string): string {
    switch (status) {
      case 'queued':
      case DOWNLOAD_STATUS_QUEUED:
        return DOWNLOAD_STATUS_QUEUED;
      case 'done':
      case DOWNLOAD_STATUS_DONE:
        return DOWNLOAD_STATUS_DONE;
      case DOWNLOAD_STATUS_READING:
        return DOWNLOAD_STATUS_READING;
      case DOWNLOAD_STATUS_DOWNLOADING:
        return DOWNLOAD_STATUS_DOWNLOADING;
      case DOWNLOAD_STATUS_PAUSED:
        return DOWNLOAD_STATUS_PAUSED;
      case DOWNLOAD_STATUS_FAILED:
        return DOWNLOAD_STATUS_FAILED;
      case DOWNLOAD_STATUS_DELETED:
        return DOWNLOAD_STATUS_DELETED;
      default:
        return DOWNLOAD_STATUS_QUEUED;
    }
  }

  private downloadKey(gid: number, site: string): string {
    return `${site}-${gid}`;
  }

  private historyKey(item: LocalGalleryRecord): string {
    return `${item.site}-${item.gid}`;
  }

  private normalizeQuickSearch(item: QuickSearchItem): QuickSearchItem {
    return {
      id: item.id,
      label: item.label.length > 0 ? item.label : item.query,
      query: item.query,
      site: item.site.length > 0 ? item.site : GallerySite.E,
      mode: item.mode.length > 0 ? item.mode : SEARCH_MODE_NORMAL,
      category: item.category > 0 ? item.category : CATEGORY_ALL,
      advancedEnabled: item.advancedEnabled,
      advancedFlags: item.advancedFlags,
      minRating: item.minRating,
      pageFrom: item.pageFrom,
      pageTo: item.pageTo,
      savedAt: item.savedAt.length > 0 ? item.savedAt : this.nowLabel()
    };
  }

  private galleryRecordFromResult(resultSet: relationalStore.ResultSet): LocalGalleryRecord {
    return {
      gid: this.resultNumber(resultSet, 'gid', 0),
      token: this.resultString(resultSet, 'token'),
      title: this.resultString(resultSet, 'title'),
      titleJpn: this.resultString(resultSet, 'title_jpn'),
      cover: this.resultString(resultSet, 'cover'),
      detailUrl: this.resultString(resultSet, 'detail_url'),
      site: this.resultString(resultSet, 'site', GallerySite.E),
      uploader: this.resultString(resultSet, 'uploader'),
      categoryLabel: this.resultString(resultSet, 'category_label'),
      posted: this.resultString(resultSet, 'posted'),
      pages: this.resultNumber(resultSet, 'pages', 0),
      language: this.resultString(resultSet, 'language'),
      rating: this.resultNumber(resultSet, 'rating', -1)
    };
  }

  private downloadLabelToBucket(label: DownloadLabelItem): relationalStore.ValuesBucket {
    return {
      label: label.label,
      created_at: label.createdAt
    };
  }

  private downloadItemToBucket(item: DownloadQueueItem): relationalStore.ValuesBucket {
    return {
      download_key: this.downloadKey(item.gid, item.site),
      gid: item.gid,
      token: item.token,
      title: item.title,
      title_jpn: item.titleJpn,
      cover: item.cover,
      detail_url: item.detailUrl,
      site: item.site,
      uploader: item.uploader,
      category_label: item.categoryLabel,
      posted: item.posted,
      pages: item.pages,
      language: item.language,
      rating: item.rating,
      status: item.status,
      label: item.label,
      queued_at: item.queuedAt,
      last_action: item.lastAction,
      downloaded: item.downloaded,
      total: item.total,
      failed_count: item.failedCount,
      archive_uri: item.archiveUri,
      created_at: item.createdAt,
      updated_at: item.updatedAt,
      current_page: item.currentPage,
      current_page_label: item.currentPageLabel,
      speed_bps: item.speedBytesPerSecond,
      remaining_seconds: item.remainingSeconds,
      download_dir: item.downloadDir,
      error: item.error,
      page_errors: JSON.stringify(item.pageErrors)
    };
  }

  private quickSearchToBucket(item: QuickSearchItem): relationalStore.ValuesBucket {
    const normalized = this.normalizeQuickSearch(item);
    return {
      quick_key: normalized.id,
      label: normalized.label,
      keyword: normalized.query,
      site: normalized.site,
      mode: normalized.mode,
      category: normalized.category,
      advanced_enabled: normalized.advancedEnabled ? 1 : 0,
      advanced_flags: normalized.advancedFlags,
      min_rating: normalized.minRating,
      page_from: normalized.pageFrom,
      page_to: normalized.pageTo,
      saved_at: normalized.savedAt,
      time: this.labelToTime(normalized.savedAt)
    };
  }

  private bookmarkToBucket(item: BookmarkItem, time: number = Date.now()): relationalStore.ValuesBucket {
    const savedAt = this.nowLabel();
    return {
      bookmark_key: item.url,
      title: item.title.length > 0 ? item.title : item.url,
      url: item.url,
      site: '',
      gid: 0,
      saved_at: savedAt,
      time
    };
  }

  private historyToBucket(item: HistoryItem): relationalStore.ValuesBucket {
    return {
      history_key: this.historyKey(item),
      gid: item.gid,
      token: item.token,
      title: item.title,
      title_jpn: item.titleJpn,
      cover: item.cover,
      detail_url: item.detailUrl,
      site: item.site,
      uploader: item.uploader,
      category_label: item.categoryLabel,
      posted: item.posted,
      pages: item.pages,
      language: item.language,
      rating: item.rating,
      visited_at: item.visitedAt,
      time: this.labelToTime(item.visitedAt)
    };
  }

  private favoriteToBucket(item: LocalGalleryRecord, time: number = Date.now()): relationalStore.ValuesBucket {
    return {
      favorite_key: this.historyKey(item),
      gid: item.gid,
      token: item.token,
      title: item.title,
      title_jpn: item.titleJpn,
      cover: item.cover,
      detail_url: item.detailUrl,
      site: item.site,
      uploader: item.uploader,
      category_label: item.categoryLabel,
      posted: item.posted,
      pages: item.pages,
      language: item.language,
      rating: item.rating,
      time
    };
  }

  async migrateFromPreferences(
    bookmarks: BookmarkItem[],
    quickSearches: QuickSearchItem[],
    searchHistoryQueries: string[],
    historyItems: HistoryItem[],
    downloadItems: DownloadQueueItem[],
    downloadLabels: DownloadLabelItem[]
  ): Promise<void> {
    if (bookmarks.length > 0) {
      await this.replaceBookmarks(bookmarks);
    }
    if (quickSearches.length > 0) {
      await this.replaceQuickSearches(quickSearches);
    }
    if (searchHistoryQueries.length > 0) {
      await this.replaceSearchHistoryQueries(searchHistoryQueries);
    }
    if (historyItems.length > 0) {
      await this.replaceHistoryItems(historyItems);
    }
    for (const label of downloadLabels) {
      await this.upsertDownloadLabel(label);
    }
    for (const item of downloadItems) {
      await this.upsertDownloadItem(item);
    }
  }

  async loadBookmarks(limit: number = LOCAL_LIST_LOAD_LIMIT): Promise<BookmarkItem[]> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      resultSet = await this.store.querySql(
        `SELECT title, url FROM ${BOOKMARKS_TABLE} ORDER BY time DESC LIMIT ${limit}`
      );
      const items: BookmarkItem[] = [];
      if (resultSet.goToFirstRow()) {
        do {
          const url = this.resultString(resultSet, 'url');
          if (url.length === 0) {
            continue;
          }
          items.push({
            title: this.resultString(resultSet, 'title', url),
            url
          });
        } while (resultSet.goToNextRow());
      }
      return items;
    } catch (error) {
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async replaceBookmarks(items: BookmarkItem[]): Promise<void> {
    await this.store.executeSql(`DELETE FROM ${BOOKMARKS_TABLE}`);
    let time = Date.now() + items.length;
    for (const item of items) {
      if (item.url.length === 0) {
        continue;
      }
      await this.store.insert(
        BOOKMARKS_TABLE,
        this.bookmarkToBucket(item, time),
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
      );
      time--;
    }
  }

  async loadQuickSearches(limit: number = LOCAL_LIST_LOAD_LIMIT): Promise<QuickSearchItem[]> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      resultSet = await this.store.querySql(
        `SELECT * FROM ${QUICK_SEARCH_TABLE} ORDER BY time DESC LIMIT ${limit}`
      );
      const items: QuickSearchItem[] = [];
      if (resultSet.goToFirstRow()) {
        do {
          const query = this.resultString(resultSet, 'keyword');
          const id = this.resultString(resultSet, 'quick_key');
          if (query.length === 0 || id.length === 0) {
            continue;
          }
          items.push({
            id,
            label: this.resultString(resultSet, 'label', query),
            query,
            site: this.resultString(resultSet, 'site', GallerySite.E),
            mode: this.resultString(resultSet, 'mode', SEARCH_MODE_NORMAL),
            category: this.resultNumber(resultSet, 'category', CATEGORY_ALL),
            advancedEnabled: this.resultNumber(resultSet, 'advanced_enabled', 1) !== 0,
            advancedFlags: this.resultNumber(resultSet, 'advanced_flags', 0),
            minRating: this.resultString(resultSet, 'min_rating'),
            pageFrom: this.resultString(resultSet, 'page_from'),
            pageTo: this.resultString(resultSet, 'page_to'),
            savedAt: this.resultString(resultSet, 'saved_at')
          });
        } while (resultSet.goToNextRow());
      }
      return items;
    } catch (error) {
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async replaceQuickSearches(items: QuickSearchItem[]): Promise<void> {
    await this.store.executeSql(`DELETE FROM ${QUICK_SEARCH_TABLE}`);
    for (const item of items) {
      if (item.id.length === 0 || item.query.length === 0) {
        continue;
      }
      await this.store.insert(
        QUICK_SEARCH_TABLE,
        this.quickSearchToBucket(item),
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
      );
    }
  }

  async deleteQuickSearch(id: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(QUICK_SEARCH_TABLE);
    predicates.equalTo('quick_key', id);
    await this.store.delete(predicates);
  }

  async loadSearchHistoryQueries(limit: number = SEARCH_HISTORY_MAX_COUNT): Promise<string[]> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      resultSet = await this.store.querySql(
        `SELECT keyword FROM ${SEARCH_HISTORY_TABLE} ORDER BY time DESC LIMIT ${limit}`
      );
      const values: string[] = [];
      if (resultSet.goToFirstRow()) {
        do {
          const keyword = this.resultString(resultSet, 'keyword');
          if (keyword.length > 0 && values.indexOf(keyword) < 0) {
            values.push(keyword);
          }
        } while (resultSet.goToNextRow());
      }
      return values;
    } catch (error) {
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async replaceSearchHistoryQueries(values: string[]): Promise<void> {
    await this.store.executeSql(`DELETE FROM ${SEARCH_HISTORY_TABLE}`);
    let time = Date.now() + values.length;
    for (const query of values) {
      const keyword = query.trim();
      if (keyword.length === 0) {
        continue;
      }
      await this.store.insert(
        SEARCH_HISTORY_TABLE,
        { keyword, time },
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
      );
      time--;
    }
  }

  async loadHistoryItems(limit: number = LOCAL_LIST_LOAD_LIMIT): Promise<HistoryItem[]> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      resultSet = await this.store.querySql(
        `SELECT * FROM ${HISTORY_TABLE} ORDER BY time DESC LIMIT ${limit}`
      );
      const items: HistoryItem[] = [];
      if (resultSet.goToFirstRow()) {
        do {
          const record = this.galleryRecordFromResult(resultSet);
          if (record.gid <= 0 || record.detailUrl.length === 0) {
            continue;
          }
          items.push({
            gid: record.gid,
            token: record.token,
            title: record.title,
            titleJpn: record.titleJpn,
            cover: record.cover,
            detailUrl: record.detailUrl,
            site: record.site,
            uploader: record.uploader,
            categoryLabel: record.categoryLabel,
            posted: record.posted,
            pages: record.pages,
            language: record.language,
            rating: record.rating,
            visitedAt: this.resultString(resultSet, 'visited_at')
          });
        } while (resultSet.goToNextRow());
      }
      return items;
    } catch (error) {
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async replaceHistoryItems(items: HistoryItem[]): Promise<void> {
    await this.store.executeSql(`DELETE FROM ${HISTORY_TABLE}`);
    for (const item of items) {
      await this.upsertHistoryItem(item);
    }
  }

  async upsertHistoryItem(item: HistoryItem): Promise<void> {
    if (item.gid <= 0 || item.detailUrl.length === 0) {
      return;
    }
    await this.store.insert(
      HISTORY_TABLE,
      this.historyToBucket(item),
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
    );
  }

  async deleteHistoryItem(item: HistoryItem): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(HISTORY_TABLE);
    predicates.equalTo('history_key', this.historyKey(item));
    await this.store.delete(predicates);
  }

  async clearHistory(): Promise<void> {
    await this.store.executeSql(`DELETE FROM ${HISTORY_TABLE}`);
  }

  async loadLocalFavorites(limit: number = LOCAL_LIST_LOAD_LIMIT): Promise<LocalGalleryRecord[]> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      resultSet = await this.store.querySql(
        `SELECT * FROM ${LOCAL_FAVORITES_TABLE} ORDER BY time DESC LIMIT ${limit}`
      );
      const items: LocalGalleryRecord[] = [];
      if (resultSet.goToFirstRow()) {
        do {
          const record = this.galleryRecordFromResult(resultSet);
          if (record.gid <= 0 || record.detailUrl.length === 0) {
            continue;
          }
          items.push(record);
        } while (resultSet.goToNextRow());
      }
      return items;
    } catch (error) {
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async upsertLocalFavorite(item: LocalGalleryRecord): Promise<void> {
    if (item.gid <= 0 || item.detailUrl.length === 0) {
      return;
    }
    await this.store.insert(
      LOCAL_FAVORITES_TABLE,
      this.favoriteToBucket(item),
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
    );
  }

  async deleteLocalFavorite(item: LocalGalleryRecord): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(LOCAL_FAVORITES_TABLE);
    predicates.equalTo('favorite_key', this.historyKey(item));
    await this.store.delete(predicates);
  }

  async loadFilters(limit: number = LOCAL_LIST_LOAD_LIMIT): Promise<FilterRule[]> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      resultSet = await this.store.querySql(
        `SELECT id, mode, text, enable FROM ${FILTER_TABLE} ORDER BY mode ASC, id ASC LIMIT ${limit}`
      );
      const items: FilterRule[] = [];
      if (resultSet.goToFirstRow()) {
        do {
          const text = this.resultString(resultSet, 'text').trim();
          if (text.length === 0) {
            continue;
          }
          items.push({
            id: this.resultNumber(resultSet, 'id', 0),
            mode: this.resultNumber(resultSet, 'mode', FILTER_MODE_TITLE),
            text,
            enabled: this.resultNumber(resultSet, 'enable', 1) !== 0
          });
        } while (resultSet.goToNextRow());
      }
      return items;
    } catch (error) {
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async insertFilter(rule: FilterRule): Promise<void> {
    const text = rule.text.trim();
    if (text.length === 0) {
      return;
    }
    await this.store.insert(
      FILTER_TABLE,
      {
        mode: rule.mode,
        text,
        enable: rule.enabled ? 1 : 0
      },
      relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
    );
  }

  async updateFilterEnabled(id: number, enabled: boolean): Promise<void> {
    if (id <= 0) {
      return;
    }
    await this.store.executeSql(
      `UPDATE ${FILTER_TABLE} SET enable = ? WHERE id = ?`,
      [enabled ? 1 : 0, id]
    );
  }

  async deleteFilter(id: number): Promise<void> {
    if (id <= 0) {
      return;
    }
    const predicates = new relationalStore.RdbPredicates(FILTER_TABLE);
    predicates.equalTo('id', id);
    await this.store.delete(predicates);
  }

  async loadBlacklist(limit: number = LOCAL_LIST_LOAD_LIMIT): Promise<BlacklistItem[]> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      resultSet = await this.store.querySql(
        `SELECT id, badgayname, reason, angrywith, add_time, mode FROM ${BLACKLIST_TABLE} ` +
          `ORDER BY id DESC LIMIT ${limit}`
      );
      const items: BlacklistItem[] = [];
      if (resultSet.goToFirstRow()) {
        do {
          const name = this.resultString(resultSet, 'badgayname').trim();
          if (name.length === 0) {
            continue;
          }
          items.push({
            id: this.resultNumber(resultSet, 'id', 0),
            name,
            reason: this.resultString(resultSet, 'reason'),
            angryWith: this.resultString(resultSet, 'angrywith'),
            addTime: this.resultString(resultSet, 'add_time'),
            mode: this.resultNumber(resultSet, 'mode', 1)
          });
        } while (resultSet.goToNextRow());
      }
      return items;
    } catch (error) {
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async insertBlacklist(item: BlacklistItem): Promise<void> {
    const name = item.name.trim();
    if (name.length === 0) {
      return;
    }
    await this.store.insert(
      BLACKLIST_TABLE,
      {
        badgayname: name,
        reason: item.reason,
        angrywith: item.angryWith.length > 0 ? item.angryWith : '/手动添加/',
        add_time: item.addTime.length > 0 ? item.addTime : this.nowLabel(),
        mode: item.mode > 0 ? item.mode : 1
      },
      relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
    );
  }

  async deleteBlacklist(id: number): Promise<void> {
    if (id <= 0) {
      return;
    }
    const predicates = new relationalStore.RdbPredicates(BLACKLIST_TABLE);
    predicates.equalTo('id', id);
    await this.store.delete(predicates);
  }

  async loadDownloadLabels(): Promise<DownloadLabelItem[]> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      resultSet = await this.store.querySql(
        `SELECT label, created_at FROM ${DOWNLOAD_LABEL_TABLE} ` +
          'ORDER BY CASE WHEN label = ? THEN 0 ELSE 1 END, label',
        [DOWNLOAD_DEFAULT_LABEL]
      );
      const labels: DownloadLabelItem[] = [];
      if (resultSet.goToFirstRow()) {
        do {
          labels.push({
            label: this.resultString(resultSet, 'label', DOWNLOAD_DEFAULT_LABEL),
            createdAt: this.resultString(resultSet, 'created_at', this.nowLabel())
          });
        } while (resultSet.goToNextRow());
      }
      return labels;
    } catch (error) {
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async loadDownloadItems(limit: number = LOCAL_LIST_LOAD_LIMIT): Promise<DownloadQueueItem[]> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      resultSet = await this.store.querySql(
        `SELECT * FROM ${DOWNLOAD_TABLE} ORDER BY updated_at DESC LIMIT ${limit}`
      );
      const items: DownloadQueueItem[] = [];
      if (resultSet.goToFirstRow()) {
        do {
          const record = this.galleryRecordFromResult(resultSet);
          if (record.gid <= 0 || record.detailUrl.length === 0) {
            continue;
          }
          items.push({
            gid: record.gid,
            token: record.token,
            title: record.title,
            titleJpn: record.titleJpn,
            cover: record.cover,
            detailUrl: record.detailUrl,
            site: record.site,
            uploader: record.uploader,
            categoryLabel: record.categoryLabel,
            posted: record.posted,
            pages: record.pages,
            language: record.language,
            rating: record.rating,
            status: this.normalizeDownloadStatus(this.resultString(resultSet, 'status', DOWNLOAD_STATUS_QUEUED)),
            label: this.resultString(resultSet, 'label', DOWNLOAD_DEFAULT_LABEL),
            queuedAt: this.resultString(resultSet, 'queued_at'),
            lastAction: this.resultString(resultSet, 'last_action'),
            downloaded: this.resultNumber(resultSet, 'downloaded', 0),
            total: this.resultNumber(resultSet, 'total', record.pages),
            failedCount: this.resultNumber(resultSet, 'failed_count', 0),
            archiveUri: this.resultString(resultSet, 'archive_uri'),
            createdAt: this.resultString(resultSet, 'created_at'),
            updatedAt: this.resultString(resultSet, 'updated_at'),
            currentPage: this.resultNumber(resultSet, 'current_page', 0),
            currentPageLabel: this.resultString(resultSet, 'current_page_label'),
            speedBytesPerSecond: this.resultNumber(resultSet, 'speed_bps', 0),
            remainingSeconds: this.resultNumber(resultSet, 'remaining_seconds', -1),
            downloadDir: this.resultString(resultSet, 'download_dir'),
            error: this.resultString(resultSet, 'error'),
            pageErrors: this.parseDownloadPageErrors(this.resultString(resultSet, 'page_errors', '[]'))
          });
        } while (resultSet.goToNextRow());
      }
      return items;
    } catch (error) {
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async upsertDownloadItem(item: DownloadQueueItem): Promise<void> {
    await this.store.insert(
      DOWNLOAD_TABLE,
      this.downloadItemToBucket(item),
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
    );
  }

  async deleteDownloadItem(item: DownloadQueueItem): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(DOWNLOAD_TABLE);
    predicates.equalTo('download_key', this.downloadKey(item.gid, item.site));
    await this.store.delete(predicates);
  }

  async upsertDownloadLabel(label: DownloadLabelItem): Promise<void> {
    await this.store.insert(
      DOWNLOAD_LABEL_TABLE,
      this.downloadLabelToBucket(label),
      relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
    );
  }

  private parseDownloadPageErrors(raw: string): DownloadPageError[] {
    try {
      const parsed = JSON.parse(raw) as Array<Record<string, Object>>;
      if (!Array.isArray(parsed)) {
        return [];
      }
      const errors: DownloadPageError[] = [];
      for (const item of parsed) {
        const page = this.readObjectNumber(item, 'page', 0);
        const message = this.readObjectString(item, 'message', '');
        if (page <= 0 || message.length === 0) {
          continue;
        }
        errors.push({
          page,
          message,
          updatedAt: this.readObjectString(item, 'updatedAt', '')
        });
      }
      return errors.slice(0, 200);
    } catch (error) {
      return [];
    }
  }
}
