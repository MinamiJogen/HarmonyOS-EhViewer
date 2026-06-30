import common from '@ohos.app.ability.common';
import wantAgent from '@ohos.app.ability.wantAgent';
import batteryInfo from '@ohos.batteryInfo';
import preferences from '@ohos.data.preferences';
import fileIo from '@ohos.file.fs';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import connection from '@ohos.net.connection';
import http from '@ohos.net.http';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';
import webview from '@ohos.web.webview';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  ChipGroup,
  ChipGroupItemOptions,
  ChipSize,
  ItemRestriction,
  SegmentButton,
  SegmentButtonOptions,
  SegmentButtonTextItem,
  window,
  SymbolGlyphModifier
} from '@kit.ArkUI';
import {
  HdsNavigation,
  HdsNavigationMenuContentOptions,
  HdsNavigationTitleBarOptions,
  HdsNavigationTitleMode,
  HdsTabs,
  ScrollEffectType,
  hdsMaterial
} from '@kit.UIDesignKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import {
  createEmptyNativeGalleryDetail,
  EhTagTranslator,
  EhUrl,
  GallerySite,
  NativeArchiveItem,
  NativeArchiveList,
  NativeEhClient,
  NativeFavoriteSlot,
  NativeGalleryComment,
  NativeGalleryDetail,
  NativeGalleryImagePage,
  NativeGalleryListResult,
  NativeGalleryPreview,
  NativeGallerySummary,
  NativeTorrentItem,
  NativeVoteCommentResult,
  NativeTopListDetail,
  NativeTopListEntry,
  NativeTopListGroup,
  NativeTopListPeriod,
  NativeTagGroup,
  NativeUserTag,
  TagTranslationSuggestion
} from '../ehviewer/EhNative';
import { HomeGalleryPage } from './gallery/HomeGalleryPage';
import { FavoriteGalleryPage } from './gallery/FavoriteGalleryPage';
import { GalleryDetailPage } from './gallery/GalleryDetailPage';
import { SearchResultsPage } from './gallery/SearchResultsPage';
import { PrivacySettingsCard } from './settings/PrivacySettingsCard';
import { SystemLoadingBlock } from '../components/SystemLoadingBlock';
import { LocalGalleryRecord, HistoryItem } from '../models/LocalModels';
import {
  DOWNLOAD_BACKGROUND_MODE,
  DOWNLOAD_DEFAULT_CONCURRENCY,
  DOWNLOAD_DEFAULT_LABEL,
  DOWNLOAD_INFO_FILENAME,
  DOWNLOAD_INFO_HEADER,
  DOWNLOAD_LABEL_ALL,
  DOWNLOAD_MAX_CONCURRENCY,
  DOWNLOAD_NOTIFICATION_BASE_ID,
  DOWNLOAD_NOTIFICATION_GROUP,
  DOWNLOAD_NOTIFICATION_INTERVAL_MS,
  DOWNLOAD_NOTIFICATION_LABEL_PREFIX,
  DOWNLOAD_PAGE_RETRY_LIMIT,
  DOWNLOAD_PROGRESS_PERSIST_INTERVAL_MS,
  DOWNLOAD_PROGRESS_UI_INTERVAL_MS,
  DOWNLOAD_STATE_POLL_INTERVAL_MS,
  DOWNLOAD_STATUS_DELETED,
  DOWNLOAD_STATUS_DONE,
  DOWNLOAD_STATUS_DOWNLOADING,
  DOWNLOAD_STATUS_FAILED,
  DOWNLOAD_STATUS_PAUSED,
  DOWNLOAD_STATUS_QUEUED,
  DOWNLOAD_STATUS_READING,
  DownloadLabelItem,
  DownloadPageError,
  DownloadPageResult,
  DownloadProgressCallback,
  DownloadQueueItem
} from '../download/DownloadModels';
import {
  DOWNLOAD_VIEW_ACTIVE,
  DOWNLOAD_VIEW_DOWNLOADED,
  DownloadQueueView
} from '../download/DownloadQueueView';
import {
  ReaderFullscreenPage,
  ReaderInlinePage,
  ReaderPageDataSource,
  ReaderResolvedPage,
  ReaderSwiperView,
  ReaderVirtualPage
} from './reader/ReaderPage';
import {
  APP_INDEX_PAGE_URL,
  createMyPageRouteParams,
  createNativeRouteParams,
  createSearchRouteParams,
  createWebRouteParams,
  PageRouteParams,
  readRouteString,
  ROUTE_NATIVE_COMMENTS,
  ROUTE_NATIVE_DETAIL,
  ROUTE_NATIVE_PREVIEWS,
  ROUTE_NATIVE_READER,
  ROUTE_SEARCH_ACTIVE
} from '../navigation/AppRoutes';
import {
  AppNetworkProxy
} from '../network/AppNetworkProxy';
import {
  APP_ABILITY_NAME,
  APP_BUNDLE_NAME,
  APP_LOCK_ENABLED_KEY,
  BACKGROUND_PREVIEW_PROTECTION_KEY,
  BOTTOM_NAV_SAFE_FALLBACK,
  CACHE_CATEGORY_GALLERY,
  CACHE_CATEGORY_IMAGE_SEARCH,
  CACHE_CATEGORY_READER,
  CACHE_DEFAULT_MAX_SIZE_MB,
  CACHE_DEFAULT_RETENTION_DAYS,
  CACHE_KEY_MAX_SIZE_MB,
  CACHE_KEY_RETENTION_DAYS,
  CACHE_MAX_MAX_SIZE_MB,
  CACHE_MAX_RETENTION_DAYS,
  CACHE_MIN_MAX_SIZE_MB,
  CACHE_MIN_RETENTION_DAYS,
  CATEGORY_ALL,
  CATEGORY_ASIAN_PORN,
  CATEGORY_ARTIST_CG,
  CATEGORY_COSPLAY,
  CATEGORY_DOUJINSHI,
  CATEGORY_GAME_CG,
  CATEGORY_IMAGE_SET,
  CATEGORY_MANGA,
  CATEGORY_MISC,
  CATEGORY_NON_H,
  CATEGORY_WESTERN,
  COOKIE_PERSIST_MAX_AGE_SECONDS,
  DETAIL_TORRENT_DIR_NAME,
  DOWNLOAD_ROUTE_ACTION_ACTIVE,
  DOWNLOAD_ROUTE_ACTION_KEY,
  DOWNLOAD_ROUTE_EVENT_STORAGE_KEY,
  DOWNLOAD_ROUTE_TARGET_STORAGE_KEY,
  EMPTY_FAVORITE_CATEGORY_COUNTS,
  EXCLUDED_LANGUAGE_KEY,
  EXCLUDED_LANGUAGE_OPTIONS,
  FAVORITE_BAR_FONT_SIZE,
  FAVORITE_BAR_GAP,
  FAVORITE_BAR_ICON_WIDTH,
  FAVORITE_BAR_PADDING,
  FAVORITE_BAR_SELECT_WIDTH,
  FAVORITE_BAR_WIDTH,
  FAVORITE_CATEGORY_COUNTS_KEY,
  FAVORITE_CATEGORY_NAMES_KEY,
  FAVORITE_DEFAULT_SLOT_KEY,
  FAVORITE_FILTER_ALL,
  FAVORITE_FILTER_LOCAL,
  FAVORITE_INVALID_DEFAULT_SLOT,
  FAVORITE_LOCAL_SLOT,
  FAVORITE_RECENT_FILTER_KEY,
  FAVORITE_SLOT_NAMES,
  FILTER_MODE_OPTIONS,
  FILTER_MODE_TAG,
  FILTER_MODE_TAG_NAMESPACE,
  FILTER_MODE_TITLE,
  FILTER_MODE_UPLOADER,
  FLOATING_BOTTOM_TAB_BAR_HEIGHT,
  GALLERY_IMAGE_CACHE_DIR_NAME,
  GALLERY_LIST_TIMEOUT_MS,
  HDS_MINI_TITLE_BAR_HEIGHT,
  HOME_CONTENT_UNAVAILABLE_MESSAGE,
  HOME_PAGE_DEFAULT,
  HOME_PAGE_POPULAR,
  HOME_PAGE_TOP,
  HOME_PAGE_WATCHED,
  LIBRARY_DOWNLOADS,
  LIBRARY_FAVORITES,
  LIBRARY_HISTORY,
  LOCAL_DATA_MIGRATION_KEY,
  LOCAL_DATA_MIGRATION_TIME_KEY,
  LOCAL_LIST_LOAD_LIMIT,
  MY_PAGE_ACCOUNT,
  MY_PAGE_BLACKLIST,
  MY_PAGE_BOOKMARKS,
  MY_PAGE_DOWNLOADS,
  MY_PAGE_FAVORITES,
  MY_PAGE_FILTERS,
  MY_PAGE_HISTORY,
  MY_PAGE_IMAGE_SEARCH,
  MY_PAGE_MAIN,
  MY_PAGE_MY_TAGS,
  MY_PAGE_SETTINGS,
  NAV_HOME,
  NAV_LIBRARY,
  NAV_MY,
  NAV_SEARCH,
  NAV_SETTINGS,
  PAGE_BOTTOM_SPACING,
  PAGE_SIDE_GUTTER,
  PREVIEW_THUMB_HEIGHT,
  PREVIEW_THUMB_WIDTH,
  READER_CACHE_DIR_NAME,
  READER_DEFAULT_PRELOAD_IMAGE,
  READER_DIRECTION_VALUES,
  READER_DOWNLOAD_DIR_NAME,
  READER_HTML_PREFETCH_CONCURRENCY,
  READER_IMAGE_EXTENSIONS,
  READER_IMAGE_PREFETCH_CONCURRENCY,
  READER_KEY_CUSTOM_LIGHTNESS,
  READER_KEY_DOWNLOAD_ORIGIN_IMAGE,
  READER_KEY_FULLSCREEN,
  READER_KEY_KEEP_SCREEN_ON,
  READER_KEY_PAGE_SCALING,
  READER_KEY_PRELOAD_IMAGE,
  READER_PROGRESS_KEY,
  READER_KEY_READING_DIRECTION,
  READER_KEY_REVERSE_VOLUME_PAGE,
  READER_KEY_SCREEN_LIGHTNESS,
  READER_KEY_SCREEN_ROTATION,
  READER_KEY_SHOW_BATTERY,
  READER_KEY_SHOW_CLOCK,
  READER_KEY_SHOW_PAGE_INTERVAL,
  READER_KEY_SHOW_PROGRESS,
  READER_KEY_START_POSITION,
  READER_KEY_START_TRANSFER_TIME,
  READER_KEY_VOLUME_PAGE,
  READER_MAX_PRELOAD_IMAGE,
  READER_PRELOAD_SIDE_COUNT,
  READER_ROTATION_VALUES,
  READER_SCALING_VALUES,
  READER_START_POSITION_VALUES,
  SEARCH_ADV_FLAG_DESCRIPTION,
  SEARCH_ADV_FLAG_DOWNVOTED,
  SEARCH_ADV_FLAG_EXPUNGED,
  SEARCH_ADV_FLAG_FILE_NAME,
  SEARCH_ADV_FLAG_LOW_POWER_TAGS,
  SEARCH_ADV_FLAG_NAME,
  SEARCH_ADV_FLAG_TAGS,
  SEARCH_ADV_FLAG_TORRENT,
  SEARCH_ADV_FLAG_TORRENT_FILE,
  SEARCH_ADV_FLAG_UPLOADER,
  SEARCH_ADVANCED_FLAG_OPTIONS,
  SEARCH_CATEGORY_OPTIONS,
  SEARCH_HISTORY_MAX_COUNT,
  SEARCH_HISTORY_SUGGEST_LIMIT,
  SEARCH_MODE_NORMAL,
  SEARCH_MODE_OPTIONS,
  SEARCH_MODE_TAG,
  SEARCH_MODE_UPLOADER,
  SEARCH_MODE_WATCHED,
  SIGN_IN_COOKIE_RETRY_DELAYS,
  TAG_SUGGEST_LIMIT,
  WEB_MODE_SIGN_IN,
  WEB_MODE_UCONFIG,
  WEB_SIGN_IN_CLOUDFLARE_HOSTS,
  WEB_SIGN_IN_RESET_COOKIE_NAMES
} from '../constants/AppConstants';
import {
  BlacklistItem,
  BookmarkItem,
  CacheCleanupResult,
  CacheFileEntry,
  FavoriteFilterOption,
  FilterModeOption,
  FilterRule,
  GalleryImageCacheEntry,
  LanguageFilterOption,
  ParsedTag,
  QuickLink,
  QuickSearchItem,
  ReaderAdjacentState,
  ReaderCommandHandler,
  ReaderImageCacheEntry,
  ReaderImagePrefetchTask,
  ReaderPrefetchTask,
  ReaderSelectChangeHandler,
  ReaderSliderChangeHandler,
  ReaderToggleChangeHandler,
  SearchAdvancedFlagOption,
  SearchCategoryOption,
  SearchModeOption
} from '../models/AppModels';
import { EhLocalDataDao } from '../data/EhLocalDataDao';
import { authenticateAppLock, AppLockAuthenticationResult } from '../privacy/AppLockAuthentication';
import {
  readPrivacySettings,
  setAppLockAuthActive as setAppLockAuthActiveStorage,
  setAppLockForegroundRequired as setAppLockForegroundRequiredStorage
} from '../privacy/PrivacySettings';
import { formatByteSize, formatBytesPerSecond, formatRating, formatRemainingSeconds, compactTags, categoryColor, metaLine } from '../utils/FormatUtils';
import { clampNumber } from '../utils/NumberUtils';
import { readObjectBoolean, readObjectNumber, readObjectString } from '../utils/RecordUtils';
import { rawBytesToString, safeFileName } from '../utils/TextUtils';
import { parseReaderProgress, readerProgressSnapshot } from '../reader/ReaderProgressStore';
import {
  emptyFavoriteCategoryCounts,
  ensureDownloadDefaultLabel,
  isSupportedExcludedLanguageTag,
  parseBookmarks,
  parseDownloadLabels,
  parseDownloadPageErrorsFromObject,
  parseExcludedLanguageTags,
  parseFavoriteCategoryCounts,
  parseFavoriteCategoryNames,
  parseLocalGalleryRecord,
  parseQuickSearches,
  parseSearchHistoryQueries
} from '../storage/PreferenceParsers';

let sharedDownloadWorkerRunning: boolean = false;
let sharedDownloadActiveKey: string = '';
let sharedDownloadItemsSnapshot: DownloadQueueItem[] = [];
let sharedDownloadWaitKeys: string[] = [];
let sharedDownloadBackgroundStopAttempted: boolean = false;
const sharedDownloadCancelKeys: Set<string> = new Set<string>();
const sharedDownloadRemovedKeys: Set<string> = new Set<string>();
const sharedDownloadStartRequestedKeys: Set<string> = new Set<string>();
const sharedDownloadRunGenerations: Map<string, number> = new Map<string, number>();
const sharedDownloadNotificationStates: Map<string, string> = new Map<string, string>();
const sharedDownloadNotificationLastAt: Map<string, number> = new Map<string, number>();
const sharedDownloadNotificationIds: Map<string, number> = new Map<string, number>();
const sharedDownloadNotificationLabels: Map<string, string> = new Map<string, string>();
const DOWNLOAD_RUNTIME_ITEMS_KEY: string = 'download_runtime_items_snapshot';
const DOWNLOAD_RUNTIME_ACTIVE_KEY: string = 'download_runtime_active_key';
const DOWNLOAD_RUNTIME_WORKER_RUNNING_KEY: string = 'download_runtime_worker_running';
const DOWNLOAD_RUNTIME_REVISION_KEY: string = 'download_runtime_revision';
const DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY: string = 'download_runtime_cancel_keys';
const DOWNLOAD_RUNTIME_REMOVED_KEYS_KEY: string = 'download_runtime_removed_keys';
const DOWNLOAD_RUNTIME_HEARTBEAT_KEY: string = 'download_runtime_heartbeat_at';
const DOWNLOAD_RUNTIME_HEARTBEAT_INTERVAL_MS: number = 1000;
const DOWNLOAD_RUNTIME_HEARTBEAT_TTL_MS: number = 12000;
const DIAG_DOMAIN = 0x0000;
const DIAG_TAG = 'EhIndex';

interface NativeReadableErrorInfo {
  code?: number | string;
  message?: string;
  data?: string;
  name?: string;
}

interface NativeRouteSnapshot {
  detail: NativeGalleryDetail;
  previewItems: NativeGalleryPreview[];
  previewPageIndex: number;
  previewPageCount: number;
  allPreviewItems: NativeGalleryPreview[];
  allPreviewLoadedPages: number;
  allPreviewPageCount: number;
  allPreviewStatus: string;
  updatedAt: number;
}

const sharedNativeRouteSnapshots: Map<string, NativeRouteSnapshot> = new Map<string, NativeRouteSnapshot>();
const SHARED_NATIVE_ROUTE_SNAPSHOT_LIMIT: number = 24;
const WATERFALL_BATCH_PAGE_COUNT: number = 2;
const WATERFALL_LOAD_REMAINING_RATIO: number = 0.3;
const WATERFALL_MIN_COLUMNS: number = 2;
const WATERFALL_COLUMN_GAP: number = 10;
const WATERFALL_ROW_GAP: number = 12;
const WATERFALL_PREFERRED_ITEM_WIDTH: number = 176;
const WATERFALL_CARD_EXTRA_HEIGHT: number = 150;
const WATERFALL_MIN_CONTENT_HEIGHT: number = 180;
const SEARCH_HISTORY_DEFAULT_VISIBLE_COUNT: number = 3;
const LOGIN_GATE_SEEN_KEY: string = 'login_gate_seen';

interface TopListPeriodOption {
  key: string;
  label: string;
  matchKeywords: string[];
}

const TOP_LIST_PERIOD_OPTIONS: TopListPeriodOption[] = [
  { key: 'yesterday', label: '昨天', matchKeywords: ['yesterday', 'past day', 'daily', '昨天'] },
  { key: 'month', label: '过去一月', matchKeywords: ['past month', 'month', 'monthly', '过去一月', '过去一个月'] },
  { key: 'year', label: '过去一年', matchKeywords: ['past year', 'year', 'yearly', '过去一年'] },
  { key: 'all', label: '所有时间', matchKeywords: ['all-time', 'all time', 'alltime', 'overall', '所有时间'] }
];

const TOP_LIST_PERIOD_SEGMENT_BUTTONS: ItemRestriction<SegmentButtonTextItem> = [
  { text: '昨天' },
  { text: '过去一月' },
  { text: '过去一年' },
  { text: '所有时间' }
];

const DOWNLOAD_VIEW_SEGMENT_BUTTONS: ItemRestriction<SegmentButtonTextItem> = [
  { text: '已下载' },
  { text: '下载中' }
];
const DOWNLOAD_TITLE_BAR_BOTTOM_HEIGHT: number = 54;
const DOWNLOAD_SCROLL_EXTRA_HEIGHT: number = 80;

@Entry
@Component
struct Index {
  private readonly controller: webview.WebviewController = new webview.WebviewController('ehviewer-main-web');
  private settingsStore?: preferences.Preferences = undefined;
  private readerWindow?: window.Window = undefined;
  private routeNativeSummary?: NativeGallerySummary = undefined;
  private routeNativeMode: string = '';
  private routeReaderPageUrl: string = '';
  private routeSearchUrl: string = '';
  private tagSearchReturnSection: number = NAV_HOME;
  private tagSearchReturnGid: number = 0;
  private tagSearchReturnToken: string = '';
  private keepNextSearchReturnDetail: boolean = false;
  private readerAutoTransferTimerId: number = -1;
  private readerClockTimerId: number = -1;
  private readerTopInfoTimerId: number = -1;
  private readerPrefetchGeneration: number = 0;
  private readerLoadSerial: number = 0;
  private readerHtmlPrefetchActiveCount: number = 0;
  private readerImagePrefetchActiveCount: number = 0;
  private nativeAllPreviewLoadSerial: number = 0;
  private readerReturnViewMode: string = 'detail';
  private pendingReaderReturnViewMode: string = '';
  private readonly readerPageCache: Map<string, NativeGalleryImagePage> = new Map();
  private readonly readerPageInFlight: Map<string, Promise<NativeGalleryImagePage>> = new Map();
  private readonly readerPageRetrySkipKeys: Map<string, string> = new Map();
  private readonly readerImageCache: Map<string, ReaderImageCacheEntry> = new Map();
  private readonly readerImageInFlight: Map<string, Promise<string>> = new Map();
  private readonly readerProgressByGallery: Map<string, number> = new Map();
  private readonly galleryImageCache: Map<string, GalleryImageCacheEntry> = new Map();
  private readonly galleryImageInFlight: Map<string, Promise<string>> = new Map();
  private localDao?: EhLocalDataDao = undefined;
  private downloadWorkerRunning: boolean = false;
  private downloadActiveKey: string = '';
  private downloadBackgroundRunning: boolean = false;
  private downloadBackgroundStarting: boolean = false;
  private downloadBackgroundTaskId: number = -1;
  private downloadNotificationPermissionAsked: boolean = false;
  private readonly downloadCancelKeys: Set<string> = new Set();
  private readonly downloadRemovedKeys: Set<string> = new Set();
  private readonly downloadStartRequestedKeys: Set<string> = new Set();
  private readonly downloadRunGenerations: Map<string, number> = new Map();
  private downloadWaitKeys: string[] = [];
  private readonly downloadPageUrlCache: Map<string, string[]> = new Map();
  private readonly downloadPersistVersions: Map<string, number> = new Map();
  private readonly downloadPageTransferFractions: Map<string, Map<number, number>> = new Map();
  private readonly downloadActiveRequests: Map<string, http.HttpRequest[]> = new Map();
  private downloadPersistQueue: Promise<void> = Promise.resolve();
  private downloadStatePollTimerId: number = -1;
  private downloadRuntimeSyncInFlight: boolean = false;
  private downloadRuntimeSyncPending: boolean = false;
  private downloadRuntimeSyncPendingForce: boolean = false;
  private downloadRuntimeHeartbeatLastWriteAt: number = 0;
  private readerHtmlPrefetchQueue: ReaderPrefetchTask[] = [];
  private readerImagePrefetchQueue: ReaderImagePrefetchTask[] = [];
  private readonly homeScroller: Scroller = new Scroller();
  private readonly searchScroller: Scroller = new Scroller();
  private readonly nativeScroller: Scroller = new Scroller();
  private readonly libraryScroller: Scroller = new Scroller();
  private readonly settingsScroller: Scroller = new Scroller();
  private readonly myScroller: Scroller = new Scroller();
  private homeScrollOffsetY: number = 0;
  private searchScrollOffsetY: number = 0;
  private libraryScrollOffsetY: number = 0;
  private restoringGalleryListScroll: boolean = false;
  private lastHomeTabClickAt: number = 0;
  private homeRawResults: NativeGallerySummary[] = [];
  private searchRawResults: NativeGallerySummary[] = [];
  private favoriteRawResults: NativeGallerySummary[] = [];
  private nativeRawResults: NativeGallerySummary[] = [];
  private homeListLoadSerial: number = 0;
  private favoriteListLoadSerial: number = 0;
  private searchListLoadSerial: number = 0;
  private homeEndToastKey: string = '';
  private searchEndToastKey: string = '';
  private favoriteEndToastKey: string = '';
  private readonly readerSwiperController: SwiperController = new SwiperController();
  private readonly readerPageDataSource: ReaderPageDataSource = new ReaderPageDataSource();
  private readonly readerPreviewPageInFlight: Map<number, Promise<void>> = new Map();
  private readerPageSourceGeneration: number = 0;

  @State private isReady: boolean = false;
  @State private isHomeRefreshing: boolean = false;
  @State private isFavoriteRefreshing: boolean = false;
  @State private activeSection: number = NAV_HOME;
  @State private myPage: string = MY_PAGE_MAIN;
  @State private myPageTitle: string = '';
  @State private mySubPage: string = MY_PAGE_MAIN;
  @State private mySubPageTitle: string = '';
  @State private libraryPanel: number = LIBRARY_FAVORITES;
  @State private homePage: string = HOME_PAGE_DEFAULT;
  @State private siteMode: string = GallerySite.E;
  @State private warningAcknowledged: boolean = false;
  @State private privateBrowsing: boolean = false;
  @StorageLink('app_lock_enabled') private appLockEnabled: boolean = false;
  @State private appLockVerified: boolean = false;
  @State private appLockAuthInProgress: boolean = false;
  @State private appLockStatus: string = '验证身份后进入应用';
  @StorageLink('background_preview_protection_enabled') private backgroundPreviewProtectionEnabled: boolean = true;
  @State private privacySettingsRevision: number = 0;
  @StorageLink('app_lock_foreground_required') private appLockForegroundRequired: boolean = false;
  @State private webSrc: string = EhUrl.home(GallerySite.E);
  @State private addressInput: string = EhUrl.home(GallerySite.E);
  @State private pageTitle: string = 'E-Harmony';
  @State private loadProgress: number = 0;
  @State private cookieDraft: string = '';
  @State private bookmarks: BookmarkItem[] = [];
  @State private quickSearches: QuickSearchItem[] = [];
  @State private historyItems: HistoryItem[] = [];
  @State private localFavorites: LocalGalleryRecord[] = [];
  @State private filterRules: FilterRule[] = [];
  @State private blacklistItems: BlacklistItem[] = [];
  @State private excludedLanguageTags: string[] = [];
  @State private filterModeDraft: number = FILTER_MODE_TITLE;
  @State private filterTextDraft: string = '';
  @State private filterTagSuggestions: TagTranslationSuggestion[] = [];
  @State private blacklistNameDraft: string = '';
  @State private blacklistReasonDraft: string = '';
  @State private homeFilteredCount: number = 0;
  @State private searchFilteredCount: number = 0;
  @State private favoriteFilteredCount: number = 0;
  @State private nativeFilteredCount: number = 0;
  @State private downloadItems: DownloadQueueItem[] = [];
  @State private downloadLabels: DownloadLabelItem[] = [];
  @State private activeDownloadLabel: string = DOWNLOAD_LABEL_ALL;
  @State private downloadLabelDraft: string = '';
  @State private downloadDirectoryPath: string = '';
  @State private downloadConcurrency: number = DOWNLOAD_DEFAULT_CONCURRENCY;
  @State private downloadUseOriginImage: boolean = false;
  @State private downloadImportExportText: string = '';
  @State private downloadManagerStatus: string = '下载器空闲';
  @State private downloadViewMode: string = DOWNLOAD_VIEW_DOWNLOADED;
  @State private downloadViewSelectedIndexes: number[] = [0];
  @StorageLink(DOWNLOAD_ROUTE_EVENT_STORAGE_KEY) @Watch('handleDownloadRouteEventChanged')
  private downloadRouteEventId: number = 0;
  @StorageLink(DOWNLOAD_ROUTE_TARGET_STORAGE_KEY) private downloadRouteTarget: string = '';
  @State private downloadViewSegmentOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: DOWNLOAD_VIEW_SEGMENT_BUTTONS,
    multiply: false,
    fontColor: '#2B2027',
    selectedFontColor: '#2B2027',
    fontSize: 14,
    selectedFontSize: 14,
    fontWeight: FontWeight.Regular,
    selectedFontWeight: FontWeight.Medium,
    backgroundColor: 'rgba(0,0,0,0.05)',
    selectedBackgroundColor: 'rgba(255,255,255,0.70)',
    textPadding: { left: 12, right: 12, top: 7, bottom: 7 }
  });
  @StorageLink(DOWNLOAD_RUNTIME_ITEMS_KEY) private downloadRuntimeItemsJson: string = '[]';
  @StorageLink(DOWNLOAD_RUNTIME_ACTIVE_KEY) private downloadRuntimeActiveKey: string = '';
  @StorageLink(DOWNLOAD_RUNTIME_WORKER_RUNNING_KEY) private downloadRuntimeWorkerRunning: boolean = false;
  @StorageLink(DOWNLOAD_RUNTIME_REVISION_KEY) private downloadRuntimeRevision: number = 0;
  @State private hasSignInCookie: boolean = false;
  @State private hasExCookie: boolean = false;
  @State private loginGateVisible: boolean = false;
  @State private cookieStatusSummary: string = '未检测到登录 Cookie';
  @State private nativeQuery: string = '';
  @State private tagSearchTransitionQuery: string = '';
  @State private searchMode: string = SEARCH_MODE_NORMAL;
  @State private searchCategoryMask: number = CATEGORY_ALL;
  @State private searchAdvancedEnabled: boolean = true;
  @State private searchFiltersExpanded: boolean = true;
  @State private searchFilterSheetVisible: boolean = false;
  @State private searchName: boolean = true;
  @State private searchTags: boolean = true;
  @State private searchDescription: boolean = false;
  @State private searchTorrent: boolean = false;
  @State private searchLowPowerTags: boolean = false;
  @State private searchExpunged: boolean = false;
  @State private searchDownvoted: boolean = false;
  @State private searchFileName: boolean = false;
  @State private searchUploader: boolean = false;
  @State private searchTorrentFile: boolean = false;
  @State private searchMinRating: string = '';
  @State private searchPageFrom: string = '';
  @State private searchPageTo: string = '';
  @State private tagTranslationsLoaded: boolean = false;
  @State private searchHistoryQueries: string[] = [];
  @State private searchHistorySuggestions: string[] = [];
  @State private searchHistoryExpanded: boolean = false;
  @State private tagSuggestions: TagTranslationSuggestion[] = [];
  @State private searchSuggestionsVisible: boolean = false;
  @State private searchInputFocused: boolean = false;
  @State private searchResultsActive: boolean = false;
  @State private homeLoading: boolean = false;
  @State private homeLoadingMessage: string = '正在加载图库...';
  @State private homeError: string = '';
  @State private homeResults: NativeGallerySummary[] = [];
  @State private homeListUrl: string = '';
  @State private homeResultCount: string = '';
  @State private homeFirstUrl: string = '';
  @State private homePrevUrl: string = '';
  @State private homeNextUrl: string = '';
  @State private homeLastUrl: string = '';
  @State private favoriteLoading: boolean = false;
  @State private favoriteLoadingMessage: string = '正在加载收藏...';
  @State private favoriteError: string = '';
  @State private favoriteResults: NativeGallerySummary[] = [];
  @State private favoriteListUrl: string = '';
  @State private favoriteResultCount: string = '';
  @State private favoriteFirstUrl: string = '';
  @State private favoritePrevUrl: string = '';
  @State private favoriteNextUrl: string = '';
  @State private favoriteLastUrl: string = '';
  @State private homeSectionTitle: string = '首页';
  @State private homeSectionRefreshUrl: string = '';
  @State private searchLoading: boolean = false;
  @State private searchLoadingMessage: string = '正在加载图库...';
  @State private searchError: string = '';
  @State private searchResults: NativeGallerySummary[] = [];
  @State private searchListUrl: string = '';
  @State private searchResultCount: string = '';
  @State private searchFirstUrl: string = '';
  @State private searchPrevUrl: string = '';
  @State private searchNextUrl: string = '';
  @State private searchLastUrl: string = '';
  @State private nativeLoading: boolean = false;
  @State private nativeLoadingMessage: string = '正在加载图库...';
  @State private nativeError: string = '';
  @State private nativeResults: NativeGallerySummary[] = [];
  @State private nativeListUrl: string = '';
  @State private nativeResultCount: string = '';
  @State private nativeFirstUrl: string = '';
  @State private nativePrevUrl: string = '';
  @State private nativeNextUrl: string = '';
  @State private nativeLastUrl: string = '';
  @State private nativeViewMode: string = 'list';
  @State private nativeDetail: NativeGalleryDetail = createEmptyNativeGalleryDetail();
  @State private nativeDetailRevision: number = 0;
  @State private downloadQueueRevision: number = 0;
  @State private nativePreviewItems: NativeGalleryPreview[] = [];
  @State private nativePreviewPageIndex: number = 0;
  @State private nativePreviewPageCount: number = 0;
  @State private nativePreviewLoading: boolean = false;
  @State private nativePreviewStripWidth: number = 0;
  @State private nativeAllPreviewItems: NativeGalleryPreview[] = [];
  @State private nativeAllPreviewLoading: boolean = false;
  @State private nativeAllPreviewLoadedPages: number = 0;
  @State private nativeAllPreviewPageCount: number = 0;
  @State private nativeAllPreviewStatus: string = '';
  @State private favoritePanelVisible: boolean = false;
  @State private ratingPanelVisible: boolean = false;
  @State private torrentPanelVisible: boolean = false;
  @State private archivePanelVisible: boolean = false;
  @State private detailActionLoading: boolean = false;
  @State private detailActionStatus: string = '';
  @State private defaultFavoriteSlot: number = FAVORITE_INVALID_DEFAULT_SLOT;
  @State private favoriteCategoryNames: string[] = FAVORITE_SLOT_NAMES.slice();
  @State private favoriteCategoryCounts: number[] = EMPTY_FAVORITE_CATEGORY_COUNTS.slice();
  @State private favoriteListFilter: number = FAVORITE_FILTER_ALL;
  @State private favoritePanelSlotDraft: number = FAVORITE_LOCAL_SLOT;
  @State private selectedRating: number = 0;
  @State private nativeCommentsLoading: boolean = false;
  @State private nativeCommentsStatus: string = '';
  @State private torrentItems: NativeTorrentItem[] = [];
  @State private torrentLoading: boolean = false;
  @State private torrentStatus: string = '';
  @State private archiveList: NativeArchiveList = {
    formParamOr: '',
    items: []
  };
  @State private archiveLoading: boolean = false;
  @State private archiveStatus: string = '';
  @State private nativeReaderPage: NativeGalleryImagePage = {
    pageIndex: 0,
    pageLabel: '',
    pageUrl: '',
    imageUrl: '',
    originImageUrl: ''
  };
  @State private nativeReaderListIndex: number = -1;
  @State private readerJumpInput: string = '';
  @State private readerFitContain: boolean = true;
  @State private readerMenuVisible: boolean = false;
  @State private readerSettingsVisible: boolean = false;
  @State private readerTopInfoVisible: boolean = false;
  @State private readerNowText: string = '';
  @State private readerBatteryText: string = '--%';
  @State private readerScreenRotation: string = '0';
  @State private readerDirection: string = '1';
  @State private readerPageScaling: string = '3';
  @State private readerStartPosition: string = '1';
  @State private readerAutoTransferSeconds: number = 2;
  @State private readerKeepScreenOn: boolean = false;
  @State private readerShowClock: boolean = true;
  @State private readerShowProgress: boolean = true;
  @State private readerShowBattery: boolean = true;
  @State private readerShowPageInterval: boolean = true;
  @State private readerVolumePage: boolean = false;
  @State private readerReverseVolumePage: boolean = false;
  @State private readerReadingFullscreen: boolean = true;
  @State private readerCustomScreenLightness: boolean = false;
  @State private readerScreenLightness: number = 50;
  @State private readerAutoTransferring: boolean = false;
  @State private readerDragOffset: number = 0;
  @State private readerDragActive: boolean = false;
  @State private readerPanPagingActive: boolean = false;
  @State private readerPageSwitching: boolean = false;
  @State private readerTargetLoading: boolean = false;
  @State private readerSwiperIndex: number = 0;
  @State private readerViewportWidth: number = 1;
  @State private readerViewportHeight: number = 1;
  @State private readerTransitionSnapshotActive: boolean = false;
  @State private readerTransitionCurrentSnapshot: ReaderAdjacentState = {
    pageUrl: '',
    pageLabel: '',
    pageIndex: -1,
    displayUrl: '',
    loading: false,
    error: ''
  };
  @State private readerTransitionNegativeSnapshot: ReaderAdjacentState = {
    pageUrl: '',
    pageLabel: '',
    pageIndex: -1,
    displayUrl: '',
    loading: false,
    error: ''
  };
  @State private readerTransitionPositiveSnapshot: ReaderAdjacentState = {
    pageUrl: '',
    pageLabel: '',
    pageIndex: -1,
    displayUrl: '',
    loading: false,
    error: ''
  };
  @State private readerPreviousAdjacent: ReaderAdjacentState = {
    pageUrl: '',
    pageLabel: '',
    pageIndex: -1,
    displayUrl: '',
    loading: false,
    error: ''
  };
  @State private readerNextAdjacent: ReaderAdjacentState = {
    pageUrl: '',
    pageLabel: '',
    pageIndex: -1,
    displayUrl: '',
    loading: false,
    error: ''
  };
  @State private readerPreloadImageCount: number = READER_DEFAULT_PRELOAD_IMAGE;
  @State private readerUseOriginImage: boolean = false;
  @State private readerDisplayImageUrl: string = '';
  @State private readerCurrentError: string = '';
  @State private readerProgressRevision: number = 0;
  @State private readerCacheStatus: string = '缓存空闲';
  @State private cacheMaxSizeMb: number = CACHE_DEFAULT_MAX_SIZE_MB;
  @State private cacheRetentionDays: number = CACHE_DEFAULT_RETENTION_DAYS;
  @State private cacheMaxSizeInput: string = `${CACHE_DEFAULT_MAX_SIZE_MB}`;
  @State private cacheRetentionDaysInput: string = `${CACHE_DEFAULT_RETENTION_DAYS}`;
  @State private cacheMaintenanceStatus: string = '缓存策略空闲';
  @State private galleryImageCacheVersion: number = 0;
  @State private topListDetail: NativeTopListDetail = {
    title: '',
    groups: []
  };
  @State private topListLoading: boolean = false;
  @State private topListError: string = '';
  @State private topListGroupIndex: number = 0;
  @State private topListPeriodSelectedIndexes: number[] = [0];
  @State private topListPeriodSegmentOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: TOP_LIST_PERIOD_SEGMENT_BUTTONS,
    multiply: false,
    fontColor: '#2B2027',
    selectedFontColor: '#FFFFFF',
    fontSize: 13,
    selectedFontSize: 13,
    fontWeight: FontWeight.Regular,
    selectedFontWeight: FontWeight.Medium,
    backgroundColor: '#F3E3EA',
    selectedBackgroundColor: '#C86B8C',
    textPadding: { left: 6, right: 6, top: 6, bottom: 6 }
  });
  @State private myTags: NativeUserTag[] = [];
  @State private myTagsLoading: boolean = false;
  @State private myTagsError: string = '';
  @State private imageSearchPath: string = '';
  @State private imageSearchSimilar: boolean = true;
  @State private imageSearchCovers: boolean = true;
  @State private imageSearchExpunged: boolean = false;
  @State private imageSearchLoading: boolean = false;
  @State private imageSearchError: string = '';
  @State private fullScreenWebUrl: string = '';
  @State private fullScreenWebTitle: string = '';
  @State private fullScreenWebMode: string = '';
  @State private fullScreenWebProgress: number = 0;
  @State private systemSafeTop: number = 0;
  @State private systemSafeBottom: number = BOTTOM_NAV_SAFE_FALLBACK;
  @State private pageViewportWidth: number = 1;
  @State private pageViewportHeight: number = 1;
  @State private customMaterialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;
  private signInSyncSerial: number = 0;
  private signInForumProbeStarted: boolean = false;
  private signInExProbeStarted: boolean = false;
  private signInExPendingNotified: boolean = false;
  private cacheMaintenanceTimerId: number = -1;
  private searchInputBlurTimerId: number = -1;
  private cacheMaintenanceRunning: boolean = false;
  private lastCacheMaintenanceAt: number = 0;
  private readerAdjacentRefreshSerial: number = 0;
  private handledDownloadRouteEventId: number = 0;

  aboutToAppear(): void {
    this.ensureDownloadRuntimeStorageDefaults();
    this.resolveBottomBarMaterialLevel();
    this.applyRouteParams(false);
    this.primeInitialRouteDisplay();
    if (this.hasInitialRouteParams()) {
      this.isReady = true;
    }
    void this.applyReaderWindowState();
    void this.loadState();
  }

  private resolveBottomBarMaterialLevel(): void {
    const materialTypes = hdsMaterial.getSystemMaterialTypes();
    if (materialTypes.indexOf(hdsMaterial.MaterialType.IMMERSIVE) < 0) {
      this.customMaterialLevel = hdsMaterial.MaterialLevel.SMOOTH;
      return;
    }
    this.customMaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;
  }

  onPageShow(): void {
    this.refreshPrivacySettingsFromStore();
    this.loadReaderProgressSettings();
    this.refreshPersistedCookieState();
    void this.applyReaderWindowState();
    void this.syncDownloadStateFromDatabase(false);
    this.updateDownloadStatePolling();
    void this.requireAppUnlockIfNeeded();
  }

  onPageHide(): void {
  }

  aboutToDisappear(): void {
    this.signInSyncSerial++;
    this.nativeAllPreviewLoadSerial++;
    if (this.cacheMaintenanceTimerId >= 0) {
      clearTimeout(this.cacheMaintenanceTimerId);
      this.cacheMaintenanceTimerId = -1;
    }
    this.cancelSearchInputBlurTimer();
    this.stopDownloadStatePolling();
    this.stopReaderRuntimeState();
  }

  onBackPress(): boolean {
    if (this.hasActiveReaderPage()) {
      this.persistCurrentReaderProgress();
      if (this.isRouteBackAvailableForCurrentSubPage()) {
        return false;
      }
      this.returnFromNativeReader();
      return true;
    }
    if (this.nativeViewMode === 'previews' || this.nativeViewMode === 'comments') {
      if (this.isRouteBackAvailableForCurrentSubPage()) {
        return false;
      }
      this.goBackToNativeDetail();
      return true;
    }
    if (this.nativeViewMode === 'detail') {
      if (this.isRouteBackAvailableForCurrentSubPage()) {
        return false;
      }
      this.goBackToNativeList();
      return true;
    }
    if (this.activeSection === NAV_SEARCH && this.searchResultsActive) {
      if (this.isRouteSearchBackAvailable()) {
        return false;
      }
      if (this.hasTagSearchReturnDetail()) {
        this.goBackToTagSearchReturnDetail();
        return true;
      }
      this.closeSearchResultsPage();
      return true;
    }
    if (this.isMySubPage()) {
      if (this.isRouterBackAvailable()) {
        return false;
      }
      this.returnToMyMainPage();
      return true;
    }
    return false;
  }

  private hasInitialRouteParams(): boolean {
    return this.routeNativeSummary !== undefined ||
      this.routeSearchUrl.length > 0 ||
      this.fullScreenWebUrl.length > 0 ||
      this.myPage !== MY_PAGE_MAIN ||
      this.activeSection !== NAV_HOME;
  }

  private primeInitialRouteDisplay(): void {
    if (this.routeNativeSummary) {
      if (!this.restoreNativeRouteSnapshot(this.routeNativeSummary, true)) {
        this.showNativeDetailPreview(this.routeNativeSummary, true);
      }
    }
  }

  private async loadState(): Promise<void> {
    const hasPrimedRoute = this.hasInitialRouteParams();
    const primedRouteSiteMode = this.siteMode;
    const primedRouteNativeQuery = this.nativeQuery;
    await this.ensureStore();
    await this.ensureLocalDatabase();
    await this.configureTagTranslationCache();
    this.siteMode = hasPrimedRoute ? primedRouteSiteMode : this.readString('site_mode', GallerySite.E);
    this.warningAcknowledged = this.readBoolean('warning_acknowledged', false);
    this.privateBrowsing = this.readBoolean('private_browsing', false);
    this.appLockEnabled = this.readBoolean(APP_LOCK_ENABLED_KEY, false);
    this.backgroundPreviewProtectionEnabled = this.readBoolean(BACKGROUND_PREVIEW_PROTECTION_KEY, true);
    this.cookieDraft = this.readString('cookie_draft', '');
    this.restoreCookieDraftToWeb();
    this.excludedLanguageTags = parseExcludedLanguageTags(this.readString(EXCLUDED_LANGUAGE_KEY, '[]'));
    this.defaultFavoriteSlot = this.normalizeFavoriteSlot(
      this.readNumber(FAVORITE_DEFAULT_SLOT_KEY, FAVORITE_INVALID_DEFAULT_SLOT),
      true
    );
    this.favoriteCategoryNames = parseFavoriteCategoryNames(this.readString(FAVORITE_CATEGORY_NAMES_KEY, '[]'));
    this.favoriteCategoryCounts = parseFavoriteCategoryCounts(this.readString(FAVORITE_CATEGORY_COUNTS_KEY, '[]'));
    this.favoriteListFilter = FAVORITE_FILTER_ALL;
    await this.migratePreferencesToLocalDatabase();
    await this.loadLocalSideData();
    await this.loadLocalFilterData();
    this.downloadDirectoryPath = this.readString('download_directory_path', '');
    this.downloadConcurrency = clampNumber(
      this.readNumber('download_concurrency', DOWNLOAD_DEFAULT_CONCURRENCY),
      1,
      DOWNLOAD_MAX_CONCURRENCY
    );
    this.downloadUseOriginImage = this.readBoolean('download_origin_image', false);
    await this.loadDownloadState();
    this.nativeQuery = hasPrimedRoute ? primedRouteNativeQuery : this.readString('native_query', '');
    this.loadReaderSettings();
    this.loadReaderProgressSettings();
    this.loadCachePolicySettings();
    this.updateDownloadStatePolling();
    const lastUrl = this.readString('last_url', EhUrl.home(this.siteMode));
    if (!hasPrimedRoute) {
      this.syncSiteModeFromUrl(lastUrl);
    }
    this.webSrc = lastUrl;
    this.addressInput = lastUrl;
    this.applyRouteParams(!this.isReady);
    if (!this.isReady) {
      this.primeInitialRouteDisplay();
    }
    this.refreshSiteCookieState();
    if (this.shouldShowLoginGateOnLaunch(hasPrimedRoute)) {
      this.loginGateVisible = true;
      this.markLoginGateSeen();
    }
    this.refreshTagTranslationState();
    this.isReady = true;
    this.applyPendingDownloadRouteEvent();
    if (this.appLockEnabled && !hasPrimedRoute) {
      this.setAppLockForegroundRequired(true);
    }
    void this.requireAppUnlockIfNeeded();
    void this.updateTagTranslations(false);
    this.scheduleCacheMaintenance();
    if (this.routeNativeSummary) {
      void this.loadNativeRoute(this.routeNativeSummary, this.routeNativeMode, this.routeReaderPageUrl);
      return;
    }
    if (this.routeSearchUrl.length > 0) {
      void this.loadSearchGalleryList(this.routeSearchUrl);
      return;
    }
    if (this.activeSection === NAV_HOME) {
      this.ensureCurrentHomePageLoaded();
    } else if (this.activeSection === NAV_LIBRARY && this.myPage !== MY_PAGE_MAIN) {
      this.ensureCurrentLibraryPageLoaded();
    } else if (this.activeSection === NAV_SETTINGS) {
      this.ensureMySubPageLoaded();
    }
  }

  private refreshPersistedCookieState(): void {
    if (!this.isReady) {
      return;
    }
    this.cookieDraft = this.readString('cookie_draft', '');
    this.restoreCookieDraftToWeb();
    this.refreshSiteCookieState();
  }

  private applyRouteSearchParams(params: Record<string, Object>): void {
    if (readRouteString(params, 'searchRoute') !== ROUTE_SEARCH_ACTIVE) {
      return;
    }
    const routeSite = readRouteString(params, 'siteMode');
    if (routeSite === GallerySite.E || routeSite === GallerySite.EX) {
      this.siteMode = routeSite;
      this.writeValue('site_mode', routeSite);
    }
    this.activeSection = NAV_SEARCH;
    this.myPage = MY_PAGE_MAIN;
    this.myPageTitle = '';
    this.clearMyNavigationPath();
    this.nativeViewMode = 'list';
    this.searchResultsActive = true;
    this.searchFiltersExpanded = false;
    this.searchFilterSheetVisible = false;
    this.hideSearchSuggestionOverlay();
    this.searchMode = this.normalizeSearchMode(readRouteString(params, 'searchMode'));
    this.setNativeQuery(readRouteString(params, 'searchQuery'));
    const categoryMask = Number(readRouteString(params, 'searchCategoryMask'));
    if (Number.isFinite(categoryMask)) {
      this.searchCategoryMask = this.normalizeCategoryMask(categoryMask);
    }
    const advancedFlags = Number(readRouteString(params, 'searchAdvancedFlags'));
    if (Number.isFinite(advancedFlags)) {
      this.applySearchAdvancedFlags(advancedFlags);
    }
    const advancedEnabled = readRouteString(params, 'searchAdvancedEnabled');
    if (advancedEnabled.length > 0) {
      this.searchAdvancedEnabled = advancedEnabled === '1';
    }
    this.searchMinRating = readRouteString(params, 'searchMinRating');
    this.searchPageFrom = readRouteString(params, 'searchPageFrom');
    this.searchPageTo = readRouteString(params, 'searchPageTo');
    const routeUrl = readRouteString(params, 'searchUrl');
    this.routeSearchUrl = routeUrl.length > 0 ? routeUrl : this.buildAdvancedSearchUrl();
    this.searchListUrl = this.routeSearchUrl;
    this.tagSearchTransitionQuery = readRouteString(params, 'searchTransitionQuery');
  }

  private applyRouteParams(showRouteLoading: boolean = true): void {
    try {
      const rawParams = this.getUIContext().getRouter().getParams();
      if (!rawParams) {
        return;
      }
      const params = rawParams as Record<string, Object>;
      const activeSection = Number(readRouteString(params, 'activeSection'));
      if (activeSection === NAV_HOME || activeSection === NAV_SEARCH ||
        activeSection === NAV_LIBRARY || activeSection === NAV_SETTINGS || activeSection === NAV_MY) {
        this.activeSection = activeSection;
      }
      const myPage = readRouteString(params, 'myPage');
      if (myPage === MY_PAGE_MAIN) {
        this.myPage = MY_PAGE_MAIN;
        this.myPageTitle = '';
        this.clearMyNavigationPath();
      } else if (myPage.length > 0) {
        this.myPage = myPage;
        this.mySubPage = myPage;
        this.activeSection = this.sectionForSubPage(myPage);
        if (this.sectionForSubPage(myPage) === NAV_LIBRARY) {
          this.libraryPanel = this.libraryPanelForPage(myPage);
        }
      }
      const myPageTitle = readRouteString(params, 'myPageTitle');
      if (myPageTitle.length > 0) {
        this.myPageTitle = myPageTitle;
        this.mySubPageTitle = myPageTitle;
      }
      const routeSite = readRouteString(params, 'siteMode');
      if (routeSite === GallerySite.E || routeSite === GallerySite.EX) {
        this.siteMode = routeSite;
        this.writeValue('site_mode', routeSite);
      }
      const webUrl = readRouteString(params, 'webUrl');
      if (webUrl.length > 0) {
        this.fullScreenWebUrl = webUrl;
        this.fullScreenWebTitle = readRouteString(params, 'webTitle');
        this.fullScreenWebMode = readRouteString(params, 'webMode');
        this.addressInput = webUrl;
      }
      this.applyRouteSearchParams(params);
      const nativeRoute = readRouteString(params, 'nativeRoute');
      if (nativeRoute.length > 0) {
        const gid = Number(readRouteString(params, 'gid'));
        const token = readRouteString(params, 'token');
        const detailUrl = readRouteString(params, 'detailUrl');
        if (Number.isFinite(gid) && gid > 0 && token.length > 0 && detailUrl.length > 0) {
          this.routeNativeSummary = {
            gid,
            token,
            title: readRouteString(params, 'title'),
            titleJpn: readRouteString(params, 'titleJpn'),
            thumb: readRouteString(params, 'thumb'),
            categoryLabel: readRouteString(params, 'categoryLabel'),
            posted: readRouteString(params, 'posted'),
            uploader: readRouteString(params, 'uploader'),
            rating: Number(readRouteString(params, 'rating')),
            pages: Number(readRouteString(params, 'pages')),
            simpleTags: [],
            simpleLanguage: readRouteString(params, 'simpleLanguage'),
            detailUrl
          };
          this.routeNativeMode = nativeRoute;
          this.routeReaderPageUrl = readRouteString(params, 'readerPageUrl');
          this.nativeError = '';
          this.nativeLoading = showRouteLoading;
          if (nativeRoute === ROUTE_NATIVE_READER) {
            this.nativeLoadingMessage = '正在加载阅读页...';
          } else if (nativeRoute === ROUTE_NATIVE_PREVIEWS) {
            this.nativeLoadingMessage = '正在加载预览...';
          } else if (nativeRoute === ROUTE_NATIVE_COMMENTS) {
            this.nativeLoadingMessage = '正在加载评论...';
          } else {
            this.nativeLoadingMessage = '正在加载详情...';
          }
        }
      }
    } catch (error) {
    }
  }

  private async ensureStore(): Promise<void> {
    if (this.settingsStore) {
      return;
    }
    const hostContext = this.getUIContext().getHostContext();
    if (!hostContext) {
      return;
    }
    try {
      this.settingsStore = await preferences.getPreferences(hostContext as common.UIAbilityContext, 'ehviewer_harmony');
      this.refreshPrivacySettingsFromStore();
    } catch (error) {
      this.toast('本地设置打开失败');
    }
  }

  private async ensureLocalDatabase(): Promise<void> {
    if (this.localDao) {
      return;
    }
    const hostContext = this.getUIContext().getHostContext();
    if (!hostContext) {
      return;
    }
    try {
      this.localDao = await EhLocalDataDao.open(hostContext as common.UIAbilityContext);
    } catch (error) {
      this.localDao = undefined;
      this.downloadManagerStatus = '本地数据库不可用，已使用 JSON 备份';
    }
  }

  private async migratePreferencesToLocalDatabase(): Promise<void> {
    if (!this.localDao || this.readBoolean(LOCAL_DATA_MIGRATION_KEY, false)) {
      return;
    }
    const backupBookmarks = parseBookmarks(this.readString('bookmarks', '[]'));
    const backupQuickSearches = parseQuickSearches(
      this.readString('quick_searches', '[]'),
      this.currentSearchAdvancedFlagsDefault()
    );
    const backupSearchHistory = parseSearchHistoryQueries(this.readString('search_history_queries', '[]'));
    const backupHistory = this.parseHistoryItems(this.readString('history_items', '[]'));
    const backupDownloads = this.parseDownloadItems(this.readString('download_items', '[]'));
    const backupLabels = ensureDownloadDefaultLabel(
      parseDownloadLabels(this.readString('download_labels', '[]'), this.nowLabel()),
      this.nowLabel()
    );
    try {
      await this.localDao.migrateFromPreferences(
        backupBookmarks,
        backupQuickSearches,
        backupSearchHistory,
        backupHistory,
        backupDownloads,
        backupLabels
      );
      this.writeValue(LOCAL_DATA_MIGRATION_KEY, true);
      this.writeValue(LOCAL_DATA_MIGRATION_TIME_KEY, this.nowLabel());
      this.writeValue('download_items_migrated_to_rdb', true);
    } catch (error) {
      this.downloadManagerStatus = '本地数据库迁移失败，已使用 JSON 备份';
    }
  }

  private async loadLocalSideData(): Promise<void> {
    const backupBookmarks = parseBookmarks(this.readString('bookmarks', '[]'));
    const backupQuickSearches = parseQuickSearches(
      this.readString('quick_searches', '[]'),
      this.currentSearchAdvancedFlagsDefault()
    );
    const backupSearchHistory = parseSearchHistoryQueries(this.readString('search_history_queries', '[]'));
    const backupHistory = this.parseHistoryItems(this.readString('history_items', '[]'));

    if (!this.localDao) {
      this.bookmarks = backupBookmarks;
      this.quickSearches = backupQuickSearches;
      this.searchHistoryQueries = backupSearchHistory;
      this.historyItems = backupHistory;
      this.localFavorites = [];
      this.refreshLocalFavoriteGalleryListIfNeeded();
      return;
    }
    try {
      const dbBookmarks = await this.localDao.loadBookmarks();
      const dbQuickSearches = await this.localDao.loadQuickSearches();
      const dbSearchHistory = await this.localDao.loadSearchHistoryQueries();
      const dbHistory = await this.localDao.loadHistoryItems();
      const dbLocalFavorites = await this.localDao.loadLocalFavorites();
      this.bookmarks = dbBookmarks.length > 0 ? dbBookmarks : backupBookmarks;
      this.quickSearches = dbQuickSearches.length > 0 ? dbQuickSearches : backupQuickSearches;
      this.searchHistoryQueries = dbSearchHistory.length > 0 ? dbSearchHistory : backupSearchHistory;
      this.historyItems = dbHistory.length > 0 ? dbHistory : backupHistory;
      this.localFavorites = dbLocalFavorites;
      this.refreshLocalFavoriteGalleryListIfNeeded();
    } catch (error) {
      this.bookmarks = backupBookmarks;
      this.quickSearches = backupQuickSearches;
      this.searchHistoryQueries = backupSearchHistory;
      this.historyItems = backupHistory;
      this.localFavorites = [];
      this.refreshLocalFavoriteGalleryListIfNeeded();
    }
  }

  private async loadLocalFilterData(): Promise<void> {
    if (!this.localDao) {
      this.filterRules = [];
      this.blacklistItems = [];
      return;
    }
    try {
      this.filterRules = await this.localDao.loadFilters();
      this.blacklistItems = await this.localDao.loadBlacklist();
    } catch (error) {
      this.filterRules = [];
      this.blacklistItems = [];
    }
  }

  private filterRuleExists(mode: number, text: string): boolean {
    const normalizedMode = this.normalizeFilterMode(mode);
    const normalizedText = text.trim();
    for (const rule of this.filterRules) {
      if (this.normalizeFilterMode(rule.mode) === normalizedMode && rule.text.trim() === normalizedText) {
        return true;
      }
    }
    return false;
  }

  private async addFilterRuleFromDraft(): Promise<void> {
    const text = this.filterTextDraft.trim();
    if (text.length === 0) {
      this.toast('过滤文本不能为空');
      return;
    }
    if (!this.localDao) {
      this.toast('本地数据库不可用');
      return;
    }
    const mode = this.normalizeFilterMode(this.filterModeDraft);
    if (this.filterRuleExists(mode, text)) {
      this.toast('过滤规则已存在');
      return;
    }
    try {
      await this.localDao.insertFilter({
        id: 0,
        mode,
        text,
        enabled: true
      });
      this.setFilterTextDraft('');
      await this.loadLocalFilterData();
      this.refreshVisibleGalleryListsFromRaw();
      this.toast('过滤规则已添加');
    } catch (error) {
      this.toast('过滤规则保存失败');
    }
  }

  private async toggleFilterRule(rule: FilterRule): Promise<void> {
    if (!this.localDao || rule.id <= 0) {
      return;
    }
    const targetEnabled = !rule.enabled;
    this.updateFilterRuleEnabledInState(rule.id, targetEnabled);
    this.refreshVisibleGalleryListsFromRaw();
    try {
      await this.localDao.updateFilterEnabled(rule.id, targetEnabled);
      await this.loadLocalFilterData();
      this.refreshVisibleGalleryListsFromRaw();
    } catch (error) {
      this.updateFilterRuleEnabledInState(rule.id, rule.enabled);
      this.refreshVisibleGalleryListsFromRaw();
      this.toast('过滤规则更新失败');
    }
  }

  private updateFilterRuleEnabledInState(id: number, enabled: boolean): void {
    this.filterRules = this.filterRules.map((item: FilterRule): FilterRule => {
      if (item.id !== id) {
        return item;
      }
      return {
        id: item.id,
        mode: item.mode,
        text: item.text,
        enabled
      };
    });
  }

  private async deleteFilterRule(rule: FilterRule): Promise<void> {
    if (!this.localDao || rule.id <= 0) {
      return;
    }
    try {
      await this.localDao.deleteFilter(rule.id);
      await this.loadLocalFilterData();
      this.refreshVisibleGalleryListsFromRaw();
      this.toast('过滤规则已删除');
    } catch (error) {
      this.toast('过滤规则删除失败');
    }
  }

  private blacklistItemExists(name: string): boolean {
    const normalizedName = name.trim();
    for (const item of this.blacklistItems) {
      if (item.name.trim() === normalizedName) {
        return true;
      }
    }
    return false;
  }

  private async addBlacklistFromDraft(): Promise<void> {
    await this.addBlacklistUser(this.blacklistNameDraft, this.blacklistReasonDraft, true);
  }

  private async addBlacklistUser(nameValue: string, reasonValue: string = '', clearDraft: boolean = false): Promise<void> {
    const name = nameValue.trim();
    if (name.length === 0) {
      this.toast('黑名单用户名不能为空');
      return;
    }
    if (!this.localDao) {
      this.toast('本地数据库不可用');
      return;
    }
    if (this.blacklistItemExists(name)) {
      this.toast('用户已在黑名单');
      return;
    }
    try {
      await this.localDao.insertBlacklist({
        id: 0,
        name,
        reason: reasonValue.trim(),
        angryWith: '/手动添加/',
        addTime: this.nowLabel(),
        mode: 1
      });
      if (clearDraft) {
        this.blacklistNameDraft = '';
        this.blacklistReasonDraft = '';
      }
      await this.loadLocalFilterData();
      this.toast('黑名单已添加');
    } catch (error) {
      this.toast('黑名单保存失败');
    }
  }

  private async deleteBlacklistItem(item: BlacklistItem): Promise<void> {
    if (!this.localDao || item.id <= 0) {
      return;
    }
    try {
      await this.localDao.deleteBlacklist(item.id);
      await this.loadLocalFilterData();
      this.toast('黑名单已删除');
    } catch (error) {
      this.toast('黑名单删除失败');
    }
  }

  private async loadDownloadState(): Promise<void> {
    const backupItems = this.parseDownloadItems(this.readString('download_items', '[]'));
    const backupLabels = parseDownloadLabels(this.readString('download_labels', '[]'), this.nowLabel());
    const dbItems = await this.loadDownloadItemsFromDatabase();
    const dbLabels = await this.loadDownloadLabelsFromDatabase();

    if (sharedDownloadItemsSnapshot.length > 0) {
      this.downloadItems = this.downloadItemsSource();
      this.downloadItems = this.reconcileDownloadItemsWithLocalFiles(this.downloadItems);
      this.publishSharedDownloadItems();
      this.downloadLabels = ensureDownloadDefaultLabel(dbLabels.length > 0 ? dbLabels : backupLabels, this.nowLabel());
      this.saveDownloadLabels();
      this.refreshDownloadManagerStatusFromState();
      return;
    }

    if (dbItems.length > 0) {
      this.downloadItems = this.recoverInterruptedDownloads(this.filterRemovedDownloadItems(dbItems));
      this.downloadItems = this.reconcileDownloadItemsWithLocalFiles(this.downloadItems);
      this.downloadLabels = ensureDownloadDefaultLabel(dbLabels, this.nowLabel());
      this.saveDownloadItems();
      this.saveDownloadLabels();
      return;
    }

    this.downloadItems = this.recoverInterruptedDownloads(this.filterRemovedDownloadItems(backupItems));
    this.downloadItems = this.reconcileDownloadItemsWithLocalFiles(this.downloadItems);
    this.downloadLabels = ensureDownloadDefaultLabel(backupLabels, this.nowLabel());
    this.saveDownloadLabels();
    if (backupItems.length > 0) {
      this.saveDownloadItems();
      this.writeValue('download_items_migrated_to_rdb', true);
    } else {
      this.publishSharedDownloadItems();
    }
  }

  private async loadDownloadLabelsFromDatabase(): Promise<DownloadLabelItem[]> {
    if (!this.localDao) {
      return [];
    }
    try {
      return await this.localDao.loadDownloadLabels();
    } catch (error) {
      return [];
    }
  }

  private async loadDownloadItemsFromDatabase(): Promise<DownloadQueueItem[]> {
    if (!this.localDao) {
      return [];
    }
    try {
      return await this.localDao.loadDownloadItems();
    } catch (error) {
      return [];
    }
  }

  private async upsertDownloadItemToDatabase(item: DownloadQueueItem): Promise<void> {
    if (!this.localDao) {
      return;
    }
    try {
      await this.localDao.upsertDownloadItem(item);
    } catch (error) {
    }
  }

  private async deleteDownloadItemFromDatabase(item: DownloadQueueItem): Promise<void> {
    if (!this.localDao) {
      return;
    }
    try {
      await this.localDao.deleteDownloadItem(item);
    } catch (error) {
    }
  }

  private async upsertDownloadLabelToDatabase(label: DownloadLabelItem): Promise<void> {
    if (!this.localDao) {
      return;
    }
    try {
      await this.localDao.upsertDownloadLabel(label);
    } catch (error) {
    }
  }

  private async configureTagTranslationCache(): Promise<void> {
    const hostContext = this.getUIContext().getHostContext();
    if (!hostContext) {
      return;
    }
    try {
      const abilityContext = hostContext as common.UIAbilityContext;
      EhTagTranslator.configureCacheDir(abilityContext.filesDir);
      const bundledRaw = await abilityContext.resourceManager.getRawFileContent('tag-translations-zh-rCN');
      EhTagTranslator.configureBundledRaw(rawBytesToString(bundledRaw));
    } catch (error) {
    }
  }

  private readString(key: string, fallback: string): string {
    if (!this.settingsStore) {
      return fallback;
    }
    try {
      return this.settingsStore.getSync(key, fallback) as string;
    } catch (error) {
      return fallback;
    }
  }

  private readBoolean(key: string, fallback: boolean): boolean {
    if (!this.settingsStore) {
      return fallback;
    }
    try {
      return this.settingsStore.getSync(key, fallback) as boolean;
    } catch (error) {
      return fallback;
    }
  }

  private readNumber(key: string, fallback: number): number {
    if (!this.settingsStore) {
      return fallback;
    }
    try {
      const value = this.settingsStore.getSync(key, fallback) as preferences.ValueType;
      if (typeof value === 'number') {
        return Number.isFinite(value) ? value : fallback;
      }
      if (typeof value === 'string') {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : fallback;
      }
      return fallback;
    } catch (error) {
      return fallback;
    }
  }

  private writeValue(key: string, value: preferences.ValueType): boolean {
    if (!this.settingsStore) {
      return false;
    }
    try {
      this.settingsStore.putSync(key, value);
      this.settingsStore.flushSync();
      return true;
    } catch (error) {
      this.toast('本地设置保存失败');
      return false;
    }
  }

  private setAppLockForegroundRequired(required: boolean): void {
    this.appLockForegroundRequired = required;
    setAppLockForegroundRequiredStorage(required);
  }

  private setAppLockAuthActive(active: boolean): void {
    setAppLockAuthActiveStorage(active);
  }

  private runInUiScope(action: () => void): void {
    try {
      this.getUIContext().runScopedTask(action);
    } catch (error) {
      action();
    }
  }

  private refreshPrivacySettingsFromStore(): void {
    if (!this.settingsStore) {
      return;
    }
    this.applyPrivacySettingsFromStore(this.settingsStore);
  }

  private applyPrivacySettingsFromStore(store: preferences.Preferences): void {
    const snapshot = readPrivacySettings(
      store,
      this.appLockEnabled,
      this.backgroundPreviewProtectionEnabled
    );
    if (
      snapshot.appLockEnabled === this.appLockEnabled &&
      snapshot.backgroundPreviewProtectionEnabled === this.backgroundPreviewProtectionEnabled
    ) {
      return;
    }
    this.appLockEnabled = snapshot.appLockEnabled;
    this.backgroundPreviewProtectionEnabled = snapshot.backgroundPreviewProtectionEnabled;
    try {
      AppStorage.setOrCreate<boolean>(APP_LOCK_ENABLED_KEY, this.appLockEnabled);
      AppStorage.setOrCreate<boolean>(BACKGROUND_PREVIEW_PROTECTION_KEY, this.backgroundPreviewProtectionEnabled);
    } catch (error) {
    }
    this.privacySettingsRevision++;
  }

  private currentAppLockEnabled(): boolean {
    this.privacySettingsRevision;
    return this.appLockEnabled;
  }

  private currentBackgroundPreviewProtectionEnabled(): boolean {
    this.privacySettingsRevision;
    return this.backgroundPreviewProtectionEnabled;
  }

  private async runAppLockAuthentication(title: string): Promise<boolean> {
    const result: AppLockAuthenticationResult = await authenticateAppLock(
      title,
      (active: boolean): void => {
        this.setAppLockAuthActive(active);
      }
    );
    if (result.unavailableMessage.length > 0) {
      this.appLockStatus = result.unavailableMessage;
    }
    return result.authenticated;
  }

  private async requireAppUnlockIfNeeded(): Promise<void> {
    if (!this.isReady || !this.appLockEnabled || !this.appLockForegroundRequired || this.appLockAuthInProgress) {
      return;
    }
    this.appLockStatus = '验证身份后进入应用';
    this.appLockAuthInProgress = true;
    const unlocked = await this.runAppLockAuthentication('解锁 E-Harmony');
    this.runInUiScope(() => {
      this.appLockAuthInProgress = false;
      if (unlocked) {
        this.appLockVerified = true;
        this.setAppLockForegroundRequired(false);
        this.appLockStatus = '已解锁';
        return;
      }
      this.appLockVerified = false;
      this.setAppLockForegroundRequired(true);
      this.appLockStatus = '未解锁，可重试面容、指纹或锁屏密码。';
    });
  }

  private async setAppLockEnabled(isOn: boolean): Promise<void> {
    if (this.appLockAuthInProgress) {
      return;
    }
    const currentEnabled = this.appLockEnabled;
    if (isOn === currentEnabled) {
      return;
    }
    this.appLockStatus = isOn ? '验证一次身份以开启锁定' : '验证身份以关闭锁定';
    this.appLockAuthInProgress = true;
    const unlocked = await this.runAppLockAuthentication(isOn ? '开启锁定 App' : '关闭锁定 App');
    this.runInUiScope(() => {
      this.appLockAuthInProgress = false;
      this.setAppLockForegroundRequired(false);
      if (!unlocked) {
        this.appLockEnabled = currentEnabled;
        this.appLockVerified = currentEnabled;
        this.appLockStatus = isOn ? '验证失败，未开启锁定 App。' : '验证失败，锁定 App 仍保持开启。';
        this.privacySettingsRevision++;
        this.toast(isOn ? '验证失败，未开启锁定 App' : '验证失败，锁定 App 未关闭');
        return;
      }
      if (!this.writeValue(APP_LOCK_ENABLED_KEY, isOn)) {
        this.appLockEnabled = currentEnabled;
        this.appLockVerified = currentEnabled;
        this.appLockStatus = currentEnabled ? '锁定 App 仍保持开启。' : '锁定 App 仍保持关闭。';
        this.privacySettingsRevision++;
        return;
      }
      this.appLockEnabled = isOn;
      this.appLockVerified = isOn;
      this.appLockStatus = isOn ? '已开启锁定 App' : '已关闭锁定 App';
      this.privacySettingsRevision++;
      this.toast(isOn ? '已开启锁定 App' : '已关闭锁定 App');
    });
  }

  private async toggleAppLockEnabledFromStore(): Promise<void> {
    await this.setAppLockEnabled(!this.appLockEnabled);
  }

  private setBackgroundPreviewProtectionEnabled(isOn: boolean): void {
    const currentEnabled = this.backgroundPreviewProtectionEnabled;
    if (isOn === currentEnabled) {
      return;
    }
    if (!this.writeValue(BACKGROUND_PREVIEW_PROTECTION_KEY, isOn)) {
      this.backgroundPreviewProtectionEnabled = currentEnabled;
      this.privacySettingsRevision++;
      return;
    }
    this.backgroundPreviewProtectionEnabled = isOn;
    this.privacySettingsRevision++;
  }

  private parseHistoryItems(raw: string): HistoryItem[] {
    try {
      const parsed = JSON.parse(raw) as Array<Record<string, Object>>;
      if (!Array.isArray(parsed)) {
        return [];
      }
      const items: HistoryItem[] = [];
      for (const item of parsed) {
        const record = parseLocalGalleryRecord(item);
        if (!record) {
          continue;
        }
        items.push(this.toHistoryItem(record, readObjectString(item, 'visitedAt', '')));
      }
      return items.slice(0, LOCAL_LIST_LOAD_LIMIT);
    } catch (error) {
      return [];
    }
  }

  private loadReaderProgressSettings(): void {
    this.readerProgressByGallery.clear();
    const progressByGallery = parseReaderProgress(this.readString(READER_PROGRESS_KEY, '{}'));
    for (const key of progressByGallery.keys()) {
      const page = progressByGallery.get(key);
      if (page !== undefined) {
        this.readerProgressByGallery.set(key, page);
      }
    }
    this.readerProgressRevision++;
  }

  private parseDownloadItems(raw: string): DownloadQueueItem[] {
    try {
      const parsed = JSON.parse(raw) as Array<Record<string, Object>>;
      if (!Array.isArray(parsed)) {
        return [];
      }
      const items: DownloadQueueItem[] = [];
      for (const item of parsed) {
        const record = parseLocalGalleryRecord(item);
        if (!record) {
          continue;
        }
        items.push(this.toDownloadItem(
          record,
          readObjectString(item, 'status', DOWNLOAD_STATUS_QUEUED),
          readObjectString(item, 'queuedAt', ''),
          readObjectString(item, 'lastAction', ''),
          readObjectString(item, 'label', DOWNLOAD_DEFAULT_LABEL),
          readObjectNumber(item, 'downloaded', 0),
          readObjectNumber(item, 'total', record.pages),
          readObjectNumber(item, 'failedCount', 0),
          readObjectString(item, 'archiveUri', ''),
          readObjectString(item, 'createdAt', ''),
          readObjectString(item, 'updatedAt', ''),
          readObjectNumber(item, 'currentPage', 0),
          readObjectString(item, 'currentPageLabel', ''),
          readObjectNumber(item, 'speedBytesPerSecond', 0),
          readObjectNumber(item, 'remainingSeconds', -1),
          readObjectString(item, 'downloadDir', ''),
          readObjectString(item, 'error', ''),
          parseDownloadPageErrorsFromObject(item)
        ));
      }
      return items.slice(0, 80);
    } catch (error) {
      return [];
    }
  }

  private downloadedFileCountForItem(item: DownloadQueueItem): number {
    const dirs: string[] = [];
    const storedDir = item.downloadDir.trim();
    if (storedDir.length > 0) {
      dirs.push(storedDir);
    }
    const defaultDir = this.galleryDownloadDir(item);
    if (defaultDir.length > 0 && dirs.indexOf(defaultDir) < 0) {
      dirs.push(defaultDir);
    }
    let count = 0;
    for (const dir of dirs) {
      try {
        if (!fileIo.accessSync(dir)) {
          continue;
        }
        const names = fileIo.listFileSync(dir);
        let dirCount = 0;
        for (const name of names) {
          const lower = name.toLowerCase();
          if (lower.endsWith('.tmp') || lower === DOWNLOAD_INFO_FILENAME) {
            continue;
          }
          if (READER_IMAGE_EXTENSIONS.some((extension: string) => lower.endsWith(extension))) {
            dirCount++;
          }
        }
        count = Math.max(count, dirCount);
      } catch (error) {
      }
    }
    return count;
  }

  private reconcileDownloadItemsWithLocalFiles(items: DownloadQueueItem[]): DownloadQueueItem[] {
    const reconciled: DownloadQueueItem[] = [];
    for (const item of items) {
      if (item.status === DOWNLOAD_STATUS_DONE || item.status === DOWNLOAD_STATUS_DELETED) {
        reconciled.push(item);
        continue;
      }
      const localCount = this.downloadedFileCountForItem(item);
      if (item.status === DOWNLOAD_STATUS_DOWNLOADING && localCount > item.downloaded) {
        const total = Math.max(item.total, item.pages, localCount);
        const key = this.downloadKey(item.gid, item.site);
        this.writeDownloadRuntimeHeartbeat(key, true, true);
        reconciled.push(this.toDownloadItem(
          item,
          DOWNLOAD_STATUS_DOWNLOADING,
          item.queuedAt,
          `正在同步本地下载进度`,
          item.label,
          localCount,
          total,
          item.failedCount,
          item.archiveUri,
          item.createdAt,
          this.nowLabel(),
          localCount,
          `${localCount}/${total}`,
          item.speedBytesPerSecond,
          item.remainingSeconds,
          item.downloadDir,
          item.error,
          item.pageErrors
        ));
        continue;
      }
      reconciled.push(item);
    }
    return reconciled;
  }

  private recoverInterruptedDownloads(items: DownloadQueueItem[]): DownloadQueueItem[] {
    const recovered: DownloadQueueItem[] = [];
    for (const item of items) {
      if (item.status === DOWNLOAD_STATUS_DOWNLOADING) {
        const key = this.downloadKey(item.gid, item.site);
        const sharedItem = this.sharedDownloadItemByKey(key);
        const runningInCurrentProcess = this.isDownloadKeyRunningInCurrentProcess(key);
        if (sharedItem && runningInCurrentProcess) {
          recovered.push(this.cloneDownloadItem(sharedItem));
          continue;
        }
        const lastAction = runningInCurrentProcess && !item.lastAction.startsWith('下载中断') ?
          item.lastAction :
          (runningInCurrentProcess ? '正在下载' : '下载中断，点开始继续');
        recovered.push(this.toDownloadItem(
          item,
          DOWNLOAD_STATUS_DOWNLOADING,
          item.queuedAt,
          lastAction,
          item.label,
          item.downloaded,
          item.total,
          item.failedCount,
          item.archiveUri,
          item.createdAt,
          this.nowLabel(),
          item.currentPage,
          item.currentPageLabel,
          runningInCurrentProcess ? item.speedBytesPerSecond : 0,
          runningInCurrentProcess ? item.remainingSeconds : -1,
          item.downloadDir,
          item.error,
          item.pageErrors
        ));
      } else {
        recovered.push(item);
      }
    }
    return recovered;
  }

  private async syncDownloadStateFromDatabase(recoverRunning: boolean, selectPreferredView: boolean = false): Promise<void> {
    if (this.downloadWorkerRunning) {
      return;
    }
    if (sharedDownloadItemsSnapshot.length > 0) {
      this.downloadItems = this.downloadItemsSource();
    } else {
      const dbItems = await this.loadDownloadItemsFromDatabase();
      if (dbItems.length > 0) {
        const filteredDbItems = this.filterRemovedDownloadItems(dbItems);
        this.downloadItems = recoverRunning ? this.recoverInterruptedDownloads(filteredDbItems) : filteredDbItems;
      } else {
        const backupItems = this.filterRemovedDownloadItems(this.parseDownloadItems(this.readString('download_items', '[]')));
        this.downloadItems = recoverRunning ?
          this.recoverInterruptedDownloads(backupItems) :
          backupItems;
      }
    }
    this.downloadItems = this.reconcileDownloadItemsWithLocalFiles(this.downloadItems);
    const dbLabels = await this.loadDownloadLabelsFromDatabase();
    if (dbLabels.length > 0) {
      this.downloadLabels = ensureDownloadDefaultLabel(dbLabels, this.nowLabel());
    }
    this.publishSharedDownloadItems();
    this.refreshDownloadManagerStatusFromState();
    this.reconcileDownloadViewMode(selectPreferredView);
    this.refreshDownloadRuntimeState(true);
  }

  private refreshDownloadManagerStatusFromState(): void {
    const activeKey = this.activeDownloadRuntimeKey();
    if (activeKey.length > 0) {
      const active = this.findDownloadItemByKey(activeKey);
      if (active) {
        this.downloadManagerStatus = active.lastAction.length > 0 ?
          active.lastAction :
          `正在下载 ${active.title.length > 0 ? active.title : active.gid}`;
        return;
      }
      this.downloadManagerStatus = '下载队列运行中';
      return;
    }
    if (this.downloadItemsSource().some((item: DownloadQueueItem) =>
      item.status === DOWNLOAD_STATUS_QUEUED || item.status === DOWNLOAD_STATUS_DOWNLOADING)) {
      this.downloadManagerStatus = '下载等待中';
      return;
    }
    this.downloadManagerStatus = '下载器空闲';
  }

  private effectiveDownloadManagerStatus(): string {
    const active = this.activeDownloadItem();
    if (active && this.isDownloadItemRunning(active)) {
      return active.lastAction.length > 0 ?
        active.lastAction :
        `正在下载 ${active.title.length > 0 ? active.title : active.gid}`;
    }
    if (this.downloadRuntimeWorkerRunning || this.downloadWorkerRunning || sharedDownloadWorkerRunning) {
      return this.downloadManagerStatus === '下载器空闲' ? '下载队列运行中' : this.downloadManagerStatus;
    }
    return this.downloadManagerStatus;
  }

  private saveBookmarks(): void {
    this.writeValue('bookmarks', JSON.stringify(this.bookmarks));
    if (this.localDao) {
      void this.localDao.replaceBookmarks(this.bookmarks);
    }
  }

  private saveQuickSearches(): void {
    this.writeValue('quick_searches', JSON.stringify(this.quickSearches));
    if (this.localDao) {
      void this.localDao.replaceQuickSearches(this.quickSearches);
    }
  }

  private saveSearchHistoryQueries(): void {
    this.writeValue('search_history_queries', JSON.stringify(this.searchHistoryQueries));
    if (this.localDao) {
      void this.localDao.replaceSearchHistoryQueries(this.searchHistoryQueries);
    }
  }

  private saveHistoryItems(): void {
    this.writeValue('history_items', JSON.stringify(this.historyItems));
    if (this.localDao) {
      void this.localDao.replaceHistoryItems(this.historyItems);
    }
  }

  private saveReaderProgressSettings(): void {
    this.writeValue(READER_PROGRESS_KEY, JSON.stringify(readerProgressSnapshot(this.readerProgressByGallery)));
    this.readerProgressRevision++;
  }

  private bumpDownloadQueueRevision(): void {
    this.downloadQueueRevision = Math.min(2147483647, this.downloadQueueRevision + 1);
  }

  private ensureDownloadRuntimeStorageDefaults(): void {
    AppStorage.setOrCreate<string>(DOWNLOAD_RUNTIME_ITEMS_KEY, '[]');
    AppStorage.setOrCreate<string>(DOWNLOAD_RUNTIME_ACTIVE_KEY, '');
    AppStorage.setOrCreate<boolean>(DOWNLOAD_RUNTIME_WORKER_RUNNING_KEY, false);
    AppStorage.setOrCreate<number>(DOWNLOAD_RUNTIME_REVISION_KEY, 0);
    AppStorage.setOrCreate<string>(DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY, '[]');
    AppStorage.setOrCreate<string>(DOWNLOAD_RUNTIME_REMOVED_KEYS_KEY,
      this.readString(DOWNLOAD_RUNTIME_REMOVED_KEYS_KEY, '[]'));
    AppStorage.setOrCreate<number>(DOWNLOAD_ROUTE_EVENT_STORAGE_KEY, 0);
    AppStorage.setOrCreate<string>(DOWNLOAD_ROUTE_TARGET_STORAGE_KEY, '');
  }

  private runtimeStringArray(key: string): string[] {
    const raw = AppStorage.get<string>(key) || this.readString(key, '[]');
    try {
      const parsed = JSON.parse(raw) as Array<string>;
      if (!Array.isArray(parsed)) {
        return [];
      }
      const values: string[] = [];
      for (const value of parsed) {
        if (typeof value === 'string' && value.length > 0 && values.indexOf(value) < 0) {
          values.push(value);
        }
      }
      return values;
    } catch (error) {
      return [];
    }
  }

  private updateRuntimeStringArray(key: string, value: string, enabled: boolean, persist: boolean = false): void {
    const values = this.runtimeStringArray(key).filter((entry: string) => entry !== value);
    if (enabled && value.length > 0) {
      values.push(value);
    }
    const raw = JSON.stringify(values);
    AppStorage.setOrCreate<string>(key, raw);
    if (persist) {
      this.writeValue(key, raw);
    }
  }

  private isRuntimeStringArrayMarked(key: string, value: string): boolean {
    return value.length > 0 && this.runtimeStringArray(key).indexOf(value) >= 0;
  }

  private publishDownloadRuntimeStorage(snapshot: DownloadQueueItem[] = sharedDownloadItemsSnapshot, force: boolean = false): void {
    const localActiveKey = this.downloadActiveKey.length > 0 ? this.downloadActiveKey : sharedDownloadActiveKey;
    const ownsDownloadRuntime = this.downloadWorkerRunning || sharedDownloadWorkerRunning || localActiveKey.length > 0;
    if (!force && !ownsDownloadRuntime && this.downloadRuntimeWorkerRunning) {
      return;
    }
    const activeKey = ownsDownloadRuntime ? localActiveKey : this.downloadRuntimeActiveKey;
    const workerRunning = ownsDownloadRuntime ?
      (this.downloadWorkerRunning || sharedDownloadWorkerRunning || localActiveKey.length > 0) :
      this.downloadRuntimeWorkerRunning;
    AppStorage.setOrCreate<string>(DOWNLOAD_RUNTIME_ITEMS_KEY, JSON.stringify(snapshot));
    AppStorage.setOrCreate<string>(DOWNLOAD_RUNTIME_ACTIVE_KEY, activeKey);
    AppStorage.setOrCreate<boolean>(DOWNLOAD_RUNTIME_WORKER_RUNNING_KEY, workerRunning);
    const currentRevision = AppStorage.get<number>(DOWNLOAD_RUNTIME_REVISION_KEY) || 0;
    AppStorage.setOrCreate<number>(DOWNLOAD_RUNTIME_REVISION_KEY, Math.min(2147483647, currentRevision + 1));
    this.writeDownloadRuntimeHeartbeat(activeKey, workerRunning, force);
  }

  private writeDownloadRuntimeHeartbeat(activeKey: string, workerRunning: boolean, force: boolean = false): void {
    const now = Date.now();
    if (!force && workerRunning && now - this.downloadRuntimeHeartbeatLastWriteAt < DOWNLOAD_RUNTIME_HEARTBEAT_INTERVAL_MS) {
      return;
    }
    this.downloadRuntimeHeartbeatLastWriteAt = now;
    this.writeValue(DOWNLOAD_RUNTIME_ACTIVE_KEY, activeKey);
    this.writeValue(DOWNLOAD_RUNTIME_WORKER_RUNNING_KEY, workerRunning);
    this.writeValue(DOWNLOAD_RUNTIME_HEARTBEAT_KEY, workerRunning ? now : 0);
  }

  private activeDownloadRuntimeKeyFromPreferences(): string {
    if (!this.readBoolean(DOWNLOAD_RUNTIME_WORKER_RUNNING_KEY, false)) {
      return '';
    }
    const heartbeatAt = this.readNumber(DOWNLOAD_RUNTIME_HEARTBEAT_KEY, 0);
    if (heartbeatAt <= 0 || Date.now() - heartbeatAt > DOWNLOAD_RUNTIME_HEARTBEAT_TTL_MS) {
      return '';
    }
    return this.readString(DOWNLOAD_RUNTIME_ACTIVE_KEY, '');
  }

  private isDownloadRuntimeHeartbeatActiveForKey(key: string): boolean {
    return key.length > 0 && this.activeDownloadRuntimeKeyFromPreferences() === key;
  }

  private saveDownloadItems(): void {
    const snapshot = [...this.downloadItems];
    this.publishSharedDownloadItems();
    this.writeValue('download_items', JSON.stringify(snapshot));
    for (const item of snapshot) {
      this.scheduleDownloadItemPersist(item);
    }
  }

  private scheduleDownloadItemPersist(item: DownloadQueueItem): void {
    if (!this.localDao) {
      return;
    }
    const key = this.downloadKey(item.gid, item.site);
    if (this.isDownloadKeyRemoved(key)) {
      return;
    }
    const nextVersion = (this.downloadPersistVersions.get(key) || 0) + 1;
    this.downloadPersistVersions.set(key, nextVersion);
    const pending = this.downloadPersistQueue.then(async () => {
      if (this.downloadPersistVersions.get(key) !== nextVersion || this.isDownloadKeyRemoved(key)) {
        return;
      }
      await this.upsertDownloadItemToDatabase(item);
    });
    this.downloadPersistQueue = pending.catch(() => {
    });
  }

  private scheduleDownloadItemDelete(item: DownloadQueueItem): void {
    const key = this.downloadKey(item.gid, item.site);
    this.markDownloadKeyRemoved(key);
    this.invalidateDownloadPersistForKey(key);
    if (!this.localDao) {
      return;
    }
    const pending = this.downloadPersistQueue.then(async () => {
      await this.deleteDownloadItemFromDatabase(item);
    });
    this.downloadPersistQueue = pending.catch(() => {
    });
  }

  private saveDownloadLabels(): void {
    this.writeValue('download_labels', JSON.stringify(this.downloadLabels));
    for (const label of this.downloadLabels) {
      void this.upsertDownloadLabelToDatabase(label);
    }
  }

  private normalizeReaderSettingValue(value: string, options: string[], fallback: string): string {
    return options.indexOf(value) >= 0 ? value : fallback;
  }

  private isReaderContainScaling(value: string): boolean {
    return value === '1' || value === '2' || value === '3';
  }

  private loadReaderSettings(): void {
    this.readerScreenRotation = this.normalizeReaderSettingValue(
      this.readString(READER_KEY_SCREEN_ROTATION, '0'),
      READER_ROTATION_VALUES,
      '0'
    );
    this.readerDirection = this.normalizeReaderSettingValue(
      this.readString(READER_KEY_READING_DIRECTION, '1'),
      READER_DIRECTION_VALUES,
      '1'
    );
    this.readerPageScaling = this.normalizeReaderSettingValue(
      this.readString(READER_KEY_PAGE_SCALING, '3'),
      READER_SCALING_VALUES,
      '3'
    );
    this.readerStartPosition = this.normalizeReaderSettingValue(
      this.readString(READER_KEY_START_POSITION, '1'),
      READER_START_POSITION_VALUES,
      '1'
    );
    this.readerAutoTransferSeconds = clampNumber(Math.floor(this.readNumber(READER_KEY_START_TRANSFER_TIME, 2)), 1, 120);
    this.readerKeepScreenOn = this.readBoolean(READER_KEY_KEEP_SCREEN_ON, false);
    this.readerShowClock = this.readBoolean(READER_KEY_SHOW_CLOCK, true);
    this.readerShowProgress = this.readBoolean(READER_KEY_SHOW_PROGRESS, true);
    this.readerShowBattery = this.readBoolean(READER_KEY_SHOW_BATTERY, true);
    this.readerShowPageInterval = this.readBoolean(READER_KEY_SHOW_PAGE_INTERVAL, true);
    this.readerVolumePage = this.readBoolean(READER_KEY_VOLUME_PAGE, false);
    this.readerReverseVolumePage = this.readBoolean(READER_KEY_REVERSE_VOLUME_PAGE, false);
    this.readerReadingFullscreen = this.readBoolean(READER_KEY_FULLSCREEN, true);
    this.readerCustomScreenLightness = this.readBoolean(READER_KEY_CUSTOM_LIGHTNESS, false);
    this.readerScreenLightness = clampNumber(Math.floor(this.readNumber(READER_KEY_SCREEN_LIGHTNESS, 50)), 0, 200);
    this.readerPreloadImageCount = clampNumber(
      Math.floor(this.readNumber(READER_KEY_PRELOAD_IMAGE, READER_DEFAULT_PRELOAD_IMAGE)),
      0,
      READER_MAX_PRELOAD_IMAGE
    );
    this.readerUseOriginImage = this.readBoolean(READER_KEY_DOWNLOAD_ORIGIN_IMAGE, false);
    this.readerFitContain = this.isReaderContainScaling(this.readerPageScaling);
  }

  private loadCachePolicySettings(): void {
    this.cacheMaxSizeMb = clampNumber(
      Math.floor(this.readNumber(CACHE_KEY_MAX_SIZE_MB, CACHE_DEFAULT_MAX_SIZE_MB)),
      CACHE_MIN_MAX_SIZE_MB,
      CACHE_MAX_MAX_SIZE_MB
    );
    this.cacheRetentionDays = clampNumber(
      Math.floor(this.readNumber(CACHE_KEY_RETENTION_DAYS, CACHE_DEFAULT_RETENTION_DAYS)),
      CACHE_MIN_RETENTION_DAYS,
      CACHE_MAX_RETENTION_DAYS
    );
    this.cacheMaxSizeInput = `${this.cacheMaxSizeMb}`;
    this.cacheRetentionDaysInput = `${this.cacheRetentionDays}`;
  }

  private numericSettingInput(value: string, maxLength: number): string {
    let result = '';
    for (let index = 0; index < value.length && result.length < maxLength; index++) {
      const code = value.charCodeAt(index);
      if (code >= 48 && code <= 57) {
        result += value.charAt(index);
      }
    }
    return result;
  }

  private updateCacheMaxSizeInput(value: string): void {
    const nextInput = this.numericSettingInput(value, 4);
    this.cacheMaxSizeInput = nextInput;
    if (nextInput.length === 0) {
      return;
    }
    const nextValue = clampNumber(Number(nextInput), CACHE_MIN_MAX_SIZE_MB, CACHE_MAX_MAX_SIZE_MB);
    this.cacheMaxSizeMb = nextValue;
    this.cacheMaxSizeInput = `${nextValue}`;
    this.writeValue(CACHE_KEY_MAX_SIZE_MB, nextValue);
    this.scheduleCacheMaintenance(true);
  }

  private updateCacheRetentionDaysInput(value: string): void {
    const nextInput = this.numericSettingInput(value, 3);
    this.cacheRetentionDaysInput = nextInput;
    if (nextInput.length === 0) {
      return;
    }
    const nextValue = clampNumber(Number(nextInput), CACHE_MIN_RETENTION_DAYS, CACHE_MAX_RETENTION_DAYS);
    this.cacheRetentionDays = nextValue;
    this.cacheRetentionDaysInput = `${nextValue}`;
    this.writeValue(CACHE_KEY_RETENTION_DAYS, nextValue);
    this.scheduleCacheMaintenance(true);
  }

  private cycleReaderSetting(current: string, values: string[]): string {
    const index = values.indexOf(current);
    if (index < 0 || values.length === 0) {
      return current;
    }
    return values[(index + 1) % values.length];
  }

  private setReaderScreenRotation(value: string): void {
    this.readerScreenRotation = this.normalizeReaderSettingValue(value, READER_ROTATION_VALUES, '0');
    this.writeValue(READER_KEY_SCREEN_ROTATION, this.readerScreenRotation);
    if (this.nativeViewMode === 'reader') {
      void this.applyReaderWindowState();
    }
  }

  private setReaderDirection(value: string): void {
    this.readerDirection = this.normalizeReaderSettingValue(value, READER_DIRECTION_VALUES, '1');
    this.writeValue(READER_KEY_READING_DIRECTION, this.readerDirection);
    if (this.nativeViewMode === 'reader') {
      this.rebuildReaderPageDataSource();
    }
  }

  private setReaderPageScaling(value: string): void {
    const normalized = this.normalizeReaderSettingValue(value, READER_SCALING_VALUES, '3');
    this.readerPageScaling = normalized;
    this.readerFitContain = this.isReaderContainScaling(normalized);
    this.writeValue(READER_KEY_PAGE_SCALING, normalized);
    if (this.nativeViewMode === 'reader') {
      this.rebuildReaderPageDataSource();
    }
  }

  private setReaderStartPosition(value: string): void {
    this.readerStartPosition = this.normalizeReaderSettingValue(value, READER_START_POSITION_VALUES, '1');
    this.writeValue(READER_KEY_START_POSITION, this.readerStartPosition);
  }

  private cycleReaderScreenRotation(): void {
    this.setReaderScreenRotation(this.cycleReaderSetting(this.readerScreenRotation, READER_ROTATION_VALUES));
  }

  private cycleReaderDirection(): void {
    this.setReaderDirection(this.cycleReaderSetting(this.readerDirection, READER_DIRECTION_VALUES));
  }

  private cycleReaderPageScaling(): void {
    this.setReaderPageScaling(this.cycleReaderSetting(this.readerPageScaling, READER_SCALING_VALUES));
  }

  private cycleReaderStartPosition(): void {
    this.setReaderStartPosition(this.cycleReaderSetting(this.readerStartPosition, READER_START_POSITION_VALUES));
  }

  private toggleReaderBoolean(key: string, current: boolean): boolean {
    const next = !current;
    this.writeValue(key, next);
    return next;
  }

  private adjustReaderAutoTransferSeconds(delta: number): void {
    this.setReaderAutoTransferSeconds(this.readerAutoTransferSeconds + delta);
  }

  private setReaderAutoTransferSeconds(value: number): void {
    this.readerAutoTransferSeconds = clampNumber(Math.round(value), 1, 120);
    this.writeValue(READER_KEY_START_TRANSFER_TIME, this.readerAutoTransferSeconds);
    if (this.readerAutoTransferring) {
      this.startReaderAutoTransfer();
    }
  }

  private adjustReaderScreenLightness(delta: number): void {
    this.setReaderScreenLightness(this.readerScreenLightness + delta);
  }

  private setReaderScreenLightness(value: number): void {
    this.readerScreenLightness = clampNumber(Math.round(value), 0, 200);
    this.writeValue(READER_KEY_SCREEN_LIGHTNESS, this.readerScreenLightness);
  }

  private readerDirectionLabel(): string {
    switch (this.readerDirection) {
      case '0':
        return '从左到右';
      case '2':
        return '从上到下';
      default:
        return '从右到左';
    }
  }

  private readerPageScalingLabel(): string {
    switch (this.readerPageScaling) {
      case '0':
        return '原始尺寸';
      case '1':
        return '适应宽度';
      case '2':
        return '适应高度';
      case '4':
        return '固定尺寸';
      default:
        return '适应屏幕';
    }
  }

  private readerScreenRotationLabel(): string {
    switch (this.readerScreenRotation) {
      case '1':
        return '竖屏';
      case '2':
        return '横屏';
      case '3':
        return '跟随传感器';
      default:
        return '默认';
    }
  }

  private readerStartPositionLabel(): string {
    switch (this.readerStartPosition) {
      case '0':
        return '左上';
      case '1':
        return '右上';
      case '2':
        return '左下';
      case '3':
        return '右下';
      case '4':
        return '居中';
      default:
        return '右上';
    }
  }

  private readerSelectIndex(value: string, values: string[]): number {
    const index = values.indexOf(value);
    return index >= 0 ? index : 0;
  }

  private readerSelectValue(index: number, values: string[], fallback: string): string {
    if (index < 0 || index >= values.length) {
      return fallback;
    }
    return values[index];
  }

  private readerScreenRotationOptions(): SelectOption[] {
    return [{ value: '默认' }, { value: '竖屏' }, { value: '横屏' }, { value: '传感器' }];
  }

  private readerDirectionOptions(): SelectOption[] {
    return [{ value: '左到右' }, { value: '右到左' }, { value: '从上到下' }];
  }

  private readerPageScalingOptions(): SelectOption[] {
    return [{ value: '原始尺寸' }, { value: '适应宽度' }, { value: '适应高度' }, { value: '适应屏幕' }, { value: '固定尺寸' }];
  }

  private readerStartPositionOptions(): SelectOption[] {
    return [{ value: '左上' }, { value: '右上' }, { value: '左下' }, { value: '右下' }, { value: '居中' }];
  }

  private isReaderVerticalDirection(): boolean {
    return this.readerDirection === '2';
  }

  private readerPreviousActionLabel(): string {
    if (this.isReaderVerticalDirection()) {
      return '上一页';
    }
    return this.readerDirection === '0' ? '左侧' : '右侧';
  }

  private readerNextActionLabel(): string {
    if (this.isReaderVerticalDirection()) {
      return '下一页';
    }
    return this.readerDirection === '0' ? '右侧' : '左侧';
  }

  private readerOverlayMaskColor(): string {
    if (!this.readerCustomScreenLightness) {
      return '#00000000';
    }
    const alpha = Math.floor((200 - this.readerScreenLightness) / 200 * 150);
    return `#${alpha.toString(16).padStart(2, '0')}000000`;
  }

  private readerAutoTransferLabel(): string {
    return this.readerAutoTransferring ? `自动 ${this.readerAutoTransferSeconds}s` : '自动';
  }

  private readerBottomHintText(): string {
    const previewText = `预览 ${this.nativePreviewPageIndex + 1}/${Math.max(1, this.nativePreviewPageCount)}`;
    const scalingText = this.readerPageScalingLabel();
    return this.readerShowPageInterval ? `${previewText} · ${scalingText}` : scalingText;
  }

  private currentReaderVisualState(): ReaderAdjacentState {
    const displayUrl = this.readerDisplayImageUrl.length > 0 ? this.readerDisplayImageUrl : this.nativeReaderPage.imageUrl;
    const loading = this.readerCurrentError.length === 0 &&
      displayUrl.length === 0 &&
      this.nativeReaderPage.pageUrl.length > 0 &&
      (this.nativeLoading || this.readerTargetLoading || this.readerPageSwitching);
    return {
      pageUrl: this.nativeReaderPage.pageUrl,
      pageLabel: this.nativeReaderPage.pageLabel,
      pageIndex: this.nativeReaderPage.pageIndex,
      displayUrl,
      loading,
      error: this.readerCurrentError
    };
  }

  private previewItemForPageUrl(pageUrl: string): NativeGalleryPreview | undefined {
    return this.nativePreviewItems.find((item: NativeGalleryPreview) => item.pageUrl === pageUrl) ||
      this.nativeAllPreviewItems.find((item: NativeGalleryPreview) => item.pageUrl === pageUrl);
  }

  private readerKnownStateForPageUrl(pageUrl: string): ReaderAdjacentState | undefined {
    if (this.readerPreviousAdjacent.pageUrl === pageUrl) {
      return this.readerPreviousAdjacent;
    }
    if (this.readerNextAdjacent.pageUrl === pageUrl) {
      return this.readerNextAdjacent;
    }
    return undefined;
  }

  private cachedReaderPageForPlaceholder(pageUrl: string): NativeGalleryImagePage | undefined {
    const cached = this.readerPageCache.get(pageUrl);
    if (cached) {
      return cached;
    }
    const localPage = this.createLocalReaderPageIfAvailable(pageUrl);
    if (localPage) {
      this.readerPageCache.set(pageUrl, localPage);
      return localPage;
    }
    return undefined;
  }

  private readerPlaceholderPage(pageUrl: string): NativeGalleryImagePage {
    const cached = this.cachedReaderPageForPlaceholder(pageUrl);
    if (cached) {
      return cached;
    }
    const preview = this.previewItemForPageUrl(pageUrl);
    const parsedPageIndex = this.parseReaderPagePosition(pageUrl);
    const pageIndex = preview ? preview.position :
      (parsedPageIndex >= 0 ? parsedPageIndex : this.nativeReaderPage.pageIndex);
    return {
      pageIndex: pageIndex >= 0 ? pageIndex : 0,
      pageLabel: preview ? preview.pageLabel : (pageIndex >= 0 ? `${pageIndex + 1}` : ''),
      pageUrl,
      imageUrl: '',
      originImageUrl: ''
    };
  }

  private applyReaderPagePlaceholder(pageUrl: string): void {
    const previousPageUrl = this.nativeReaderPage.pageUrl;
    const placeholder = this.readerPlaceholderPage(pageUrl);
    const knownState = this.readerKnownStateForPageUrl(pageUrl);
    this.nativeReaderPage = placeholder;
    this.nativeReaderListIndex = this.findPreviewIndex(pageUrl);
    this.readerJumpInput = placeholder.pageLabel;
    this.readerDisplayImageUrl = knownState && knownState.displayUrl.length > 0 ?
      knownState.displayUrl : this.readerDisplayUrlForPage(placeholder);
    this.readerCurrentError = '';
    this.nativeViewMode = 'reader';
    this.rebuildReaderPageDataSource();
    this.onReaderEntered();
    this.refreshReaderAdjacentPages();
    this.scheduleReaderPreloadWindow(pageUrl);
    if (previousPageUrl.length > 0 && previousPageUrl !== pageUrl) {
      this.showReaderTopInfo();
    }
  }

  private emptyReaderAdjacentState(): ReaderAdjacentState {
    return {
      pageUrl: '',
      pageLabel: '',
      pageIndex: -1,
      displayUrl: '',
      loading: false,
      error: ''
    };
  }

  private setReaderAdjacentState(offset: number, state: ReaderAdjacentState): void {
    if (offset < 0) {
      this.readerPreviousAdjacent = state;
      return;
    }
    this.readerNextAdjacent = state;
  }

  private readerAdjacentState(offset: number): ReaderAdjacentState {
    return offset < 0 ? this.readerPreviousAdjacent : this.readerNextAdjacent;
  }

  private resetReaderAdjacentPages(): void {
    this.readerAdjacentRefreshSerial++;
    this.readerPreviousAdjacent = this.emptyReaderAdjacentState();
    this.readerNextAdjacent = this.emptyReaderAdjacentState();
  }

  private currentReaderPreviewIndex(): number {
    const currentIndex = this.findPreviewIndex(this.nativeReaderPage.pageUrl);
    if (currentIndex >= 0) {
      return currentIndex;
    }
    if (this.nativeReaderListIndex >= 0 &&
      this.nativeReaderListIndex < this.nativePreviewItems.length &&
      this.nativePreviewItems[this.nativeReaderListIndex].pageUrl === this.nativeReaderPage.pageUrl) {
      return this.nativeReaderListIndex;
    }
    return -1;
  }

  private previewUrlByAbsolutePosition(position: number): string {
    if (position < 0) {
      return '';
    }
    const preview = this.nativeAllPreviewItems.find((item: NativeGalleryPreview) => item.position === position) ||
      this.nativePreviewItems.find((item: NativeGalleryPreview) => item.position === position);
    return preview ? preview.pageUrl : '';
  }

  private readerPreviewForAbsolutePosition(position: number): NativeGalleryPreview | undefined {
    if (position < 0) {
      return undefined;
    }
    return this.nativeAllPreviewItems.find((item: NativeGalleryPreview) => item.position === position) ||
      this.nativePreviewItems.find((item: NativeGalleryPreview) => item.position === position);
  }

  private readerTotalPageCount(): number {
    let total = Math.max(0, this.nativeDetail.pages);
    for (const item of this.nativeAllPreviewItems) {
      total = Math.max(total, item.position + 1);
    }
    for (const item of this.nativePreviewItems) {
      total = Math.max(total, item.position + 1);
    }
    if (this.nativeReaderPage.pageIndex >= 0 && this.nativeReaderPage.pageUrl.length > 0) {
      total = Math.max(total, this.nativeReaderPage.pageIndex + 1);
    }
    return Math.max(1, total);
  }

  private isReaderReverseSwiperOrder(): boolean {
    return !this.isReaderVerticalDirection() && this.readerDirection === '1';
  }

  private readerPageIndexForSwiperIndex(index: number, total: number = this.readerTotalPageCount()): number {
    const normalizedIndex = clampNumber(Math.floor(index), 0, Math.max(0, total - 1));
    return this.isReaderReverseSwiperOrder() ? Math.max(0, total - 1 - normalizedIndex) : normalizedIndex;
  }

  private readerSwiperIndexForPageIndex(pageIndex: number, total: number = this.readerTotalPageCount()): number {
    const normalizedPageIndex = clampNumber(Math.floor(pageIndex), 0, Math.max(0, total - 1));
    return this.isReaderReverseSwiperOrder() ? Math.max(0, total - 1 - normalizedPageIndex) : normalizedPageIndex;
  }

  private rebuildReaderPageDataSource(forcePageReload: boolean = false): void {
    if (forcePageReload) {
      this.readerPageSourceGeneration++;
    }
    const total = this.readerTotalPageCount();
    const items: ReaderVirtualPage[] = [];
    for (let swiperIndex = 0; swiperIndex < total; swiperIndex++) {
      const pageIndex = this.readerPageIndexForSwiperIndex(swiperIndex, total);
      const preview = this.readerPreviewForAbsolutePosition(pageIndex);
      let pageUrl = preview ? preview.pageUrl : '';
      let pageLabel = preview && preview.pageLabel.length > 0 ? preview.pageLabel : `${pageIndex + 1}`;
      if (this.nativeReaderPage.pageIndex === pageIndex && this.nativeReaderPage.pageUrl.length > 0) {
        pageUrl = this.nativeReaderPage.pageUrl;
        pageLabel = this.nativeReaderPage.pageLabel.length > 0 ? this.nativeReaderPage.pageLabel : pageLabel;
      }
      items.push({
        pageIndex,
        pageLabel,
        pageUrl,
        generation: this.readerPageSourceGeneration
      });
    }
    this.readerPageDataSource.reload(items);
    this.syncReaderSwiperIndex();
  }

  private syncReaderSwiperIndex(): void {
    if (this.nativeReaderPage.pageIndex < 0) {
      this.readerSwiperIndex = 0;
      return;
    }
    this.readerSwiperIndex = this.readerSwiperIndexForPageIndex(this.nativeReaderPage.pageIndex);
  }

  private readerPreviewPageSizeEstimate(): number {
    return Math.max(40, this.nativePreviewItems.length, this.nativeAllPreviewItems.length > 0 ? 40 : 0);
  }

  private async cacheReaderPreviewPage(previewPageIndex: number): Promise<void> {
    if (this.nativeDetail.detailUrl.length === 0) {
      return;
    }
    const previewPageCount = Math.max(1, this.nativePreviewPageCount, this.nativeDetail.previewPageCount,
      this.nativeAllPreviewPageCount);
    const boundedPageIndex = clampNumber(Math.floor(previewPageIndex), 0, Math.max(0, previewPageCount - 1));
    const pending = this.readerPreviewPageInFlight.get(boundedPageIndex);
    if (pending) {
      await pending;
      return;
    }
    const promise = this.loadReaderPreviewPageIntoCache(boundedPageIndex);
    this.readerPreviewPageInFlight.set(boundedPageIndex, promise);
    try {
      await promise;
    } finally {
      if (this.readerPreviewPageInFlight.get(boundedPageIndex) === promise) {
        this.readerPreviewPageInFlight.delete(boundedPageIndex);
      }
    }
  }

  private async loadReaderPreviewPageIntoCache(previewPageIndex: number): Promise<void> {
    const previewPage = await NativeEhClient.fetchGalleryPreviewPage(this.siteMode, this.nativeDetail.detailUrl, previewPageIndex);
    this.nativeAllPreviewItems = this.mergeNativePreviewItems(this.nativeAllPreviewItems, previewPage.items);
    this.nativeAllPreviewLoadedPages = Math.max(this.nativeAllPreviewLoadedPages, previewPage.pageIndex + 1);
    this.nativeAllPreviewPageCount = Math.max(this.nativeAllPreviewPageCount, previewPage.pageCount);
    this.rebuildReaderPageDataSource();
    this.prefetchGalleryPreviewImages(previewPage.items);
  }

  private async resolveReaderPageUrlByIndex(pageIndex: number): Promise<string> {
    if (this.nativeReaderPage.pageIndex === pageIndex && this.nativeReaderPage.pageUrl.length > 0) {
      return this.nativeReaderPage.pageUrl;
    }
    const knownPreview = this.readerPreviewForAbsolutePosition(pageIndex);
    if (knownPreview && knownPreview.pageUrl.length > 0) {
      return knownPreview.pageUrl;
    }
    const localPageUrl = this.localReaderPageUrl(this.nativeDetail.gid, pageIndex);
    const localPage = this.createLocalReaderPageIfAvailable(localPageUrl);
    if (localPage) {
      this.readerPageCache.set(localPage.pageUrl, localPage);
      return localPage.pageUrl;
    }
    if (this.nativeDetail.detailUrl.length === 0) {
      return '';
    }

    const previewPageCount = Math.max(1, this.nativePreviewPageCount, this.nativeDetail.previewPageCount,
      this.nativeAllPreviewPageCount);
    const guessedPage = clampNumber(
      Math.floor(pageIndex / this.readerPreviewPageSizeEstimate()),
      0,
      Math.max(0, previewPageCount - 1)
    );
    const visited: number[] = [];
    const candidates: number[] = [guessedPage, this.nativePreviewPageIndex, 0];
    for (let offset = 1; offset < previewPageCount; offset++) {
      candidates.push(guessedPage - offset);
      candidates.push(guessedPage + offset);
    }

    for (const candidate of candidates) {
      if (candidate < 0 || candidate >= previewPageCount || visited.indexOf(candidate) >= 0) {
        continue;
      }
      visited.push(candidate);
      await this.cacheReaderPreviewPage(candidate);
      const preview = this.readerPreviewForAbsolutePosition(pageIndex);
      if (preview && preview.pageUrl.length > 0) {
        return preview.pageUrl;
      }
    }
    return '';
  }

  private async resolveReaderVirtualPage(page: ReaderVirtualPage): Promise<ReaderResolvedPage> {
    const pageUrl = page.pageUrl.length > 0 ? page.pageUrl : await this.resolveReaderPageUrlByIndex(page.pageIndex);
    if (pageUrl.length === 0) {
      throw new Error('未找到阅读页链接');
    }
    const prepared = await this.ensureReaderPagePrepared(pageUrl);
    const sourceUrl = this.readerSelectedImageUrl(prepared);
    return {
      pageIndex: prepared.pageIndex,
      pageLabel: prepared.pageLabel.length > 0 ? prepared.pageLabel : `${prepared.pageIndex + 1}`,
      pageUrl: prepared.pageUrl,
      imageUrl: prepared.imageUrl,
      originImageUrl: prepared.originImageUrl,
      skipHathKey: prepared.skipHathKey ? prepared.skipHathKey : '',
      sourceUrl,
      displayUrl: this.readerDisplayUrlForPage(prepared)
    };
  }

  private async cacheReaderResolvedPageImage(page: ReaderResolvedPage): Promise<string> {
    const nativePage: NativeGalleryImagePage = {
      pageIndex: page.pageIndex,
      pageLabel: page.pageLabel,
      pageUrl: page.pageUrl,
      imageUrl: page.imageUrl,
      originImageUrl: page.originImageUrl,
      skipHathKey: page.skipHathKey ? page.skipHathKey : ''
    };
    try {
      return await this.ensureReaderImageCached(nativePage);
    } catch (error) {
      this.markReaderPageForRetryRefresh(page.pageUrl);
      throw new Error(this.readableErrorMessage(error, '阅读器图片下载失败'));
    }
  }

  private handleReaderVirtualPageAppear(page: ReaderVirtualPage): void {
    if (page.pageUrl.length === 0 || this.nativeViewMode !== 'reader') {
      return;
    }
  }

  private handleReaderVirtualPageImageReady(page: ReaderVirtualPage): void {
    if (page.pageUrl.length > 0 && page.pageUrl === this.nativeReaderPage.pageUrl) {
      this.readerCurrentError = '';
    }
    if (page.pageUrl.length > 0) {
      this.readerPageRetrySkipKeys.delete(page.pageUrl);
    }
  }

  private handleReaderVirtualPageImageError(page: ReaderVirtualPage): void {
    if (page.pageUrl.length === 0) {
      return;
    }
    this.markReaderPageForRetryRefresh(page.pageUrl);
    if (page.pageUrl === this.nativeReaderPage.pageUrl) {
      this.readerCurrentError = '';
    }
  }

  private handleReaderSwiperChange(index: number): void {
    this.readerSwiperIndex = index;
    const pageIndex = this.readerPageIndexForSwiperIndex(index);
    if (pageIndex === this.nativeReaderPage.pageIndex && this.nativeReaderPage.pageUrl.length > 0) {
      return;
    }
    this.showReaderTopInfo();
    void this.activateReaderPageIndex(pageIndex);
  }

  private async activateReaderPageIndex(pageIndex: number): Promise<void> {
    const total = this.readerTotalPageCount();
    if (pageIndex < 0 || pageIndex >= total) {
      this.toast('没有更多页面');
      this.syncReaderSwiperIndex();
      return;
    }
    this.readerTargetLoading = true;
    try {
      const pageUrl = await this.resolveReaderPageUrlByIndex(pageIndex);
      if (pageUrl.length === 0) {
        this.toast('未找到目标阅读页');
        this.syncReaderSwiperIndex();
        return;
      }
      await this.loadNativeReaderByPageUrl(pageUrl);
    } catch (error) {
      this.readerCurrentError = this.readableErrorMessage(error, '阅读页切换失败');
    } finally {
      this.readerTargetLoading = false;
    }
  }

  private showReaderPageByOffset(offset: number): void {
    const pageIndex = this.nativeReaderPage.pageIndex + offset;
    const total = this.readerTotalPageCount();
    if (pageIndex < 0 || pageIndex >= total) {
      this.toast('没有更多页面');
      return;
    }
    const nextSwiperIndex = this.readerSwiperIndexForPageIndex(pageIndex, total);
    this.readerSwiperIndex = nextSwiperIndex;
    this.showReaderTopInfo();
    void this.activateReaderPageIndex(pageIndex);
  }

  private readerPageUrlNear(currentPageUrl: string, offset: number): string {
    const currentIndex = this.findPreviewIndex(currentPageUrl);
    if (currentIndex >= 0) {
      const targetIndex = currentIndex + offset;
      if (targetIndex >= 0 && targetIndex < this.nativePreviewItems.length) {
        return this.nativePreviewItems[targetIndex].pageUrl;
      }
    }
    const preview = this.previewItemForPageUrl(currentPageUrl);
    const parsedPosition = this.parseReaderPagePosition(currentPageUrl);
    const currentPosition = preview ? preview.position : parsedPosition;
    return this.previewUrlByAbsolutePosition(currentPosition + offset);
  }

  private readerPageUrlByOffset(offset: number): string {
    const currentListIndex = this.currentReaderPreviewIndex();
    const targetListIndex = currentListIndex >= 0 ? currentListIndex + offset : -1;
    if (targetListIndex >= 0 && targetListIndex < this.nativePreviewItems.length) {
      return this.nativePreviewItems[targetListIndex].pageUrl;
    }
    const targetPageIndex = this.nativeReaderPage.pageIndex + offset;
    return this.previewUrlByAbsolutePosition(targetPageIndex);
  }

  private readerAdjacentPlaceholder(offset: number, pageUrl: string): ReaderAdjacentState {
    let pageLabel = '';
    let pageIndex = -1;
    const preview = this.nativePreviewItems.find((item: NativeGalleryPreview) => item.pageUrl === pageUrl) ||
      this.nativeAllPreviewItems.find((item: NativeGalleryPreview) => item.pageUrl === pageUrl);
    if (preview) {
      pageIndex = preview.position;
      pageLabel = `${preview.position + 1}`;
    } else if (this.nativeReaderPage.pageLabel.length > 0) {
      pageIndex = this.nativeReaderPage.pageIndex + offset;
      if (pageIndex >= 0) {
        pageLabel = `${pageIndex + 1}`;
      }
    }
    return {
      pageUrl,
      pageLabel,
      pageIndex,
      displayUrl: '',
      loading: true,
      error: ''
    };
  }

  private updateReaderAdjacentDisplay(offset: number, pageUrl: string, displayUrl: string, error: string = ''): void {
    const current = this.readerAdjacentState(offset);
    if (current.pageUrl !== pageUrl) {
      return;
    }
    const next: ReaderAdjacentState = {
      pageUrl: current.pageUrl,
      pageLabel: current.pageLabel,
      pageIndex: current.pageIndex,
      displayUrl: displayUrl.length > 0 ? displayUrl : current.displayUrl,
      loading: false,
      error
    };
    this.setReaderAdjacentState(offset, next);
  }

  private async loadReaderAdjacentPage(offset: number, serial: number): Promise<void> {
    const pageUrl = this.readerPageUrlByOffset(offset);
    if (pageUrl.length === 0) {
      if (serial === this.readerAdjacentRefreshSerial) {
        this.setReaderAdjacentState(offset, this.emptyReaderAdjacentState());
      }
      return;
    }

    this.setReaderAdjacentState(offset, this.readerAdjacentPlaceholder(offset, pageUrl));
    try {
      const page = await this.ensureReaderPagePrepared(pageUrl);
      if (serial !== this.readerAdjacentRefreshSerial) {
        return;
      }
      const displayUrl = this.readerDisplayUrlForPage(page);
      this.setReaderAdjacentState(offset, {
        pageUrl: page.pageUrl,
        pageLabel: page.pageLabel.length > 0 ? page.pageLabel : `${page.pageIndex + 1}`,
        pageIndex: page.pageIndex,
        displayUrl,
        loading: false,
        error: ''
      });
      void this.ensureReaderImageCached(page).then((localUri: string) => {
        if (serial !== this.readerAdjacentRefreshSerial) {
          return;
        }
        if (localUri.length > 0) {
          this.updateReaderAdjacentDisplay(offset, page.pageUrl, localUri);
        }
      }).catch((error: Object) => {
        if (serial !== this.readerAdjacentRefreshSerial) {
          return;
        }
        const message = this.readableErrorMessage(error, '相邻页加载失败');
        this.updateReaderAdjacentDisplay(offset, page.pageUrl, displayUrl, message);
      });
    } catch (error) {
      if (serial !== this.readerAdjacentRefreshSerial) {
        return;
      }
      const placeholder = this.readerAdjacentPlaceholder(offset, pageUrl);
      placeholder.loading = false;
      placeholder.error = this.readableErrorMessage(error, '相邻页加载失败');
      this.setReaderAdjacentState(offset, placeholder);
    }
  }

  private refreshReaderAdjacentPages(): void {
    this.resetReaderAdjacentPages();
  }

  private readerViewportPrimarySize(): number {
    return Math.max(1, this.isReaderVerticalDirection() ? this.readerViewportHeight : this.readerViewportWidth);
  }

  private readerPagerInterval(): number {
    return this.readerShowPageInterval ? 48 : 0;
  }

  private readerPagerSpan(): number {
    return this.readerViewportPrimarySize() + this.readerPagerInterval();
  }

  private readerNegativeSideState(): ReaderAdjacentState {
    if (this.isReaderVerticalDirection() || this.readerDirection === '0') {
      return this.readerPreviousAdjacent;
    }
    return this.readerNextAdjacent;
  }

  private readerPositiveSideState(): ReaderAdjacentState {
    if (this.isReaderVerticalDirection() || this.readerDirection === '0') {
      return this.readerNextAdjacent;
    }
    return this.readerPreviousAdjacent;
  }

  private readerRenderCurrentState(): ReaderAdjacentState {
    if (this.readerTransitionSnapshotActive) {
      return this.readerTransitionCurrentSnapshot;
    }
    return this.currentReaderVisualState();
  }

  private readerRenderNegativeState(): ReaderAdjacentState {
    if (this.readerTransitionSnapshotActive) {
      return this.readerTransitionNegativeSnapshot;
    }
    return this.readerNegativeSideState();
  }

  private readerRenderPositiveState(): ReaderAdjacentState {
    if (this.readerTransitionSnapshotActive) {
      return this.readerTransitionPositiveSnapshot;
    }
    return this.readerPositiveSideState();
  }

  private clearReaderTransitionSnapshot(): void {
    this.readerTransitionSnapshotActive = false;
    this.readerTransitionCurrentSnapshot = this.emptyReaderAdjacentState();
    this.readerTransitionNegativeSnapshot = this.emptyReaderAdjacentState();
    this.readerTransitionPositiveSnapshot = this.emptyReaderAdjacentState();
  }

  private captureReaderTransitionSnapshot(): void {
    this.readerTransitionCurrentSnapshot = this.currentReaderVisualState();
    this.readerTransitionNegativeSnapshot = this.readerNegativeSideState();
    this.readerTransitionPositiveSnapshot = this.readerPositiveSideState();
    this.readerTransitionSnapshotActive = true;
  }

  private readerVisibleCurrentState(): ReaderAdjacentState {
    return this.readerRenderCurrentState();
  }

  private readerLayerTranslateX(layer: 'negative' | 'current' | 'positive'): number {
    if (this.isReaderVerticalDirection()) {
      return 0;
    }
    const width = this.readerPagerSpan();
    switch (layer) {
      case 'negative':
        return this.readerDragOffset - width;
      case 'positive':
        return this.readerDragOffset + width;
      default:
        return this.readerDragOffset;
    }
  }

  private readerLayerTranslateY(layer: 'negative' | 'current' | 'positive'): number {
    if (!this.isReaderVerticalDirection()) {
      return 0;
    }
    const height = this.readerPagerSpan();
    switch (layer) {
      case 'negative':
        return this.readerDragOffset - height;
      case 'positive':
        return this.readerDragOffset + height;
      default:
        return this.readerDragOffset;
    }
  }

  private refreshReaderBatteryText(): void {
    try {
      const soc = Math.max(0, Math.min(100, Math.floor(batteryInfo.batterySOC)));
      const charging = batteryInfo.chargingStatus === batteryInfo.BatteryChargeState.ENABLE ||
        batteryInfo.chargingStatus === batteryInfo.BatteryChargeState.FULL;
      this.readerBatteryText = charging ? `${soc}%+` : `${soc}%`;
    } catch (error) {
      this.readerBatteryText = '--%';
    }
  }

  private refreshReaderClockText(): void {
    const now = new Date();
    const hours = `${now.getHours()}`.padStart(2, '0');
    const minutes = `${now.getMinutes()}`.padStart(2, '0');
    this.readerNowText = `${hours}:${minutes}`;
    this.refreshReaderBatteryText();
  }

  private readerWindowOrientation(): window.Orientation {
    switch (this.readerScreenRotation) {
      case '1':
        return window.Orientation.PORTRAIT;
      case '2':
        return window.Orientation.LANDSCAPE;
      case '3':
        return window.Orientation.AUTO_ROTATION;
      default:
        return window.Orientation.UNSPECIFIED;
    }
  }

  private async obtainReaderWindow(): Promise<window.Window | undefined> {
    if (this.readerWindow) {
      return this.readerWindow;
    }
    try {
      const hostContext = this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
      if (!hostContext) {
        return undefined;
      }
      this.readerWindow = await window.getLastWindow(hostContext);
      return this.readerWindow;
    } catch (error) {
      return undefined;
    }
  }

  private async applyReaderWindowState(forceReaderActive?: boolean): Promise<void> {
    const hostWindow = await this.obtainReaderWindow();
    if (!hostWindow) {
      return;
    }

    const readerActive = forceReaderActive !== undefined ? forceReaderActive : this.nativeViewMode === 'reader';
    const visibleBars: Array<'status' | 'navigation'> = ['status', 'navigation'];
    const hiddenBars: Array<'status' | 'navigation'> = [];
    const fullscreenReader = readerActive && this.readerReadingFullscreen;

    try {
      await hostWindow.setWindowKeepScreenOn(readerActive && this.readerKeepScreenOn);
    } catch (error) {
    }

    try {
      await hostWindow.setPreferredOrientation(readerActive ? this.readerWindowOrientation() : window.Orientation.UNSPECIFIED);
    } catch (error) {
    }

    try {
      await hostWindow.setWindowLayoutFullScreen(true);
    } catch (error) {
    }

    try {
      const uiContext = this.getUIContext();
      const systemArea = hostWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      this.systemSafeTop = Math.max(0, Math.round(uiContext.px2vp(systemArea.topRect.height)));
      let safeBottom = Math.max(0, Math.round(uiContext.px2vp(systemArea.bottomRect.height)));
      try {
        const navigationArea = hostWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        safeBottom = Math.max(safeBottom, Math.round(uiContext.px2vp(navigationArea.bottomRect.height)));
      } catch (error) {
      }
      this.systemSafeBottom = safeBottom;
    } catch (error) {
      this.systemSafeBottom = BOTTOM_NAV_SAFE_FALLBACK;
    }

    try {
      await hostWindow.setWindowSystemBarEnable(fullscreenReader ? hiddenBars : visibleBars);
    } catch (error) {
    }

    try {
      if (readerActive) {
        await hostWindow.setWindowSystemBarProperties({
          statusBarColor: fullscreenReader ? '#00000000' : '#CC111315',
          navigationBarColor: fullscreenReader ? '#00000000' : '#CC111315',
          isStatusBarLightIcon: true,
          isNavigationBarLightIcon: true
        });
      } else {
        await hostWindow.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          isStatusBarLightIcon: false,
          isNavigationBarLightIcon: false,
          statusBarContentColor: '#2B2027',
          navigationBarContentColor: '#2B2027'
        });
      }
    } catch (error) {
    }
  }

  private startReaderClockTicker(): void {
    this.stopReaderClockTicker();
    this.refreshReaderClockText();
    const handle = setInterval(() => {
      this.refreshReaderClockText();
    }, 30000);
    this.readerClockTimerId = Number(handle);
  }

  private stopReaderClockTicker(): void {
    if (this.readerClockTimerId >= 0) {
      clearInterval(this.readerClockTimerId);
      this.readerClockTimerId = -1;
    }
  }

  private clearReaderTopInfoTimer(): void {
    if (this.readerTopInfoTimerId >= 0) {
      clearTimeout(this.readerTopInfoTimerId);
      this.readerTopInfoTimerId = -1;
    }
  }

  private showReaderTopInfo(): void {
    if (!this.readerShowBattery && !this.readerShowProgress && !this.readerShowClock) {
      return;
    }
    this.refreshReaderClockText();
    this.clearReaderTopInfoTimer();
    this.readerTopInfoVisible = true;
    const handle = setTimeout(() => {
      this.readerTopInfoTimerId = -1;
      this.readerTopInfoVisible = false;
    }, 2000);
    this.readerTopInfoTimerId = Number(handle);
  }

  private hideReaderTopInfo(): void {
    this.clearReaderTopInfoTimer();
    this.readerTopInfoVisible = false;
  }

  private stopReaderAutoTransfer(): void {
    if (this.readerAutoTransferTimerId >= 0) {
      clearInterval(this.readerAutoTransferTimerId);
      this.readerAutoTransferTimerId = -1;
    }
    this.readerAutoTransferring = false;
  }

  private startReaderAutoTransfer(): void {
    this.stopReaderAutoTransfer();
    const intervalSeconds = clampNumber(this.readerAutoTransferSeconds, 1, 120);
    this.readerAutoTransferSeconds = intervalSeconds;
    this.readerAutoTransferring = true;
    const handle = setInterval(() => {
      if (this.nativeViewMode !== 'reader' || this.nativeLoading) {
        return;
      }
      if (!this.canShiftNativeReaderForward()) {
        this.stopReaderAutoTransfer();
        return;
      }
      this.goReaderNext();
    }, intervalSeconds * 1000);
    this.readerAutoTransferTimerId = Number(handle);
  }

  private toggleReaderAutoTransfer(): void {
    if (this.readerAutoTransferring) {
      this.stopReaderAutoTransfer();
      return;
    }
    this.startReaderAutoTransfer();
  }

  private onReaderEntered(): void {
    this.readerSettingsVisible = false;
    this.readerMenuVisible = !this.readerReadingFullscreen;
    this.hideReaderTopInfo();
    this.stopReaderAutoTransfer();
    this.startReaderClockTicker();
    this.refreshReaderBatteryText();
    void this.applyReaderWindowState(true);
  }

  private stopReaderRuntimeState(): void {
    this.readerLoadSerial++;
    this.readerMenuVisible = false;
    this.readerSettingsVisible = false;
    this.hideReaderTopInfo();
    this.cancelReaderPrefetchWindow();
    this.readerPageDataSource.reload([]);
    this.readerSwiperIndex = 0;
    this.stopReaderAutoTransfer();
    this.stopReaderClockTicker();
    void this.applyReaderWindowState(false);
  }

  private cancelReaderPrefetchWindow(): void {
    this.readerPrefetchGeneration++;
    this.readerHtmlPrefetchQueue = [];
    this.readerImagePrefetchQueue = [];
    this.readerCacheStatus = '缓存空闲';
  }

  private abilityFilesDir(): string {
    const abilityContext = this.uiAbilityContext();
    return abilityContext ? abilityContext.filesDir : '';
  }

  private uiAbilityContext(): common.UIAbilityContext | undefined {
    const hostContext = this.getUIContext().getHostContext();
    if (!hostContext) {
      return undefined;
    }
    return hostContext as common.UIAbilityContext;
  }

  private ensureLocalDirectory(path: string): boolean {
    if (path.length === 0) {
      return false;
    }
    try {
      if (!fileIo.accessSync(path)) {
        fileIo.mkdirSync(path, true);
      }
      return true;
    } catch (error) {
      try {
        fileIo.mkdirSync(path, true);
        return true;
      } catch (innerError) {
        return false;
      }
    }
  }

  private fileUri(path: string): string {
    return path.length > 0 ? `file://${path}` : '';
  }

  private readerCacheRoot(): string {
    const filesDir = this.abilityFilesDir();
    return filesDir.length > 0 ? `${filesDir}/${READER_CACHE_DIR_NAME}` : '';
  }

  private readerGalleryCacheDir(): string {
    const root = this.readerCacheRoot();
    if (root.length === 0 || this.nativeDetail.gid <= 0) {
      return '';
    }
    return `${root}/${this.siteMode}-${this.nativeDetail.gid}`;
  }

  private galleryImageCacheRoot(): string {
    const filesDir = this.abilityFilesDir();
    return filesDir.length > 0 ? `${filesDir}/${GALLERY_IMAGE_CACHE_DIR_NAME}` : '';
  }

  private readerSafeSegment(value: string): string {
    return value.replace(/[^A-Za-z0-9._-]/g, '_').substring(0, 80);
  }

  private readerHostFromUrl(url: string): string {
    const match = /^https?:\/\/([^/?#]+)/i.exec(url);
    return match && match[1] ? match[1] : '';
  }

  private readerImageExtensionFromUrl(url: string): string {
    const cleanUrl = url.split('?')[0].split('#')[0].toLowerCase();
    for (const extension of READER_IMAGE_EXTENSIONS) {
      if (cleanUrl.endsWith(extension)) {
        return extension === '.jpeg' ? '.jpg' : extension;
      }
    }
    return '.jpg';
  }

  private stableHash(value: string): string {
    let hash = 5381;
    for (let index = 0; index < value.length; index++) {
      hash = ((hash << 5) + hash + value.charCodeAt(index)) >>> 0;
    }
    return hash.toString(16);
  }

  private galleryImageCacheKey(url: string): string {
    return `${this.siteMode}:${this.stableHash(url)}`;
  }

  private galleryImageCachePath(url: string): string {
    const root = this.galleryImageCacheRoot();
    if (root.length === 0 || url.length === 0) {
      return '';
    }
    return `${root}/${this.galleryImageCacheKey(url).replace(/:/g, '-')}${this.readerImageExtensionFromUrl(url)}`;
  }

  private readerSelectedImageUrl(page: NativeGalleryImagePage): string {
    if (this.readerUseOriginImage && page.originImageUrl.length > 0) {
      return page.originImageUrl;
    }
    return page.imageUrl;
  }

  private readerImageCacheKey(page: NativeGalleryImagePage): string {
    const mode = this.readerUseOriginImage && page.originImageUrl.length > 0 ? 'origin' : 'image';
    const sourceUrl = this.readerSelectedImageUrl(page);
    return `${this.siteMode}:${this.nativeDetail.gid}:${page.pageIndex}:${mode}:${this.stableHash(page.pageUrl)}:${this.stableHash(sourceUrl)}`;
  }

  private readerImageCachePath(page: NativeGalleryImagePage, sourceUrl: string): string {
    const dir = this.readerGalleryCacheDir();
    if (dir.length === 0) {
      return '';
    }
    const pageName = `${page.pageIndex + 1}`.padStart(8, '0');
    const mode = this.readerUseOriginImage && page.originImageUrl.length > 0 ? 'origin' : 'image';
    return `${dir}/${pageName}-${mode}-${this.stableHash(page.pageUrl)}-${this.stableHash(sourceUrl)}${this.readerImageExtensionFromUrl(sourceUrl)}`;
  }

  private stringToArrayBuffer(value: string): ArrayBuffer {
    const buffer = new ArrayBuffer(value.length);
    const bytes = new Uint8Array(buffer);
    for (let index = 0; index < value.length; index++) {
      bytes[index] = value.charCodeAt(index) & 0xff;
    }
    return buffer;
  }

  private appendReaderCookieSource(url: string, names: string[], values: string[]): void {
    try {
      const cookie = webview.WebCookieManager.fetchCookieSync(url, false);
      if (cookie.length === 0) {
        return;
      }
      const parts = cookie.split(';');
      for (const part of parts) {
        const trimmed = part.trim();
        const separator = trimmed.indexOf('=');
        if (separator <= 0) {
          continue;
        }
        const name = trimmed.substring(0, separator);
        const existingIndex = names.indexOf(name);
        if (existingIndex >= 0) {
          values[existingIndex] = trimmed;
        } else {
          names.push(name);
          values.push(trimmed);
        }
      }
    } catch (error) {
    }
  }

  private readerCookieHeader(url: string): string {
    const names: string[] = [];
    const values: string[] = [];
    this.appendReaderCookieSource(EhUrl.DOMAIN_FORUMS, names, values);
    this.appendReaderCookieSource(EhUrl.DOMAIN_E, names, values);
    if (this.siteMode === GallerySite.EX) {
      this.appendReaderCookieSource(EhUrl.DOMAIN_EX, names, values);
    }
    this.appendReaderCookieSource(url, names, values);
    if (this.siteMode === GallerySite.E && names.indexOf('nw') < 0) {
      names.push('nw');
      values.push('nw=1');
    }
    return values.join('; ');
  }

  private readerDownloadedImageUri(pageIndex: number): string {
    const filesDir = this.abilityFilesDir();
    if (filesDir.length === 0 || this.nativeDetail.gid <= 0) {
      return '';
    }
    const safeTitle = this.readerSafeSegment(this.nativeDetail.title.length > 0 ? this.nativeDetail.title : `${this.nativeDetail.gid}`);
    const dirs: string[] = [
      `${filesDir}/${READER_DOWNLOAD_DIR_NAME}/${this.siteMode}-${this.nativeDetail.gid}`,
      `${filesDir}/${READER_DOWNLOAD_DIR_NAME}/${this.nativeDetail.gid}`,
      `${filesDir}/${READER_DOWNLOAD_DIR_NAME}/${safeTitle}`,
      `${filesDir}/download/${this.siteMode}-${this.nativeDetail.gid}`,
      `${filesDir}/download/${this.nativeDetail.gid}`
    ];
    const oneBased = pageIndex + 1;
    const names: string[] = [];
    for (const extension of READER_IMAGE_EXTENSIONS) {
      names.push(`${oneBased}`.padStart(8, '0') + extension);
      names.push(`${oneBased}`.padStart(5, '0') + extension);
      names.push(`${oneBased}${extension}`);
    }
    for (const dir of dirs) {
      for (const name of names) {
        const path = `${dir}/${name}`;
        try {
          if (fileIo.accessSync(path)) {
            return this.fileUri(path);
          }
        } catch (error) {
        }
      }
    }
    return '';
  }

  private readerExistingCachedImageUri(page: NativeGalleryImagePage): string {
    const localDownloadUri = this.readerDownloadedImageUri(page.pageIndex);
    if (localDownloadUri.length > 0) {
      return localDownloadUri;
    }
    const key = this.readerImageCacheKey(page);
    const sourceUrl = this.readerSelectedImageUrl(page);
    const cached = this.readerImageCache.get(key);
    if (cached && cached.localPath.length > 0 && cached.pageUrl === page.pageUrl && cached.sourceUrl === sourceUrl) {
      try {
        if (fileIo.accessSync(cached.localPath)) {
          return cached.localUri;
        }
      } catch (error) {
      }
    }
    const cachePath = this.readerImageCachePath(page, sourceUrl);
    if (cachePath.length === 0) {
      return '';
    }
    try {
      if (fileIo.accessSync(cachePath)) {
        const entry: ReaderImageCacheEntry = {
          key,
          pageUrl: page.pageUrl,
          pageIndex: page.pageIndex,
          localPath: cachePath,
          localUri: this.fileUri(cachePath),
          sourceUrl,
          cachedAt: Date.now()
        };
        this.readerImageCache.set(key, entry);
        return entry.localUri;
      }
    } catch (error) {
    }
    return '';
  }

  private removeManagedReaderCacheFile(path: string): void {
    const root = this.readerCacheRoot();
    if (path.length === 0 || root.length === 0 || !path.startsWith(`${root}/`)) {
      return;
    }
    try {
      if (fileIo.accessSync(path)) {
        fileIo.unlinkSync(path);
      }
    } catch (error) {
    }
  }

  private invalidateReaderImageCache(page: NativeGalleryImagePage): void {
    const sourceUrl = this.readerSelectedImageUrl(page);
    if (sourceUrl.startsWith('file://')) {
      return;
    }
    const key = this.readerImageCacheKey(page);
    const cached = this.readerImageCache.get(key);
    if (cached) {
      this.readerImageCache.delete(key);
      this.removeManagedReaderCacheFile(cached.localPath);
    }
    const cachePath = this.readerImageCachePath(page, sourceUrl);
    if (!cached || cached.localPath !== cachePath) {
      this.removeManagedReaderCacheFile(cachePath);
    }
    this.readerImageInFlight.delete(key);
  }

  private markReaderPageForRetryRefresh(pageUrl: string): void {
    if (pageUrl.length === 0) {
      return;
    }
    const cachedPage = this.readerPageCache.get(pageUrl);
    const currentPage = this.nativeReaderPage.pageUrl === pageUrl ? this.nativeReaderPage : undefined;
    const page = cachedPage ? cachedPage : currentPage;
    if (page) {
      this.invalidateReaderImageCache(page);
      const skipHathKey = page.skipHathKey ? page.skipHathKey : '';
      if (skipHathKey.length > 0) {
        this.readerPageRetrySkipKeys.set(pageUrl, skipHathKey);
      }
    }
    this.readerPageCache.delete(pageUrl);
    this.readerPageInFlight.delete(pageUrl);
    this.readerHtmlPrefetchQueue = this.readerHtmlPrefetchQueue.filter((item: ReaderPrefetchTask): boolean => {
      return item.pageUrl !== pageUrl;
    });
    this.readerImagePrefetchQueue = this.readerImagePrefetchQueue.filter((item: ReaderImagePrefetchTask): boolean => {
      return item.page.pageUrl !== pageUrl;
    });
  }

  private readerDisplayUrlForPage(page: NativeGalleryImagePage): string {
    const cachedUri = this.readerExistingCachedImageUri(page);
    if (cachedUri.length > 0) {
      return cachedUri;
    }
    return this.readerSelectedImageUrl(page);
  }

  private galleryImageDisplayUrl(url: string): string {
    this.galleryImageCacheVersion;
    if (url.length === 0) {
      return '';
    }
    const key = this.galleryImageCacheKey(url);
    const cached = this.galleryImageCache.get(key);
    if (cached && cached.localPath.length > 0) {
      try {
        if (fileIo.accessSync(cached.localPath)) {
          return cached.localUri;
        }
      } catch (error) {
      }
    }
    const cachePath = this.galleryImageCachePath(url);
    if (cachePath.length > 0) {
      try {
        if (fileIo.accessSync(cachePath)) {
          const entry: GalleryImageCacheEntry = {
            key,
            sourceUrl: url,
            localPath: cachePath,
            localUri: this.fileUri(cachePath),
            cachedAt: Date.now()
          };
          this.galleryImageCache.set(key, entry);
          return entry.localUri;
        }
      } catch (error) {
      }
    }
    return url;
  }

  private async downloadGalleryImageToCache(url: string, referer: string): Promise<string> {
    const root = this.galleryImageCacheRoot();
    const key = this.galleryImageCacheKey(url);
    const cachePath = this.galleryImageCachePath(url);
    if (url.length === 0 || cachePath.length === 0 || !this.ensureLocalDirectory(root)) {
      throw new Error('图库封面缓存目录不可用');
    }

    const request = http.createHttp();
    const headers: Record<string, string> = {
      'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'User-Agent': 'Mozilla/5.0 (Phone; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36',
      'Referer': referer.length > 0 ? referer : EhUrl.referer(this.siteMode)
    };
    const host = this.readerHostFromUrl(url);
    if (host.length > 0) {
      headers['Host'] = host;
    }
    const cookie = this.readerCookieHeader(url);
    if (cookie.length > 0) {
      headers['Cookie'] = cookie;
    }

    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        usingCache: false,
        usingProxy: AppNetworkProxy.requestProxy(),
        readTimeout: 20000,
        connectTimeout: 12000,
        header: headers
      });
      const code = Number(response.responseCode);
      if (code < 200 || code >= 400) {
        throw new Error(`HTTP ${code}`);
      }
      const result = response.result;
      const data = typeof result === 'string' ? this.stringToArrayBuffer(result) : result as ArrayBuffer;
      const tempPath = `${cachePath}.tmp`;
      let file: fileIo.File | undefined = undefined;
      try {
        file = fileIo.openSync(tempPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
        fileIo.writeSync(file.fd, data);
      } finally {
        if (file) {
          try {
            fileIo.closeSync(file);
          } catch (closeError) {
          }
        }
      }
      try {
        if (fileIo.accessSync(cachePath)) {
          fileIo.unlinkSync(cachePath);
        }
      } catch (error) {
      }
      try {
        fileIo.renameSync(tempPath, cachePath);
      } catch (renameError) {
        throw new Error(`${renameError}`);
      }
      const entry: GalleryImageCacheEntry = {
        key,
        sourceUrl: url,
        localPath: cachePath,
        localUri: this.fileUri(cachePath),
        cachedAt: Date.now()
      };
      this.galleryImageCache.set(key, entry);
      this.scheduleCacheMaintenance();
      return entry.localUri;
    } catch (error) {
      const message = `${error}`;
      throw new Error(message.length > 0 ? message : '图库封面缓存失败');
    } finally {
      request.destroy();
    }
  }

  private async ensureGalleryImageCached(url: string, referer: string): Promise<string> {
    if (url.length === 0 || url.startsWith('file://')) {
      return url;
    }
    const current = this.galleryImageDisplayUrl(url);
    if (current.startsWith('file://')) {
      return current;
    }
    const key = this.galleryImageCacheKey(url);
    const pending = this.galleryImageInFlight.get(key);
    if (pending) {
      return await pending;
    }
    const promise = this.downloadGalleryImageToCache(url, referer);
    this.galleryImageInFlight.set(key, promise);
    try {
      const localUri = await promise;
      this.galleryImageCacheVersion++;
      return localUri;
    } finally {
      if (this.galleryImageInFlight.get(key) === promise) {
        this.galleryImageInFlight.delete(key);
      }
    }
  }

  private prefetchGalleryImages(items: NativeGallerySummary[], referer: string): void {
    const limit = Math.min(items.length, 40);
    for (let index = 0; index < limit; index++) {
      const url = items[index].thumb;
      if (url.length > 0) {
        void this.ensureGalleryImageCached(url, referer).catch(() => {
        });
      }
    }
  }

  private prefetchGalleryDetailCover(): void {
    if (this.nativeDetail.cover.length === 0) {
      return;
    }
    void this.ensureGalleryImageCached(this.nativeDetail.cover, this.nativeDetail.detailUrl).catch(() => {
    });
  }

  private prefetchGalleryPreviewImages(items: NativeGalleryPreview[]): void {
    const limit = Math.min(items.length, 40);
    for (let index = 0; index < limit; index++) {
      const url = items[index].thumbUrl;
      if (url.length > 0) {
        void this.ensureGalleryImageCached(url, this.nativeDetail.detailUrl).catch(() => {
        });
      }
    }
  }

  private async fetchAndCacheReaderPage(pageUrl: string, skipHathKey: string = ''): Promise<NativeGalleryImagePage> {
    const page = await NativeEhClient.fetchReaderPage(this.siteMode, pageUrl, skipHathKey);
    this.readerPageCache.set(pageUrl, page);
    if (skipHathKey.length > 0 && this.readerPageRetrySkipKeys.get(pageUrl) === skipHathKey) {
      this.readerPageRetrySkipKeys.delete(pageUrl);
    }
    return page;
  }

  private createLocalReaderPageIfAvailable(pageUrl: string): NativeGalleryImagePage | undefined {
    const pageIndex = this.parseReaderPagePosition(pageUrl);
    if (pageIndex < 0) {
      return undefined;
    }
    const localUri = this.readerDownloadedImageUri(pageIndex);
    if (localUri.length === 0) {
      return undefined;
    }
    return {
      pageIndex,
      pageLabel: `${pageIndex + 1}`,
      pageUrl,
      imageUrl: localUri,
      originImageUrl: ''
    };
  }

  private async ensureReaderPagePrepared(pageUrl: string): Promise<NativeGalleryImagePage> {
    const skipHathKey = this.readerPageRetrySkipKeys.get(pageUrl) || '';
    if (skipHathKey.length === 0) {
      const cached = this.readerPageCache.get(pageUrl);
      if (cached) {
        return cached;
      }
      const localPage = this.createLocalReaderPageIfAvailable(pageUrl);
      if (localPage) {
        this.readerPageCache.set(pageUrl, localPage);
        return localPage;
      }
    }
    const pending = this.readerPageInFlight.get(pageUrl);
    if (pending) {
      return await pending;
    }
    const promise = this.fetchAndCacheReaderPage(pageUrl, skipHathKey);
    this.readerPageInFlight.set(pageUrl, promise);
    try {
      return await promise;
    } finally {
      if (this.readerPageInFlight.get(pageUrl) === promise) {
        this.readerPageInFlight.delete(pageUrl);
      }
    }
  }

  private async downloadReaderImageToCache(
    page: NativeGalleryImagePage,
    sourceUrl: string,
    key: string,
    cachePath: string
  ): Promise<string> {
    const dir = this.readerGalleryCacheDir();
    if (sourceUrl.length === 0 || cachePath.length === 0 || !this.ensureLocalDirectory(dir)) {
      throw new Error('阅读器缓存目录不可用');
    }

    const request = http.createHttp();
    const headers: Record<string, string> = {
      'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'User-Agent': 'Mozilla/5.0 (Phone; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36',
      'Referer': page.pageUrl
    };
    const host = this.readerHostFromUrl(sourceUrl);
    if (host.length > 0) {
      headers['Host'] = host;
    }
    const cookie = this.readerCookieHeader(sourceUrl);
    if (cookie.length > 0) {
      headers['Cookie'] = cookie;
    }

    try {
      const response = await request.request(sourceUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        usingCache: false,
        usingProxy: AppNetworkProxy.requestProxy(),
        readTimeout: 30000,
        connectTimeout: 12000,
        header: headers
      });
      const code = Number(response.responseCode);
      if (code < 200 || code >= 400) {
        throw new Error(`HTTP ${code}`);
      }
      const result = response.result;
      const data = typeof result === 'string' ? this.stringToArrayBuffer(result) : result as ArrayBuffer;
      const tempPath = `${cachePath}.tmp`;
      let file: fileIo.File | undefined = undefined;
      try {
        file = fileIo.openSync(tempPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
        fileIo.writeSync(file.fd, data);
      } finally {
        if (file) {
          try {
            fileIo.closeSync(file);
          } catch (closeError) {
          }
        }
      }
      try {
        if (fileIo.accessSync(cachePath)) {
          fileIo.unlinkSync(cachePath);
        }
      } catch (error) {
      }
      fileIo.renameSync(tempPath, cachePath);
      const entry: ReaderImageCacheEntry = {
        key,
        pageUrl: page.pageUrl,
        pageIndex: page.pageIndex,
        localPath: cachePath,
        localUri: this.fileUri(cachePath),
        sourceUrl,
        cachedAt: Date.now()
      };
      this.readerImageCache.set(key, entry);
      this.scheduleCacheMaintenance();
      return entry.localUri;
    } catch (error) {
      throw new Error(this.readableErrorMessage(error, '阅读器图片下载失败'));
    } finally {
      request.destroy();
    }
  }

  private async ensureReaderImageCached(page: NativeGalleryImagePage): Promise<string> {
    const localDownloadUri = this.readerDownloadedImageUri(page.pageIndex);
    if (localDownloadUri.length > 0) {
      return localDownloadUri;
    }
    const sourceUrl = this.readerSelectedImageUrl(page);
    const key = this.readerImageCacheKey(page);
    const cachedUri = this.readerExistingCachedImageUri(page);
    if (cachedUri.length > 0) {
      return cachedUri;
    }
    const pending = this.readerImageInFlight.get(key);
    if (pending) {
      return await pending;
    }
    const cachePath = this.readerImageCachePath(page, sourceUrl);
    const promise = this.downloadReaderImageToCache(page, sourceUrl, key, cachePath);
    this.readerImageInFlight.set(key, promise);
    try {
      return await promise;
    } finally {
      if (this.readerImageInFlight.get(key) === promise) {
        this.readerImageInFlight.delete(key);
      }
    }
  }

  private readerPageIndexFromPageUrl(pageUrl: string): number {
    if (pageUrl.length === 0) {
      return -1;
    }
    if (this.nativeReaderPage.pageUrl === pageUrl && this.nativeReaderPage.pageIndex >= 0) {
      return this.nativeReaderPage.pageIndex;
    }
    const cachedPage = this.readerPageCache.get(pageUrl);
    if (cachedPage) {
      return cachedPage.pageIndex;
    }
    const preview = this.previewItemForPageUrl(pageUrl);
    if (preview) {
      return preview.position;
    }
    return this.parseReaderPagePosition(pageUrl);
  }

  private collectReaderPreloadPageIndexes(currentPageUrl: string): number[] {
    const indexes: number[] = [];
    const total = this.readerTotalPageCount();
    const currentPageIndex = this.readerPageIndexFromPageUrl(currentPageUrl);
    if (currentPageIndex < 0) {
      return indexes;
    }
    const pushIndex = (pageIndex: number): void => {
      if (pageIndex >= 0 && pageIndex < total && indexes.indexOf(pageIndex) < 0) {
        indexes.push(pageIndex);
      }
    };
    pushIndex(currentPageIndex);
    for (let offset = 1; offset <= READER_PRELOAD_SIDE_COUNT; offset++) {
      pushIndex(currentPageIndex + offset);
      pushIndex(currentPageIndex - offset);
    }
    return indexes;
  }

  private enqueueReaderHtmlPrefetch(task: ReaderPrefetchTask): void {
    if (task.pageUrl.length === 0) {
      return;
    }
    if (this.readerPageCache.has(task.pageUrl)) {
      const page = this.readerPageCache.get(task.pageUrl);
      if (page) {
        this.enqueueReaderImagePrefetch({
          page,
          priority: task.priority,
          generation: task.generation
        });
      }
      return;
    }
    if (this.readerHtmlPrefetchQueue.some((item: ReaderPrefetchTask) => item.pageUrl === task.pageUrl)) {
      return;
    }
    this.readerHtmlPrefetchQueue.push(task);
    this.readerHtmlPrefetchQueue.sort((left: ReaderPrefetchTask, right: ReaderPrefetchTask) => left.priority - right.priority);
    this.processReaderHtmlPrefetchQueue();
  }

  private enqueueReaderImagePrefetch(task: ReaderImagePrefetchTask): void {
    if (this.readerExistingCachedImageUri(task.page).length > 0) {
      return;
    }
    const key = this.readerImageCacheKey(task.page);
    if (this.readerImageInFlight.has(key)) {
      return;
    }
    if (this.readerImagePrefetchQueue.some((item: ReaderImagePrefetchTask) => this.readerImageCacheKey(item.page) === key)) {
      return;
    }
    this.readerImagePrefetchQueue.push(task);
    this.readerImagePrefetchQueue.sort((left: ReaderImagePrefetchTask, right: ReaderImagePrefetchTask) => left.priority - right.priority);
    this.processReaderImagePrefetchQueue();
  }

  private processReaderHtmlPrefetchQueue(): void {
    while (this.readerHtmlPrefetchActiveCount < READER_HTML_PREFETCH_CONCURRENCY && this.readerHtmlPrefetchQueue.length > 0) {
      const task = this.readerHtmlPrefetchQueue.shift();
      if (!task || task.generation !== this.readerPrefetchGeneration) {
        continue;
      }
      this.readerHtmlPrefetchActiveCount++;
      void this.runReaderHtmlPrefetchTask(task);
    }
  }

  private async runReaderHtmlPrefetchTask(task: ReaderPrefetchTask): Promise<void> {
    try {
      const page = await this.ensureReaderPagePrepared(task.pageUrl);
      if (task.generation === this.readerPrefetchGeneration) {
        this.enqueueReaderImagePrefetch({
          page,
          priority: task.priority,
          generation: task.generation
        });
      }
    } catch (error) {
      if (task.pageUrl === this.nativeReaderPage.pageUrl) {
        this.readerCurrentError = this.readableErrorMessage(error, '当前阅读页预载失败');
      }
    } finally {
      this.readerHtmlPrefetchActiveCount = Math.max(0, this.readerHtmlPrefetchActiveCount - 1);
      this.processReaderHtmlPrefetchQueue();
    }
  }

  private processReaderImagePrefetchQueue(): void {
    while (this.readerImagePrefetchActiveCount < READER_IMAGE_PREFETCH_CONCURRENCY && this.readerImagePrefetchQueue.length > 0) {
      const task = this.readerImagePrefetchQueue.shift();
      if (!task || task.generation !== this.readerPrefetchGeneration) {
        continue;
      }
      this.readerImagePrefetchActiveCount++;
      void this.runReaderImagePrefetchTask(task);
    }
  }

  private async runReaderImagePrefetchTask(task: ReaderImagePrefetchTask): Promise<void> {
    try {
      const localUri = await this.ensureReaderImageCached(task.page);
      if (task.page.pageUrl === this.nativeReaderPage.pageUrl && localUri.length > 0) {
        this.readerDisplayImageUrl = localUri;
        this.readerCurrentError = '';
      }
      if (localUri.length > 0) {
        if (task.page.pageUrl === this.readerPreviousAdjacent.pageUrl) {
          this.updateReaderAdjacentDisplay(-1, task.page.pageUrl, localUri);
        }
        if (task.page.pageUrl === this.readerNextAdjacent.pageUrl) {
          this.updateReaderAdjacentDisplay(1, task.page.pageUrl, localUri);
        }
      }
      if (task.generation === this.readerPrefetchGeneration) {
        this.readerCacheStatus = `已缓存第 ${task.page.pageIndex + 1} 页`;
      }
    } catch (error) {
      if (task.page.pageUrl === this.nativeReaderPage.pageUrl && this.readerDisplayImageUrl.length === 0) {
        this.readerCurrentError = this.readableErrorMessage(error, '当前图片缓存失败');
      }
    } finally {
      this.readerImagePrefetchActiveCount = Math.max(0, this.readerImagePrefetchActiveCount - 1);
      this.processReaderImagePrefetchQueue();
    }
  }

  private scheduleReaderPreloadWindow(currentPageUrl: string): void {
    if (this.nativeViewMode !== 'reader' || currentPageUrl.length === 0) {
      return;
    }
    const pageIndexes = this.collectReaderPreloadPageIndexes(currentPageUrl);
    const generation = this.readerPrefetchGeneration + 1;
    this.readerPrefetchGeneration = generation;
    this.readerHtmlPrefetchQueue = [];
    this.readerImagePrefetchQueue = [];
    if (pageIndexes.length === 0) {
      this.readerCacheStatus = '预载空闲';
      return;
    }
    this.readerCacheStatus = `正在预载前后 ${READER_PRELOAD_SIDE_COUNT} 页`;
    for (let index = 0; index < pageIndexes.length; index++) {
      this.enqueueReaderPreloadPageIndex(pageIndexes[index], index, generation);
    }
  }

  private enqueueReaderPreloadPageIndex(pageIndex: number, priority: number, generation: number): void {
    void this.resolveReaderPageUrlByIndex(pageIndex).then((pageUrl: string) => {
      if (generation !== this.readerPrefetchGeneration || pageUrl.length === 0) {
        return;
      }
      this.enqueueReaderHtmlPrefetch({
        pageUrl,
        priority,
        generation
      });
    }).catch((error: Object) => {
      if (generation !== this.readerPrefetchGeneration || pageIndex !== this.nativeReaderPage.pageIndex) {
        return;
      }
      if (this.readerDisplayImageUrl.length === 0) {
        this.readerCurrentError = this.readableErrorMessage(error, '当前图片预载失败');
      }
    });
  }

  private readerCacheSummaryText(): string {
    const mode = this.readerUseOriginImage ? '原图' : '压缩图';
    return `${mode}缓存 · 前后 ${READER_PRELOAD_SIDE_COUNT} 页 · ${this.readerCacheStatus}`;
  }

  private adjustReaderPreloadImageCount(delta: number): void {
    this.readerPreloadImageCount = clampNumber(this.readerPreloadImageCount + delta, 0, READER_MAX_PRELOAD_IMAGE);
    this.writeValue(READER_KEY_PRELOAD_IMAGE, this.readerPreloadImageCount);
    if (this.nativeViewMode === 'reader') {
      this.scheduleReaderPreloadWindow(this.nativeReaderPage.pageUrl);
    }
  }

  private toggleReaderOriginImage(): void {
    this.readerUseOriginImage = this.toggleReaderBoolean(READER_KEY_DOWNLOAD_ORIGIN_IMAGE, this.readerUseOriginImage);
    if (this.nativeViewMode === 'reader') {
      this.readerDisplayImageUrl = this.readerDisplayUrlForPage(this.nativeReaderPage);
      this.refreshReaderAdjacentPages();
      this.rebuildReaderPageDataSource(true);
      this.scheduleReaderPreloadWindow(this.nativeReaderPage.pageUrl);
    }
  }

  private removePathRecursive(path: string): void {
    if (path.length === 0) {
      return;
    }
    try {
      if (!fileIo.accessSync(path)) {
        return;
      }
      const stat = fileIo.statSync(path);
      if (stat.isDirectory()) {
        const names = fileIo.listFileSync(path);
        for (const name of names) {
          this.removePathRecursive(`${path}/${name}`);
        }
        fileIo.rmdirSync(path);
      } else {
        fileIo.unlinkSync(path);
      }
    } catch (error) {
    }
  }

  private cacheFileModifiedAtMs(stat: fileIo.Stat): number {
    return stat.mtime > 100000000000 ? stat.mtime : stat.mtime * 1000;
  }

  private formatCacheSize(bytes: number): string {
    if (bytes >= 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
    }
    if (bytes >= 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    }
    if (bytes >= 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    }
    return `${bytes} B`;
  }

  private collectCacheFilesFromPath(path: string, category: string, result: CacheFileEntry[]): void {
    if (path.length === 0) {
      return;
    }
    try {
      if (!fileIo.accessSync(path)) {
        return;
      }
      const stat = fileIo.statSync(path);
      if (stat.isDirectory()) {
        const names = fileIo.listFileSync(path);
        for (const name of names) {
          this.collectCacheFilesFromPath(`${path}/${name}`, category, result);
        }
      } else {
        result.push({
          path,
          size: Math.max(0, stat.size),
          modifiedAt: this.cacheFileModifiedAtMs(stat),
          category
        });
      }
    } catch (error) {
    }
  }

  private collectImageSearchCacheFiles(result: CacheFileEntry[]): void {
    const filesDir = this.abilityFilesDir();
    if (filesDir.length === 0) {
      return;
    }
    try {
      const names = fileIo.listFileSync(filesDir);
      for (const name of names) {
        if (name.startsWith('image-search-')) {
          this.collectCacheFilesFromPath(`${filesDir}/${name}`, CACHE_CATEGORY_IMAGE_SEARCH, result);
        }
      }
    } catch (error) {
    }
  }

  private collectManagedCacheFiles(category: string = ''): CacheFileEntry[] {
    const result: CacheFileEntry[] = [];
    if (category.length === 0 || category === CACHE_CATEGORY_READER) {
      this.collectCacheFilesFromPath(this.readerCacheRoot(), CACHE_CATEGORY_READER, result);
    }
    if (category.length === 0 || category === CACHE_CATEGORY_GALLERY) {
      this.collectCacheFilesFromPath(this.galleryImageCacheRoot(), CACHE_CATEGORY_GALLERY, result);
    }
    if (category.length === 0 || category === CACHE_CATEGORY_IMAGE_SEARCH) {
      this.collectImageSearchCacheFiles(result);
    }
    return result;
  }

  private cacheFilesSize(files: CacheFileEntry[]): number {
    let total = 0;
    for (const file of files) {
      total += file.size;
    }
    return total;
  }

  private removeCacheFile(file: CacheFileEntry): boolean {
    try {
      if (fileIo.accessSync(file.path)) {
        fileIo.unlinkSync(file.path);
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  private removeEmptyCacheDirectories(path: string): void {
    if (path.length === 0) {
      return;
    }
    try {
      if (!fileIo.accessSync(path)) {
        return;
      }
      const stat = fileIo.statSync(path);
      if (!stat.isDirectory()) {
        return;
      }
      const names = fileIo.listFileSync(path);
      for (const name of names) {
        this.removeEmptyCacheDirectories(`${path}/${name}`);
      }
      if (fileIo.listFileSync(path).length === 0) {
        fileIo.rmdirSync(path);
      }
    } catch (error) {
    }
  }

  private removeEmptyManagedCacheDirectories(category: string = ''): void {
    if (category.length === 0 || category === CACHE_CATEGORY_READER) {
      this.removeEmptyCacheDirectories(this.readerCacheRoot());
    }
    if (category.length === 0 || category === CACHE_CATEGORY_GALLERY) {
      this.removeEmptyCacheDirectories(this.galleryImageCacheRoot());
    }
    if (category.length === 0 || category === CACHE_CATEGORY_IMAGE_SEARCH) {
      const filesDir = this.abilityFilesDir();
      if (filesDir.length > 0) {
        try {
          const names = fileIo.listFileSync(filesDir);
          for (const name of names) {
            if (name.startsWith('image-search-')) {
              this.removeEmptyCacheDirectories(`${filesDir}/${name}`);
            }
          }
        } catch (error) {
        }
      }
    }
  }

  private refreshCacheMemoryAfterCleanup(category: string = ''): void {
    if (category.length === 0 || category === CACHE_CATEGORY_READER) {
      this.readerPageCache.clear();
      this.readerPageInFlight.clear();
      this.readerPageRetrySkipKeys.clear();
      this.readerImageInFlight.clear();
      const removedKeys: string[] = [];
      this.readerImageCache.forEach((entry: ReaderImageCacheEntry, key: string) => {
        try {
          if (!fileIo.accessSync(entry.localPath)) {
            removedKeys.push(key);
          }
        } catch (error) {
          removedKeys.push(key);
        }
      });
      for (const key of removedKeys) {
        this.readerImageCache.delete(key);
      }
      if (this.nativeReaderPage.pageUrl.length > 0) {
        this.readerDisplayImageUrl = this.readerSelectedImageUrl(this.nativeReaderPage);
        this.rebuildReaderPageDataSource(true);
      }
    }
    if (category.length === 0 || category === CACHE_CATEGORY_GALLERY) {
      this.galleryImageInFlight.clear();
      const removedKeys: string[] = [];
      this.galleryImageCache.forEach((entry: GalleryImageCacheEntry, key: string) => {
        try {
          if (!fileIo.accessSync(entry.localPath)) {
            removedKeys.push(key);
          }
        } catch (error) {
          removedKeys.push(key);
        }
      });
      for (const key of removedKeys) {
        this.galleryImageCache.delete(key);
      }
      if (removedKeys.length > 0 || category === CACHE_CATEGORY_GALLERY || category.length === 0) {
        this.galleryImageCacheVersion++;
      }
    }
    if ((category.length === 0 || category === CACHE_CATEGORY_IMAGE_SEARCH) &&
      this.imageSearchPath.startsWith(`${this.abilityFilesDir()}/image-search-`)) {
      try {
        if (!fileIo.accessSync(this.imageSearchPath)) {
          this.imageSearchPath = '';
        }
      } catch (error) {
        this.imageSearchPath = '';
      }
    }
  }

  private emptyCacheCleanupResult(scannedBytes: number = 0): CacheCleanupResult {
    return {
      scannedBytes,
      removedBytes: 0,
      removedFiles: 0
    };
  }

  private clearManagedCacheCategory(category: string, label: string): void {
    const files = this.collectManagedCacheFiles(category);
    const result = this.emptyCacheCleanupResult(this.cacheFilesSize(files));
    for (const file of files) {
      if (this.removeCacheFile(file)) {
        result.removedFiles++;
        result.removedBytes += file.size;
      }
    }
    this.removeEmptyManagedCacheDirectories(category);
    this.refreshCacheMemoryAfterCleanup(category);
    this.cacheMaintenanceStatus = `${label}已清理 ${this.formatCacheSize(result.removedBytes)}`;
    this.readerCacheStatus = this.cacheMaintenanceStatus;
    this.toast(this.cacheMaintenanceStatus);
  }

  private scheduleCacheMaintenance(force: boolean = false): void {
    const now = Date.now();
    if (!force && now - this.lastCacheMaintenanceAt < 60000) {
      return;
    }
    if (this.cacheMaintenanceTimerId >= 0) {
      return;
    }
    const handle = setTimeout(() => {
      this.cacheMaintenanceTimerId = -1;
      this.runCachePolicyCleanup(false);
    }, force ? 0 : 1200);
    this.cacheMaintenanceTimerId = Number(handle);
  }

  private runCachePolicyCleanup(showToast: boolean): void {
    if (this.cacheMaintenanceRunning) {
      return;
    }
    this.cacheMaintenanceRunning = true;
    try {
      const startedFiles = this.collectManagedCacheFiles();
      const startedBytes = this.cacheFilesSize(startedFiles);
      const result = this.emptyCacheCleanupResult(startedBytes);
      const expireBefore = Date.now() - this.cacheRetentionDays * 24 * 60 * 60 * 1000;
      for (const file of startedFiles) {
        if (file.modifiedAt < expireBefore && this.removeCacheFile(file)) {
          result.removedFiles++;
          result.removedBytes += file.size;
        }
      }

      let remainingFiles = this.collectManagedCacheFiles();
      let remainingBytes = this.cacheFilesSize(remainingFiles);
      const maxBytes = this.cacheMaxSizeMb * 1024 * 1024;
      if (remainingBytes > maxBytes) {
        remainingFiles = remainingFiles.sort((left: CacheFileEntry, right: CacheFileEntry) => left.modifiedAt - right.modifiedAt);
        for (const file of remainingFiles) {
          if (remainingBytes <= maxBytes) {
            break;
          }
          if (this.removeCacheFile(file)) {
            result.removedFiles++;
            result.removedBytes += file.size;
            remainingBytes -= file.size;
          }
        }
      }

      this.removeEmptyManagedCacheDirectories();
      this.refreshCacheMemoryAfterCleanup();
      const finalBytes = this.cacheFilesSize(this.collectManagedCacheFiles());
      this.cacheMaintenanceStatus =
        `缓存 ${this.formatCacheSize(finalBytes)} / ${this.cacheMaxSizeMb} MB，保留 ${this.cacheRetentionDays} 天，清理 ${this.formatCacheSize(result.removedBytes)}`;
      this.readerCacheStatus = this.cacheMaintenanceStatus;
      this.lastCacheMaintenanceAt = Date.now();
      if (showToast) {
        this.toast(this.cacheMaintenanceStatus);
      }
    } finally {
      this.cacheMaintenanceRunning = false;
    }
  }

  private clearCurrentReaderCache(): void {
    const dir = this.readerGalleryCacheDir();
    this.readerImageCache.clear();
    this.readerPageCache.clear();
    this.readerImageInFlight.clear();
    this.readerPageInFlight.clear();
    this.readerPageRetrySkipKeys.clear();
    this.readerHtmlPrefetchQueue = [];
    this.readerImagePrefetchQueue = [];
    this.readerPrefetchGeneration++;
    this.removePathRecursive(dir);
    if (this.nativeReaderPage.pageUrl.length > 0) {
      this.readerDisplayImageUrl = this.readerSelectedImageUrl(this.nativeReaderPage);
    }
    this.rebuildReaderPageDataSource(true);
    this.readerCacheStatus = '阅读器缓存已清理';
    this.toast('阅读器缓存已清理');
  }

  private clearImageSearchTempFiles(): void {
    const filesDir = this.abilityFilesDir();
    if (filesDir.length === 0) {
      return;
    }
    try {
      const names = fileIo.listFileSync(filesDir);
      for (const name of names) {
        if (name.startsWith('image-search-')) {
          this.removePathRecursive(`${filesDir}/${name}`);
        }
      }
    } catch (error) {
    }
  }

  private clearReaderCaches(): void {
    this.cancelReaderPrefetchWindow();
    this.clearManagedCacheCategory(CACHE_CATEGORY_READER, '阅读器缓存');
  }

  private clearGalleryImageCaches(): void {
    this.clearManagedCacheCategory(CACHE_CATEGORY_GALLERY, '图库图片缓存');
  }

  private clearImageSearchCaches(): void {
    this.clearManagedCacheCategory(CACHE_CATEGORY_IMAGE_SEARCH, '图片搜索临时文件');
  }

  private clearAllCaches(): void {
    this.cancelReaderPrefetchWindow();
    this.clearManagedCacheCategory('', '全部缓存');
  }

  private retryCurrentReaderPage(): void {
    if (this.nativeReaderPage.pageUrl.length === 0 || this.nativeLoading) {
      return;
    }
    this.readerCurrentError = '';
    this.markReaderPageForRetryRefresh(this.nativeReaderPage.pageUrl);
    void this.loadNativeReaderByPageUrl(this.nativeReaderPage.pageUrl);
  }

  private readableErrorMessage(error: Object | string | undefined, fallback: string): string {
    const raw = `${error}`.replace('Error: ', '').trim();
    const lower = raw.toLowerCase();
    if (raw.length > 0 &&
      lower !== 'undefined' &&
      lower !== 'null' &&
      lower !== 'object' &&
      lower !== 'object object' &&
      lower !== '[object object]') {
      return raw;
    }
    if (error !== undefined && typeof error === 'object') {
      const detail = error as NativeReadableErrorInfo;
      const parts: string[] = [];
      const code = `${detail.code}`.trim();
      const message = `${detail.message}`.replace('Error: ', '').trim();
      const data = `${detail.data}`.trim();
      const name = `${detail.name}`.trim();
      const codeLower = code.toLowerCase();
      const messageLower = message.toLowerCase();
      const dataLower = data.toLowerCase();
      const nameLower = name.toLowerCase();
      if (code.length > 0 && codeLower !== 'undefined' && codeLower !== 'null') {
        parts.push(`code=${code}`);
      }
      if (message.length > 0 &&
        messageLower !== 'undefined' &&
        messageLower !== 'null' &&
        messageLower !== '[object object]') {
        parts.push(message);
      }
      if (data.length > 0 && dataLower !== 'undefined' && dataLower !== 'null') {
        parts.push(data);
      }
      if (name.length > 0 && nameLower !== 'undefined' && nameLower !== 'null') {
        parts.push(name);
      }
      if (parts.length > 0) {
        return parts.join(' ');
      }
    }
    if (raw.length === 0 ||
      lower === 'undefined' ||
      lower === 'null' ||
      lower === 'object' ||
      lower === 'object object' ||
      lower === '[object object]') {
      return fallback;
    }
    return raw;
  }

  private toast(message: string): void {
    const options: promptAction.ShowToastOptions = {
      message,
      duration: 1800
    };
    try {
      this.getUIContext().getPromptAction().showToast(options);
    } catch (error) {
    }
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

  private fetchCookie(url: string): string {
    try {
      return webview.WebCookieManager.fetchCookieSync(url, false);
    } catch (error) {
      return '';
    }
  }

  private async fetchCookieAsync(url: string): Promise<string> {
    try {
      return await webview.WebCookieManager.fetchCookie(url, false);
    } catch (error) {
      return this.fetchCookie(url);
    }
  }

  private normalizeJavaScriptString(value: string): string {
    const trimmed = value.trim();
    if (trimmed.length === 0 || trimmed === 'null' || trimmed === 'undefined') {
      return '';
    }
    if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
      try {
        return JSON.parse(trimmed) as string;
      } catch (error) {
        return trimmed.substring(1, trimmed.length - 1);
      }
    }
    return trimmed;
  }

  private async fetchDocumentCookie(): Promise<string> {
    try {
      const result = await this.controller.runJavaScript('document.cookie');
      return this.normalizeJavaScriptString(result);
    } catch (error) {
      return '';
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  private splitCookiePieces(raw: string): string[] {
    return raw
      .split(/[\n;]+/)
      .map((item: string) => item.trim())
      .map((item: string) => this.normalizeCookiePiece(item))
      .filter((item: string) => {
        if (!item.includes('=')) {
          return false;
        }
        const name = this.cookiePieceName(item).toLowerCase();
        return !this.isCookieAttributeName(name) && !this.isVolatileCookieName(name) &&
          this.cookiePieceValue(item).length > 0;
      });
  }

  private normalizeCookiePiece(item: string): string {
    const equalsIndex = item.indexOf('=');
    if (equalsIndex > 0) {
      return item;
    }
    const colonIndex = item.indexOf(':');
    if (colonIndex <= 0) {
      return item;
    }
    const name = item.substring(0, colonIndex).trim();
    const value = item.substring(colonIndex + 1).trim();
    if (name.length === 0 || value.length === 0) {
      return item;
    }
    return `${name}=${value}`;
  }

  private isCookieAttributeName(name: string): boolean {
    return name === 'domain' || name === 'path' || name === 'expires' || name === 'max-age' ||
      name === 'samesite' || name === 'secure' || name === 'httponly';
  }

  private isVolatileCookieName(name: string): boolean {
    return name === 'cf_clearance' || name === '_cfuvid' || name === '__cf_bm' ||
      name.startsWith('__cf') || name.startsWith('cf_chl');
  }

  private cookiePieceValue(piece: string): string {
    const splitIndex = piece.indexOf('=');
    return splitIndex >= 0 ? piece.substring(splitIndex + 1).trim() : '';
  }

  private isUsableIgneousValue(value: string): boolean {
    const normalized = value.trim().toLowerCase();
    return normalized.length > 0 && normalized !== 'mystery' && normalized !== 'deleted' &&
      normalized !== 'delete' && normalized !== 'null' && normalized !== 'undefined' &&
      normalized !== 'none' && normalized !== '0';
  }

  private containsCookiePiece(cookieValue: string, name: string, requireUsableIgneous: boolean = false): boolean {
    const pieces = this.splitCookiePieces(cookieValue);
    for (const piece of pieces) {
      if (this.cookiePieceName(piece) !== name) {
        continue;
      }
      const value = this.cookiePieceValue(piece);
      if (requireUsableIgneous) {
        return this.isUsableIgneousValue(value);
      }
      return value.length > 0;
    }
    return false;
  }

  private containsAuthCookie(cookieValue: string): boolean {
    return this.containsCookiePiece(cookieValue, 'ipb_member_id') &&
      this.containsCookiePiece(cookieValue, 'ipb_pass_hash');
  }

  private containsExCookie(cookieValue: string): boolean {
    return this.containsCookiePiece(cookieValue, 'igneous', true);
  }

  private hasAvailableCookie(): boolean {
    return this.hasSignInCookie || this.hasExCookie;
  }

  private hasCurrentSiteCredential(): boolean {
    return this.siteMode === GallerySite.EX ? this.hasExCookie : this.hasAvailableCookie();
  }

  private shouldShowLoginGateOnLaunch(hasPrimedRoute: boolean): boolean {
    if (hasPrimedRoute || this.hasCurrentSiteCredential()) {
      return false;
    }
    if (this.siteMode === GallerySite.EX) {
      return true;
    }
    return !this.readBoolean(LOGIN_GATE_SEEN_KEY, false);
  }

  private markLoginGateSeen(): void {
    this.writeValue(LOGIN_GATE_SEEN_KEY, true);
  }

  private refreshSiteCookieState(): void {
    const webCookies = this.collectWebCookies('');
    const stableCookies = this.mergeCookiePieces(this.splitCookiePieces(this.cookieDraft), webCookies).join('; ');
    NativeEhClient.configureCookieHeader(stableCookies);
    this.hasSignInCookie = this.containsAuthCookie(stableCookies);
    this.hasExCookie = this.containsExCookie(stableCookies);

    if (this.hasExCookie) {
      this.cookieStatusSummary = 'EXHentai Cookie 已就绪';
    } else if (this.hasSignInCookie) {
      this.cookieStatusSummary = '已登录，等待 EX Cookie';
    } else {
      this.cookieStatusSummary = '未检测到登录 Cookie';
    }

    if (this.hasCurrentSiteCredential()) {
      this.loginGateVisible = false;
    }
  }

  private appendCookiePiece(piece: string, names: string[], values: string[]): void {
    const splitIndex = piece.indexOf('=');
    const name = splitIndex > 0 ? piece.substring(0, splitIndex).trim() : '';
    const value = splitIndex >= 0 ? piece.substring(splitIndex + 1).trim() : '';
    const lowerName = name.toLowerCase();
    if (name.length === 0 || value.length === 0 || this.isCookieAttributeName(lowerName) ||
      this.isVolatileCookieName(lowerName)) {
      return;
    }
    if (name === 'igneous' && !this.isUsableIgneousValue(value)) {
      return;
    }
    const existingIndex = names.indexOf(name);
    if (existingIndex >= 0) {
      const existingValue = this.cookiePieceValue(values[existingIndex]);
      if (name === 'igneous' && this.isUsableIgneousValue(existingValue) && !this.isUsableIgneousValue(value)) {
        return;
      }
      values[existingIndex] = `${name}=${value}`;
    } else {
      names.push(name);
      values.push(`${name}=${value}`);
    }
  }

  private appendCookiePieces(cookieValue: string, names: string[], values: string[]): void {
    const pieces = cookieValue
      .split(';')
      .map((item: string) => item.trim())
      .filter((item: string) => item.includes('='));
    for (const piece of pieces) {
      this.appendCookiePiece(piece, names, values);
    }
  }

  private mergeCookiePieces(basePieces: string[], incomingPieces: string[]): string[] {
    const names: string[] = [];
    const values: string[] = [];
    for (const piece of basePieces) {
      this.appendCookiePiece(piece, names, values);
    }
    for (const piece of incomingPieces) {
      this.appendCookiePiece(piece, names, values);
    }
    return values;
  }

  private collectWebCookies(currentUrl: string): string[] {
    const names: string[] = [];
    const values: string[] = [];
    this.appendCookiePieces(this.fetchCookie(EhUrl.DOMAIN_FORUMS), names, values);
    if (currentUrl.length > 0) {
      this.appendCookiePieces(this.fetchCookie(currentUrl), names, values);
    }
    this.appendCookiePieces(this.fetchCookie(EhUrl.DOMAIN_E), names, values);
    this.appendCookiePieces(this.fetchCookie(EhUrl.DOMAIN_EX), names, values);
    return values;
  }

  private async collectWebCookiesAsync(currentUrl: string): Promise<string[]> {
    const names: string[] = [];
    const values: string[] = [];
    this.appendCookiePieces(await this.fetchCookieAsync(EhUrl.DOMAIN_FORUMS), names, values);
    if (currentUrl.length > 0) {
      this.appendCookiePieces(await this.fetchCookieAsync(currentUrl), names, values);
      this.appendCookiePieces(await this.fetchDocumentCookie(), names, values);
    }
    this.appendCookiePieces(await this.fetchCookieAsync(EhUrl.DOMAIN_E), names, values);
    this.appendCookiePieces(await this.fetchCookieAsync(EhUrl.DOMAIN_EX), names, values);
    return values;
  }

  private shouldRestoreCookieDraft(): boolean {
    const draftCookieHeader = this.splitCookiePieces(this.cookieDraft).join('; ');
    return this.containsAuthCookie(draftCookieHeader) || this.containsExCookie(draftCookieHeader);
  }

  private restoreCookieDraftToWeb(): void {
    const pieces = this.splitCookiePieces(this.cookieDraft);
    if (pieces.length === 0 || !this.shouldRestoreCookieDraft()) {
      return;
    }
    this.persistCookiesToTargets(pieces);
    NativeEhClient.configureCookieHeader(pieces.join('; '));
  }

  private cookieDomainForTarget(target: string): string {
    if (target.indexOf('forums.e-hentai.org') >= 0) {
      return 'forums.e-hentai.org';
    }
    return target.indexOf('exhentai.org') >= 0 ? 'exhentai.org' : 'e-hentai.org';
  }

  private persistentCookiePiece(target: string, piece: string): string {
    const segments = piece.split(';');
    const firstSegment = segments.length > 0 ? segments[0].trim() : '';
    if (firstSegment.length === 0 || firstSegment.indexOf('=') <= 0) {
      return '';
    }
    return `${firstSegment}; Domain=${this.cookieDomainForTarget(target)}; Path=/; Max-Age=${COOKIE_PERSIST_MAX_AGE_SECONDS}; Secure`;
  }

  private persistCookiesToTargets(pieces: string[]): void {
    if (pieces.length === 0) {
      return;
    }
    try {
      for (const target of EhUrl.cookieTargets()) {
        for (const piece of pieces) {
          const persistentPiece = this.persistentCookiePiece(target, piece);
          if (persistentPiece.length === 0) {
            continue;
          }
          try {
            webview.WebCookieManager.configCookieSync(target, persistentPiece, false, true);
          } catch (httpOnlyError) {
            webview.WebCookieManager.configCookieSync(target, persistentPiece, false);
          }
        }
      }
      webview.WebCookieManager.saveCookieSync();
    } catch (error) {
    }
  }

  private saveWebCookies(): void {
    try {
      webview.WebCookieManager.saveCookieSync();
    } catch (error) {
    }
  }

  private clearWebCookieStore(): void {
    try {
      webview.WebCookieManager.clearAllCookiesSync(false);
      webview.WebCookieManager.saveCookieSync();
    } catch (error) {
    }
  }

  private expiredCookiePiece(target: string, name: string): string {
    return `${name}=; Domain=${this.cookieDomainForTarget(target)}; Path=/; Max-Age=0; ` +
      'Expires=Thu, 01 Jan 1970 00:00:00 GMT; Secure';
  }

  private clearWebSignInAuthCookies(): void {
    try {
      for (const target of EhUrl.cookieTargets()) {
        for (const name of WEB_SIGN_IN_RESET_COOKIE_NAMES) {
          const expiredPiece = this.expiredCookiePiece(target, name);
          try {
            webview.WebCookieManager.configCookieSync(target, expiredPiece, false, true);
          } catch (httpOnlyError) {
            try {
              webview.WebCookieManager.configCookieSync(target, expiredPiece, false);
            } catch (error) {
            }
          }
        }
      }
      webview.WebCookieManager.saveCookieSync();
    } catch (error) {
    }
  }

  private async clearWebSignInHostOverrides(): Promise<void> {
    for (const host of WEB_SIGN_IN_CLOUDFLARE_HOSTS) {
      try {
        webview.WebviewController.clearHostIP(host);
      } catch (error) {
      }
      try {
        await connection.removeCustomDnsRule(host);
      } catch (error) {
      }
    }
  }

  private cookiePieceName(piece: string): string {
    const splitIndex = piece.indexOf('=');
    return splitIndex > 0 ? piece.substring(0, splitIndex).trim() : '';
  }

  private persistWebCookiesToAllTargets(pieces: string[]): void {
    this.persistCookiesToTargets(pieces);
  }

  private navigateFullScreenWeb(url: string, title: string): void {
    const nextUrl = this.normalizeUrl(url);
    this.fullScreenWebUrl = nextUrl;
    this.fullScreenWebTitle = title;
    try {
      this.controller.loadUrl(nextUrl);
    } catch (error) {
    }
  }

  private isCloudflareChallengeState(url: string): boolean {
    const lowerUrl = url.toLowerCase();
    const lowerTitle = this.pageTitle.toLowerCase();
    return lowerUrl.indexOf('__cf_chl') >= 0 ||
      lowerUrl.indexOf('challenge-platform') >= 0 ||
      lowerUrl.indexOf('/cdn-cgi/challenge-platform/') >= 0 ||
      lowerTitle.indexOf('just a moment') >= 0 ||
      lowerTitle.indexOf('cloudflare') >= 0 ||
      lowerTitle.indexOf('verify you are human') >= 0 ||
      lowerTitle.indexOf('checking your browser') >= 0;
  }

  private async prepareWebSignIn(): Promise<void> {
    this.signInSyncSerial++;
    this.signInForumProbeStarted = false;
    this.signInExProbeStarted = false;
    this.signInExPendingNotified = false;
    this.pageTitle = '';
    try {
      webview.WebCookieManager.putAcceptCookieEnabled(true);
      webview.WebCookieManager.putAcceptThirdPartyCookieEnabled(true);
    } catch (error) {
    }
    await this.clearWebSignInHostOverrides();
    this.clearWebSignInAuthCookies();
    this.cookieDraft = '';
    this.writeValue('cookie_draft', '');
    NativeEhClient.configureCookieHeader('');
    this.refreshSiteCookieState();
    this.resetNativeState();
  }

  private syncCookiesFromWeb(url: string, closeOnSuccess: boolean): void {
    const serial = this.signInSyncSerial;
    void this.syncCookiesFromWebAsync(url, closeOnSuccess, 0, serial);
  }

  private async syncCookiesFromWebAsync(
    url: string,
    closeOnSuccess: boolean,
    retryAttempt: number,
    serial: number
  ): Promise<void> {
    if (closeOnSuccess && (serial !== this.signInSyncSerial || this.fullScreenWebMode !== WEB_MODE_SIGN_IN)) {
      return;
    }
    this.saveWebCookies();
    const webPieces = closeOnSuccess ? await this.collectWebCookiesAsync(url) : this.collectWebCookies(url);
    const basePieces = closeOnSuccess ? [] : this.splitCookiePieces(this.cookieDraft);
    const pieces = this.mergeCookiePieces(basePieces, webPieces);
    this.persistWebCookiesToAllTargets(pieces);
    this.saveWebCookies();
    const cookieHeader = pieces.join('; ');
    this.cookieDraft = cookieHeader;
    this.writeValue('cookie_draft', cookieHeader);
    NativeEhClient.configureCookieHeader(cookieHeader);
    this.refreshSiteCookieState();
    const signedIn = this.containsAuthCookie(cookieHeader);
    const exReady = this.containsExCookie(cookieHeader);
    if (closeOnSuccess && !signedIn && !exReady && !this.isCloudflareChallengeState(url) &&
      retryAttempt < SIGN_IN_COOKIE_RETRY_DELAYS.length) {
      await this.delay(SIGN_IN_COOKIE_RETRY_DELAYS[retryAttempt]);
      await this.syncCookiesFromWebAsync(url, closeOnSuccess, retryAttempt + 1, serial);
      return;
    }
    if (closeOnSuccess && signedIn && !this.signInForumProbeStarted && !this.isCloudflareChallengeState(url)) {
      this.signInForumProbeStarted = true;
      this.navigateFullScreenWeb(EhUrl.DOMAIN_FORUMS, '同步论坛登录');
      return;
    }
    if (closeOnSuccess && signedIn && !exReady && !this.signInExProbeStarted && !this.isCloudflareChallengeState(url)) {
      this.signInExProbeStarted = true;
      this.navigateFullScreenWeb(EhUrl.galleryFront(GallerySite.EX), '同步 EX Cookie');
      return;
    }
    if (closeOnSuccess && signedIn && !exReady && this.signInExProbeStarted) {
      if (!this.signInExPendingNotified && !this.isCloudflareChallengeState(url)) {
        this.signInExPendingNotified = true;
        this.toast('EX Cookie 未同步，请留在当前 EX 页面完成验证');
      }
      return;
    }
    if (closeOnSuccess && (signedIn || exReady) && !this.isCloudflareChallengeState(url)) {
      if (!exReady && this.siteMode === GallerySite.EX) {
        this.siteMode = GallerySite.E;
        this.writeValue('site_mode', GallerySite.E);
      }
      this.toast(exReady ? '网页登录成功，Cookie 已同步' : '网页登录成功，EX Cookie 未同步');
      this.signInForumProbeStarted = false;
      this.signInExProbeStarted = false;
      this.signInExPendingNotified = false;
      this.fullScreenWebUrl = '';
      this.fullScreenWebMode = '';
      this.clearMyNavigationPath();
      this.activeSection = NAV_HOME;
      this.signInSyncSerial++;
      this.resetNativeState();
      this.ensureNativeLoaded();
    }
  }

  private inferSiteFromUrl(url: string): string {
    if (url.indexOf('exhentai.org') >= 0) {
      return GallerySite.EX;
    }
    if (url.indexOf('e-hentai.org') >= 0 && url.indexOf('forums.e-hentai.org') < 0) {
      return GallerySite.E;
    }
    return '';
  }

  private syncSiteModeFromUrl(url: string): void {
    const inferred = this.inferSiteFromUrl(url);
    if (inferred.length === 0 || inferred === this.siteMode) {
      return;
    }
    this.siteMode = inferred;
    this.writeValue('site_mode', inferred);
  }

  private normalizeUrl(value: string): string {
    const trimmed = value.trim();
    if (trimmed.length === 0) {
      return EhUrl.home(this.siteMode);
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return `${EhUrl.host(this.siteMode)}${trimmed.substring(1)}`;
    }
    return `https://${trimmed}`;
  }

  private openHome(): void {
    this.openHomeRoute(EhUrl.galleryFront(this.siteMode));
  }

  private openInternalWeb(url: string, title: string): void {
    const nextUrl = this.normalizeUrl(url);
    this.syncSiteModeFromUrl(nextUrl);
    this.webSrc = nextUrl;
    this.addressInput = nextUrl;
    this.writeValue('last_url', nextUrl);
    this.openFullScreenWeb(nextUrl, title, '');
  }

  private openFullScreenWeb(url: string, title: string, mode: string): void {
    void this.applyReaderWindowState(false);
    const nextUrl = this.normalizeUrl(url);
    const params: PageRouteParams = createWebRouteParams(
      this.currentRouteActiveSection(),
      this.currentRouteMyPage(),
      this.currentRouteMyPageTitle(),
      nextUrl,
      title,
      mode
    );
    try {
      void this.getUIContext().getRouter().pushUrl({
        url: APP_INDEX_PAGE_URL,
        params
      }).catch(() => {
        this.fullScreenWebUrl = nextUrl;
        this.fullScreenWebTitle = title;
        this.fullScreenWebMode = mode;
      });
    } catch (error) {
      this.fullScreenWebUrl = nextUrl;
      this.fullScreenWebTitle = title;
      this.fullScreenWebMode = mode;
    }
  }

  private currentRouteMyPage(): string {
    if (this.isMySubPage() && this.mySubPage !== MY_PAGE_MAIN) {
      return this.mySubPage;
    }
    return this.myPage;
  }

  private currentRouteActiveSection(): number {
    if (this.isMySubPage() && this.mySubPage !== MY_PAGE_MAIN) {
      return this.sectionForSubPage(this.mySubPage);
    }
    return this.activeSection;
  }

  private currentRouteMyPageTitle(): string {
    if (this.isMySubPage() && this.mySubPageTitle.length > 0) {
      return this.mySubPageTitle;
    }
    return this.myPageTitle;
  }

  private configureWebControllerForEh(): void {
    try {
      this.controller.setCustomUserAgent(NativeEhClient.USER_AGENT);
    } catch (error) {
      try {
        const controllerUserAgent = this.controller.getUserAgent();
        if (controllerUserAgent.length > 0) {
          this.controller.setCustomUserAgent(controllerUserAgent);
        }
      } catch (fallbackError) {
      }
    }
  }

  private openWebSignIn(): void {
    void this.openWebSignInAsync();
  }

  private openWebSignInFromGate(): void {
    this.markLoginGateSeen();
    this.loginGateVisible = false;
    this.openWebSignIn();
  }

  private openCookieSignInFromGate(): void {
    this.markLoginGateSeen();
    this.loginGateVisible = false;
    this.openMyPage(MY_PAGE_SETTINGS, '设置');
  }

  private enterGuestModeFromGate(): void {
    this.markLoginGateSeen();
    this.loginGateVisible = false;
    const guestHomeUrl = EhUrl.galleryFront(GallerySite.E);
    this.webSrc = guestHomeUrl;
    this.addressInput = guestHomeUrl;
    this.writeValue('last_url', guestHomeUrl);
    this.toggleSite(GallerySite.E);
    this.nativeError = '';
    this.openHomePrimaryPage(HOME_PAGE_DEFAULT);
  }

  private async openWebSignInAsync(): Promise<void> {
    await this.prepareWebSignIn();
    this.openFullScreenWeb(EhUrl.signIn(), '网页登录', WEB_MODE_SIGN_IN);
  }

  private createSummaryFromGalleryUrl(url: string): NativeGallerySummary | undefined {
    const match = /\/g\/(\d+)\/([0-9a-f]{10})/i.exec(url);
    if (!match || !match[1] || !match[2]) {
      return undefined;
    }
    const gid = Number(match[1]);
    if (!Number.isFinite(gid) || gid <= 0) {
      return undefined;
    }
    const item: NativeGallerySummary = {
      gid,
      token: match[2],
      title: `Gallery ${gid}`,
      titleJpn: '',
      thumb: '',
      categoryLabel: '',
      posted: '',
      uploader: '',
      rating: -1,
      pages: 0,
      simpleTags: [],
      simpleLanguage: '',
      detailUrl: EhUrl.galleryDetail(this.siteMode, gid, match[2])
    };
    return item;
  }

  private isEhGalleryListRoute(url: string): boolean {
    const lower = url.toLowerCase();
    const host = EhUrl.host(this.siteMode).toLowerCase();
    if (!lower.startsWith(host)) {
      return false;
    }
    if (lower.includes('/g/') || lower.includes('/s/') || lower.includes('api.php')) {
      return false;
    }
    if (lower === host || lower === `${host}home.php` || lower.startsWith(`${host}?`)) {
      return true;
    }
    return lower.startsWith(`${host}popular`) ||
      lower.startsWith(`${host}watched`) ||
      lower.startsWith(`${host}favorites.php`) ||
      lower.startsWith(`${host}tag/`) ||
      lower.startsWith(`${host}uploader/`);
  }

  private tryOpenEhUrlInApp(url: string): boolean {
    const nextUrl = this.normalizeUrl(url);
    this.syncSiteModeFromUrl(nextUrl);
    if (nextUrl === EhUrl.signIn()) {
      this.openWebSignIn();
      return true;
    }
    const gallery = this.createSummaryFromGalleryUrl(nextUrl);
    if (gallery) {
      this.clearMyNavigationPath();
      this.activeSection = NAV_SEARCH;
      void this.openNativeDetail(gallery);
      return true;
    }
    if (this.isEhGalleryListRoute(nextUrl)) {
      this.openHomeRoute(nextUrl === EhUrl.home(this.siteMode) ? EhUrl.galleryFront(this.siteMode) : nextUrl);
      return true;
    }
    return false;
  }

  private openEhRouteOrInternalWeb(url: string, title: string): void {
    if (this.tryOpenEhUrlInApp(url)) {
      return;
    }
    this.openInternalWeb(url, title);
  }

  private buildQuickLinks(): QuickLink[] {
    return [
      {
        title: '首页',
        description: 'Android 主入口页面。',
        url: EhUrl.home(this.siteMode)
      },
      {
        title: '热门',
        description: '热门画廊入口。',
        url: EhUrl.popular(this.siteMode)
      },
      {
        title: '收藏',
        description: '站点收藏列表。',
        url: EhUrl.favorites(this.siteMode)
      },
      {
        title: '关注',
        description: '关注标签和订阅列表。',
        url: EhUrl.watched(this.siteMode)
      },
      {
        title: '我的标签',
        description: '账号标签管理页面。',
        url: EhUrl.myTags(this.siteMode)
      },
      {
        title: 'UConfig',
        description: '账号站点配置页面。',
        url: EhUrl.uConfig(this.siteMode)
      },
      {
        title: '登录',
        description: 'Android 使用的论坛登录流程。',
        url: EhUrl.signIn()
      },
      {
        title: '资讯',
        description: 'EH 站点资讯。',
        url: EhUrl.news()
      }
    ];
  }

  private toggleSite(nextSite: string): void {
    this.siteMode = nextSite;
    this.writeValue('site_mode', nextSite);
    this.resetNativeState();
    this.resetMyRemoteState();
    if (nextSite === GallerySite.EX && !this.canUseNativeSite(nextSite)) {
      this.loginGateVisible = true;
      this.toast('EXHentai 需要登录或导入 Cookie');
    } else if (nextSite === GallerySite.E) {
      this.loginGateVisible = false;
    }
  }

  private switchSiteAndRestart(nextSite: string): void {
    this.toggleSite(nextSite);
    const targetUrl = EhUrl.galleryFront(nextSite);
    this.webSrc = targetUrl;
    this.addressInput = targetUrl;
    this.writeValue('last_url', targetUrl);
    this.fullScreenWebUrl = '';
    this.fullScreenWebTitle = '';
    this.fullScreenWebMode = '';
    this.fullScreenWebProgress = 0;
    this.clearMyNavigationPath();
    this.activeSection = NAV_HOME;
    this.myPage = MY_PAGE_MAIN;
    this.myPageTitle = '';
    this.mySubPage = MY_PAGE_MAIN;
    this.mySubPageTitle = '';
    this.homePage = HOME_PAGE_DEFAULT;
    this.nativeViewMode = 'list';
    this.searchResultsActive = false;
    this.searchFilterSheetVisible = false;
    this.searchFiltersExpanded = true;
    const params: PageRouteParams = createMyPageRouteParams(NAV_HOME, MY_PAGE_MAIN, '', nextSite);
    try {
      this.getUIContext().getRouter().clear();
      void this.getUIContext().getRouter().replaceUrl({
        url: APP_INDEX_PAGE_URL,
        params
      }).catch(() => {
      });
    } catch (error) {
    }
    if (this.canUseNativeSite(nextSite)) {
      this.prepareHomeGalleryReload(targetUrl);
      void this.loadHomeGalleryList(targetUrl);
    }
  }

  private acknowledgeWarning(): void {
    this.warningAcknowledged = true;
    this.writeValue('warning_acknowledged', true);
  }

  private togglePrivateBrowsing(): void {
    this.privateBrowsing = !this.privateBrowsing;
    this.writeValue('private_browsing', this.privateBrowsing);
    this.toast(this.privateBrowsing ? '已开启私密浏览' : '已关闭私密浏览');
  }

  private addCurrentPageToBookmarks(): void {
    const nextUrl = this.addressInput.trim();
    if (nextUrl.length === 0) {
      this.toast('当前没有可加入书签的页面');
      return;
    }
    const nextTitle = this.pageTitle.trim().length > 0 ? this.pageTitle.trim() : nextUrl;
    const filtered = this.bookmarks.filter((item: BookmarkItem) => item.url !== nextUrl);
    const nextBookmark: BookmarkItem = { title: nextTitle, url: nextUrl };
    this.bookmarks = [nextBookmark, ...filtered].slice(0, 24);
    this.saveBookmarks();
    this.toast('书签已保存');
  }

  private removeBookmark(url: string): void {
    this.bookmarks = this.bookmarks.filter((item: BookmarkItem) => item.url !== url);
    this.saveBookmarks();
  }

  private importCookies(): void {
    const pieces = this.splitCookiePieces(this.cookieDraft);
    if (pieces.length === 0) {
      this.toast('请先粘贴 Cookie header');
      return;
    }
    const cookieHeader = pieces.join('; ');
    if (!this.containsAuthCookie(cookieHeader)) {
      this.toast('Cookie 需要包含 ipb_member_id 和 ipb_pass_hash');
      return;
    }
    try {
      webview.WebCookieManager.putAcceptCookieEnabled(true);
      webview.WebCookieManager.putAcceptThirdPartyCookieEnabled(true);
      this.clearWebCookieStore();
      this.persistCookiesToTargets(pieces);
      this.cookieDraft = cookieHeader;
      this.writeValue('cookie_draft', cookieHeader);
      NativeEhClient.configureCookieHeader(cookieHeader);
      this.refreshSiteCookieState();
      this.toast('Cookie 已导入');
      this.resetNativeState();
      this.ensureNativeLoaded();
    } catch (error) {
      this.toast('Cookie 导入失败');
    }
  }

  private exportCookies(): void {
    try {
      const webPieces: string[] = [];
      for (const target of EhUrl.cookieTargets()) {
        for (const piece of this.splitCookiePieces(this.fetchCookie(target))) {
          webPieces.push(piece);
        }
      }
      const exported = this.mergeCookiePieces(this.splitCookiePieces(this.cookieDraft), webPieces)
        .join('; ');
      this.cookieDraft = exported;
      this.writeValue('cookie_draft', exported);
      NativeEhClient.configureCookieHeader(exported);
      this.refreshSiteCookieState();
      this.toast(exported.length > 0 ? 'Cookie 已加载到编辑器' : '未找到已保存的 Cookie');
    } catch (error) {
      this.toast('Cookie 读取失败');
    }
  }

  private currentCookieHeader(): string {
    try {
      return this.mergeCookiePieces(this.splitCookiePieces(this.cookieDraft), this.collectWebCookies('')).join('; ');
    } catch (error) {
      return this.cookieDraft.trim();
    }
  }

  private updateSettingsCookieDraft(value: string): void {
    this.cookieDraft = value;
    this.writeValue('cookie_draft', value);
    this.restoreCookieDraftToWeb();
    this.refreshSiteCookieState();
  }

  private copyCurrentCookie(): void {
    const cookie = this.currentCookieHeader();
    if (cookie.length === 0) {
      this.toast('当前没有可复制的 Cookie');
      return;
    }
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, cookie);
      void pasteboard.getSystemPasteboard().setData(data)
        .then(() => {
          this.toast('Cookie 已复制');
        })
        .catch(() => {
          this.toast('Cookie 复制失败');
        });
    } catch (error) {
      this.toast('Cookie 复制失败');
    }
  }

  private isSignedIn(): boolean {
    return this.hasSignInCookie;
  }

  private showLoginPrompt(): void {
    this.loginGateVisible = true;
  }

  private isAccountOnlyMyAction(action: string): boolean {
    return action === 'mytags' || action === 'uconfig';
  }

  private runMyActionWhenSignedIn(action: string): void {
    if (action === 'logout') {
      this.confirmClearLocalAccountCache();
      return;
    }
    if (this.isAccountOnlyMyAction(action) && !this.isSignedIn()) {
      this.showLoginPrompt();
      return;
    }
    this.handleMyDrawerAction(action);
  }

  private clearCookies(): void {
    this.clearLocalAccountCache();
  }

  private clearLocalAccountCache(): void {
    try {
      this.clearWebCookieStore();
      this.cookieDraft = '';
      this.signInForumProbeStarted = false;
      this.signInExProbeStarted = false;
      this.signInExPendingNotified = false;
      NativeEhClient.configureCookieHeader('');
      this.writeValue('cookie_draft', '');
      if (this.siteMode === GallerySite.EX) {
        this.siteMode = GallerySite.E;
        this.writeValue('site_mode', GallerySite.E);
        const targetUrl = EhUrl.galleryFront(GallerySite.E);
        this.webSrc = targetUrl;
        this.addressInput = targetUrl;
        this.writeValue('last_url', targetUrl);
      }
      this.refreshSiteCookieState();
      this.loginGateVisible = false;
      this.nativeError = '';
      this.resetNativeState();
      this.resetMyRemoteState();
      this.toast('本地账号缓存已删除');
    } catch (error) {
      this.toast('本地账号缓存删除失败');
    }
  }

  private confirmClearLocalAccountCache(): void {
    const options: promptAction.ShowDialogOptions = {
      title: '删除本地账号缓存',
      message: '确定要删除本地保存的登录 Cookie 和账号状态吗？下载、历史、书签和本地收藏不会被删除。',
      buttons: [
        { text: '取消', color: '#6F5964' },
        { text: '删除', color: '#B42318' }
      ]
    };
    try {
      void this.getUIContext().getPromptAction().showDialog(options)
        .then((result: promptAction.ShowDialogSuccessResponse) => {
          if (result.index === 1) {
            this.clearLocalAccountCache();
          }
        })
        .catch(() => {
        });
    } catch (error) {
    }
  }

  private goBackward(): void {
    try {
      if (this.controller.accessBackward()) {
        this.controller.backward();
      }
    } catch (error) {
      this.toast('没有后退历史');
    }
  }

  private goForward(): void {
    try {
      if (this.controller.accessForward()) {
        this.controller.forward();
      }
    } catch (error) {
      this.toast('没有前进历史');
    }
  }

  private refreshPage(): void {
    try {
      this.controller.refresh();
    } catch (error) {
      this.openEhRouteOrInternalWeb(this.addressInput, '内置网页');
    }
  }

  private setActiveSection(index: number): void {
    const wasSearchSection = this.activeSection === NAV_SEARCH;
    this.clearMyNavigationPath();
    if (index !== NAV_SEARCH) {
      this.clearTagSearchReturnDetail();
      this.tagSearchTransitionQuery = '';
      this.stopReaderRuntimeState();
      this.searchFilterSheetVisible = false;
      this.hideSearchSuggestionOverlay();
    }
    this.activeSection = index;
    if (index === NAV_HOME) {
      this.myPage = MY_PAGE_MAIN;
      this.myPageTitle = '';
      this.ensureCurrentHomePageLoaded();
    } else if (index === NAV_LIBRARY) {
      this.myPage = MY_PAGE_MAIN;
      this.myPageTitle = '';
      this.nativeViewMode = 'list';
    } else if (index === NAV_SETTINGS) {
      this.myPage = MY_PAGE_SETTINGS;
      this.myPageTitle = '设置';
    } else if (index === NAV_SEARCH) {
      this.myPage = MY_PAGE_MAIN;
      this.myPageTitle = '';
      if (!wasSearchSection) {
        this.searchResultsActive = false;
        this.searchFiltersExpanded = true;
      }
      if (!this.searchResultsActive && this.nativeViewMode !== 'detail' && this.nativeViewMode !== 'reader' &&
        this.nativeViewMode !== 'previews' && this.nativeViewMode !== 'comments') {
        this.nativeViewMode = 'list';
      }
    }
  }

  private bottomTabIndex(): number {
    if (this.activeSection === NAV_SEARCH) {
      return 1;
    }
    if (this.activeSection === NAV_LIBRARY || this.activeSection === NAV_SETTINGS) {
      return 2;
    }
    return 0;
  }

  private sectionForBottomTabIndex(index: number): number {
    if (index === 1) {
      return NAV_SEARCH;
    }
    if (index === 2) {
      return NAV_LIBRARY;
    }
    return NAV_HOME;
  }

  private handleBottomTabClick(index: number): void {
    const targetSection = this.sectionForBottomTabIndex(index);
    if (targetSection === NAV_HOME && this.activeSection === NAV_HOME &&
      this.myPage === MY_PAGE_MAIN && this.nativeViewMode === 'list') {
      const now = Date.now();
      if (now - this.lastHomeTabClickAt <= 360) {
        this.scrollHomeToTopAndRefresh();
      }
      this.lastHomeTabClickAt = now;
    }
    this.setActiveSection(targetSection);
  }

  private scrollHomeToTopAndRefresh(): void {
    try {
      this.homeScroller.scrollTo({
        xOffset: 0,
        yOffset: 0,
        animation: true
      });
    } catch (error) {
    }
    if (this.homePage === HOME_PAGE_TOP) {
      void this.loadTopList();
    } else {
      void this.refreshHomeWaterfall();
    }
  }

  private shouldShowBottomTabs(): boolean {
    if (this.hasMyNavigationPath()) {
      return false;
    }
    if (this.activeSection === NAV_HOME) {
      return this.myPage === MY_PAGE_MAIN &&
        this.nativeViewMode === 'list' &&
        !this.shouldShowNativeRouteLoading();
    }
    if (this.activeSection === NAV_SEARCH) {
      return this.nativeViewMode === 'list' &&
        !this.shouldShowNativeRouteLoading();
    }
    if (this.activeSection === NAV_LIBRARY) {
      return this.myPage === MY_PAGE_MAIN &&
        this.nativeViewMode === 'list' &&
        !this.shouldShowNativeRouteLoading();
    }
    return false;
  }

  private shouldRenderBottomTabHost(): boolean {
    return this.shouldShowBottomTabs();
  }

  private bottomTabBarHeight(): number {
    return FLOATING_BOTTOM_TAB_BAR_HEIGHT;
  }

  private closeSearchResultsPage(): void {
    this.clearTagSearchReturnDetail();
    this.searchResultsActive = false;
    this.searchFiltersExpanded = true;
    this.hideSearchSuggestionOverlay();
    this.nativeViewMode = 'list';
  }

  private resetNativeState(): void {
    this.homeListLoadSerial++;
    this.favoriteListLoadSerial++;
    this.stopReaderRuntimeState();
    this.homeLoading = false;
    this.homeLoadingMessage = '正在加载图库...';
    this.homeError = '';
    this.homeRawResults = [];
    this.homeResults = [];
    this.homeListUrl = '';
    this.homeResultCount = '';
    this.homeFirstUrl = '';
    this.homePrevUrl = '';
    this.homeNextUrl = '';
    this.homeLastUrl = '';
    this.homeFilteredCount = 0;
    this.homeSectionTitle = '首页';
    this.homeSectionRefreshUrl = '';
    this.favoriteLoading = false;
    this.favoriteLoadingMessage = '正在加载收藏...';
    this.favoriteError = '';
    this.favoriteRawResults = [];
    this.favoriteResults = [];
    this.favoriteListUrl = '';
    this.favoriteResultCount = '';
    this.favoriteFirstUrl = '';
    this.favoritePrevUrl = '';
    this.favoriteNextUrl = '';
    this.favoriteLastUrl = '';
    this.favoriteFilteredCount = 0;
    this.favoriteEndToastKey = '';
    this.searchLoading = false;
    this.searchLoadingMessage = '正在加载图库...';
    this.searchError = '';
    this.searchRawResults = [];
    this.searchResults = [];
    this.searchListUrl = '';
    this.searchResultCount = '';
    this.searchFirstUrl = '';
    this.searchPrevUrl = '';
    this.searchNextUrl = '';
    this.searchLastUrl = '';
    this.searchFilteredCount = 0;
    this.searchResultsActive = false;
    this.searchFiltersExpanded = true;
    this.hideSearchSuggestionOverlay();
    this.nativeError = '';
    this.nativeRawResults = [];
    this.nativeResults = [];
    this.nativeListUrl = '';
    this.nativeResultCount = '';
    this.nativeFirstUrl = '';
    this.nativePrevUrl = '';
    this.nativeNextUrl = '';
    this.nativeLastUrl = '';
    this.nativeFilteredCount = 0;
    this.nativeViewMode = 'list';
    this.nativeDetail = createEmptyNativeGalleryDetail();
    this.nativeDetailRevision++;
    this.nativePreviewItems = [];
    this.nativePreviewPageIndex = 0;
    this.nativePreviewPageCount = 0;
    this.nativePreviewLoading = false;
    this.nativeAllPreviewLoadSerial++;
    this.nativeAllPreviewItems = [];
    this.nativeAllPreviewLoading = false;
    this.nativeAllPreviewLoadedPages = 0;
    this.nativeAllPreviewPageCount = 0;
    this.nativeAllPreviewStatus = '';
    this.nativeReaderPage = {
      pageIndex: 0,
      pageLabel: '',
      pageUrl: '',
      imageUrl: '',
      originImageUrl: ''
    };
    this.nativeReaderListIndex = -1;
    this.readerJumpInput = '';
    this.readerDisplayImageUrl = '';
    this.readerCurrentError = '';
    this.readerCacheStatus = '缓存空闲';
    this.resetReaderAdjacentPages();
    this.readerPageCache.clear();
    this.readerPageRetrySkipKeys.clear();
    this.readerImageCache.clear();
  }

  private resetMyRemoteState(): void {
    this.topListDetail = {
      title: '',
      groups: []
    };
    this.topListError = '';
    this.topListLoading = false;
    this.topListGroupIndex = 0;
    this.topListPeriodSelectedIndexes = [0];
    this.myTags = [];
    this.myTagsError = '';
    this.myTagsLoading = false;
    this.imageSearchError = '';
    this.imageSearchLoading = false;
  }

  private ensureMySubPageLoaded(page: string = this.myPage): void {
    if (page === MY_PAGE_MY_TAGS) {
      if (!this.myTagsLoading && this.myTags.length === 0 && this.myTagsError.length === 0) {
        void this.loadMyTags();
      }
    }
  }

  private async loadTopList(): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      this.topListError = this.nativeError;
      return;
    }
    this.topListLoading = true;
    this.topListError = '';
    try {
      this.topListDetail = await NativeEhClient.fetchTopList(this.siteMode);
      this.topListGroupIndex = 0;
      this.topListPeriodSelectedIndexes = [0];
      this.prefetchTopListImages(this.topListDetail);
    } catch (error) {
      this.topListDetail = {
        title: '',
        groups: []
      };
      const detail = `${error}`.replace('Error: ', '');
      this.topListError = detail.length > 0 ? detail : '排行榜加载失败';
    } finally {
      this.topListLoading = false;
    }
  }

  private async loadMyTags(): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      this.myTagsError = this.nativeError;
      return;
    }
    this.myTagsLoading = true;
    this.myTagsError = '';
    try {
      this.myTags = await NativeEhClient.fetchUserTags(this.siteMode);
      if (this.myTags.length === 0) {
        this.myTagsError = '没有解析到我的标签。若未登录，请先使用网页登录或导入 Cookie。';
      }
    } catch (error) {
      this.myTags = [];
      const detail = `${error}`.replace('Error: ', '');
      this.myTagsError = detail.length > 0 ? detail : '我的标签加载失败';
    } finally {
      this.myTagsLoading = false;
    }
  }

  private openTopListFollow(period: NativeTopListPeriod): void {
    if (period.follow.length > 0) {
      this.openHomeRoute(`${EhUrl.topList()}?${period.follow}`);
      return;
    }
    if (period.url.length === 0) {
      return;
    }
    this.openHomeRoute(period.url);
  }

  private currentTopListGroup(): NativeTopListGroup {
    if (this.topListGroupIndex >= 0 && this.topListGroupIndex < this.topListDetail.groups.length) {
      return this.topListDetail.groups[this.topListGroupIndex];
    }
    const fallback: NativeTopListGroup = {
      title: '',
      periods: []
    };
    return fallback;
  }

  private prefetchTopListImages(detail: NativeTopListDetail): void {
    const seenUrls: string[] = [];
    let queuedCount = 0;
    for (const group of detail.groups) {
      for (const period of group.periods) {
        for (const entry of period.entries) {
          if (entry.thumb.length === 0 || seenUrls.indexOf(entry.thumb) >= 0) {
            continue;
          }
          seenUrls.push(entry.thumb);
          queuedCount++;
          void this.ensureGalleryImageCached(entry.thumb, EhUrl.topList()).catch(() => {
          });
          if (queuedCount >= 60) {
            return;
          }
        }
      }
    }
  }

  private topListGroupSelectOptions(): SelectOption[] {
    return this.topListDetail.groups.map((group: NativeTopListGroup): SelectOption => {
      return { value: this.topListGroupDisplayTitle(group.title) };
    });
  }

  private topListGroupSelectedIndex(): number {
    if (this.topListGroupIndex >= 0 && this.topListGroupIndex < this.topListDetail.groups.length) {
      return this.topListGroupIndex;
    }
    return 0;
  }

  private topListGroupSummary(): string {
    const group = this.currentTopListGroup();
    return group.title.length > 0 ? this.topListGroupDisplayTitle(group.title) : '图库排行榜';
  }

  private topListGroupDisplayTitle(title: string): string {
    const normalized = title.toLowerCase();
    if (normalized.indexOf('gallery') >= 0) {
      return '图库排行榜';
    }
    if (normalized.indexOf('uploader') >= 0) {
      return '上传者排行榜';
    }
    if (normalized.indexOf('tagging') >= 0 || normalized.indexOf('tag') >= 0) {
      return '标签排行榜';
    }
    if (normalized.indexOf('rating') >= 0 || normalized.indexOf('review') >= 0) {
      return '评分与评论排行榜';
    }
    if (normalized.indexOf('search') >= 0) {
      return '搜索排行榜';
    }
    if (normalized.indexOf('torrent') >= 0) {
      return '种子排行榜';
    }
    if (normalized.indexOf('cleanup') >= 0) {
      return '清理排行榜';
    }
    return title;
  }

  private isTopListGroupSelected(title: string): boolean {
    return this.currentTopListGroup().title === title;
  }

  private selectTopListGroup(title: string): void {
    for (let index = 0; index < this.topListDetail.groups.length; index++) {
      if (this.topListDetail.groups[index].title === title) {
        this.topListGroupIndex = index;
        this.syncTopListPeriodSelectedIndex();
        return;
      }
    }
  }

  private selectTopListGroupByIndex(index: number): void {
    if (index < 0 || index >= this.topListDetail.groups.length) {
      return;
    }
    this.topListGroupIndex = index;
    this.syncTopListPeriodSelectedIndex();
  }

  private topListPeriodSelectedIndex(): number {
    if (this.topListPeriodSelectedIndexes.length === 0) {
      return 0;
    }
    const index = this.topListPeriodSelectedIndexes[0];
    return index >= 0 && index < TOP_LIST_PERIOD_OPTIONS.length ? index : 0;
  }

  private normalizeTopListPeriodLabel(value: string): string {
    return value.toLowerCase().replace(/[_\s-]+/g, ' ').trim();
  }

  private topListPeriodMatches(period: NativeTopListPeriod, option: TopListPeriodOption): boolean {
    const normalized = this.normalizeTopListPeriodLabel(period.label);
    const compact = normalized.replace(/\s+/g, '');
    for (const keyword of option.matchKeywords) {
      const normalizedKeyword = this.normalizeTopListPeriodLabel(keyword);
      if (normalized.indexOf(normalizedKeyword) >= 0 || compact.indexOf(normalizedKeyword.replace(/\s+/g, '')) >= 0) {
        return true;
      }
    }
    return false;
  }

  private topListPeriodForIndex(index: number): NativeTopListPeriod {
    const group = this.currentTopListGroup();
    const fallback: NativeTopListPeriod = {
      label: '',
      follow: '',
      url: '',
      entries: []
    };
    if (group.periods.length === 0) {
      return fallback;
    }
    const safeIndex = index >= 0 && index < TOP_LIST_PERIOD_OPTIONS.length ? index : 0;
    const option = TOP_LIST_PERIOD_OPTIONS[safeIndex];
    for (const period of group.periods) {
      if (this.topListPeriodMatches(period, option)) {
        return period;
      }
    }
    return safeIndex < group.periods.length ? group.periods[safeIndex] : group.periods[0];
  }

  private currentTopListPeriod(): NativeTopListPeriod {
    return this.topListPeriodForIndex(this.topListPeriodSelectedIndex());
  }

  private syncTopListPeriodSelectedIndex(): void {
    const selectedIndex = this.topListPeriodSelectedIndex();
    const period = this.topListPeriodForIndex(selectedIndex);
    if (period.entries.length > 0 || this.currentTopListGroup().periods.length === 0) {
      this.topListPeriodSelectedIndexes = [selectedIndex];
      return;
    }
    for (let index = 0; index < TOP_LIST_PERIOD_OPTIONS.length; index++) {
      if (this.topListPeriodForIndex(index).entries.length > 0) {
        this.topListPeriodSelectedIndexes = [index];
        return;
      }
    }
    this.topListPeriodSelectedIndexes = [0];
  }

  private topListRankLabel(entry: NativeTopListEntry, fallbackIndex: number): string {
    const digits = entry.rank.replace(/[^0-9]/g, '');
    const rank = digits.length > 0 ? digits : `${fallbackIndex + 1}`;
    return `${rank}#`;
  }

  private openTopListEntry(entry: NativeTopListEntry): void {
    if (entry.gid > 0 && entry.token.length > 0) {
      const item: NativeGallerySummary = {
        gid: entry.gid,
        token: entry.token,
        title: entry.title,
        titleJpn: '',
        thumb: entry.thumb,
        categoryLabel: '',
        posted: '',
        uploader: '',
        rating: -1,
        pages: 0,
        simpleTags: [],
        simpleLanguage: '',
        detailUrl: EhUrl.galleryDetail(this.siteMode, entry.gid, entry.token)
      };
      void this.openNativeDetail(item);
      return;
    }
    this.openEhRouteOrInternalWeb(entry.url, entry.title);
  }

  private openUserTagSearch(item: NativeUserTag): void {
    if (item.tagName.length === 0) {
      return;
    }
    this.activeSection = NAV_SEARCH;
    this.searchMode = SEARCH_MODE_TAG;
    this.setNativeQuery(item.tagName);
    this.nativeViewMode = 'list';
    void this.searchNative();
  }

  private async pickImageForSearch(): Promise<void> {
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const result = await photoPicker.select(options);
      if (result.photoUris.length > 0) {
        this.imageSearchPath = this.copyPickedImageForSearch(result.photoUris[0]);
        this.imageSearchError = '';
      }
    } catch (error) {
      const detail = `${error}`.replace('Error: ', '');
      this.imageSearchError = detail.length > 0 ? detail : '图片选择失败';
    }
  }

  private copyPickedImageForSearch(uri: string): string {
    const hostContext = this.getUIContext().getHostContext();
    if (!hostContext) {
      return uri;
    }
    try {
      const abilityContext = hostContext as common.UIAbilityContext;
      const target = `${abilityContext.filesDir}/image-search-${Date.now()}.jpg`;
      fileIo.copyFileSync(uri, target);
      this.scheduleCacheMaintenance();
      return target;
    } catch (error) {
      return uri;
    }
  }

  private async runImageSearch(): Promise<void> {
    const filePath = this.imageSearchPath.trim();
    if (filePath.length === 0) {
      this.imageSearchError = '请先选择图片';
      return;
    }
    if (!this.ensureNativeSiteReady()) {
      this.imageSearchError = this.nativeError;
      return;
    }
    this.imageSearchLoading = true;
    this.imageSearchError = '';
    try {
      const result = await NativeEhClient.searchByImage(
        this.siteMode,
        filePath,
        this.imageSearchSimilar,
        this.imageSearchCovers,
        this.imageSearchExpunged
      );
      this.applySearchGalleryList(result);
      this.searchError = '';
      this.clearTagSearchReturnDetail();
      this.tagSearchTransitionQuery = '';
      this.nativeViewMode = 'list';
      this.clearMyNavigationPath();
      this.activeSection = NAV_SEARCH;
      this.searchResultsActive = true;
      this.prefetchGalleryImages(result.items, result.requestUrl);
    } catch (error) {
      const detail = `${error}`.replace('Error: ', '');
      this.imageSearchError = detail.length > 0 ? detail : '图片搜索失败';
    } finally {
      this.imageSearchLoading = false;
    }
  }

  private cancelSearchInputBlurTimer(): void {
    if (this.searchInputBlurTimerId >= 0) {
      clearTimeout(this.searchInputBlurTimerId);
      this.searchInputBlurTimerId = -1;
    }
  }

  private hideSearchSuggestionOverlay(): void {
    this.cancelSearchInputBlurTimer();
    this.searchInputFocused = false;
    this.searchSuggestionsVisible = false;
  }

  private hideSearchSuggestionOverlayKeepingInputActive(): void {
    this.cancelSearchInputBlurTimer();
    this.searchInputFocused = true;
    this.searchSuggestionsVisible = false;
  }

  private handleSearchInputFocus(allowOpen: boolean = false): void {
    if (!allowOpen && !this.searchInputFocused) {
      return;
    }
    this.cancelSearchInputBlurTimer();
    this.searchInputFocused = true;
    this.searchSuggestionsVisible = true;
    this.updateSearchSuggestions();
  }

  private handleSearchInputUserInteraction(): void {
    this.handleSearchInputFocus(true);
  }

  private handleSearchInputBlur(): void {
    this.cancelSearchInputBlurTimer();
    this.searchInputBlurTimerId = setTimeout((): void => {
      this.searchInputBlurTimerId = -1;
      this.hideSearchSuggestionOverlay();
    }, 120);
  }

  private setNativeQuery(value: string): void {
    this.nativeQuery = value;
    this.writeValue('native_query', value);
    if (value.trim().length > 0) {
      this.searchHistoryExpanded = false;
    }
    if (value.trim().length > 0 && this.searchFilterSheetVisible && this.activeSection === NAV_SEARCH) {
      this.searchFilterSheetVisible = false;
    }
    this.updateSearchSuggestions();
  }

  private setNativeQueryFromSearchInput(value: string): void {
    if (this.searchInputFocused) {
      this.searchSuggestionsVisible = true;
    }
    this.setNativeQuery(value);
  }

  private refreshTagTranslationState(): void {
    this.tagTranslationsLoaded = EhTagTranslator.isLoaded();
    this.updateSearchSuggestions();
    this.updateFilterTagSuggestions();
  }

  private async updateTagTranslations(showToast: boolean): Promise<void> {
    const updateTask = EhTagTranslator.update();
    this.refreshTagTranslationState();
    const loaded = await updateTask;
    this.refreshTagTranslationState();
    if (showToast) {
      this.toast(loaded ? '标签翻译已更新' : '完整标签库加载失败，已保留内置翻译');
    }
  }

  private extractTagSuggestionKeyword(query: string): string {
    const normalized = query.replace(/\s+$/g, '');
    if (normalized.length === 0) {
      return '';
    }
    const parts = normalized.split(/\s+/g);
    const tail = parts.length > 0 ? parts[parts.length - 1] : '';
    return this.cleanTagSuggestionKeyword(tail);
  }

  private cleanTagSuggestionKeyword(token: string): string {
    let keyword = token.trim();
    const separatorIndex = keyword.indexOf(':');
    if (separatorIndex >= 0) {
      keyword = keyword.substring(separatorIndex + 1);
    }
    keyword = keyword
      .replace(/^[-"'`]+/g, '')
      .replace(/[\$"'`]+$/g, '')
      .trim();
    return keyword;
  }

  private updateTagSuggestions(): void {
    const keyword = this.extractTagSuggestionKeyword(this.nativeQuery);
    this.tagSuggestions = EhTagTranslator.suggest(keyword, TAG_SUGGEST_LIMIT);
  }

  private updateSearchHistorySuggestions(): void {
    const prefix = this.nativeQuery;
    const result: string[] = [];
    for (const query of this.searchHistoryQueries) {
      if (result.length >= SEARCH_HISTORY_SUGGEST_LIMIT) {
        break;
      }
      if (prefix.length > 0 && !query.startsWith(prefix)) {
        continue;
      }
      if (query === prefix) {
        continue;
      }
      result.push(query);
    }
    this.searchHistorySuggestions = result;
  }

  private updateSearchSuggestions(): void {
    this.updateSearchHistorySuggestions();
    this.updateTagSuggestions();
  }

  private addSearchHistoryQuery(query: string): void {
    if (query.trim().length === 0) {
      return;
    }
    const nextValues = this.searchHistoryQueries.filter((item: string) => item !== query);
    this.searchHistoryQueries = [query, ...nextValues].slice(0, SEARCH_HISTORY_MAX_COUNT);
    this.saveSearchHistoryQueries();
    this.updateSearchHistorySuggestions();
  }

  private removeSearchHistoryQuery(query: string): void {
    this.searchHistoryQueries = this.searchHistoryQueries.filter((item: string) => item !== query);
    if (this.searchHistoryQueries.length <= SEARCH_HISTORY_DEFAULT_VISIBLE_COUNT) {
      this.searchHistoryExpanded = false;
    }
    this.saveSearchHistoryQueries();
    this.updateSearchSuggestions();
  }

  private clearSearchHistoryQueries(): void {
    this.searchHistoryQueries = [];
    this.searchHistoryExpanded = false;
    this.saveSearchHistoryQueries();
    this.updateSearchSuggestions();
  }

  private shouldShowSearchHistoryExpandButton(): boolean {
    return this.searchHistoryQueries.length > SEARCH_HISTORY_DEFAULT_VISIBLE_COUNT;
  }

  private visibleSearchHistoryQueries(): string[] {
    if (this.searchHistoryExpanded || !this.shouldShowSearchHistoryExpandButton()) {
      return this.searchHistoryQueries;
    }
    return this.searchHistoryQueries.slice(0, SEARCH_HISTORY_DEFAULT_VISIBLE_COUNT);
  }

  private searchHistoryExpandButtonLabel(): string {
    return this.searchHistoryExpanded ? '收起' : '展开全部';
  }

  private toggleSearchHistoryExpanded(): void {
    const nextValue = !this.searchHistoryExpanded;
    try {
      this.getUIContext().animateTo({
        duration: 220,
        curve: Curve.EaseOut
      }, (): void => {
        this.searchHistoryExpanded = nextValue;
      });
    } catch (error) {
      this.searchHistoryExpanded = nextValue;
    }
  }

  private confirmClearSearchHistoryQueries(): void {
    if (this.searchHistoryQueries.length === 0) {
      return;
    }
    const options: promptAction.ShowDialogOptions = {
      title: '清空历史记录',
      message: '确定要清空全部搜索历史记录吗？',
      buttons: [
        { text: '取消', color: '#6F5964' },
        { text: '清空', color: '#B42318' }
      ]
    };
    try {
      void this.getUIContext().getPromptAction().showDialog(options)
        .then((result: promptAction.ShowDialogSuccessResponse) => {
          if (result.index === 1) {
            this.clearSearchHistoryQueries();
          }
        })
        .catch(() => {
        });
    } catch (error) {
    }
  }

  private buildSearchTokenFromSuggestion(item: TagTranslationSuggestion): string {
    return this.buildSearchTokenFromTag(item.namespace, item.tag);
  }

  private buildSearchTokenFromTag(namespace: string, tag: string): string {
    const prefix = EhTagTranslator.namespaceToPrefix(namespace);
    if (prefix !== undefined) {
      return `${prefix}"${tag}$"`;
    }
    return `${namespace}:${tag}`;
  }

  private replaceTagSuggestionTail(token: string): string {
    const current = this.nativeQuery.replace(/\s+$/g, '');
    if (current.length === 0) {
      return token;
    }
    const lastSpaceMatch = /\s+\S*$/.exec(current);
    if (!lastSpaceMatch || lastSpaceMatch.index <= 0) {
      return token;
    }
    const prefix = current.substring(0, lastSpaceMatch.index).trimEnd();
    return prefix.length > 0 ? `${prefix} ${token}` : token;
  }

  private applyTagSuggestion(item: TagTranslationSuggestion): void {
    this.setNativeQuery(this.replaceTagSuggestionTail(this.buildSearchTokenFromSuggestion(item)));
    this.hideSearchSuggestionOverlayKeepingInputActive();
  }

  private applyHistorySuggestion(query: string): void {
    this.setNativeQuery(query);
    this.hideSearchSuggestionOverlayKeepingInputActive();
  }

  private filterUsesTagSuggestions(): boolean {
    return this.normalizeFilterMode(this.filterModeDraft) === FILTER_MODE_TAG;
  }

  private updateFilterTagSuggestions(): void {
    if (!this.filterUsesTagSuggestions()) {
      this.filterTagSuggestions = [];
      return;
    }
    const keyword = this.filterTextDraft.trim();
    this.filterTagSuggestions = EhTagTranslator.suggest(keyword, TAG_SUGGEST_LIMIT);
  }

  private setFilterTextDraft(value: string): void {
    this.filterTextDraft = value;
    this.updateFilterTagSuggestions();
  }

  private applyFilterTagSuggestion(item: TagTranslationSuggestion): void {
    this.filterTextDraft = item.key;
    this.filterTagSuggestions = [];
  }

  private siteLabel(): string {
    return this.siteMode === GallerySite.EX ? 'EXHENTAI' : 'E-HENTAI';
  }

  private siteDisplayName(site: string): string {
    return site === GallerySite.EX ? 'EXHentai' : 'E-Hentai';
  }

  private searchModeLabel(mode: string): string {
    switch (mode) {
      case SEARCH_MODE_WATCHED:
        return '关注';
      case SEARCH_MODE_UPLOADER:
        return '上传者';
      case SEARCH_MODE_TAG:
        return '标签';
      default:
        return '普通';
    }
  }

  private searchInputPlaceholder(): string {
    if (this.searchMode === SEARCH_MODE_UPLOADER) {
      return '输入上传者';
    }
    if (this.searchMode === SEARCH_MODE_TAG) {
      return '输入标签，例如 female:sole female';
    }
    return '输入关键词';
  }

  private toggleSearchFiltersExpanded(): void {
    if (this.activeSection !== NAV_SEARCH || this.nativeViewMode !== 'list') {
      return;
    }
    this.hideSearchSuggestionOverlay();
    this.searchFilterSheetVisible = !this.searchFilterSheetVisible;
    this.searchFiltersExpanded = this.searchFilterSheetVisible;
  }

  private closeSearchFilterSheet(): void {
    this.searchFilterSheetVisible = false;
    this.searchFiltersExpanded = false;
  }

  private applySearchFiltersFromSheet(): void {
    if (!this.canApplySearchFilters()) {
      return;
    }
    this.closeSearchFilterSheet();
    void this.searchNative();
  }

  private canApplySearchFilters(): boolean {
    return this.searchCategoryMask !== 0;
  }

  private searchModeSelectOptions(): SelectOption[] {
    return SEARCH_MODE_OPTIONS.map((item: SearchModeOption): SelectOption => {
      return { value: item.label };
    });
  }

  private searchModeSelectedIndex(): number {
    const index = SEARCH_MODE_OPTIONS.findIndex((item: SearchModeOption) => item.mode === this.searchMode);
    return index >= 0 ? index : 0;
  }

  private applySearchModeByIndex(index: number): void {
    if (index >= 0 && index < SEARCH_MODE_OPTIONS.length) {
      this.setSearchMode(SEARCH_MODE_OPTIONS[index].mode);
    }
  }

  private selectedSearchCategoryOptions(): SearchCategoryOption[] {
    return SEARCH_CATEGORY_OPTIONS.filter((option: SearchCategoryOption): boolean => {
      return this.categorySelected(option.bit);
    });
  }

  private unselectedSearchCategoryOptions(): SearchCategoryOption[] {
    return SEARCH_CATEGORY_OPTIONS.filter((option: SearchCategoryOption): boolean => {
      return !this.categorySelected(option.bit);
    });
  }

  private animateSearchCategoryChange(action: () => void): void {
    try {
      this.getUIContext().animateTo({
        duration: 220,
        curve: Curve.EaseOut
      }, action);
    } catch (error) {
      action();
    }
  }

  private toggleSearchCategoryFromSheet(bit: number): void {
    let nextMask = this.searchCategoryMask;
    if ((nextMask & bit) !== 0) {
      nextMask = nextMask & (~bit);
    } else {
      nextMask = nextMask | bit;
    }
    this.searchCategoryMask = nextMask & CATEGORY_ALL;
  }

  private searchAdvancedFlagChipItems(): ChipGroupItemOptions[] {
    return SEARCH_ADVANCED_FLAG_OPTIONS.map((item: SearchAdvancedFlagOption): ChipGroupItemOptions => {
      return {
        label: { text: item.label }
      };
    });
  }

  private searchFlagActive(flag: string): boolean {
    switch (flag) {
      case 'name':
        return this.searchName;
      case 'tags':
        return this.searchTags;
      case 'desc':
        return this.searchDescription;
      case 'torrent':
        return this.searchTorrent;
      case 'low':
        return this.searchLowPowerTags;
      case 'expunged':
        return this.searchExpunged;
      case 'downvoted':
        return this.searchDownvoted;
      case 'filename':
        return this.searchFileName;
      case 'uploader':
        return this.searchUploader;
      case 'torrentfile':
        return this.searchTorrentFile;
      default:
        return false;
    }
  }

  private selectedSearchAdvancedFlagIndexes(): number[] {
    const result: number[] = [];
    for (let index = 0; index < SEARCH_ADVANCED_FLAG_OPTIONS.length; index++) {
      if (this.searchFlagActive(SEARCH_ADVANCED_FLAG_OPTIONS[index].flag)) {
        result.push(index);
      }
    }
    return result;
  }

  private applySelectedSearchAdvancedFlagIndexes(indexes: number[]): void {
    let flags = 0;
    for (const index of indexes) {
      if (index < 0 || index >= SEARCH_ADVANCED_FLAG_OPTIONS.length) {
        continue;
      }
      switch (SEARCH_ADVANCED_FLAG_OPTIONS[index].flag) {
        case 'name':
          flags |= SEARCH_ADV_FLAG_NAME;
          break;
        case 'tags':
          flags |= SEARCH_ADV_FLAG_TAGS;
          break;
        case 'desc':
          flags |= SEARCH_ADV_FLAG_DESCRIPTION;
          break;
        case 'torrent':
          flags |= SEARCH_ADV_FLAG_TORRENT;
          break;
        case 'low':
          flags |= SEARCH_ADV_FLAG_LOW_POWER_TAGS;
          break;
        case 'expunged':
          flags |= SEARCH_ADV_FLAG_EXPUNGED;
          break;
        case 'downvoted':
          flags |= SEARCH_ADV_FLAG_DOWNVOTED;
          break;
        case 'filename':
          flags |= SEARCH_ADV_FLAG_FILE_NAME;
          break;
        case 'uploader':
          flags |= SEARCH_ADV_FLAG_UPLOADER;
          break;
        case 'torrentfile':
          flags |= SEARCH_ADV_FLAG_TORRENT_FILE;
          break;
        default:
          break;
      }
    }
    this.applySearchAdvancedFlags(flags);
  }

  private searchFilterSummary(): string {
    const details: string[] = [this.searchModeLabel(this.searchMode)];
    if (this.nativeQuery.trim().length > 0) {
      details.push(this.nativeQuery.trim());
    }
    if (this.searchCategoryMask !== CATEGORY_ALL) {
      details.push('自定义分类');
    }
    if (this.searchAdvancedEnabled) {
      details.push('高级搜索');
    }
    return details.join('  ·  ');
  }

  private quickSearchSummary(item: QuickSearchItem): string {
    const details: string[] = [this.siteDisplayName(item.site), this.searchModeLabel(item.mode)];
    if (item.category !== CATEGORY_ALL) {
      details.push('自定义分类');
    }
    if (item.minRating.length > 0) {
      details.push(`评分 ${item.minRating}+`);
    }
    if (item.pageFrom.length > 0 || item.pageTo.length > 0) {
      details.push(`页数 ${item.pageFrom || '0'}-${item.pageTo || '*'}`);
    }
    details.push(item.savedAt);
    return details.join('  ·  ');
  }

  private sitePanelTitle(): string {
    return this.siteMode === GallerySite.EX ? 'EXHentai 里站' : 'E-Hentai 外站';
  }

  private canUseNativeSite(site: string): boolean {
    return site !== GallerySite.EX || this.hasExCookie;
  }

  private siteAccessHeadline(): string {
    if (this.siteMode === GallerySite.E) {
      return '外站可直接访问';
    }
    if (this.hasExCookie) {
      return '里站 Cookie 已就绪';
    }
    if (this.hasSignInCookie) {
      return '已检测到登录态';
    }
    return '里站需要登录或 Cookie';
  }

  private siteAccessDescription(): string {
    if (this.siteMode === GallerySite.E) {
      return 'E-Hentai 可以直接浏览，登录后还能访问收藏、关注和账户页。';
    }
    if (this.hasExCookie) {
      return '当前已检测到 EX 相关 Cookie，原生和网页都可以按里站模式运行。';
    }
    if (this.hasSignInCookie) {
      return '已经检测到登录 Cookie，但 EX 的 igneous 可能还没同步。若里站仍不可用，请在可通过 EX 的节点打开一次 EX 首页，或导入安卓版导出的完整 Cookie。';
    }
    return 'EXHentai 需要登录或导入 Cookie。未登录时原生侧会阻止里站请求，避免直接落到错误页。';
  }

  private ensureNativeSiteReady(): boolean {
    if (this.canUseNativeSite(this.siteMode)) {
      return true;
    }
    this.nativeError = 'EXHentai 原生模式需要登录或导入 Cookie。请先登录或在设置中导入 Cookie。';
    this.nativeViewMode = 'list';
    return false;
  }

  private ensureNativeLoaded(): void {
    this.ensureCurrentHomePageLoaded();
  }

  private prepareHomeGalleryReload(url: string): void {
    this.syncHomeSectionMeta(url);
    this.clearHomeGalleryList(url);
    this.homeLoading = true;
    this.homeLoadingMessage = '正在加载图库...';
    this.homeError = '';
    this.nativeViewMode = 'list';
  }

  private prepareFavoriteGalleryReload(url: string): void {
    this.clearFavoriteGalleryList(url);
    this.favoriteLoading = true;
    this.favoriteLoadingMessage = '正在加载收藏...';
    this.favoriteError = '';
    this.nativeViewMode = 'list';
  }

  private currentHomeGalleryKeyPrefix(): string {
    if (this.homePage === HOME_PAGE_TOP) {
      return `top:${this.siteMode}`;
    }
    const targetUrl = this.homeSectionRefreshUrl.length > 0 ? this.homeSectionRefreshUrl : this.currentHomeTargetUrl();
    return `home:${this.stripPageParam(targetUrl)}`;
  }

  private currentFavoriteGalleryKeyPrefix(): string {
    return `favorites:${this.favoriteListFilter}:${this.siteMode}`;
  }

  private createLocalFavoriteGalleryListResult(): NativeGalleryListResult {
    return {
      items: this.localFavoriteSummaries(),
      requestUrl: this.localFavoriteListUrl(),
      resultCount: `${this.localFavorites.length}`,
      firstUrl: '',
      prevUrl: '',
      nextUrl: '',
      lastUrl: ''
    };
  }

  private localFavoriteSummaries(): NativeGallerySummary[] {
    return this.localFavorites.map((item: LocalGalleryRecord): NativeGallerySummary => this.toNativeSummary(item));
  }

  private favoriteItemsForCurrentFilter(items: NativeGallerySummary[]): NativeGallerySummary[] {
    if (this.favoriteListFilter !== FAVORITE_FILTER_ALL) {
      return items;
    }
    return this.appendGalleryItems(this.localFavoriteSummaries(), items);
  }

  private createFallbackAllFavoriteGalleryListResult(url: string): NativeGalleryListResult {
    return {
      items: [],
      requestUrl: url,
      resultCount: `${this.localFavorites.length}`,
      firstUrl: '',
      prevUrl: '',
      nextUrl: '',
      lastUrl: ''
    };
  }

  private loadLocalFavoriteGalleryList(): void {
    const loadSerial = ++this.favoriteListLoadSerial;
    this.favoriteLoading = true;
    this.favoriteLoadingMessage = '正在加载本地收藏...';
    this.favoriteError = '';
    this.nativeViewMode = 'list';
    const result = this.createLocalFavoriteGalleryListResult();
    if (loadSerial !== this.favoriteListLoadSerial) {
      return;
    }
    this.applyFavoriteGalleryList(result);
    this.favoriteLoading = false;
    this.favoriteLoadingMessage = '正在加载收藏...';
  }

  private loadCurrentLibraryFavoriteList(resetList: boolean = false): void {
    if (this.favoriteListFilter === FAVORITE_FILTER_LOCAL) {
      if (resetList) {
        this.prepareFavoriteGalleryReload(this.localFavoriteListUrl());
      }
      this.loadLocalFavoriteGalleryList();
      return;
    }
    const targetUrl = this.favoriteFilterUrl(this.favoriteListFilter);
    if (resetList) {
      this.prepareFavoriteGalleryReload(targetUrl);
    }
    void this.loadFavoriteGalleryList(targetUrl);
  }

  private refreshLocalFavoriteGalleryListIfNeeded(): void {
    if (this.activeSection === NAV_LIBRARY && this.libraryPanel === LIBRARY_FAVORITES &&
      this.favoriteListFilter === FAVORITE_FILTER_LOCAL && this.nativeViewMode === 'list') {
      this.loadLocalFavoriteGalleryList();
    }
  }

  private isFavoritesUrl(url: string): boolean {
    return url.toLowerCase().indexOf('favorites.php') >= 0;
  }

  private currentHomeTargetUrl(): string {
    switch (this.homePage) {
      case HOME_PAGE_POPULAR:
        return EhUrl.popular(this.siteMode);
      case HOME_PAGE_WATCHED:
        return EhUrl.watched(this.siteMode);
      default:
        return EhUrl.galleryFront(this.siteMode);
    }
  }

  private ensureCurrentHomePageLoaded(): void {
    if (this.homePage === HOME_PAGE_TOP) {
      if (!this.topListLoading && this.topListDetail.groups.length === 0 && this.topListError.length === 0) {
        void this.loadTopList();
      }
      return;
    }
    if (!this.ensureNativeSiteReady()) {
      return;
    }
    const targetUrl = this.currentHomeTargetUrl();
    this.syncHomeSectionMeta(targetUrl);
    const currentBaseUrl = this.stripPageParam(this.homeListUrl);
    const targetBaseUrl = this.stripPageParam(targetUrl);
    if (this.homeLoading) {
      return;
    }
    if (currentBaseUrl === targetBaseUrl &&
      (this.homeResults.length > 0 || this.homeResultCount.length > 0 || this.homeError.length > 0)) {
      return;
    }
    void this.loadHomeGalleryList(targetUrl);
  }

  private ensureCurrentLibraryPageLoaded(): void {
    if (this.libraryPanel !== LIBRARY_FAVORITES) {
      return;
    }
    if (this.favoriteListFilter === FAVORITE_FILTER_LOCAL) {
      const targetUrl = this.localFavoriteListUrl();
      const currentBaseUrl = this.stripPageParam(this.favoriteListUrl);
      const targetBaseUrl = this.stripPageParam(targetUrl);
      if (this.favoriteLoading) {
        return;
      }
      if (currentBaseUrl === targetBaseUrl &&
        (this.favoriteResults.length > 0 || this.favoriteResultCount.length > 0 || this.favoriteError.length > 0)) {
        return;
      }
      this.loadLocalFavoriteGalleryList();
      return;
    }
    if (!this.ensureNativeSiteReady()) {
      return;
    }
    const targetUrl = this.favoriteFilterUrl(this.favoriteListFilter);
    const currentBaseUrl = this.stripPageParam(this.favoriteListUrl);
    const targetBaseUrl = this.stripPageParam(targetUrl);
    if (this.favoriteLoading) {
      return;
    }
    if (currentBaseUrl === targetBaseUrl &&
      (this.favoriteResults.length > 0 || this.favoriteResultCount.length > 0 || this.favoriteError.length > 0)) {
      return;
    }
    void this.loadFavoriteGalleryList(targetUrl);
  }

  private applyHomeGalleryList(result: NativeGalleryListResult): void {
    this.homeRawResults = result.items;
    this.homeResults = this.applyLocalGalleryFilters(this.homeRawResults);
    this.homeFilteredCount = this.filterHiddenCount(this.homeRawResults, this.homeResults);
    this.homeListUrl = result.requestUrl;
    this.homeResultCount = result.resultCount;
    this.homeFirstUrl = result.firstUrl;
    this.homePrevUrl = result.prevUrl;
    this.homeNextUrl = result.nextUrl;
    this.homeLastUrl = result.lastUrl;
    this.homeEndToastKey = '';
  }

  private clearHomeGalleryList(url: string): void {
    this.homeRawResults = [];
    this.homeResults = [];
    this.homeListUrl = url;
    this.homeResultCount = '';
    this.homeFirstUrl = '';
    this.homePrevUrl = '';
    this.homeNextUrl = '';
    this.homeLastUrl = '';
    this.homeFilteredCount = 0;
    this.homeEndToastKey = '';
  }

  private applyFavoriteGalleryList(result: NativeGalleryListResult): void {
    this.favoriteRawResults = this.favoriteItemsForCurrentFilter(result.items);
    this.favoriteResults = this.applyLocalGalleryFilters(this.favoriteRawResults);
    this.favoriteFilteredCount = this.filterHiddenCount(this.favoriteRawResults, this.favoriteResults);
    this.favoriteListUrl = result.requestUrl;
    this.favoriteResultCount = result.resultCount;
    this.favoriteFirstUrl = result.firstUrl;
    this.favoritePrevUrl = result.prevUrl;
    this.favoriteNextUrl = result.nextUrl;
    this.favoriteLastUrl = result.lastUrl;
    this.favoriteEndToastKey = '';
  }

  private clearFavoriteGalleryList(url: string): void {
    this.favoriteRawResults = [];
    this.favoriteResults = [];
    this.favoriteListUrl = url;
    this.favoriteResultCount = '';
    this.favoriteFirstUrl = '';
    this.favoritePrevUrl = '';
    this.favoriteNextUrl = '';
    this.favoriteLastUrl = '';
    this.favoriteFilteredCount = 0;
    this.favoriteEndToastKey = '';
  }

  private applySearchGalleryList(result: NativeGalleryListResult): void {
    this.searchRawResults = result.items;
    this.searchResults = this.applyLocalGalleryFilters(this.searchRawResults);
    this.searchFilteredCount = this.filterHiddenCount(this.searchRawResults, this.searchResults);
    this.searchListUrl = result.requestUrl;
    this.searchResultCount = result.resultCount;
    this.searchFirstUrl = result.firstUrl;
    this.searchPrevUrl = result.prevUrl;
    this.searchNextUrl = result.nextUrl;
    this.searchLastUrl = result.lastUrl;
    this.searchEndToastKey = '';
  }

  private clearSearchGalleryList(url: string): void {
    this.searchRawResults = [];
    this.searchResults = [];
    this.searchListUrl = url;
    this.searchResultCount = '';
    this.searchFirstUrl = '';
    this.searchPrevUrl = '';
    this.searchNextUrl = '';
    this.searchLastUrl = '';
    this.searchFilteredCount = 0;
    this.searchEndToastKey = '';
  }

  private gallerySummaryKey(item: NativeGallerySummary): string {
    return `${item.gid}:${item.token}`;
  }

  private appendGalleryItems(
    currentItems: NativeGallerySummary[],
    nextItems: NativeGallerySummary[]
  ): NativeGallerySummary[] {
    const merged = currentItems.slice();
    const itemKeys = new Set<string>();
    for (const item of currentItems) {
      itemKeys.add(this.gallerySummaryKey(item));
    }
    for (const item of nextItems) {
      const key = this.gallerySummaryKey(item);
      if (!itemKeys.has(key)) {
        merged.push(item);
        itemKeys.add(key);
      }
    }
    return merged;
  }

  private appendHomeGalleryList(result: NativeGalleryListResult): void {
    this.homeRawResults = this.appendGalleryItems(this.homeRawResults, result.items);
    this.homeResults = this.applyLocalGalleryFilters(this.homeRawResults);
    this.homeFilteredCount = this.filterHiddenCount(this.homeRawResults, this.homeResults);
    this.homeListUrl = result.requestUrl;
    if (result.resultCount.length > 0) {
      this.homeResultCount = result.resultCount;
    }
    this.homeNextUrl = result.nextUrl;
    this.homeLastUrl = result.lastUrl;
    this.homeEndToastKey = '';
  }

  private appendFavoriteGalleryList(result: NativeGalleryListResult): void {
    this.favoriteRawResults = this.appendGalleryItems(this.favoriteRawResults, result.items);
    this.favoriteResults = this.applyLocalGalleryFilters(this.favoriteRawResults);
    this.favoriteFilteredCount = this.filterHiddenCount(this.favoriteRawResults, this.favoriteResults);
    this.favoriteListUrl = result.requestUrl;
    if (result.resultCount.length > 0) {
      this.favoriteResultCount = result.resultCount;
    }
    this.favoriteNextUrl = result.nextUrl;
    this.favoriteLastUrl = result.lastUrl;
    this.favoriteEndToastKey = '';
  }

  private appendSearchGalleryList(result: NativeGalleryListResult): void {
    this.searchRawResults = this.appendGalleryItems(this.searchRawResults, result.items);
    this.searchResults = this.applyLocalGalleryFilters(this.searchRawResults);
    this.searchFilteredCount = this.filterHiddenCount(this.searchRawResults, this.searchResults);
    this.searchListUrl = result.requestUrl;
    if (result.resultCount.length > 0) {
      this.searchResultCount = result.resultCount;
    }
    this.searchNextUrl = result.nextUrl;
    this.searchLastUrl = result.lastUrl;
    this.searchEndToastKey = '';
  }

  private showEndOfWaterfallToast(scope: 'home' | 'search' | 'favorite'): void {
    let toastKey = '';
    if (scope === 'home') {
      toastKey = `${this.homeListUrl}|${this.homeResults.length}`;
    } else if (scope === 'favorite') {
      toastKey = `${this.favoriteListUrl}|${this.favoriteResults.length}`;
    } else {
      toastKey = `${this.searchListUrl}|${this.searchResults.length}`;
    }
    if (toastKey.length === 0) {
      return;
    }
    if (scope === 'home') {
      if (this.homeEndToastKey === toastKey) {
        return;
      }
      this.homeEndToastKey = toastKey;
    } else if (scope === 'favorite') {
      if (this.favoriteEndToastKey === toastKey) {
        return;
      }
      this.favoriteEndToastKey = toastKey;
    } else {
      if (this.searchEndToastKey === toastKey) {
        return;
      }
      this.searchEndToastKey = toastKey;
    }
    this.toast('已经到底，没有更多内容了');
  }

  private async fetchGalleryListWithTimeout(url: string): Promise<NativeGalleryListResult> {
    hilog.info(DIAG_DOMAIN, DIAG_TAG, 'Fetch gallery list start. Site=%{public}s Url=%{public}s', this.siteMode, url);
    const result = await Promise.race<NativeGalleryListResult | undefined>([
      NativeEhClient.fetchGalleryList(this.siteMode, url),
      this.delay(GALLERY_LIST_TIMEOUT_MS).then((): undefined => undefined)
    ]);
    if (result === undefined) {
      hilog.error(DIAG_DOMAIN, DIAG_TAG, 'Fetch gallery list timeout. Site=%{public}s Url=%{public}s TimeoutMs=%{public}d',
        this.siteMode, url, GALLERY_LIST_TIMEOUT_MS);
      throw new Error('列表请求超时，请检查网络或 Cookie 状态。');
    }
    hilog.info(DIAG_DOMAIN, DIAG_TAG, 'Fetch gallery list success. Site=%{public}s Url=%{public}s', this.siteMode, url);
    return result;
  }

  private nextWaterfallBatchUrl(result: NativeGalleryListResult, previousUrls: string[]): string {
    const nextUrl = result.nextUrl;
    if (nextUrl.length === 0 || nextUrl === result.requestUrl || previousUrls.indexOf(nextUrl) >= 0) {
      return '';
    }
    return nextUrl;
  }

  private async loadGalleryListBatch(
    startUrl: string,
    onResult: (result: NativeGalleryListResult, pageIndex: number) => void,
    shouldContinue: () => boolean
  ): Promise<void> {
    const previousUrls: string[] = [];
    let nextUrl = startUrl;
    for (let pageIndex = 0; pageIndex < WATERFALL_BATCH_PAGE_COUNT && nextUrl.length > 0; pageIndex++) {
      try {
        const result = await this.fetchGalleryListWithTimeout(nextUrl);
        if (!shouldContinue()) {
          return;
        }
        onResult(result, pageIndex);
        previousUrls.push(result.requestUrl);
        nextUrl = this.nextWaterfallBatchUrl(result, previousUrls);
      } catch (error) {
        if (pageIndex === 0) {
          const message = `${error}`.replace('Error: ', '');
          throw new Error(message.length > 0 ? message : '列表请求失败');
        }
        break;
      }
    }
  }

  private applyFavoriteCategoryMetaFromListResult(result: NativeGalleryListResult): void {
    if (this.isFavoritesUrl(result.requestUrl) && result.favoriteSlots) {
      this.applyFavoriteCategoryMeta(result.favoriteSlots);
    }
  }

  private async loadHomeGalleryList(url: string): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      this.homeError = this.nativeError;
      return;
    }
    const loadSerial = ++this.homeListLoadSerial;
    this.syncHomeSectionMeta(url);
    this.homeLoading = true;
    this.homeLoadingMessage = '正在加载图库...';
    this.homeError = '';
    this.nativeViewMode = 'list';
    try {
      await this.loadGalleryListBatch(url, (result: NativeGalleryListResult, pageIndex: number): void => {
        this.applyFavoriteCategoryMetaFromListResult(result);
        if (pageIndex === 0) {
          this.applyHomeGalleryList(result);
        } else {
          this.appendHomeGalleryList(result);
        }
        this.prefetchGalleryImages(result.items, result.requestUrl);
      }, (): boolean => loadSerial === this.homeListLoadSerial);
    } catch (error) {
      if (loadSerial !== this.homeListLoadSerial) {
        return;
      }
      this.clearHomeGalleryList(url);
      this.homeError = this.readableErrorMessage(error, HOME_CONTENT_UNAVAILABLE_MESSAGE);
    } finally {
      if (loadSerial === this.homeListLoadSerial) {
        this.homeLoading = false;
        this.homeLoadingMessage = '正在加载图库...';
      }
    }
  }

  private async loadFavoriteGalleryList(url: string): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      this.favoriteError = this.nativeError;
      return;
    }
    const loadSerial = ++this.favoriteListLoadSerial;
    this.favoriteLoading = true;
    this.favoriteLoadingMessage = '正在加载收藏...';
    this.favoriteError = '';
    this.nativeViewMode = 'list';
    try {
      await this.loadGalleryListBatch(url, (result: NativeGalleryListResult, pageIndex: number): void => {
        this.applyFavoriteCategoryMetaFromListResult(result);
        if (pageIndex === 0) {
          this.applyFavoriteGalleryList(result);
        } else {
          this.appendFavoriteGalleryList(result);
        }
        this.prefetchGalleryImages(result.items, result.requestUrl);
      }, (): boolean => loadSerial === this.favoriteListLoadSerial);
    } catch (error) {
      if (loadSerial !== this.favoriteListLoadSerial) {
        return;
      }
      if (this.favoriteListFilter === FAVORITE_FILTER_ALL && this.localFavorites.length > 0) {
        this.applyFavoriteGalleryList(this.createFallbackAllFavoriteGalleryListResult(url));
        this.favoriteError = '';
        return;
      }
      this.clearFavoriteGalleryList(url);
      const detail = `${error}`.replace('Error: ', '');
      this.favoriteError = detail.length > 0 ? detail : (this.siteMode === GallerySite.EX ?
        '里站收藏加载失败。请确认已经同步有效 EX Cookie。' :
        '收藏加载失败。若该页面需要登录，请先完成网页登录。');
    } finally {
      if (loadSerial === this.favoriteListLoadSerial) {
        this.favoriteLoading = false;
        this.favoriteLoadingMessage = '正在加载收藏...';
      }
    }
  }

  private async loadSearchGalleryList(url: string): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      this.searchError = this.nativeError;
      return;
    }
    const loadSerial = ++this.searchListLoadSerial;
    this.searchLoading = true;
    this.searchLoadingMessage = '正在加载图库...';
    this.searchError = '';
    this.nativeViewMode = 'list';
    try {
      await this.loadGalleryListBatch(url, (result: NativeGalleryListResult, pageIndex: number): void => {
        if (pageIndex === 0) {
          this.applySearchGalleryList(result);
        } else {
          this.appendSearchGalleryList(result);
        }
        this.prefetchGalleryImages(result.items, result.requestUrl);
      }, (): boolean => loadSerial === this.searchListLoadSerial);
    } catch (error) {
      if (loadSerial !== this.searchListLoadSerial) {
        return;
      }
      this.clearSearchGalleryList(url);
      const detail = `${error}`.replace('Error: ', '');
      this.searchError = detail.length > 0 ? detail : (this.siteMode === GallerySite.EX ?
        '里站搜索加载失败。请确认已经同步有效 EX Cookie。' :
        '搜索加载失败。若该页面需要登录，请先完成网页登录。');
    } finally {
      if (loadSerial === this.searchListLoadSerial) {
        this.searchLoading = false;
        this.searchLoadingMessage = '正在加载图库...';
      }
    }
  }

  private async loadMoreHomeGalleryList(): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      this.homeError = this.nativeError;
      return;
    }
    if (this.homeLoading) {
      return;
    }
    const nextUrl = this.homeNextUrl;
    if (nextUrl.length === 0 || nextUrl === this.homeListUrl) {
      this.showEndOfWaterfallToast('home');
      return;
    }
    const loadSerial = ++this.homeListLoadSerial;
    this.homeLoading = true;
    this.homeLoadingMessage = '正在加载下一页...';
    this.homeError = '';
    this.nativeViewMode = 'list';
    try {
      await this.loadGalleryListBatch(nextUrl, (result: NativeGalleryListResult, _pageIndex: number): void => {
        this.applyFavoriteCategoryMetaFromListResult(result);
        this.appendHomeGalleryList(result);
        this.prefetchGalleryImages(result.items, result.requestUrl);
      }, (): boolean => loadSerial === this.homeListLoadSerial);
    } catch (error) {
      if (loadSerial !== this.homeListLoadSerial) {
        return;
      }
      this.homeError = this.readableErrorMessage(error, HOME_CONTENT_UNAVAILABLE_MESSAGE);
      this.toast(this.homeError);
    } finally {
      if (loadSerial === this.homeListLoadSerial) {
        this.homeLoading = false;
        this.homeLoadingMessage = '正在加载图库...';
      }
    }
  }

  private async loadMoreFavoriteGalleryList(): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      this.favoriteError = this.nativeError;
      return;
    }
    if (this.favoriteLoading) {
      return;
    }
    const nextUrl = this.favoriteNextUrl;
    if (nextUrl.length === 0 || nextUrl === this.favoriteListUrl) {
      this.showEndOfWaterfallToast('favorite');
      return;
    }
    const loadSerial = ++this.favoriteListLoadSerial;
    this.favoriteLoading = true;
    this.favoriteLoadingMessage = '正在加载下一页...';
    this.favoriteError = '';
    this.nativeViewMode = 'list';
    try {
      await this.loadGalleryListBatch(nextUrl, (result: NativeGalleryListResult, _pageIndex: number): void => {
        this.applyFavoriteCategoryMetaFromListResult(result);
        this.appendFavoriteGalleryList(result);
        this.prefetchGalleryImages(result.items, result.requestUrl);
      }, (): boolean => loadSerial === this.favoriteListLoadSerial);
    } catch (error) {
      if (loadSerial !== this.favoriteListLoadSerial) {
        return;
      }
      const detail = `${error}`.replace('Error: ', '');
      this.favoriteError = detail.length > 0 ? detail : (this.siteMode === GallerySite.EX ?
        '里站收藏下一页加载失败。请确认已经同步有效 EX Cookie。' :
        '收藏下一页加载失败。若该页面需要登录，请先完成网页登录。');
      this.toast(this.favoriteError);
    } finally {
      if (loadSerial === this.favoriteListLoadSerial) {
        this.favoriteLoading = false;
        this.favoriteLoadingMessage = '正在加载收藏...';
      }
    }
  }

  private async loadMoreSearchGalleryList(): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      this.searchError = this.nativeError;
      return;
    }
    if (this.searchLoading) {
      return;
    }
    const nextUrl = this.searchNextUrl;
    if (nextUrl.length === 0 || nextUrl === this.searchListUrl) {
      this.showEndOfWaterfallToast('search');
      return;
    }
    this.searchLoading = true;
    this.searchLoadingMessage = '正在加载下一页...';
    this.searchError = '';
    this.nativeViewMode = 'list';
    const loadSerial = ++this.searchListLoadSerial;
    try {
      await this.loadGalleryListBatch(nextUrl, (result: NativeGalleryListResult, _pageIndex: number): void => {
        this.appendSearchGalleryList(result);
        this.prefetchGalleryImages(result.items, result.requestUrl);
      }, (): boolean => loadSerial === this.searchListLoadSerial);
    } catch (error) {
      if (loadSerial !== this.searchListLoadSerial) {
        return;
      }
      const detail = `${error}`.replace('Error: ', '');
      this.searchError = detail.length > 0 ? detail : (this.siteMode === GallerySite.EX ?
        '里站搜索下一页加载失败。请确认已经同步有效 EX Cookie。' :
        '搜索下一页加载失败。若该页面需要登录，请先完成网页登录。');
      this.toast(this.searchError);
    } finally {
      if (loadSerial === this.searchListLoadSerial) {
        this.searchLoading = false;
        this.searchLoadingMessage = '正在加载图库...';
      }
    }
  }

  private async loadNativeList(url: string): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      return;
    }
    this.nativeLoading = true;
    this.nativeLoadingMessage = '正在加载图库...';
    this.nativeError = '';
    this.nativeViewMode = 'list';
    try {
      const result = await NativeEhClient.fetchGalleryList(this.siteMode, url);
      this.nativeRawResults = result.items;
      this.nativeResults = this.applyLocalGalleryFilters(this.nativeRawResults);
      this.nativeFilteredCount = this.filterHiddenCount(this.nativeRawResults, this.nativeResults);
      this.nativeListUrl = result.requestUrl;
      this.nativeResultCount = result.resultCount;
      this.nativeFirstUrl = result.firstUrl;
      this.nativePrevUrl = result.prevUrl;
      this.nativeNextUrl = result.nextUrl;
      this.nativeLastUrl = result.lastUrl;
      this.prefetchGalleryImages(result.items, result.requestUrl);
    } catch (error) {
      this.nativeRawResults = [];
      this.nativeResults = [];
      this.nativeListUrl = url;
      this.nativeResultCount = '';
      this.nativeFirstUrl = '';
      this.nativePrevUrl = '';
      this.nativeNextUrl = '';
      this.nativeLastUrl = '';
      this.nativeFilteredCount = 0;
      const detail = `${error}`.replace('Error: ', '');
      this.nativeError = detail.length > 0 ? detail : (this.siteMode === GallerySite.EX ?
        '里站原生列表加载失败。请确认已经同步有效 EX Cookie。' :
        '原生列表加载失败。若该页面需要登录，请先完成网页登录。');
    } finally {
      this.nativeLoading = false;
      if (!this.readerPageSwitching) {
        this.readerTargetLoading = false;
      }
      this.nativeLoadingMessage = '正在加载图库...';
    }
  }

  private async refreshHomeWaterfall(): Promise<void> {
    if (!this.canUseNativeSite(this.siteMode)) {
      this.isHomeRefreshing = false;
      return;
    }
    this.isHomeRefreshing = true;
    try {
      const refreshUrl = this.homeSectionRefreshUrl.length > 0 ? this.homeSectionRefreshUrl : this.defaultHomeSectionUrl();
      await this.loadHomeGalleryList(refreshUrl);
    } finally {
      this.isHomeRefreshing = false;
    }
  }

  private async refreshFavoriteWaterfall(): Promise<void> {
    if (this.favoriteListFilter === FAVORITE_FILTER_LOCAL) {
      this.isFavoriteRefreshing = true;
      try {
        this.loadLocalFavoriteGalleryList();
      } finally {
        this.isFavoriteRefreshing = false;
      }
      return;
    }
    if (!this.canUseNativeSite(this.siteMode)) {
      this.isFavoriteRefreshing = false;
      return;
    }
    this.isFavoriteRefreshing = true;
    try {
      await this.loadFavoriteGalleryList(this.favoriteFilterUrl(this.favoriteListFilter));
    } finally {
      this.isFavoriteRefreshing = false;
    }
  }

  private async searchNative(): Promise<void> {
    this.hideSearchSuggestionOverlay();
    if (!this.keepNextSearchReturnDetail) {
      this.clearTagSearchReturnDetail();
      this.tagSearchTransitionQuery = '';
    }
    this.keepNextSearchReturnDetail = false;
    this.clearMyNavigationPath();
    this.activeSection = NAV_SEARCH;
    this.searchResultsActive = true;
    this.nativeViewMode = 'list';
    this.searchFiltersExpanded = false;
    this.searchFilterSheetVisible = false;
    this.addSearchHistoryQuery(this.nativeQuery);
    const nextUrl = this.buildAdvancedSearchUrl();
    await this.loadSearchGalleryList(nextUrl);
  }

  private appendQueryParam(params: string[], key: string, value: string): void {
    params.push(`${key}=${encodeURIComponent(value)}`);
  }

  private normalizeNumericInput(value: string): string {
    const trimmed = value.trim();
    if (trimmed.length === 0) {
      return '';
    }
    const numericValue = Number(trimmed);
    if (!Number.isFinite(numericValue) || numericValue < 0) {
      return '';
    }
    return `${Math.floor(numericValue)}`;
  }

  private normalizedTagSearchQuery(query: string): string {
    const trimmed = query.trim();
    if (trimmed.length === 0) {
      return '';
    }
    const separatorIndex = trimmed.indexOf(':');
    if (separatorIndex > 0 && trimmed.indexOf('"') < 0 && trimmed.indexOf('$') < 0) {
      const namespace = trimmed.substring(0, separatorIndex);
      const tag = trimmed.substring(separatorIndex + 1).trim();
      if (tag.length > 0 && EhTagTranslator.namespaceToPrefix(namespace) !== undefined) {
        return this.buildSearchTokenFromTag(namespace, tag);
      }
    }
    if (trimmed.indexOf('"') >= 0 || trimmed.indexOf('$') >= 0) {
      return trimmed;
    }
    return `"${trimmed}$"`;
  }

  private buildAdvancedSearchUrl(): string {
    return this.buildAdvancedSearchUrlFor(this.searchMode, this.nativeQuery);
  }

  private buildAdvancedSearchUrlFor(searchMode: string, searchQuery: string): string {
    const normalizedMode = this.normalizeSearchMode(searchMode);
    const rawQuery = searchQuery.trim();
    const query = normalizedMode === SEARCH_MODE_TAG ? this.normalizedTagSearchQuery(rawQuery) : rawQuery;
    if (normalizedMode === SEARCH_MODE_UPLOADER && query.length > 0) {
      return `${EhUrl.host(this.siteMode)}uploader/${encodeURIComponent(query)}`;
    }

    const baseUrl = normalizedMode === SEARCH_MODE_WATCHED ? EhUrl.watched(this.siteMode) : EhUrl.host(this.siteMode);
    const params: string[] = [];
    if (this.searchCategoryMask !== CATEGORY_ALL) {
      this.appendQueryParam(params, 'f_cats', `${(~this.searchCategoryMask) & CATEGORY_ALL}`);
    }
    if (query.length > 0) {
      this.appendQueryParam(params, 'f_search', query);
    }

    if (this.searchAdvancedEnabled) {
      this.appendQueryParam(params, 'advsearch', '1');
      if (this.searchName) {
        this.appendQueryParam(params, 'f_sname', 'on');
      }
      if (this.searchTags) {
        this.appendQueryParam(params, 'f_stags', 'on');
      }
      if (this.searchDescription) {
        this.appendQueryParam(params, 'f_sdesc', 'on');
      }
      if (this.searchTorrent) {
        this.appendQueryParam(params, 'f_storr', 'on');
      }
      if (this.searchLowPowerTags) {
        this.appendQueryParam(params, 'f_sto', 'on');
      }
      if (this.searchExpunged) {
        this.appendQueryParam(params, 'f_sdt1', 'on');
      }
      if (this.searchDownvoted) {
        this.appendQueryParam(params, 'f_sdt2', 'on');
      }
      if (this.searchFileName) {
        this.appendQueryParam(params, 'f_sfl', 'on');
      }
      if (this.searchUploader) {
        this.appendQueryParam(params, 'f_sfu', 'on');
      }
      if (this.searchTorrentFile) {
        this.appendQueryParam(params, 'f_sft', 'on');
      }
      const minRating = this.normalizeNumericInput(this.searchMinRating);
      if (minRating.length > 0) {
        this.appendQueryParam(params, 'f_sr', 'on');
        this.appendQueryParam(params, 'f_srdd', minRating);
      }
      const pageFrom = this.normalizeNumericInput(this.searchPageFrom);
      const pageTo = this.normalizeNumericInput(this.searchPageTo);
      if (pageFrom.length > 0 || pageTo.length > 0) {
        this.appendQueryParam(params, 'f_sp', 'on');
        this.appendQueryParam(params, 'f_spf', pageFrom);
        this.appendQueryParam(params, 'f_spt', pageTo);
      }
    }

    if (params.length === 0) {
      return baseUrl;
    }
    return baseUrl.indexOf('?') >= 0 ? `${baseUrl}&${params.join('&')}` : `${baseUrl}?${params.join('&')}`;
  }

  private pushSearchRoute(
    searchMode: string,
    query: string,
    categoryMask: number,
    searchUrl: string,
    transitionQuery: string,
    fallback: () => void
  ): void {
    const params = createSearchRouteParams(
      NAV_SEARCH,
      MY_PAGE_MAIN,
      '',
      this.siteMode,
      searchMode,
      query,
      categoryMask,
      this.currentSearchAdvancedFlags(),
      searchUrl,
      transitionQuery,
      this.searchAdvancedEnabled,
      this.normalizeNumericInput(this.searchMinRating),
      this.normalizeNumericInput(this.searchPageFrom),
      this.normalizeNumericInput(this.searchPageTo)
    );
    try {
      void this.getUIContext().getRouter().pushUrl({
        url: APP_INDEX_PAGE_URL,
        params
      }).catch(() => {
        fallback();
      });
    } catch (error) {
      fallback();
    }
  }

  private setSearchMode(value: string): void {
    this.searchMode = this.normalizeSearchMode(value);
  }

  private normalizeSearchMode(value: string): string {
    switch (value) {
      case SEARCH_MODE_NORMAL:
      case SEARCH_MODE_WATCHED:
      case SEARCH_MODE_UPLOADER:
      case SEARCH_MODE_TAG:
        return value;
      default:
        return SEARCH_MODE_NORMAL;
    }
  }

  private normalizeCategoryMask(value: number): number {
    const normalized = Math.floor(value) & CATEGORY_ALL;
    return normalized > 0 ? normalized : CATEGORY_ALL;
  }

  private categorySelected(bit: number): boolean {
    return (this.searchCategoryMask & bit) !== 0;
  }

  private toggleSearchCategory(bit: number): void {
    if (this.categorySelected(bit)) {
      this.searchCategoryMask = this.searchCategoryMask & (~bit);
    } else {
      this.searchCategoryMask = this.searchCategoryMask | bit;
    }
    if (this.searchCategoryMask === 0) {
      this.searchCategoryMask = bit;
    }
  }

  private resetSearchFilters(): void {
    this.searchMode = SEARCH_MODE_NORMAL;
    this.searchCategoryMask = CATEGORY_ALL;
    this.searchAdvancedEnabled = true;
    this.searchName = true;
    this.searchTags = true;
    this.searchDescription = false;
    this.searchTorrent = false;
    this.searchLowPowerTags = false;
    this.searchExpunged = false;
    this.searchDownvoted = false;
    this.searchFileName = false;
    this.searchUploader = false;
    this.searchTorrentFile = false;
    this.searchMinRating = '';
    this.searchPageFrom = '';
    this.searchPageTo = '';
  }

  private currentSearchAdvancedFlagsDefault(): number {
    return SEARCH_ADV_FLAG_NAME | SEARCH_ADV_FLAG_TAGS;
  }

  private currentSearchAdvancedFlags(): number {
    let flags = 0;
    if (this.searchName) {
      flags |= SEARCH_ADV_FLAG_NAME;
    }
    if (this.searchTags) {
      flags |= SEARCH_ADV_FLAG_TAGS;
    }
    if (this.searchDescription) {
      flags |= SEARCH_ADV_FLAG_DESCRIPTION;
    }
    if (this.searchTorrent) {
      flags |= SEARCH_ADV_FLAG_TORRENT;
    }
    if (this.searchLowPowerTags) {
      flags |= SEARCH_ADV_FLAG_LOW_POWER_TAGS;
    }
    if (this.searchExpunged) {
      flags |= SEARCH_ADV_FLAG_EXPUNGED;
    }
    if (this.searchDownvoted) {
      flags |= SEARCH_ADV_FLAG_DOWNVOTED;
    }
    if (this.searchFileName) {
      flags |= SEARCH_ADV_FLAG_FILE_NAME;
    }
    if (this.searchUploader) {
      flags |= SEARCH_ADV_FLAG_UPLOADER;
    }
    if (this.searchTorrentFile) {
      flags |= SEARCH_ADV_FLAG_TORRENT_FILE;
    }
    return flags;
  }

  private applySearchAdvancedFlags(flags: number): void {
    this.searchName = (flags & SEARCH_ADV_FLAG_NAME) !== 0;
    this.searchTags = (flags & SEARCH_ADV_FLAG_TAGS) !== 0;
    this.searchDescription = (flags & SEARCH_ADV_FLAG_DESCRIPTION) !== 0;
    this.searchTorrent = (flags & SEARCH_ADV_FLAG_TORRENT) !== 0;
    this.searchLowPowerTags = (flags & SEARCH_ADV_FLAG_LOW_POWER_TAGS) !== 0;
    this.searchExpunged = (flags & SEARCH_ADV_FLAG_EXPUNGED) !== 0;
    this.searchDownvoted = (flags & SEARCH_ADV_FLAG_DOWNVOTED) !== 0;
    this.searchFileName = (flags & SEARCH_ADV_FLAG_FILE_NAME) !== 0;
    this.searchUploader = (flags & SEARCH_ADV_FLAG_UPLOADER) !== 0;
    this.searchTorrentFile = (flags & SEARCH_ADV_FLAG_TORRENT_FILE) !== 0;
  }

  private toggleSearchFlag(flag: string): void {
    switch (flag) {
      case 'advanced':
        this.searchAdvancedEnabled = !this.searchAdvancedEnabled;
        break;
      case 'name':
        this.searchName = !this.searchName;
        break;
      case 'tags':
        this.searchTags = !this.searchTags;
        break;
      case 'desc':
        this.searchDescription = !this.searchDescription;
        break;
      case 'torrent':
        this.searchTorrent = !this.searchTorrent;
        break;
      case 'low':
        this.searchLowPowerTags = !this.searchLowPowerTags;
        break;
      case 'expunged':
        this.searchExpunged = !this.searchExpunged;
        break;
      case 'downvoted':
        this.searchDownvoted = !this.searchDownvoted;
        break;
      case 'filename':
        this.searchFileName = !this.searchFileName;
        break;
      case 'uploader':
        this.searchUploader = !this.searchUploader;
        break;
      case 'torrentfile':
        this.searchTorrentFile = !this.searchTorrentFile;
        break;
      default:
        break;
    }
  }

  private createRecordFromSummary(item: NativeGallerySummary): LocalGalleryRecord {
    const record: LocalGalleryRecord = {
      gid: item.gid,
      token: item.token,
      title: item.title,
      titleJpn: item.titleJpn,
      cover: item.thumb,
      detailUrl: item.detailUrl,
      site: this.siteMode,
      uploader: item.uploader,
      categoryLabel: item.categoryLabel,
      posted: item.posted,
      pages: item.pages,
      language: item.simpleLanguage,
      rating: item.rating
    };
    return record;
  }

  private createRecordFromDetail(): LocalGalleryRecord | undefined {
    if (this.nativeDetail.gid <= 0 || this.nativeDetail.detailUrl.length === 0) {
      return undefined;
    }
    const record: LocalGalleryRecord = {
      gid: this.nativeDetail.gid,
      token: this.nativeDetail.token,
      title: this.nativeDetail.title,
      titleJpn: this.nativeDetail.titleJpn,
      cover: this.nativeDetail.cover,
      detailUrl: this.nativeDetail.detailUrl,
      site: this.siteMode,
      uploader: this.nativeDetail.uploader,
      categoryLabel: this.nativeDetail.categoryLabel,
      posted: this.nativeDetail.posted,
      pages: this.nativeDetail.pages,
      language: this.nativeDetail.language,
      rating: this.nativeDetail.rating
    };
    return record;
  }

  private toHistoryItem(record: LocalGalleryRecord, visitedAt: string): HistoryItem {
    const item: HistoryItem = {
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
      visitedAt
    };
    return item;
  }

  private toDownloadItem(
    record: LocalGalleryRecord,
    status: string,
    queuedAt: string,
    lastAction: string,
    label: string = DOWNLOAD_DEFAULT_LABEL,
    downloaded: number = 0,
    total: number = 0,
    failedCount: number = 0,
    archiveUri: string = '',
    createdAt: string = '',
    updatedAt: string = '',
    currentPage: number = 0,
    currentPageLabel: string = '',
    speedBytesPerSecond: number = 0,
    remainingSeconds: number = -1,
    downloadDir: string = '',
    error: string = '',
    pageErrors: DownloadPageError[] = []
  ): DownloadQueueItem {
    const normalizedStatus = this.normalizeDownloadStatus(status);
    const created = createdAt.length > 0 ? createdAt : (queuedAt.length > 0 ? queuedAt : this.nowLabel());
    const updated = updatedAt.length > 0 ? updatedAt : created;
    const normalizedTotal = total > 0 ? total : record.pages;
    const normalizedDownloaded = clampNumber(downloaded, 0, Math.max(0, normalizedTotal));
    const item: DownloadQueueItem = {
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
      status: normalizedStatus,
      label: label.length > 0 ? label : DOWNLOAD_DEFAULT_LABEL,
      queuedAt: queuedAt.length > 0 ? queuedAt : created,
      lastAction,
      downloaded: normalizedDownloaded,
      total: Math.max(0, normalizedTotal),
      failedCount: Math.max(0, failedCount),
      archiveUri,
      createdAt: created,
      updatedAt: updated,
      currentPage: Math.max(0, currentPage),
      currentPageLabel,
      speedBytesPerSecond: Math.max(0, speedBytesPerSecond),
      remainingSeconds,
      downloadDir,
      error,
      pageErrors
    };
    return item;
  }

  private cloneDownloadItem(item: DownloadQueueItem): DownloadQueueItem {
    return this.toDownloadItem(
      item,
      item.status,
      item.queuedAt,
      item.lastAction,
      item.label,
      item.downloaded,
      item.total,
      item.failedCount,
      item.archiveUri,
      item.createdAt,
      item.updatedAt,
      item.currentPage,
      item.currentPageLabel,
      item.speedBytesPerSecond,
      item.remainingSeconds,
      item.downloadDir,
      item.error,
      item.pageErrors
    );
  }

  private cloneSharedDownloadItems(): DownloadQueueItem[] {
    return sharedDownloadItemsSnapshot.map((item: DownloadQueueItem) => this.cloneDownloadItem(item));
  }

  private runtimeDownloadItemsSnapshot(): DownloadQueueItem[] {
    const raw = this.downloadRuntimeItemsJson.length > 0 ?
      this.downloadRuntimeItemsJson :
      (AppStorage.get<string>(DOWNLOAD_RUNTIME_ITEMS_KEY) || '[]');
    return this.parseDownloadItems(raw);
  }

  private toNativeSummary(record: LocalGalleryRecord): NativeGallerySummary {
    const summary: NativeGallerySummary = {
      gid: record.gid,
      token: record.token,
      title: record.title,
      titleJpn: record.titleJpn,
      thumb: record.cover,
      categoryLabel: record.categoryLabel,
      posted: record.posted,
      uploader: record.uploader,
      rating: record.rating,
      pages: record.pages,
      simpleTags: [],
      simpleLanguage: record.language,
      detailUrl: record.detailUrl
    };
    return summary;
  }

  private normalizeFilterMode(mode: number): number {
    switch (mode) {
      case FILTER_MODE_TITLE:
      case FILTER_MODE_UPLOADER:
      case FILTER_MODE_TAG:
      case FILTER_MODE_TAG_NAMESPACE:
        return mode;
      default:
        return FILTER_MODE_TITLE;
    }
  }

  private filterModeLabel(mode: number): string {
    const normalized = this.normalizeFilterMode(mode);
    for (const option of FILTER_MODE_OPTIONS) {
      if (option.mode === normalized) {
        return option.label;
      }
    }
    return '标题';
  }

  private filterModePlaceholder(mode: number): string {
    const normalized = this.normalizeFilterMode(mode);
    for (const option of FILTER_MODE_OPTIONS) {
      if (option.mode === normalized) {
        return option.placeholder;
      }
    }
    return '标题包含的关键词';
  }

  private filterModeSelectOptions(): SelectOption[] {
    return FILTER_MODE_OPTIONS.map((item: FilterModeOption): SelectOption => {
      return { value: item.label };
    });
  }

  private filterModeSelectedIndex(): number {
    for (let index = 0; index < FILTER_MODE_OPTIONS.length; index++) {
      if (FILTER_MODE_OPTIONS[index].mode === this.normalizeFilterMode(this.filterModeDraft)) {
        return index;
      }
    }
    return 0;
  }

  private applyFilterModeByIndex(index: number): void {
    if (index >= 0 && index < FILTER_MODE_OPTIONS.length) {
      this.filterModeDraft = FILTER_MODE_OPTIONS[index].mode;
      this.updateFilterTagSuggestions();
    }
  }

  private filterRulesForMode(mode: number): FilterRule[] {
    const normalized = this.normalizeFilterMode(mode);
    return this.filterRules.filter((rule: FilterRule) => this.normalizeFilterMode(rule.mode) === normalized);
  }

  private isExcludedLanguageSelected(tag: string): boolean {
    return this.excludedLanguageTags.indexOf(tag) >= 0;
  }

  private toggleExcludedLanguage(tag: string): void {
    if (!isSupportedExcludedLanguageTag(tag)) {
      return;
    }
    if (this.isExcludedLanguageSelected(tag)) {
      this.excludedLanguageTags = this.excludedLanguageTags.filter((item: string) => item !== tag);
    } else {
      this.excludedLanguageTags = [...this.excludedLanguageTags, tag];
    }
    this.writeValue(EXCLUDED_LANGUAGE_KEY, JSON.stringify(this.excludedLanguageTags));
    this.refreshVisibleGalleryListsFromRaw();
  }

  private languageOptionByTag(tag: string): LanguageFilterOption | undefined {
    for (const option of EXCLUDED_LANGUAGE_OPTIONS) {
      if (option.tag === tag) {
        return option;
      }
    }
    return undefined;
  }

  private galleryMatchesExcludedLanguage(item: NativeGallerySummary): boolean {
    if (this.excludedLanguageTags.length === 0) {
      return false;
    }
    const simpleLanguage = item.simpleLanguage.trim().toUpperCase();
    for (const excludedTag of this.excludedLanguageTags) {
      const option = this.languageOptionByTag(excludedTag);
      if (!option) {
        continue;
      }
      if (simpleLanguage.length > 0 && simpleLanguage === option.code) {
        return true;
      }
      const expectedTag = `language:${option.tag}`;
      for (const tag of item.simpleTags) {
        if (tag.trim().toLowerCase() === expectedTag) {
          return true;
        }
      }
    }
    return false;
  }

  private activeGalleryFilters(): FilterRule[] {
    const filters: FilterRule[] = [];
    for (const rule of this.filterRules) {
      if (rule.enabled && rule.text.trim().length > 0) {
        filters.push(rule);
      }
    }
    return filters;
  }

  private parseTagValue(value: string): ParsedTag {
    const normalized = value.trim().toLowerCase();
    const separatorIndex = normalized.indexOf(':');
    if (separatorIndex < 0) {
      return {
        namespace: '',
        name: normalized
      };
    }
    return {
      namespace: normalized.substring(0, separatorIndex),
      name: normalized.substring(separatorIndex + 1)
    };
  }

  private matchesTagFilter(tagValue: string, filterText: string): boolean {
    const tag = this.parseTagValue(tagValue);
    const filter = this.parseTagValue(filterText);
    if (tag.name.length === 0 || filter.name.length === 0) {
      return false;
    }
    if (tag.namespace.length > 0 && filter.namespace.length > 0 && tag.namespace !== filter.namespace) {
      return false;
    }
    return tag.name === filter.name;
  }

  private matchesTagNamespaceFilter(tagValue: string, filterText: string): boolean {
    const tag = this.parseTagValue(tagValue);
    const namespace = filterText.trim().toLowerCase();
    return tag.namespace.length > 0 && namespace.length > 0 && tag.namespace === namespace;
  }

  private galleryMatchesFilter(item: NativeGallerySummary, rule: FilterRule): boolean {
    const text = rule.text.trim();
    if (text.length === 0) {
      return false;
    }
    switch (this.normalizeFilterMode(rule.mode)) {
      case FILTER_MODE_TITLE: {
        const title = `${item.title}\n${item.titleJpn}`.toLowerCase();
        return title.indexOf(text.toLowerCase()) >= 0;
      }
      case FILTER_MODE_UPLOADER:
        return item.uploader === text;
      case FILTER_MODE_TAG:
        for (const tag of item.simpleTags) {
          if (this.matchesTagFilter(tag, text)) {
            return true;
          }
        }
        return false;
      case FILTER_MODE_TAG_NAMESPACE:
        for (const tag of item.simpleTags) {
          if (this.matchesTagNamespaceFilter(tag, text)) {
            return true;
          }
        }
        return false;
      default:
        return false;
    }
  }

  private shouldHideGalleryByLocalFilters(item: NativeGallerySummary): boolean {
    if (this.galleryMatchesExcludedLanguage(item)) {
      return true;
    }
    for (const rule of this.activeGalleryFilters()) {
      if (this.galleryMatchesFilter(item, rule)) {
        return true;
      }
    }
    return false;
  }

  private applyLocalGalleryFilters(items: NativeGallerySummary[]): NativeGallerySummary[] {
    if (this.activeGalleryFilters().length === 0 && this.excludedLanguageTags.length === 0) {
      return items.slice();
    }
    return items.filter((item: NativeGallerySummary) => !this.shouldHideGalleryByLocalFilters(item));
  }

  private filterHiddenCount(rawItems: NativeGallerySummary[], visibleItems: NativeGallerySummary[]): number {
    return Math.max(0, rawItems.length - visibleItems.length);
  }

  private refreshVisibleGalleryListsFromRaw(): void {
    this.homeResults = this.applyLocalGalleryFilters(this.homeRawResults);
    this.homeFilteredCount = this.filterHiddenCount(this.homeRawResults, this.homeResults);
    this.favoriteResults = this.applyLocalGalleryFilters(this.favoriteRawResults);
    this.favoriteFilteredCount = this.filterHiddenCount(this.favoriteRawResults, this.favoriteResults);
    this.searchResults = this.applyLocalGalleryFilters(this.searchRawResults);
    this.searchFilteredCount = this.filterHiddenCount(this.searchRawResults, this.searchResults);
    this.nativeResults = this.applyLocalGalleryFilters(this.nativeRawResults);
    this.nativeFilteredCount = this.filterHiddenCount(this.nativeRawResults, this.nativeResults);
  }

  private filterStatusText(hiddenCount: number): string {
    if (hiddenCount <= 0) {
      return '';
    }
    return `本地过滤已隐藏 ${hiddenCount} 个画廊`;
  }

  private blacklistNameSet(): Set<string> {
    const names: Set<string> = new Set<string>();
    for (const item of this.blacklistItems) {
      const name = item.name.trim();
      if (name.length > 0) {
        names.add(name);
      }
    }
    return names;
  }

  private isBlacklistedUser(user: string): boolean {
    return this.blacklistNameSet().has(user.trim());
  }

  private visibleNativeComments(): NativeGalleryComment[] {
    const names = this.blacklistNameSet();
    if (names.size === 0) {
      return this.nativeDetail.comments.slice();
    }
    return this.nativeDetail.comments.filter((comment: NativeGalleryComment) => !names.has(comment.user.trim()));
  }

  private visibleNativeCommentPreview(): NativeGalleryComment[] {
    return this.visibleNativeComments().slice(0, 2);
  }

  private hiddenNativeCommentCount(): number {
    return Math.max(0, this.nativeDetail.comments.length - this.visibleNativeComments().length);
  }

  private commentsActionSubtitle(): string {
    const hidden = this.hiddenNativeCommentCount();
    if (this.nativeDetail.hasMoreComments) {
      return hidden > 0 ? `查看全部 · 已隐藏 ${hidden}` : '查看全部';
    }
    const total = this.nativeDetail.comments.length;
    const visible = total - hidden;
    return hidden > 0 ? `${visible}/${total}` : `${total}`;
  }

  private historyKey(record: LocalGalleryRecord): string {
    return `${record.site}-${record.gid}`;
  }

  private currentGalleryProgressKey(): string {
    if (this.nativeDetail.gid <= 0) {
      return '';
    }
    return `${this.siteMode}-${this.nativeDetail.gid}`;
  }

  private currentGalleryProgressPage(): number {
    this.readerProgressRevision;
    const key = this.currentGalleryProgressKey();
    if (key.length === 0) {
      return 0;
    }
    const page = this.readerProgressByGallery.get(key);
    if (page === undefined || page <= 0) {
      return 0;
    }
    const upperBound = Math.max(1, this.nativeDetail.pages, this.readerTotalPageCount());
    return clampNumber(Math.floor(page), 1, upperBound);
  }

  private hasCurrentGalleryProgress(): boolean {
    return this.currentGalleryProgressPage() > 0;
  }

  private currentGalleryProgressSubtitle(): string {
    const page = this.currentGalleryProgressPage();
    return page > 0 ? `从${page}页` : `${this.nativeDetail.pages} 页`;
  }

  private persistCurrentReaderProgress(): void {
    if (this.nativeDetail.gid <= 0 || this.nativeReaderPage.pageIndex < 0) {
      return;
    }
    const key = this.currentGalleryProgressKey();
    if (key.length === 0) {
      return;
    }
    const page = clampNumber(
      Math.floor(this.nativeReaderPage.pageIndex) + 1,
      1,
      Math.max(1, this.nativeDetail.pages, this.readerTotalPageCount())
    );
    this.readerProgressByGallery.set(key, page);
    this.saveReaderProgressSettings();
  }

  private downloadKey(gid: number, site: string): string {
    return `${site}-${gid}`;
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

  private recordHistory(record: LocalGalleryRecord): void {
    const nextItem = this.toHistoryItem(record, this.nowLabel());
    const nextKey = this.historyKey(record);
    const filtered = this.historyItems.filter((item: HistoryItem) => this.historyKey(item) !== nextKey);
    this.historyItems = [nextItem, ...filtered].slice(0, LOCAL_LIST_LOAD_LIMIT);
    this.saveHistoryItems();
  }

  private createRouteParamsForSummary(item: NativeGallerySummary, nativeRoute: string, readerPageUrl: string = ''): PageRouteParams {
    return createNativeRouteParams(
      this.currentRouteActiveSection(),
      this.currentRouteMyPage(),
      this.currentRouteMyPageTitle(),
      this.siteMode,
      item,
      nativeRoute,
      readerPageUrl
    );
  }

  private nativeRouteSnapshotKey(siteMode: string, item: NativeGallerySummary): string {
    return `${siteMode}:${item.gid}:${item.token}`;
  }

  private hasLoadedNativeDetailForSnapshot(item: NativeGallerySummary): boolean {
    if (this.nativeDetail.gid !== item.gid || this.nativeDetail.token !== item.token ||
      this.nativeDetail.detailUrl !== item.detailUrl) {
      return false;
    }
    return this.nativeDetail.tagGroups.length > 0 ||
      this.nativeDetail.comments.length > 0 ||
      this.nativeDetail.fileSize.length > 0 ||
      this.nativeDetail.visible.length > 0 ||
      this.nativeDetail.previewPageCount > 1;
  }

  private pruneNativeRouteSnapshots(): void {
    while (sharedNativeRouteSnapshots.size > SHARED_NATIVE_ROUTE_SNAPSHOT_LIMIT) {
      let oldestKey = '';
      let oldestUpdatedAt = Number.MAX_SAFE_INTEGER;
      sharedNativeRouteSnapshots.forEach((snapshot: NativeRouteSnapshot, key: string): void => {
        if (snapshot.updatedAt < oldestUpdatedAt) {
          oldestUpdatedAt = snapshot.updatedAt;
          oldestKey = key;
        }
      });
      if (oldestKey.length === 0) {
        return;
      }
      sharedNativeRouteSnapshots.delete(oldestKey);
    }
  }

  private saveNativeRouteSnapshot(item: NativeGallerySummary): void {
    if (!this.hasLoadedNativeDetailForSnapshot(item)) {
      return;
    }
    const key = this.nativeRouteSnapshotKey(this.siteMode, item);
    sharedNativeRouteSnapshots.set(key, {
      detail: this.nativeDetailSnapshot(),
      previewItems: this.nativePreviewItems.slice(),
      previewPageIndex: this.nativePreviewPageIndex,
      previewPageCount: this.nativePreviewPageCount,
      allPreviewItems: this.nativeAllPreviewItems.slice(),
      allPreviewLoadedPages: this.nativeAllPreviewLoadedPages,
      allPreviewPageCount: this.nativeAllPreviewPageCount,
      allPreviewStatus: this.nativeAllPreviewStatus,
      updatedAt: Date.now()
    });
    this.pruneNativeRouteSnapshots();
  }

  private nativeRouteTargetViewMode(): string {
    if (this.routeNativeMode === ROUTE_NATIVE_PREVIEWS) {
      return 'previews';
    }
    if (this.routeNativeMode === ROUTE_NATIVE_COMMENTS) {
      return 'comments';
    }
    return 'detail';
  }

  private restoreNativeRouteSnapshot(item: NativeGallerySummary, animate: boolean = false): boolean {
    const snapshot = sharedNativeRouteSnapshots.get(this.nativeRouteSnapshotKey(this.siteMode, item));
    if (!snapshot) {
      return false;
    }
    this.nativeDetail = snapshot.detail;
    this.nativeDetailRevision++;
    this.nativePreviewItems = snapshot.previewItems.slice();
    this.nativePreviewPageIndex = snapshot.previewPageIndex;
    this.nativePreviewPageCount = snapshot.previewPageCount;
    this.nativeAllPreviewItems = snapshot.allPreviewItems.slice();
    this.nativeAllPreviewLoadedPages = snapshot.allPreviewLoadedPages;
    this.nativeAllPreviewPageCount = snapshot.allPreviewPageCount;
    this.nativeAllPreviewStatus = snapshot.allPreviewStatus;
    this.nativeAllPreviewLoading = false;
    this.nativeCommentsLoading = false;
    this.nativeLoading = false;
    this.nativeLoadingMessage = '正在加载图库...';
    const targetViewMode = this.nativeRouteTargetViewMode();
    this.nativeViewMode = 'detail';
    if (targetViewMode !== 'detail') {
      const showTarget = (): void => {
        this.nativeViewMode = targetViewMode;
      };
      if (animate) {
        setTimeout(() => {
          this.runNativeRouteTransition(showTarget);
        }, 0);
      } else {
        showTarget();
      }
    }
    this.rebuildReaderPageDataSource();
    return true;
  }

  private clearPushedNativeRouteState(): void {
    this.routeNativeSummary = undefined;
    this.routeNativeMode = '';
    this.routeReaderPageUrl = '';
  }

  private shouldUseLocalNativeRoute(nativeRoute: string): boolean {
    return nativeRoute === ROUTE_NATIVE_DETAIL ||
      nativeRoute === ROUTE_NATIVE_READER;
  }

  private pushNativeRoute(item: NativeGallerySummary, nativeRoute: string, readerPageUrl: string = ''): void {
    if (this.shouldUseLocalNativeRoute(nativeRoute)) {
      this.clearPushedNativeRouteState();
      void this.loadNativeRoute(item, nativeRoute, readerPageUrl);
      return;
    }
    this.saveNativeRouteSnapshot(item);
    const params = this.createRouteParamsForSummary(item, nativeRoute, readerPageUrl);
    try {
      void this.getUIContext().getRouter().pushUrl({
        url: APP_INDEX_PAGE_URL,
        params
      }).catch(() => {
        void this.loadNativeRoute(item, nativeRoute, readerPageUrl);
      });
    } catch (error) {
      void this.loadNativeRoute(item, nativeRoute, readerPageUrl);
    }
  }

  private galleryCoverTransitionId(gid: number, token: string): string {
    if (gid <= 0 || token.length === 0) {
      return '';
    }
    return `gallery-cover:${gid}:${token}`;
  }

  private galleryCoverTransitionIdForSummary(item: NativeGallerySummary): string {
    if (item.thumb.length === 0) {
      return '';
    }
    return this.galleryCoverTransitionId(item.gid, item.token);
  }

  private galleryCoverTransitionIdForRecord(item: LocalGalleryRecord): string {
    if (item.cover.length === 0) {
      return '';
    }
    return this.galleryCoverTransitionId(item.gid, item.token);
  }

  private galleryCoverTransitionIdForDetail(): string {
    if (this.nativeDetail.cover.length === 0) {
      return '';
    }
    return this.galleryCoverTransitionId(this.nativeDetail.gid, this.nativeDetail.token);
  }

  private runGalleryCoverTransition(action: () => void): void {
    try {
      this.getUIContext().animateTo({
        duration: 320,
        curve: Curve.EaseOut
      }, action);
    } catch (error) {
      action();
    }
  }

  private runNativeRouteTransition(action: () => void): void {
    try {
      this.getUIContext().animateTo({
        duration: 280,
        curve: Curve.EaseOut
      }, action);
    } catch (error) {
      action();
    }
  }

  private showNativeDetailPreview(item: NativeGallerySummary, animate: boolean = true): void {
    this.hideSearchSuggestionOverlay();
    const action = (): void => {
      if (this.shouldReplaceNativeDetailPreview(item)) {
        this.nativeDetail = this.createDetailPreviewFromSummary(item);
        this.nativeDetailRevision++;
        this.nativePreviewItems = [];
        this.nativePreviewPageIndex = 0;
        this.nativePreviewPageCount = 1;
      }
      this.nativeViewMode = 'detail';
    };
    if (animate && this.nativeViewMode === 'list') {
      this.runGalleryCoverTransition(action);
    } else {
      action();
    }
  }

  private createDetailPreviewFromSummary(item: NativeGallerySummary): NativeGalleryDetail {
    const detail = createEmptyNativeGalleryDetail();
    detail.gid = item.gid;
    detail.token = item.token;
    detail.title = item.title;
    detail.titleJpn = item.titleJpn;
    detail.cover = item.thumb;
    detail.categoryLabel = item.categoryLabel;
    detail.posted = item.posted;
    detail.uploader = item.uploader;
    detail.rating = item.rating;
    detail.pages = item.pages;
    detail.language = item.simpleLanguage;
    detail.detailUrl = item.detailUrl;
    return detail;
  }

  private nativeDetailSnapshot(): NativeGalleryDetail {
    const detail = this.nativeDetail;
    return {
      gid: detail.gid,
      token: detail.token,
      title: detail.title,
      titleJpn: detail.titleJpn,
      cover: detail.cover,
      categoryLabel: detail.categoryLabel,
      posted: detail.posted,
      uploader: detail.uploader,
      rating: detail.rating,
      ratingCount: detail.ratingCount,
      pages: detail.pages,
      favoriteCount: detail.favoriteCount,
      isFavorited: detail.isFavorited,
      favoriteName: detail.favoriteName,
      apiUid: detail.apiUid,
      apiKey: detail.apiKey,
      torrentCount: detail.torrentCount,
      torrentUrl: detail.torrentUrl,
      archiveUrl: detail.archiveUrl,
      visible: detail.visible,
      language: detail.language,
      fileSize: detail.fileSize,
      parentUrl: detail.parentUrl,
      detailUrl: detail.detailUrl,
      previewPageCount: detail.previewPageCount,
      tagGroups: detail.tagGroups.map((group: NativeTagGroup): NativeTagGroup => {
        return {
          name: group.name,
          tags: group.tags.slice()
        };
      }),
      comments: detail.comments.slice(),
      hasMoreComments: detail.hasMoreComments
    };
  }

  private nativeDetailMetadataKey(): string {
    return [
      this.nativeDetail.gid,
      this.nativeDetail.token,
      this.nativeDetailRevision,
      this.nativeDetail.language,
      this.nativeDetail.visible,
      this.nativeDetail.fileSize,
      this.nativeDetail.favoriteCount,
      this.nativeDetail.torrentCount
    ].join(':');
  }

  @Builder
  private NativeDetailMetadataLine(label: string, value: string): void {
    Row({ space: 8 }) {
      Text(label)
        .width(48)
        .fontSize(12)
        .fontColor('#9A7D8A')
        .maxLines(1);
      Text(value.length > 0 ? value : '-')
        .layoutWeight(1)
        .fontSize(13)
        .fontColor('#4E3A45')
        .maxLines(1);
    }
    .width('100%')
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private NativeDetailMetadata(): void {
    ForEach([this.nativeDetailMetadataKey()], (_key: string) => {
      Column({ space: 7 }) {
        this.NativeDetailMetadataLine('语言', this.nativeDetail.language);
        this.NativeDetailMetadataLine('可见性', this.nativeDetail.visible);
        this.NativeDetailMetadataLine('大小', this.nativeDetail.fileSize);
        this.NativeDetailMetadataLine('收藏数', `${this.nativeDetail.favoriteCount}`);
        this.NativeDetailMetadataLine('Torrent', this.nativeDetail.torrentCount > 0 ? `${this.nativeDetail.torrentCount}` : '0');
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
    }, (key: string) => key);
  }

  private shouldReplaceNativeDetailPreview(item: NativeGallerySummary): boolean {
    return this.nativeDetail.gid !== item.gid ||
      this.nativeDetail.token !== item.token ||
      this.nativeDetail.detailUrl !== item.detailUrl;
  }

  private createSummaryFromDetail(): NativeGallerySummary | undefined {
    if (this.nativeDetail.gid <= 0 || this.nativeDetail.detailUrl.length === 0) {
      return undefined;
    }
    return {
      gid: this.nativeDetail.gid,
      token: this.nativeDetail.token,
      title: this.nativeDetail.title,
      titleJpn: this.nativeDetail.titleJpn,
      thumb: this.nativeDetail.cover,
      categoryLabel: this.nativeDetail.categoryLabel,
      posted: this.nativeDetail.posted,
      uploader: this.nativeDetail.uploader,
      rating: this.nativeDetail.rating,
      pages: this.nativeDetail.pages,
      simpleTags: [],
      simpleLanguage: this.nativeDetail.language,
      detailUrl: this.nativeDetail.detailUrl
    };
  }

  private async openNativeDetail(item: NativeGallerySummary): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      return;
    }
    this.saveCurrentGalleryListScrollOffset();
    this.hideSearchSuggestionOverlay();
    this.recordHistory(this.createRecordFromSummary(item));
    this.pushNativeRoute(item, ROUTE_NATIVE_DETAIL);
  }

  private async loadNativeRoute(item: NativeGallerySummary, nativeRoute: string, readerPageUrl: string): Promise<void> {
    this.nativeError = '';
    this.stopReaderRuntimeState();
    const restored = this.restoreNativeRouteSnapshot(item, false);
    if (!restored) {
      this.showNativeDetailPreview(item);
      this.nativeLoading = true;
      if (nativeRoute === ROUTE_NATIVE_READER) {
        this.nativeLoadingMessage = '正在加载阅读页...';
      } else if (nativeRoute === ROUTE_NATIVE_PREVIEWS) {
        this.nativeLoadingMessage = '正在加载预览...';
      } else if (nativeRoute === ROUTE_NATIVE_COMMENTS) {
        this.nativeLoadingMessage = '正在加载评论...';
      } else {
        this.nativeLoadingMessage = '正在加载详情...';
      }
    }
    const loaded = restored || await this.loadNativeDetail(item, nativeRoute === ROUTE_NATIVE_DETAIL);
    if (loaded && nativeRoute === ROUTE_NATIVE_READER && readerPageUrl.length > 0) {
      await this.loadNativeReaderByPageUrl(readerPageUrl);
    } else if (loaded && nativeRoute === ROUTE_NATIVE_PREVIEWS) {
      if (restored && this.nativeAllPreviewItems.length > 0) {
        this.nativeViewMode = 'previews';
      } else {
        await this.loadNativeAllPreviewPages();
      }
    } else if (loaded && nativeRoute === ROUTE_NATIVE_COMMENTS) {
      await this.loadNativeCommentsPageLocal();
    } else if (loaded) {
      this.nativeViewMode = 'detail';
    }
  }

  private async loadNativeDetail(item: NativeGallerySummary, revealDetail: boolean = true): Promise<boolean> {
    if (!this.ensureNativeSiteReady()) {
      return false;
    }
    this.nativeLoading = true;
    this.nativeLoadingMessage = '正在加载详情...';
    this.nativeError = '';
    if (this.activeSection === NAV_HOME) {
      this.homeError = '';
    } else if (this.activeSection === NAV_SEARCH) {
      this.searchError = '';
    }
    try {
      this.nativeDetail = await NativeEhClient.fetchGalleryDetail(this.siteMode, item);
      this.nativeDetailRevision++;
      this.resetNativeDetailAccountPanels();
      this.nativeAllPreviewLoadSerial++;
      this.nativeAllPreviewItems = [];
      this.nativeAllPreviewLoading = false;
      this.nativeAllPreviewLoadedPages = 0;
      this.nativeAllPreviewPageCount = 0;
      this.nativeAllPreviewStatus = '';
      this.prefetchGalleryDetailCover();
      try {
        await this.loadNativePreviewPage(0);
      } catch (error) {
        this.nativePreviewItems = [];
        this.nativePreviewPageIndex = 0;
        this.nativePreviewPageCount = Math.max(1, this.nativeDetail.previewPageCount);
      }
      this.stopReaderRuntimeState();
      if (revealDetail) {
        this.nativeViewMode = 'detail';
      }
      this.saveNativeRouteSnapshot(item);
      return true;
    } catch (error) {
      this.nativeError = '原生详情加载失败。';
      if (this.activeSection === NAV_HOME) {
        this.homeError = this.nativeError;
      } else if (this.activeSection === NAV_SEARCH) {
        this.searchError = this.nativeError;
      }
      return false;
    } finally {
      this.nativeLoading = false;
      this.nativeLoadingMessage = '正在加载图库...';
    }
  }

  private resetNativeDetailAccountPanels(): void {
    this.favoritePanelVisible = false;
    this.ratingPanelVisible = false;
    this.torrentPanelVisible = false;
    this.archivePanelVisible = false;
    this.detailActionLoading = false;
    this.detailActionStatus = '';
    this.selectedRating = this.nativeDetail.rating > 0 ? this.nativeDetail.rating : 0;
    this.nativeCommentsLoading = false;
    this.nativeCommentsStatus = '';
    this.torrentItems = [];
    this.torrentLoading = false;
    this.torrentStatus = '';
    this.archiveList = {
      formParamOr: '',
      items: []
    };
    this.archiveLoading = false;
    this.archiveStatus = '';
    this.favoritePanelSlotDraft = this.favoriteQuickSlot();
  }

  private async loadNativePreviewPage(pageIndex: number): Promise<void> {
    if (!this.ensureNativeSiteReady() || this.nativeDetail.detailUrl.length === 0) {
      return;
    }
    const previewPage = await NativeEhClient.fetchGalleryPreviewPage(this.siteMode, this.nativeDetail.detailUrl, pageIndex);
    this.nativePreviewItems = previewPage.items;
    this.nativePreviewPageIndex = previewPage.pageIndex;
    this.nativePreviewPageCount = previewPage.pageCount;
    this.rebuildReaderPageDataSource();
    this.prefetchGalleryPreviewImages(previewPage.items);
    const currentSummary = this.createSummaryFromDetail();
    if (currentSummary) {
      this.saveNativeRouteSnapshot(currentSummary);
    }
  }

  private async changeNativePreviewPage(pageIndex: number): Promise<void> {
    if (!this.ensureNativeSiteReady()) {
      return;
    }
    this.nativePreviewLoading = true;
    this.nativeError = '';
    try {
      await this.loadNativePreviewPage(pageIndex);
    } catch (error) {
      this.nativeError = '预览页加载失败。';
    } finally {
      this.nativePreviewLoading = false;
    }
  }

  private mergeNativePreviewItems(baseItems: NativeGalleryPreview[], nextItems: NativeGalleryPreview[]): NativeGalleryPreview[] {
    const merged: NativeGalleryPreview[] = [];
    const seenUrls: string[] = [];
    const appendItems = (items: NativeGalleryPreview[]): void => {
      for (const item of items) {
        if (item.pageUrl.length === 0 || seenUrls.indexOf(item.pageUrl) >= 0) {
          continue;
        }
        seenUrls.push(item.pageUrl);
        merged.push(item);
      }
    };
    appendItems(baseItems);
    appendItems(nextItems);
    merged.sort((left: NativeGalleryPreview, right: NativeGalleryPreview): number => left.position - right.position);
    return merged;
  }

  private async loadNativeAllPreviewPages(): Promise<void> {
    if (!this.ensureNativeSiteReady() || this.nativeDetail.detailUrl.length === 0) {
      return;
    }
    const serial = ++this.nativeAllPreviewLoadSerial;
    this.nativeViewMode = 'previews';
    this.nativeAllPreviewItems = this.mergeNativePreviewItems([], this.nativePreviewItems);
    this.nativeAllPreviewLoadedPages = this.nativePreviewItems.length > 0 ? 1 : 0;
    this.nativeAllPreviewPageCount = Math.max(1, this.nativePreviewPageCount, this.nativeDetail.previewPageCount);
    this.nativeAllPreviewLoading = true;
    this.nativeAllPreviewStatus = `正在加载预览 ${this.nativeAllPreviewLoadedPages}/${this.nativeAllPreviewPageCount}`;
    this.nativeError = '';

    try {
      if (this.nativePreviewItems.length === 0 || this.nativePreviewPageIndex !== 0) {
        this.nativeAllPreviewStatus = `正在加载预览 1/${this.nativeAllPreviewPageCount}`;
        const firstPage = await NativeEhClient.fetchGalleryPreviewPage(this.siteMode, this.nativeDetail.detailUrl, 0);
        if (serial !== this.nativeAllPreviewLoadSerial) {
          return;
        }
        this.nativePreviewItems = firstPage.items;
        this.nativePreviewPageIndex = firstPage.pageIndex;
        this.nativePreviewPageCount = firstPage.pageCount;
        this.nativeAllPreviewItems = this.mergeNativePreviewItems(this.nativeAllPreviewItems, firstPage.items);
        this.nativeAllPreviewLoadedPages = 1;
        this.nativeAllPreviewPageCount = Math.max(this.nativeAllPreviewPageCount, firstPage.pageCount);
        this.rebuildReaderPageDataSource();
        this.prefetchGalleryPreviewImages(firstPage.items);
      }

      let pageCount = Math.max(this.nativeAllPreviewPageCount, this.nativePreviewPageCount, this.nativeDetail.previewPageCount);
      for (let pageIndex = 1; pageIndex < pageCount; pageIndex++) {
        if (serial !== this.nativeAllPreviewLoadSerial) {
          return;
        }
        this.nativeAllPreviewStatus = `正在加载预览 ${pageIndex + 1}/${pageCount}`;
        const previewPage = await NativeEhClient.fetchGalleryPreviewPage(this.siteMode, this.nativeDetail.detailUrl, pageIndex);
        if (serial !== this.nativeAllPreviewLoadSerial) {
          return;
        }
        this.nativeAllPreviewItems = this.mergeNativePreviewItems(this.nativeAllPreviewItems, previewPage.items);
        this.nativeAllPreviewLoadedPages = Math.max(this.nativeAllPreviewLoadedPages, pageIndex + 1);
        pageCount = Math.max(pageCount, previewPage.pageCount);
        this.nativeAllPreviewPageCount = pageCount;
        this.rebuildReaderPageDataSource();
        this.prefetchGalleryPreviewImages(previewPage.items);
      }
      this.nativeAllPreviewStatus = `已加载 ${this.nativeAllPreviewItems.length} 张预览`;
    } catch (error) {
      if (serial === this.nativeAllPreviewLoadSerial) {
        this.nativeError = '全部预览加载失败。';
        this.nativeAllPreviewStatus = `请求失败前已加载 ${this.nativeAllPreviewItems.length} 张预览`;
      }
    } finally {
      if (serial === this.nativeAllPreviewLoadSerial) {
        this.nativeAllPreviewLoading = false;
        const currentSummary = this.createSummaryFromDetail();
        if (currentSummary) {
          this.saveNativeRouteSnapshot(currentSummary);
        }
      }
    }
  }

  private async openNativeAllPreviews(): Promise<void> {
    const currentSummary = this.createSummaryFromDetail();
    if (currentSummary) {
      this.pushNativeRoute(currentSummary, ROUTE_NATIVE_PREVIEWS);
      return;
    }
    await this.loadNativeAllPreviewPages();
  }

  private findPreviewIndex(pageUrl: string): number {
    for (let index = 0; index < this.nativePreviewItems.length; index++) {
      if (this.nativePreviewItems[index].pageUrl === pageUrl) {
        return index;
      }
    }
    return -1;
  }

  private parseReaderPagePosition(pageUrl: string): number {
    const localMatch = /^local:\/\/reader\/\d+\/(\d+)$/i.exec(pageUrl);
    if (localMatch && localMatch[1]) {
      const localPageNumber = Number(localMatch[1]);
      return Number.isFinite(localPageNumber) && localPageNumber > 0 ? localPageNumber - 1 : -1;
    }
    const match = /\/s\/[0-9a-f]{10}\/\d+-(\d+)/i.exec(pageUrl);
    if (!match || !match[1]) {
      return -1;
    }
    const pageNumber = Number(match[1]);
    return Number.isFinite(pageNumber) && pageNumber > 0 ? pageNumber - 1 : -1;
  }

  private previewPageGuessForReader(pageUrl: string): number {
    const pagePosition = this.parseReaderPagePosition(pageUrl);
    if (pagePosition < 0) {
      return this.nativePreviewPageIndex;
    }
    const currentSize = this.nativePreviewItems.length > 0 ? this.nativePreviewItems.length : 40;
    return Math.min(Math.max(0, Math.floor(pagePosition / currentSize)), Math.max(0, this.nativePreviewPageCount - 1));
  }

  private async ensurePreviewPageContains(pageUrl: string): Promise<number> {
    let previewIndex = this.findPreviewIndex(pageUrl);
    if (previewIndex >= 0) {
      return previewIndex;
    }
    if (this.nativeDetail.detailUrl.length === 0 || this.nativePreviewPageCount <= 1) {
      return -1;
    }

    const guessedPage = this.previewPageGuessForReader(pageUrl);
    const visited: number[] = [];
    const candidates: number[] = [guessedPage, this.nativePreviewPageIndex, 0];
    for (let offset = 1; offset < this.nativePreviewPageCount; offset++) {
      candidates.push(guessedPage - offset);
      candidates.push(guessedPage + offset);
    }

    for (const candidate of candidates) {
      if (candidate < 0 || candidate >= this.nativePreviewPageCount || visited.indexOf(candidate) >= 0) {
        continue;
      }
      visited.push(candidate);
      await this.loadNativePreviewPage(candidate);
      previewIndex = this.findPreviewIndex(pageUrl);
      if (previewIndex >= 0) {
        return previewIndex;
      }
    }
    return -1;
  }

  private canShiftNativeReaderBackward(): boolean {
    return this.nativeReaderPage.pageIndex > 0 ||
      this.readerPageUrlByOffset(-1).length > 0 ||
      this.nativePreviewPageIndex > 0;
  }

  private canShiftNativeReaderForward(): boolean {
    return this.nativeReaderPage.pageIndex + 1 < this.readerTotalPageCount() ||
      this.readerPageUrlByOffset(1).length > 0 ||
      this.nativePreviewPageIndex + 1 < this.nativePreviewPageCount;
  }

  private hasActiveReaderPage(): boolean {
    return this.nativeViewMode === 'reader' && this.nativeReaderPage.pageUrl.length > 0;
  }

  private normalizeReaderReturnViewMode(viewMode: string): string {
    if (viewMode === 'previews' || viewMode === 'comments' || viewMode === 'detail') {
      return viewMode;
    }
    return 'detail';
  }

  private captureReaderReturnViewMode(viewMode: string): void {
    if (viewMode === 'reader') {
      return;
    }
    this.readerReturnViewMode = this.normalizeReaderReturnViewMode(viewMode);
  }

  private async openNativeReaderByPageUrl(pageUrl: string): Promise<void> {
    const currentSummary = this.createSummaryFromDetail();
    if (currentSummary) {
      this.pendingReaderReturnViewMode = this.normalizeReaderReturnViewMode(this.nativeViewMode);
      this.pushNativeRoute(currentSummary, ROUTE_NATIVE_READER, pageUrl);
      return;
    }
    await this.loadNativeReaderByPageUrl(pageUrl);
  }

  private firstReadablePreviewUrl(): string {
    if (this.nativePreviewItems.length > 0) {
      return this.nativePreviewItems[0].pageUrl;
    }
    return '';
  }

  private async openNativeReaderFromStart(): Promise<void> {
    if (!this.ensureNativeSiteReady() || this.nativeDetail.detailUrl.length === 0) {
      return;
    }
    this.nativeLoading = true;
    this.nativeLoadingMessage = '正在准备阅读器...';
    this.nativeError = '';
    try {
      if (this.nativePreviewItems.length === 0) {
        await this.loadNativePreviewPage(0);
      }
      let firstUrl = this.firstReadablePreviewUrl();
      if (firstUrl.length === 0) {
        firstUrl = await NativeEhClient.fetchFirstReaderPageUrl(this.siteMode, this.nativeDetail.detailUrl);
      }
      if (firstUrl.length === 0) {
        this.toast('未找到该画廊的阅读页链接');
        return;
      }
      await this.openNativeReaderByPageUrl(firstUrl);
    } catch (error) {
      this.nativeError = '阅读器启动失败。';
    } finally {
      this.nativeLoading = false;
      this.nativeLoadingMessage = '正在加载图库...';
    }
  }

  private async openNativeReaderFromProgress(): Promise<void> {
    const page = this.currentGalleryProgressPage();
    if (page <= 0) {
      await this.openNativeReaderFromStart();
      return;
    }
    if (!this.ensureNativeSiteReady() || this.nativeDetail.detailUrl.length === 0) {
      return;
    }
    this.nativeLoading = true;
    this.nativeLoadingMessage = `正在跳转到第 ${page} 页...`;
    this.nativeError = '';
    try {
      const pageUrl = await this.resolveReaderPageUrlByIndex(page - 1);
      if (pageUrl.length === 0) {
        this.toast('未找到上次阅读页，已从头开始');
        await this.openNativeReaderFromStart();
        return;
      }
      await this.openNativeReaderByPageUrl(pageUrl);
    } catch (error) {
      this.nativeError = '阅读器启动失败。';
    } finally {
      this.nativeLoading = false;
      this.nativeLoadingMessage = '正在加载图库...';
    }
  }

  private cacheNativeReaderImageInBackground(page: NativeGalleryImagePage, loadSerial: number): void {
    void this.ensureReaderImageCached(page).then((localUri: string) => {
      if (loadSerial !== this.readerLoadSerial || page.pageUrl !== this.nativeReaderPage.pageUrl) {
        return;
      }
      if (localUri.length > 0) {
        this.readerDisplayImageUrl = localUri;
      }
      this.readerCurrentError = '';
      this.readerCacheStatus = `第 ${page.pageIndex + 1} 页已缓存`;
      this.refreshReaderAdjacentPages();
    }).catch((imageError: Object) => {
      if (loadSerial !== this.readerLoadSerial || page.pageUrl !== this.nativeReaderPage.pageUrl) {
        return;
      }
      this.markReaderPageForRetryRefresh(page.pageUrl);
      const message = this.readableErrorMessage(imageError, '当前图片缓存失败');
      if (this.readerDisplayImageUrl.length === 0) {
        this.readerCurrentError = message;
        this.readerDisplayImageUrl = this.readerSelectedImageUrl(page);
      }
      this.readerCacheStatus = '当前图片缓存失败';
      this.refreshReaderAdjacentPages();
    });
  }

  private async loadNativeReaderByPageUrl(pageUrl: string): Promise<void> {
    if (!this.isLocalReaderPageUrl(pageUrl) && !this.ensureNativeSiteReady()) {
      return;
    }
    if (this.nativeViewMode !== 'reader') {
      const returnViewMode = this.pendingReaderReturnViewMode.length > 0 ?
        this.pendingReaderReturnViewMode :
        this.nativeViewMode;
      this.captureReaderReturnViewMode(returnViewMode);
      this.pendingReaderReturnViewMode = '';
    }
    const loadSerial = ++this.readerLoadSerial;
    const isLatestLoad = (): boolean => loadSerial === this.readerLoadSerial;
    const previewIndex = await this.ensurePreviewPageContains(pageUrl);
    if (!isLatestLoad()) {
      return;
    }
    this.nativeLoading = true;
    this.nativeLoadingMessage = '正在加载阅读页...';
    this.nativeError = '';
    this.readerCurrentError = '';
    try {
      const page = await this.ensureReaderPagePrepared(pageUrl);
      if (!isLatestLoad()) {
        return;
      }
      const previousPageUrl = this.nativeReaderPage.pageUrl;
      this.nativeReaderPage = page;
      this.nativeReaderListIndex = previewIndex;
      this.readerJumpInput = this.nativeReaderPage.pageLabel;
      this.readerDisplayImageUrl = this.readerDisplayUrlForPage(page);
      this.nativeViewMode = 'reader';
      this.rebuildReaderPageDataSource();
      this.onReaderEntered();
      this.refreshReaderAdjacentPages();
      this.scheduleReaderPreloadWindow(page.pageUrl);
      if (previousPageUrl.length > 0 && previousPageUrl !== page.pageUrl) {
        this.showReaderTopInfo();
      }
      this.cacheNativeReaderImageInBackground(page, loadSerial);
    } catch (error) {
      if (!isLatestLoad()) {
        return;
      }
      const message = this.readableErrorMessage(error, '阅读器加载失败');
      this.nativeError = message.length > 0 ? `原生阅读器加载失败：${message}` : '原生阅读器加载失败。';
      this.readerCurrentError = this.nativeError;
    } finally {
      if (isLatestLoad()) {
        this.nativeLoading = false;
        this.nativeLoadingMessage = '正在加载图库...';
      }
    }
  }

  private async shiftNativeReader(offset: number): Promise<void> {
    const targetReaderPageIndex = this.nativeReaderPage.pageIndex + offset;
    if (this.nativeReaderListIndex >= 0) {
      const nextIndex = this.nativeReaderListIndex + offset;
      if (nextIndex >= 0 && nextIndex < this.nativePreviewItems.length) {
        await this.loadNativeReaderByPageUrl(this.nativePreviewItems[nextIndex].pageUrl);
        return;
      }
    }
    let nextPreviewPage = this.nativePreviewPageIndex + (offset > 0 ? 1 : -1);
    if (this.nativeReaderListIndex < 0 && this.nativeReaderPage.pageIndex >= 0) {
      const pageSetSize = this.nativePreviewItems.length > 0 ? this.nativePreviewItems.length : 40;
      nextPreviewPage = Math.floor(targetReaderPageIndex / pageSetSize);
    }
    if (nextPreviewPage < 0 || nextPreviewPage >= this.nativePreviewPageCount) {
      this.toast('没有更多页面');
      return;
    }
    this.nativeLoading = true;
    this.nativeLoadingMessage = '正在加载预览...';
    this.nativeError = '';
    try {
      await this.loadNativePreviewPage(nextPreviewPage);
      if (this.nativePreviewItems.length === 0) {
        this.toast('当前预览组没有解析到页面');
        return;
      }
      let targetIndex = offset > 0 ? 0 : this.nativePreviewItems.length - 1;
      if (this.nativeReaderListIndex < 0 && targetReaderPageIndex >= 0) {
        const positionIndex = this.nativePreviewItems.findIndex((item: NativeGalleryPreview) =>
          item.position === targetReaderPageIndex);
        if (positionIndex >= 0) {
          targetIndex = positionIndex;
        }
      }
      await this.loadNativeReaderByPageUrl(this.nativePreviewItems[targetIndex].pageUrl);
    } catch (error) {
      this.nativeError = '阅读页切换失败。';
    } finally {
      this.nativeLoading = false;
      this.nativeLoadingMessage = '正在加载图库...';
    }
  }

  private async jumpNativeReader(): Promise<void> {
    const pageNumber = Number(this.readerJumpInput.trim());
    if (!Number.isFinite(pageNumber) || pageNumber <= 0) {
      this.toast('请输入有效页码');
      return;
    }
    const maximumPage = this.nativeDetail.pages > 0 ? this.nativeDetail.pages : pageNumber;
    const normalizedPage = Math.min(Math.floor(pageNumber), maximumPage);
    const currentPage = this.nativeReaderPage.pageIndex + 1;
    if (normalizedPage === currentPage) {
      return;
    }
    const pagePosition = normalizedPage - 1;
    const pageSetSize = this.nativePreviewItems.length > 0 ? this.nativePreviewItems.length : 40;
    const previewPage = Math.min(Math.floor(pagePosition / pageSetSize), Math.max(0, this.nativePreviewPageCount - 1));
    this.showReaderTopInfo();
    this.nativeLoading = true;
    this.nativeLoadingMessage = '正在跳转阅读页...';
    this.nativeError = '';
    try {
      await this.loadNativePreviewPage(previewPage);
      for (const item of this.nativePreviewItems) {
        if (item.position === pagePosition) {
          await this.loadNativeReaderByPageUrl(item.pageUrl);
          return;
        }
      }
      this.toast('预览数据中未找到目标页');
    } catch (error) {
      this.nativeError = '阅读页跳转失败。';
    } finally {
      this.nativeLoading = false;
      this.nativeLoadingMessage = '正在加载图库...';
    }
  }

  private toggleReaderFit(): void {
    this.setReaderPageScaling(this.readerFitContain ? '0' : '3');
  }

  private readerPageInfoText(): string {
    const state = this.readerVisibleCurrentState();
    const pageLabel = state.pageLabel.length > 0 ? state.pageLabel : `${state.pageIndex + 1}`;
    return `第 ${pageLabel} 页`;
  }

  private readerProgressText(): string {
    const totalPages = this.nativeDetail.pages > 0 ? this.nativeDetail.pages : 0;
    if (totalPages <= 0) {
      return '';
    }
    const currentPage = this.readerVisibleCurrentState().pageIndex + 1;
    return `${currentPage}/${totalPages}`;
  }

  private readerTopPageText(): string {
    const progress = this.readerProgressText();
    if (progress.length > 0) {
      return progress;
    }
    return this.readerPageInfoText();
  }

  private readerRubberBandOffset(offset: number): number {
    const primarySize = this.readerPagerSpan();
    const limit = Math.max(96, primarySize * 0.45);
    const maximum = Math.max(limit + 32, primarySize * 0.72);
    const absoluteOffset = Math.abs(offset);
    const direction = offset < 0 ? -1 : 1;
    if (absoluteOffset <= limit) {
      return offset;
    }
    return direction * Math.min(maximum, limit + (absoluteOffset - limit) * 0.28);
  }

  private readerPrimaryGestureOffset(event: GestureEvent): number {
    return this.isReaderVerticalDirection() ? event.offsetY : event.offsetX;
  }

  private readerShiftFromGesture(): number {
    const primaryOffset = this.readerDragOffset;
    const threshold = Math.max(48, this.readerViewportPrimarySize() * 0.5);
    if (Math.abs(primaryOffset) < threshold) {
      return 0;
    }

    if (this.isReaderVerticalDirection()) {
      return primaryOffset < 0 ? 1 : -1;
    }
    if (this.readerDirection === '1') {
      return primaryOffset > 0 ? 1 : -1;
    }
    return primaryOffset < 0 ? 1 : -1;
  }

  private readerExitOffsetForShift(offset: number): number {
    const distance = this.readerPagerSpan();
    if (this.isReaderVerticalDirection()) {
      return offset > 0 ? -distance : distance;
    }
    if (this.readerDirection === '1') {
      return offset > 0 ? distance : -distance;
    }
    return offset > 0 ? -distance : distance;
  }

  private readerLoadingText(): string {
    if (this.nativeLoadingMessage.length > 0 && this.nativeLoadingMessage !== '正在加载图库...') {
      return this.nativeLoadingMessage;
    }
    if (this.readerPageSwitching || this.readerTargetLoading) {
      return '正在加载阅读页...';
    }
    return this.nativeLoadingMessage;
  }

  private shouldShowReaderGlobalLoading(): boolean {
    return this.nativeReaderPage.pageUrl.length === 0 &&
      (this.nativeLoading || this.readerTargetLoading || this.readerPageSwitching);
  }

  private resetReaderDragOffset(): void {
    this.readerDragActive = false;
    this.readerPanPagingActive = false;
    this.readerDragOffset = 0;
  }

  private readerTransitionDuration(): number {
    return 180;
  }

  private isPushedNativeReaderRoute(): boolean {
    return this.routeNativeSummary !== undefined && this.routeNativeMode === ROUTE_NATIVE_READER;
  }

  private tryBackToPushedNativeDetail(): boolean {
    if (!this.isPushedNativeReaderRoute()) {
      return false;
    }
    return this.tryRouterBack();
  }

  private isRouterBackAvailable(): boolean {
    try {
      const router = this.getUIContext().getRouter();
      const length = router.getStackSize();
      return Number.isFinite(length) && length > 1;
    } catch (error) {
    }
    return false;
  }

  private tryRouterBack(): boolean {
    try {
      const router = this.getUIContext().getRouter();
      const length = router.getStackSize();
      if (Number.isFinite(length) && length > 1) {
        router.back();
        return true;
      }
    } catch (error) {
    }
    return false;
  }

  private isRouteSearchBackAvailable(): boolean {
    return this.routeSearchUrl.length > 0 &&
      this.activeSection === NAV_SEARCH &&
      this.nativeViewMode === 'list' &&
      this.searchResultsActive &&
      this.isRouterBackAvailable();
  }

  private isRouteBackAvailableForCurrentSubPage(): boolean {
    if (this.isMySubPage()) {
      return false;
    }
    if (this.routeNativeSummary === undefined) {
      return false;
    }
    if (this.nativeViewMode === 'reader') {
      return this.routeNativeMode === ROUTE_NATIVE_READER && this.isRouterBackAvailable();
    }
    if (this.nativeViewMode === 'previews') {
      return this.routeNativeMode === ROUTE_NATIVE_PREVIEWS && this.isRouterBackAvailable();
    }
    if (this.nativeViewMode === 'comments') {
      return this.routeNativeMode === ROUTE_NATIVE_COMMENTS && this.isRouterBackAvailable();
    }
    if (this.nativeViewMode === 'detail') {
      return this.routeNativeMode === ROUTE_NATIVE_DETAIL && this.isRouterBackAvailable();
    }
    return false;
  }

  private async waitReaderTransitionDuration(): Promise<void> {
    await new Promise<void>((resolve: () => void): void => {
      setTimeout(() => {
        resolve();
      }, this.readerTransitionDuration());
    });
  }

  private async shiftReaderWithFeedback(offset: number, releaseOffset: number = 0): Promise<void> {
    const targetPageUrl = this.readerPageUrlByOffset(offset);
    if (this.readerPageSwitching) {
      this.readerTargetLoading = true;
      return;
    }
    if (this.nativeLoading) {
      this.readerTargetLoading = true;
      return;
    }
    if (offset < 0 && !this.canShiftNativeReaderBackward()) {
      this.resetReaderDragOffset();
      this.toast('没有更多页面');
      return;
    }
    if (offset > 0 && !this.canShiftNativeReaderForward()) {
      this.resetReaderDragOffset();
      this.toast('没有更多页面');
      return;
    }

    this.readerPageSwitching = true;
    this.readerTargetLoading = true;
    this.readerDragActive = false;
    this.captureReaderTransitionSnapshot();
    this.nativeLoadingMessage = offset > 0 ? '正在加载下一页...' : '正在加载上一页...';
    if (releaseOffset !== 0) {
      this.readerDragOffset = releaseOffset;
    }
    this.readerDragOffset = this.readerExitOffsetForShift(offset);
    try {
      await this.waitReaderTransitionDuration();
      if (targetPageUrl.length > 0) {
        this.applyReaderPagePlaceholder(targetPageUrl);
        this.clearReaderTransitionSnapshot();
        this.readerDragOffset = 0;
        await this.loadNativeReaderByPageUrl(targetPageUrl);
      } else {
        await this.shiftNativeReader(offset);
      }
    } finally {
      this.clearReaderTransitionSnapshot();
      this.readerPageSwitching = false;
      this.readerTargetLoading = false;
      this.resetReaderDragOffset();
    }
  }

  private goReaderPrevious(): void {
    if (!this.canShiftNativeReaderBackward()) {
      return;
    }
    this.showReaderPageByOffset(-1);
  }

  private goReaderNext(): void {
    if (!this.canShiftNativeReaderForward()) {
      return;
    }
    this.showReaderPageByOffset(1);
  }

  private goReaderLeftSide(): void {
    if (this.readerDirection === '1') {
      this.goReaderNext();
      return;
    }
    this.goReaderPrevious();
  }

  private goReaderRightSide(): void {
    if (this.readerDirection === '1') {
      this.goReaderPrevious();
      return;
    }
    this.goReaderNext();
  }

  private handleReaderPanStart(): void {
    if (this.nativeLoading || this.readerPageSwitching) {
      this.readerTargetLoading = true;
      return;
    }
    this.readerDragActive = true;
    this.readerPanPagingActive = false;
    this.readerTargetLoading = false;
  }

  private handleReaderPanUpdate(event: GestureEvent): void {
    if (this.nativeLoading || this.readerPageSwitching) {
      this.readerTargetLoading = true;
      return;
    }
    const horizontal = Math.abs(event.offsetX);
    const vertical = Math.abs(event.offsetY);
    if (!this.readerPanPagingActive) {
      if (this.isReaderVerticalDirection()) {
        this.readerPanPagingActive = vertical > horizontal * 1.5;
      } else {
        this.readerPanPagingActive = horizontal > vertical * 1.5;
      }
    }
    if (!this.readerPanPagingActive) {
      return;
    }
    this.readerDragActive = true;
    this.readerDragOffset = this.readerRubberBandOffset(this.readerPrimaryGestureOffset(event));
  }

  private handleReaderPanEnd(_event: GestureEvent): void {
    if (!this.readerPanPagingActive) {
      this.resetReaderDragOffset();
      return;
    }
    const shiftOffset = this.readerShiftFromGesture();
    this.readerDragActive = false;
    if (shiftOffset === 0) {
      this.readerDragOffset = 0;
      return;
    }
    if (shiftOffset < 0 && !this.canShiftNativeReaderBackward()) {
      this.readerDragOffset = 0;
      this.toast('没有更多页面');
      return;
    }
    if (shiftOffset > 0 && !this.canShiftNativeReaderForward()) {
      this.readerDragOffset = 0;
      this.toast('没有更多页面');
      return;
    }
    void this.shiftReaderWithFeedback(shiftOffset, this.readerDragOffset);
  }

  private handleReaderPanCancel(): void {
    this.resetReaderDragOffset();
  }

  private handleReaderTap(event: ClickEvent): void {
    const previousWeight = 4;
    const menuWeight = 5;
    const totalWeight = previousWeight + menuWeight + 4;
    const previousLimit = previousWeight / totalWeight;
    const menuLimit = (previousWeight + menuWeight) / totalWeight;
    const primary = this.isReaderVerticalDirection() ?
      event.y / Math.max(1, this.readerViewportHeight) :
      event.x / Math.max(1, this.readerViewportWidth);
    if (primary < previousLimit) {
      if (this.isReaderVerticalDirection()) {
        this.goReaderPrevious();
      } else {
        this.goReaderLeftSide();
      }
      return;
    }
    if (primary < menuLimit) {
      this.toggleReaderOverlayMenu();
      return;
    }
    if (this.isReaderVerticalDirection()) {
      this.goReaderNext();
    } else {
      this.goReaderRightSide();
    }
  }

  private toggleReaderOverlayMenu(): void {
    if (!this.readerReadingFullscreen) {
      return;
    }
    this.readerMenuVisible = !this.readerMenuVisible;
    if (!this.readerMenuVisible) {
      this.readerSettingsVisible = false;
    }
    this.refreshReaderClockText();
  }

  private toggleReaderSettingsPanel(): void {
    this.readerSettingsVisible = !this.readerSettingsVisible;
    if (this.readerSettingsVisible) {
      this.readerMenuVisible = true;
    }
  }

  private toggleReaderFullscreenSetting(): void {
    this.readerReadingFullscreen = this.toggleReaderBoolean(READER_KEY_FULLSCREEN, this.readerReadingFullscreen);
    this.readerSettingsVisible = false;
    this.readerMenuVisible = !this.readerReadingFullscreen;
    if (this.nativeViewMode === 'reader') {
      void this.applyReaderWindowState();
    }
  }

  private toggleReaderKeepScreenOn(): void {
    this.readerKeepScreenOn = this.toggleReaderBoolean(READER_KEY_KEEP_SCREEN_ON, this.readerKeepScreenOn);
    if (this.nativeViewMode === 'reader') {
      void this.applyReaderWindowState();
    }
  }

  private toggleReaderShowClock(): void {
    this.readerShowClock = this.toggleReaderBoolean(READER_KEY_SHOW_CLOCK, this.readerShowClock);
  }

  private toggleReaderShowProgress(): void {
    this.readerShowProgress = this.toggleReaderBoolean(READER_KEY_SHOW_PROGRESS, this.readerShowProgress);
  }

  private toggleReaderShowBattery(): void {
    this.readerShowBattery = this.toggleReaderBoolean(READER_KEY_SHOW_BATTERY, this.readerShowBattery);
  }

  private toggleReaderShowPageInterval(): void {
    this.readerShowPageInterval = this.toggleReaderBoolean(READER_KEY_SHOW_PAGE_INTERVAL, this.readerShowPageInterval);
  }

  private toggleReaderVolumePage(): void {
    this.readerVolumePage = this.toggleReaderBoolean(READER_KEY_VOLUME_PAGE, this.readerVolumePage);
  }

  private toggleReaderReverseVolumePage(): void {
    this.readerReverseVolumePage = this.toggleReaderBoolean(READER_KEY_REVERSE_VOLUME_PAGE, this.readerReverseVolumePage);
  }

  private toggleReaderCustomLightness(): void {
    this.readerCustomScreenLightness = this.toggleReaderBoolean(READER_KEY_CUSTOM_LIGHTNESS, this.readerCustomScreenLightness);
  }

  private readerStateTag(enabled: boolean): string {
    return enabled ? '开' : '关';
  }

  private galleryBookmarkLabel(): string {
    if (this.nativeDetail.detailUrl.length === 0) {
      return '书签';
    }
    return this.bookmarks.some((item: BookmarkItem) => item.url === this.nativeDetail.detailUrl) ?
      '已书签' : '书签';
  }

  private toggleCurrentGalleryBookmark(): void {
    if (this.nativeDetail.detailUrl.length === 0) {
      return;
    }
    const existing = this.bookmarks.some((item: BookmarkItem) => item.url === this.nativeDetail.detailUrl);
    if (existing) {
      this.removeBookmark(this.nativeDetail.detailUrl);
      this.toast('书签已移除');
      return;
    }
    const title = this.nativeDetail.title.length > 0 ? this.nativeDetail.title : `${this.nativeDetail.gid}`;
    const nextBookmark: BookmarkItem = {
      title,
      url: this.nativeDetail.detailUrl
    };
    const filtered = this.bookmarks.filter((item: BookmarkItem) => item.url !== this.nativeDetail.detailUrl);
    this.bookmarks = [nextBookmark, ...filtered].slice(0, 24);
    this.saveBookmarks();
    this.toast('书签已保存');
  }

  private categoryBitFromLabel(categoryLabel: string): number {
    switch (categoryLabel.toLowerCase()) {
      case 'doujinshi':
        return CATEGORY_DOUJINSHI;
      case 'manga':
        return CATEGORY_MANGA;
      case 'artist cg sets':
      case 'artist cg':
      case 'artistcg':
        return CATEGORY_ARTIST_CG;
      case 'game cg sets':
      case 'game cg':
      case 'gamecg':
        return CATEGORY_GAME_CG;
      case 'western':
        return CATEGORY_WESTERN;
      case 'non-h':
        return CATEGORY_NON_H;
      case 'image sets':
      case 'image set':
      case 'imageset':
        return CATEGORY_IMAGE_SET;
      case 'cosplay':
        return CATEGORY_COSPLAY;
      case 'asian porn':
      case 'asianporn':
        return CATEGORY_ASIAN_PORN;
      default:
        return CATEGORY_MISC;
    }
  }

  private async openNativeCategoryList(): Promise<void> {
    const bit = this.categoryBitFromLabel(this.nativeDetail.categoryLabel);
    const searchUrl = `${EhUrl.host(this.siteMode)}?f_cats=${(~bit) & CATEGORY_ALL}`;
    const fallback = (): void => {
      this.clearTagSearchReturnDetail();
      this.tagSearchTransitionQuery = '';
      this.clearMyNavigationPath();
      this.activeSection = NAV_SEARCH;
      this.searchMode = SEARCH_MODE_NORMAL;
      this.searchCategoryMask = bit;
      this.searchResultsActive = true;
      this.nativeViewMode = 'list';
      void this.loadSearchGalleryList(searchUrl);
    };
    this.pushSearchRoute(SEARCH_MODE_NORMAL, '', bit, searchUrl, '', fallback);
  }

  private extractSimilarKeyword(): string {
    const title = this.nativeDetail.title.length > 0 ? this.nativeDetail.title : this.nativeDetail.titleJpn;
    const cleaned = title
      .replace(/\[[^\]]*]/g, ' ')
      .replace(/\([^)]*\)/g, ' ')
      .replace(/【[^】]*】/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
    if (cleaned.length > 0) {
      return cleaned.length > 56 ? cleaned.substring(0, 56) : cleaned;
    }
    for (const group of this.nativeDetail.tagGroups) {
      if (group.name === 'artist' && group.tags.length > 0) {
        return `artist:"${group.tags[0]}$"`;
      }
    }
    return this.nativeDetail.uploader;
  }

  private async openNativeSimilarList(): Promise<void> {
    const keyword = this.extractSimilarKeyword();
    if (keyword.length === 0) {
      this.toast('没有可用的相似搜索关键词');
      return;
    }
    const query = keyword.startsWith('artist:') ? keyword : `"${keyword}"`;
    const searchUrl = `${EhUrl.host(this.siteMode)}?f_search=${encodeURIComponent(query)}`;
    const fallback = (): void => {
      this.activeSection = NAV_SEARCH;
      this.searchMode = SEARCH_MODE_NORMAL;
      this.setNativeQuery(query);
      this.nativeViewMode = 'list';
      void this.searchNative();
    };
    this.pushSearchRoute(SEARCH_MODE_NORMAL, query, CATEGORY_ALL, searchUrl, '', fallback);
  }

  private async openNativeUploaderList(): Promise<void> {
    if (this.nativeDetail.uploader.length === 0) {
      this.toast('没有可用的上传者');
      return;
    }
    const query = this.nativeDetail.uploader;
    const searchUrl = `${EhUrl.host(this.siteMode)}uploader/${encodeURIComponent(query)}`;
    const fallback = (): void => {
      this.activeSection = NAV_SEARCH;
      this.searchMode = SEARCH_MODE_UPLOADER;
      this.setNativeQuery(query);
      this.nativeViewMode = 'list';
      void this.searchNative();
    };
    this.pushSearchRoute(SEARCH_MODE_UPLOADER, query, CATEGORY_ALL, searchUrl, '', fallback);
  }

  private async openNativeParentGallery(): Promise<void> {
    const match = /\/g\/(\d+)\/([0-9a-f]{10})/i.exec(this.nativeDetail.parentUrl);
    if (!match || !match[1] || !match[2]) {
      this.toast('父画廊不可用');
      return;
    }
    const gid = Number(match[1]);
    const token = match[2];
    const item: NativeGallerySummary = {
      gid,
      token,
      title: `父画廊 ${gid}`,
      titleJpn: '',
      thumb: '',
      categoryLabel: this.nativeDetail.categoryLabel,
      posted: '',
      uploader: '',
      rating: -1,
      pages: 0,
      simpleTags: [],
      simpleLanguage: '',
      detailUrl: EhUrl.galleryDetail(this.siteMode, gid, token)
    };
    await this.openNativeDetail(item);
  }

  private hasDetailAccountCredential(): boolean {
    return this.nativeDetail.apiUid >= 0 && this.nativeDetail.apiKey.length > 0;
  }

  private ensureDetailAccountCredential(): boolean {
    if (this.hasDetailAccountCredential()) {
      return true;
    }
    this.toast('请先登录或导入有效 Cookie');
    return false;
  }

  private async upsertLocalFavoriteRecord(record: LocalGalleryRecord): Promise<void> {
    const key = this.localFavoriteKey(record);
    const filtered = this.localFavorites.filter((item: LocalGalleryRecord) => this.localFavoriteKey(item) !== key);
    this.localFavorites = [record, ...filtered].slice(0, LOCAL_LIST_LOAD_LIMIT);
    this.refreshLocalFavoriteGalleryListIfNeeded();
    if (this.localDao) {
      try {
        await this.localDao.upsertLocalFavorite(record);
      } catch (error) {
      }
    }
  }

  private async deleteLocalFavoriteRecord(record: LocalGalleryRecord): Promise<void> {
    const key = this.localFavoriteKey(record);
    this.localFavorites = this.localFavorites.filter((item: LocalGalleryRecord) => this.localFavoriteKey(item) !== key);
    this.refreshLocalFavoriteGalleryListIfNeeded();
    if (this.localDao) {
      try {
        await this.localDao.deleteLocalFavorite(record);
      } catch (error) {
      }
    }
  }

  private setNativeFavoriteState(isFavorited: boolean, favoriteName: string): void {
    this.nativeDetail.isFavorited = isFavorited;
    this.nativeDetail.favoriteName = isFavorited ? favoriteName : '';
    this.nativeDetailRevision++;
  }

  private openFavoritePanel(): void {
    this.favoritePanelVisible = !this.favoritePanelVisible;
    if (this.favoritePanelVisible) {
      this.favoritePanelSlotDraft = this.favoriteQuickSlot();
      this.ratingPanelVisible = false;
      this.torrentPanelVisible = false;
      this.archivePanelVisible = false;
    }
  }

  private showFavoritePanel(): void {
    this.favoritePanelVisible = true;
    this.favoritePanelSlotDraft = this.favoriteQuickSlot();
    this.ratingPanelVisible = false;
    this.torrentPanelVisible = false;
    this.archivePanelVisible = false;
  }

  private async applyFavoriteSlot(slot: number, rememberDefault: boolean): Promise<void> {
    const normalizedSlot = this.normalizeFavoriteSlot(slot, false);
    const record = this.createRecordFromDetail();
    if (!record) {
      return;
    }
    this.detailActionLoading = true;
    this.detailActionStatus = `正在添加到 ${this.favoriteSlotName(normalizedSlot)}...`;
    try {
      if (normalizedSlot === FAVORITE_LOCAL_SLOT) {
        await this.upsertLocalFavoriteRecord(record);
        this.nativeDetailRevision++;
      } else {
        if (!this.ensureDetailAccountCredential()) {
          this.detailActionStatus = '需要登录后才能添加站点收藏';
          return;
        }
        await NativeEhClient.modifyFavorite(this.siteMode, this.nativeDetail.gid, this.nativeDetail.token, normalizedSlot, '');
        this.setNativeFavoriteState(true, this.favoriteSlotName(normalizedSlot));
      }
      if (rememberDefault || this.defaultFavoriteSlot !== normalizedSlot) {
        this.setDefaultFavoriteSlot(normalizedSlot);
      }
      this.favoritePanelVisible = false;
      this.detailActionStatus = `已收藏到 ${this.favoriteSlotName(normalizedSlot)}`;
      this.toast('收藏已更新');
    } catch (error) {
      this.detailActionStatus = `${error}`.replace('Error: ', '');
      this.toast('收藏更新失败');
    } finally {
      this.detailActionLoading = false;
    }
  }

  private async applyDefaultFavoriteSlot(): Promise<void> {
    if (this.defaultFavoriteSlot === FAVORITE_INVALID_DEFAULT_SLOT) {
      this.openFavoritePanel();
      return;
    }
    await this.applyFavoriteSlot(this.defaultFavoriteSlot, false);
  }

  private async removeCurrentGalleryFavorite(): Promise<void> {
    const record = this.createRecordFromDetail();
    const removeSiteFavorite = this.nativeDetail.isFavorited;
    const removeLocalFavorite = !removeSiteFavorite && !!record && this.isRecordLocalFavorite(record);
    const removedName = this.currentFavoriteRemovalName();
    if (!removeSiteFavorite && !removeLocalFavorite) {
      await this.applyFavoriteSlot(this.favoriteQuickSlot(), true);
      return;
    }
    if (removeSiteFavorite && !this.ensureDetailAccountCredential()) {
      this.detailActionStatus = '需要登录后才能移除站点收藏';
      return;
    }
    this.detailActionLoading = true;
    this.detailActionStatus = `正在移除 ${removedName.length > 0 ? removedName : '收藏'}...`;
    try {
      if (removeSiteFavorite) {
        await NativeEhClient.modifyFavorite(this.siteMode, this.nativeDetail.gid, this.nativeDetail.token, -1, '');
        this.setNativeFavoriteState(false, '');
      } else if (record) {
        await this.deleteLocalFavoriteRecord(record);
        this.nativeDetailRevision++;
      }
      const remainingName = this.currentFavoriteRemovalName();
      if (remainingName.length > 0) {
        this.detailActionStatus = `已移除 ${removedName}，仍在 ${remainingName}`;
      } else {
        this.detailActionStatus = '已取消收藏';
      }
      this.toast('收藏已移除');
    } catch (error) {
      this.detailActionStatus = `${error}`.replace('Error: ', '');
      this.toast('取消收藏失败');
    } finally {
      this.detailActionLoading = false;
    }
  }

  private openRatingPanel(): void {
    if (!this.ensureDetailAccountCredential()) {
      return;
    }
    this.selectedRating = this.nativeDetail.rating > 0 ? this.nativeDetail.rating : 3;
    this.ratingPanelVisible = !this.ratingPanelVisible;
    if (this.ratingPanelVisible) {
      this.favoritePanelVisible = false;
      this.torrentPanelVisible = false;
      this.archivePanelVisible = false;
    }
  }

  private adjustSelectedRating(delta: number): void {
    const next = Math.round((this.selectedRating + delta) * 2) / 2;
    this.selectedRating = clampNumber(next, 0.5, 5);
  }

  private async submitSelectedRating(): Promise<void> {
    if (!this.ensureDetailAccountCredential()) {
      return;
    }
    this.detailActionLoading = true;
    this.detailActionStatus = '正在提交评分...';
    try {
      const result = await NativeEhClient.rateGallery(
        this.siteMode,
        this.nativeDetail.apiUid,
        this.nativeDetail.apiKey,
        this.nativeDetail.gid,
        this.nativeDetail.token,
        this.selectedRating
      );
      this.nativeDetail.rating = result.rating;
      this.nativeDetail.ratingCount = result.ratingCount;
      this.nativeDetailRevision++;
      this.ratingPanelVisible = false;
      this.detailActionStatus = '评分已更新';
      this.toast('评分成功');
    } catch (error) {
      this.detailActionStatus = `${error}`.replace('Error: ', '');
      this.toast('评分失败');
    } finally {
      this.detailActionLoading = false;
    }
  }

  private async loadNativeCommentsPageLocal(): Promise<void> {
    this.nativeViewMode = 'comments';
    if (this.nativeDetail.hasMoreComments || this.nativeDetail.comments.length === 0) {
      await this.loadNativeAllComments();
    }
  }

  private async openNativeComments(): Promise<void> {
    const currentSummary = this.createSummaryFromDetail();
    if (currentSummary) {
      this.pushNativeRoute(currentSummary, ROUTE_NATIVE_COMMENTS);
      return;
    }
    await this.loadNativeCommentsPageLocal();
  }

  private async loadNativeAllComments(): Promise<void> {
    if (!this.ensureNativeSiteReady() || this.nativeDetail.gid <= 0) {
      return;
    }
    this.nativeCommentsLoading = true;
    this.nativeCommentsStatus = '正在加载完整评论...';
    try {
      this.nativeDetail = await NativeEhClient.fetchGalleryDetailComments(this.siteMode, this.nativeDetail);
      this.nativeDetailRevision++;
      const hidden = this.hiddenNativeCommentCount();
      this.nativeCommentsStatus = hidden > 0 ?
        `已加载 ${this.visibleNativeComments().length} 条评论，黑名单隐藏 ${hidden} 条` :
        `已加载 ${this.nativeDetail.comments.length} 条评论`;
    } catch (error) {
      this.nativeCommentsStatus = `${error}`.replace('Error: ', '');
      this.toast('评论加载失败');
    } finally {
      this.nativeCommentsLoading = false;
      const currentSummary = this.createSummaryFromDetail();
      if (currentSummary) {
        this.saveNativeRouteSnapshot(currentSummary);
      }
    }
  }

  private async voteGalleryComment(comment: NativeGalleryComment, vote: number): Promise<void> {
    if (!this.ensureDetailAccountCredential() || comment.id <= 0) {
      return;
    }
    this.nativeCommentsStatus = vote > 0 ? '正在赞同评论...' : '正在反对评论...';
    try {
      const result = await NativeEhClient.voteComment(
        this.siteMode,
        this.nativeDetail.apiUid,
        this.nativeDetail.apiKey,
        this.nativeDetail.gid,
        this.nativeDetail.token,
        comment.id,
        vote
      );
      this.applyVoteCommentResult(result);
      this.nativeCommentsStatus = result.vote !== 0 ? '投票已更新' : '投票已取消';
      this.toast('评论投票成功');
    } catch (error) {
      this.nativeCommentsStatus = `${error}`.replace('Error: ', '');
      this.toast('评论投票失败');
    }
  }

  private applyVoteCommentResult(result: NativeVoteCommentResult): void {
    const comments: NativeGalleryComment[] = [];
    for (const comment of this.nativeDetail.comments) {
      if (comment.id !== result.id) {
        comments.push(comment);
        continue;
      }
      comments.push({
        id: comment.id,
        user: comment.user,
        posted: comment.posted,
        body: comment.body,
        score: result.score,
        voteState: comment.voteState,
        editable: comment.editable,
        voteUpAble: comment.voteUpAble,
        voteUpEd: result.expectVote > 0 && result.vote !== 0,
        voteDownAble: comment.voteDownAble,
        voteDownEd: result.expectVote < 0 && result.vote !== 0
      });
    }
    this.nativeDetail.comments = comments;
    this.nativeDetailRevision++;
  }

  private openCommentWebFallback(): void {
    this.openFullScreenWeb(
      EhUrl.galleryComments(this.siteMode, this.nativeDetail.gid, this.nativeDetail.token),
      '画廊评论',
      ''
    );
  }

  private async openTorrentPanel(): Promise<void> {
    if (this.nativeDetail.torrentUrl.length === 0) {
      this.toast('没有 Torrent 入口');
      return;
    }
    this.torrentPanelVisible = !this.torrentPanelVisible;
    if (this.torrentPanelVisible) {
      this.favoritePanelVisible = false;
      this.ratingPanelVisible = false;
      this.archivePanelVisible = false;
      if (this.torrentItems.length === 0 && !this.torrentLoading) {
        await this.loadTorrentList();
      }
    }
  }

  private async loadTorrentList(): Promise<void> {
    if (this.nativeDetail.torrentUrl.length === 0) {
      return;
    }
    this.torrentLoading = true;
    this.torrentStatus = '正在加载 Torrent 列表...';
    try {
      this.torrentItems = await NativeEhClient.fetchTorrentList(
        this.siteMode,
        this.nativeDetail.torrentUrl,
        this.nativeDetail.gid,
        this.nativeDetail.token
      );
      this.torrentStatus = this.torrentItems.length > 0 ? `已加载 ${this.torrentItems.length} 个 Torrent` : '没有可用 Torrent';
    } catch (error) {
      this.torrentStatus = `${error}`.replace('Error: ', '');
      this.toast('Torrent 列表加载失败');
    } finally {
      this.torrentLoading = false;
    }
  }

  private detailDownloadDir(name: string): string {
    const filesDir = this.abilityFilesDir();
    return filesDir.length > 0 ? `${filesDir}/${name}` : '';
  }

  private writeBinaryFile(path: string, data: ArrayBuffer): void {
    const dir = path.substring(0, path.lastIndexOf('/'));
    if (!this.ensureLocalDirectory(dir)) {
      throw new Error('目标目录不可用');
    }
    const tempPath = `${path}.tmp`;
    let file: fileIo.File | undefined = undefined;
    try {
      file = fileIo.openSync(tempPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(file.fd, data);
    } finally {
      if (file) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
        }
      }
    }
    try {
      if (fileIo.accessSync(path)) {
        fileIo.unlinkSync(path);
      }
    } catch (error) {
    }
    fileIo.renameSync(tempPath, path);
  }

  private async downloadTorrentItem(item: NativeTorrentItem): Promise<void> {
    const dir = this.detailDownloadDir(DETAIL_TORRENT_DIR_NAME);
    if (dir.length === 0) {
      this.toast('下载目录不可用');
      return;
    }
    this.torrentStatus = `正在保存 ${item.name}...`;
    try {
      const data = await NativeEhClient.downloadBinary(this.siteMode, item.url, this.nativeDetail.detailUrl);
      const name = safeFileName(item.name, `torrent-${this.nativeDetail.gid}`);
      const path = `${dir}/${name.endsWith('.torrent') ? name : `${name}.torrent`}`;
      this.writeBinaryFile(path, data);
      this.torrentStatus = `已保存到 ${path}`;
      this.toast('Torrent 已保存');
    } catch (error) {
      this.torrentStatus = `${error}`.replace('Error: ', '');
      this.toast('Torrent 保存失败');
    }
  }

  private async openArchivePanel(): Promise<void> {
    if (this.nativeDetail.archiveUrl.length === 0) {
      this.toast('没有 Archive 入口');
      return;
    }
    if (!this.ensureDetailAccountCredential()) {
      return;
    }
    this.archivePanelVisible = !this.archivePanelVisible;
    if (this.archivePanelVisible) {
      this.favoritePanelVisible = false;
      this.ratingPanelVisible = false;
      this.torrentPanelVisible = false;
      if (this.archiveList.items.length === 0 && !this.archiveLoading) {
        await this.loadArchiveList();
      }
    }
  }

  private async loadArchiveList(): Promise<void> {
    this.archiveLoading = true;
    this.archiveStatus = '正在加载 Archive / H@H 选项...';
    try {
      this.archiveList = await NativeEhClient.fetchArchiveList(
        this.siteMode,
        this.nativeDetail.archiveUrl,
        this.nativeDetail.gid,
        this.nativeDetail.token
      );
      this.archiveStatus = this.archiveList.items.length > 0 ?
        `已加载 ${this.archiveList.items.length} 个 H@H 选项` :
        '没有解析到 H@H 选项，可使用网页 Archive fallback';
    } catch (error) {
      this.archiveStatus = `${error}`.replace('Error: ', '');
      this.toast('Archive 选项加载失败');
    } finally {
      this.archiveLoading = false;
    }
  }

  private async submitArchiveItem(item: NativeArchiveItem): Promise<void> {
    if (!this.ensureDetailAccountCredential()) {
      return;
    }
    this.archiveStatus = `正在提交 ${item.name}...`;
    try {
      await NativeEhClient.submitArchiveDownload(
        this.siteMode,
        this.nativeDetail.gid,
        this.nativeDetail.token,
        this.archiveList.formParamOr,
        item.res
      );
      this.archiveStatus = 'Archive 请求已提交；如果配置了 H@H 客户端，站点会开始处理下载。';
      this.toast('Archive 请求已提交');
    } catch (error) {
      this.archiveStatus = `${error}`.replace('Error: ', '');
      this.toast('Archive 请求失败，可使用网页 fallback');
    }
  }

  private openArchiveWebFallback(): void {
    if (this.nativeDetail.archiveUrl.length === 0) {
      return;
    }
    this.openFullScreenWeb(this.nativeDetail.archiveUrl, 'Archive 下载', '');
  }

  private handleNativeDetailAction(action: string): void {
    switch (action) {
      case 'read':
        void this.openNativeReaderFromStart();
        break;
      case 'queue':
        this.toggleCurrentGalleryQueue();
        break;
      case 'bookmark':
        this.toggleCurrentGalleryBookmark();
        break;
      case 'favorite':
        void this.handleFavoriteSquareClick();
        break;
      case 'favorite_panel':
        this.openFavoritePanel();
        break;
      case 'rate':
        this.openRatingPanel();
        break;
      case 'comments':
        void this.openNativeComments();
        break;
      case 'torrent':
        void this.openTorrentPanel();
        break;
      case 'archive':
        void this.openArchivePanel();
        break;
      case 'similar':
        void this.openNativeSimilarList();
        break;
      case 'uploader':
        void this.openNativeUploaderList();
        break;
      case 'category':
        void this.openNativeCategoryList();
        break;
      case 'parent':
        void this.openNativeParentGallery();
        break;
      default:
        break;
    }
  }

  private goBackToNativeList(): void {
    this.stopReaderRuntimeState();
    this.clearReaderTransitionSnapshot();
    this.readerReturnViewMode = 'detail';
    this.pendingReaderReturnViewMode = '';
    this.runGalleryCoverTransition((): void => {
      this.nativeViewMode = 'list';
      this.restoreCurrentGalleryListScrollOffset();
    });
  }

  private goBackToNativeDetail(): void {
    this.stopReaderRuntimeState();
    this.clearReaderTransitionSnapshot();
    this.readerReturnViewMode = 'detail';
    this.pendingReaderReturnViewMode = '';
    this.routeNativeMode = ROUTE_NATIVE_DETAIL;
    this.routeReaderPageUrl = '';
    this.nativeViewMode = 'detail';
  }

  private prepareTagSearchReturnDetail(): void {
    if (this.nativeDetail.gid <= 0) {
      this.clearTagSearchReturnDetail();
      return;
    }
    this.tagSearchReturnSection = this.activeSection;
    this.tagSearchReturnGid = this.nativeDetail.gid;
    this.tagSearchReturnToken = this.nativeDetail.token;
    this.keepNextSearchReturnDetail = true;
  }

  private clearTagSearchReturnDetail(): void {
    this.tagSearchReturnSection = NAV_HOME;
    this.tagSearchReturnGid = 0;
    this.tagSearchReturnToken = '';
    this.keepNextSearchReturnDetail = false;
  }

  private hasTagSearchReturnDetail(): boolean {
    return this.activeSection === NAV_SEARCH &&
      this.nativeViewMode === 'list' &&
      this.nativeDetail.gid > 0 &&
      this.tagSearchReturnGid === this.nativeDetail.gid &&
      this.tagSearchReturnToken === this.nativeDetail.token;
  }

  private goBackToTagSearchReturnDetail(): void {
    const targetSection = this.tagSearchReturnSection;
    this.stopReaderRuntimeState();
    this.clearReaderTransitionSnapshot();
    this.routeNativeMode = ROUTE_NATIVE_DETAIL;
    this.routeReaderPageUrl = '';
    this.readerReturnViewMode = 'detail';
    this.pendingReaderReturnViewMode = '';
    this.runNativeRouteTransition((): void => {
      this.clearTagSearchReturnDetail();
      this.activeSection = targetSection;
      this.nativeViewMode = 'detail';
      this.searchFilterSheetVisible = false;
      this.hideSearchSuggestionOverlay();
    });
  }

  private tagSearchTransitionId(): string {
    return this.tagSearchTransitionQuery.length > 0 ? `tag-search:${this.tagSearchTransitionQuery}` : '';
  }

  private openNativeTagSearch(namespace: string, tag: string): void {
    const transitionQuery = `${namespace}:${tag}`;
    const query = this.buildSearchTokenFromTag(namespace, tag);
    this.prepareTagSearchReturnDetail();
    this.tagSearchTransitionQuery = transitionQuery;
    const searchUrl = this.buildAdvancedSearchUrlFor(SEARCH_MODE_TAG, query);
    const fallback = (): void => {
      this.searchMode = SEARCH_MODE_TAG;
      this.setNativeQuery(query);
      this.runNativeRouteTransition((): void => {
        this.activeSection = NAV_SEARCH;
        this.searchResultsActive = true;
        this.nativeViewMode = 'list';
        this.searchFiltersExpanded = false;
        this.searchFilterSheetVisible = false;
      });
      void this.searchNative();
    };
    this.pushSearchRoute(SEARCH_MODE_TAG, query, this.searchCategoryMask, searchUrl, transitionQuery, fallback);
  }

  private returnFromNativeReader(): void {
    this.persistCurrentReaderProgress();
    const targetViewMode = this.normalizeReaderReturnViewMode(this.readerReturnViewMode);
    this.stopReaderRuntimeState();
    this.clearReaderTransitionSnapshot();
    this.routeNativeMode = ROUTE_NATIVE_DETAIL;
    this.routeReaderPageUrl = '';
    this.pendingReaderReturnViewMode = '';
    this.readerReturnViewMode = 'detail';
    if (this.nativeDetail.gid > 0) {
      this.nativeViewMode = targetViewMode;
    } else {
      this.nativeViewMode = 'detail';
    }
  }

  private saveCurrentQuickSearch(): void {
    const query = this.nativeQuery.trim();
    if (query.length === 0) {
      this.toast('请先输入搜索关键词');
      return;
    }
    const minRating = this.normalizeNumericInput(this.searchMinRating);
    const pageFrom = this.normalizeNumericInput(this.searchPageFrom);
    const pageTo = this.normalizeNumericInput(this.searchPageTo);
    const advancedFlags = this.currentSearchAdvancedFlags();
    const key = [
      this.siteMode,
      this.searchMode,
      `${this.searchCategoryMask}`,
      this.searchAdvancedEnabled ? '1' : '0',
      `${advancedFlags}`,
      minRating,
      pageFrom,
      pageTo,
      query.toLowerCase()
    ].join(':');
    const nextItem: QuickSearchItem = {
      id: key,
      label: query,
      query,
      site: this.siteMode,
      mode: this.searchMode,
      category: this.searchCategoryMask,
      advancedEnabled: this.searchAdvancedEnabled,
      advancedFlags,
      minRating,
      pageFrom,
      pageTo,
      savedAt: this.nowLabel()
    };
    const filtered = this.quickSearches.filter((item: QuickSearchItem) => item.id !== key);
    this.quickSearches = [nextItem, ...filtered].slice(0, 20);
    this.saveQuickSearches();
    this.toast('快捷搜索已保存');
  }

  private removeQuickSearch(id: string): void {
    this.quickSearches = this.quickSearches.filter((item: QuickSearchItem) => item.id !== id);
    this.saveQuickSearches();
  }

  private applyQuickSearch(item: QuickSearchItem): void {
    this.toggleSite(item.site);
    this.searchMode = this.normalizeSearchMode(item.mode);
    this.searchCategoryMask = this.normalizeCategoryMask(item.category);
    this.searchAdvancedEnabled = item.advancedEnabled;
    this.applySearchAdvancedFlags(item.advancedFlags);
    this.searchMinRating = item.minRating;
    this.searchPageFrom = item.pageFrom;
    this.searchPageTo = item.pageTo;
    this.setNativeQuery(item.query);
    this.activeSection = NAV_SEARCH;
    void this.searchNative();
  }

  private topListUrl(): string {
    return EhUrl.topList();
  }

  private imageSearchUrl(): string {
    return this.siteMode === GallerySite.EX ?
      'https://upld.exhentai.org/upld/image_lookup.php' : 'https://upld.e-hentai.org/image_lookup.php';
  }

  private defaultHomeSectionUrl(): string {
    return EhUrl.galleryFront(this.siteMode);
  }

  private stripPageParam(url: string): string {
    const trimmed = url.trim();
    if (trimmed.length === 0) {
      return '';
    }
    const hashIndex = trimmed.indexOf('#');
    const hash = hashIndex >= 0 ? trimmed.substring(hashIndex) : '';
    const withoutHash = hashIndex >= 0 ? trimmed.substring(0, hashIndex) : trimmed;
    const queryIndex = withoutHash.indexOf('?');
    if (queryIndex < 0) {
      return `${withoutHash}${hash}`;
    }
    const base = withoutHash.substring(0, queryIndex);
    const query = withoutHash.substring(queryIndex + 1);
    const params = query.split('&').filter((item: string) => {
      if (item.length === 0) {
        return false;
      }
      const pair = item.split('=');
      return decodeURIComponent(pair[0] ?? '') !== 'page';
    });
    return params.length > 0 ? `${base}?${params.join('&')}${hash}` : `${base}${hash}`;
  }

  private resolveHomeSectionTitle(url: string): string {
    const normalized = this.normalizeUrl(url).toLowerCase();
    const host = EhUrl.host(this.siteMode).toLowerCase();
    if (normalized.startsWith(`${host}popular`)) {
      return '热门';
    }
    if (normalized.startsWith(`${host}watched`)) {
      return '关注';
    }
    if (normalized.startsWith(`${host}favorites.php`)) {
      return '收藏';
    }
    if (normalized.startsWith(`${host}tag/`)) {
      return '标签';
    }
    if (normalized.startsWith(`${host}uploader/`)) {
      return '上传者';
    }
    if (normalized.includes('f_search=')) {
      return '搜索结果';
    }
    return '首页';
  }

  private syncHomeSectionMeta(url: string): void {
    const refreshUrl = this.stripPageParam(url);
    this.homeSectionRefreshUrl = refreshUrl.length > 0 ? refreshUrl : this.defaultHomeSectionUrl();
    this.homeSectionTitle = this.resolveHomeSectionTitle(refreshUrl.length > 0 ? refreshUrl : url);
  }

  private resolveHomePageFromUrl(url: string): string {
    const normalized = this.normalizeUrl(url).toLowerCase();
    const host = EhUrl.host(this.siteMode).toLowerCase();
    if (normalized.startsWith(`${host}popular`)) {
      return HOME_PAGE_POPULAR;
    }
    if (normalized.startsWith(`${host}watched`)) {
      return HOME_PAGE_WATCHED;
    }
    return HOME_PAGE_DEFAULT;
  }

  private openHomePrimaryPage(page: string): void {
    this.clearMyNavigationPath();
    this.homePage = page;
    this.activeSection = NAV_HOME;
    this.myPage = MY_PAGE_MAIN;
    this.myPageTitle = '';
    this.nativeViewMode = 'list';
    if (page === HOME_PAGE_TOP) {
      if (!this.topListLoading && this.topListDetail.groups.length === 0 && this.topListError.length === 0) {
        void this.loadTopList();
      }
      return;
    }
    const targetUrl = this.currentHomeTargetUrl();
    this.prepareHomeGalleryReload(targetUrl);
    void this.loadHomeGalleryList(targetUrl);
  }

  private openHomeRoute(url: string): void {
    this.clearMyNavigationPath();
    this.homePage = this.resolveHomePageFromUrl(url);
    this.activeSection = NAV_HOME;
    this.myPage = MY_PAGE_MAIN;
    this.myPageTitle = '';
    this.prepareHomeGalleryReload(url);
    void this.loadHomeGalleryList(url);
  }

  private openLibraryPage(index: number): void {
    this.openMyPage(this.myPageForLibraryPanel(index), this.titleForLibraryPanel(index));
  }

  private prepareMySubPageLocal(page: string, title: string): void {
    this.activeSection = this.sectionForSubPage(page);
    this.myPage = page;
    this.myPageTitle = title;
    this.mySubPage = page;
    this.mySubPageTitle = title;
    this.nativeViewMode = 'list';
    if (this.activeSection === NAV_LIBRARY) {
      this.libraryPanel = this.libraryPanelForPage(page);
      if (this.libraryPanel === LIBRARY_FAVORITES) {
        this.favoriteListFilter = FAVORITE_FILTER_ALL;
        this.ensureCurrentLibraryPageLoaded();
      } else if (this.libraryPanel === LIBRARY_HISTORY) {
        void this.loadLocalSideData();
      } else if (this.libraryPanel === LIBRARY_DOWNLOADS) {
        if (!this.downloadWorkerRunning) {
          void this.syncDownloadStateFromDatabase(false);
        }
      }
      return;
    }
    this.ensureMySubPageLoaded(page);
  }

  private myPageForLibraryPanel(index: number): string {
    if (index === LIBRARY_HISTORY) {
      return MY_PAGE_HISTORY;
    }
    if (index === LIBRARY_DOWNLOADS) {
      return MY_PAGE_DOWNLOADS;
    }
    return MY_PAGE_FAVORITES;
  }

  private titleForLibraryPanel(index: number): string {
    if (index === LIBRARY_HISTORY) {
      return '历史';
    }
    if (index === LIBRARY_DOWNLOADS) {
      return '下载';
    }
    return '收藏夹';
  }

  private currentHomeSectionTitle(): string {
    switch (this.homePage) {
      case HOME_PAGE_POPULAR:
        return '热门';
      case HOME_PAGE_WATCHED:
        return '关注';
      case HOME_PAGE_TOP:
        return '排行榜';
      default:
        return this.homeSectionTitle.length > 0 ? this.homeSectionTitle : '首页';
    }
  }

  private currentLibraryTitle(): string {
    if (this.libraryPanel === LIBRARY_FAVORITES) {
      return this.favoriteFilterLabel(this.favoriteListFilter);
    }
    if (this.libraryPanel === LIBRARY_HISTORY) {
      return '历史';
    }
    return '下载';
  }

  private currentNavigationTitle(): string {
    if (this.hasVisibleNativeSubPage()) {
      return '';
    }
    if (this.activeSection === NAV_LIBRARY && this.myPage !== MY_PAGE_MAIN) {
      return this.currentLibraryTitle();
    }
    if (this.hasMyNavigationPath() && this.mySubPageTitle.length > 0) {
      return this.mySubPageTitle;
    }
    if (this.activeSection === NAV_HOME) {
      return this.currentHomeSectionTitle();
    }
    if (this.activeSection === NAV_SEARCH) {
      return '搜索';
    }
    if (this.activeSection === NAV_LIBRARY) {
      if (this.myPage === MY_PAGE_MAIN) {
        return '我的';
      }
      return this.currentLibraryTitle();
    }
    if (this.myPageTitle.length > 0) {
      return this.myPageTitle;
    }
    return '我的';
  }

  private openMyWebRoute(url: string): void {
    this.openEhRouteOrInternalWeb(url, '内置网页');
  }

  private libraryPanelForPage(page: string): number {
    if (page === MY_PAGE_DOWNLOADS) {
      return LIBRARY_DOWNLOADS;
    }
    if (page === MY_PAGE_HISTORY) {
      return LIBRARY_HISTORY;
    }
    return LIBRARY_FAVORITES;
  }

  private sectionForSubPage(page: string): number {
    if (page === MY_PAGE_FAVORITES || page === MY_PAGE_DOWNLOADS || page === MY_PAGE_HISTORY) {
      return NAV_LIBRARY;
    }
    return NAV_SETTINGS;
  }

  private showMyPageLocal(page: string, title: string): void {
    this.prepareMySubPageLocal(page, title);
  }

  private pushMyPageRoute(page: string, title: string): void {
    const params: PageRouteParams = createMyPageRouteParams(this.sectionForSubPage(page), page, title, this.siteMode);
    try {
      void this.getUIContext().getRouter().pushUrl({
        url: APP_INDEX_PAGE_URL,
        params
      }).catch(() => {
        this.showMyPageLocal(page, title);
      });
    } catch (error) {
      this.showMyPageLocal(page, title);
    }
  }

  private openMyPage(page: string, title: string): void {
    this.pushMyPageRoute(page, title);
    if (!this.downloadWorkerRunning) {
      void this.syncDownloadStateFromDatabase(false);
    }
  }

  private handleMyDrawerAction(action: string): void {
    switch (action) {
      case 'home':
        this.openHomePrimaryPage(HOME_PAGE_DEFAULT);
        break;
      case 'watched':
        this.openHomePrimaryPage(HOME_PAGE_WATCHED);
        break;
      case 'popular':
        this.openHomePrimaryPage(HOME_PAGE_POPULAR);
        break;
      case 'top':
        this.openHomePrimaryPage(HOME_PAGE_TOP);
        break;
      case 'favorites':
        this.openLibraryPage(LIBRARY_FAVORITES);
        break;
      case 'history':
        this.openLibraryPage(LIBRARY_HISTORY);
        break;
      case 'downloads':
        this.openLibraryPage(LIBRARY_DOWNLOADS);
        break;
      case 'bookmarks':
        this.openMyPage(MY_PAGE_BOOKMARKS, '书签');
        break;
      case 'mytags':
        this.openMyPage(MY_PAGE_MY_TAGS, '我的标签');
        break;
      case 'uconfig':
        this.openFullScreenWeb(EhUrl.uConfig(this.siteMode), 'UConfig', WEB_MODE_UCONFIG);
        break;
      case 'imagesearch':
        this.openMyPage(MY_PAGE_IMAGE_SEARCH, '图片搜索');
        break;
      case 'filters':
        this.openMyPage(MY_PAGE_FILTERS, '屏蔽画廊');
        break;
      case 'blacklist':
        this.openMyPage(MY_PAGE_BLACKLIST, '评论黑名单');
        break;
      case 'signin':
        this.openWebSignIn();
        break;
      case 'account':
        this.openMyPage(MY_PAGE_ACCOUNT, '账户');
        break;
      case 'settings':
        this.openMyPage(MY_PAGE_SETTINGS, '设置');
        break;
      case 'web':
        this.openHomeRoute(EhUrl.galleryFront(this.siteMode));
        break;
      default:
        break;
    }
  }

  private findDownloadIndex(gid: number, site: string): number {
    for (let index = 0; index < this.downloadItems.length; index++) {
      if (this.downloadItems[index].gid === gid && this.downloadItems[index].site === site) {
        return index;
      }
    }
    return -1;
  }

  private findDownloadItem(gid: number, site: string): DownloadQueueItem | undefined {
    const index = this.findDownloadIndex(gid, site);
    return index >= 0 ? this.downloadItems[index] : undefined;
  }

  private localDownloadItemByKey(key: string): DownloadQueueItem | undefined {
    for (const item of this.downloadItems) {
      if (this.downloadKey(item.gid, item.site) === key) {
        return item;
      }
    }
    return undefined;
  }

  private findDownloadItemByKey(key: string): DownloadQueueItem | undefined {
    if (this.isDownloadKeyRemoved(key)) {
      return undefined;
    }
    for (const item of this.downloadItemsSource()) {
      if (this.downloadKey(item.gid, item.site) === key) {
        return item;
      }
    }
    return undefined;
  }

  private sharedDownloadItemByKey(key: string): DownloadQueueItem | undefined {
    for (const item of sharedDownloadItemsSnapshot) {
      if (this.downloadKey(item.gid, item.site) === key) {
        return item;
      }
    }
    for (const item of this.runtimeDownloadItemsSnapshot()) {
      if (this.downloadKey(item.gid, item.site) === key) {
        return item;
      }
    }
    return undefined;
  }

  private isDownloadKeyCancelled(key: string): boolean {
    return this.downloadCancelKeys.has(key) ||
      sharedDownloadCancelKeys.has(key) ||
      this.isRuntimeStringArrayMarked(DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY, key);
  }

  private isDownloadKeyRemoved(key: string): boolean {
    return this.downloadRemovedKeys.has(key) ||
      sharedDownloadRemovedKeys.has(key) ||
      this.isRuntimeStringArrayMarked(DOWNLOAD_RUNTIME_REMOVED_KEYS_KEY, key);
  }

  private markDownloadKeyRemoved(key: string): void {
    this.downloadRemovedKeys.add(key);
    sharedDownloadRemovedKeys.add(key);
    this.updateRuntimeStringArray(DOWNLOAD_RUNTIME_REMOVED_KEYS_KEY, key, true, true);
    this.downloadCancelKeys.add(key);
    sharedDownloadCancelKeys.add(key);
    this.updateRuntimeStringArray(DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY, key, true);
    this.downloadStartRequestedKeys.delete(key);
    sharedDownloadStartRequestedKeys.delete(key);
    this.downloadWaitKeys = this.downloadWaitKeys.filter((entry: string) => entry !== key);
    this.removeSharedDownloadWaitKey(key);
    if (this.downloadActiveKey === key) {
      this.downloadActiveKey = '';
    }
    if (sharedDownloadActiveKey === key) {
      sharedDownloadActiveKey = '';
    }
  }

  private clearDownloadKeyRemoved(key: string): void {
    this.downloadRemovedKeys.delete(key);
    sharedDownloadRemovedKeys.delete(key);
    this.updateRuntimeStringArray(DOWNLOAD_RUNTIME_REMOVED_KEYS_KEY, key, false, true);
  }

  private filterRemovedDownloadItems(items: DownloadQueueItem[]): DownloadQueueItem[] {
    return items.filter((item: DownloadQueueItem) => !this.isDownloadKeyRemoved(this.downloadKey(item.gid, item.site)));
  }

  private isDownloadKeyRunningInCurrentProcess(key: string): boolean {
    if (key.length <= 0 || this.isDownloadKeyCancelled(key) || this.isDownloadKeyRemoved(key)) {
      return false;
    }
    if (this.downloadWorkerRunning && this.downloadActiveKey === key) {
      return true;
    }
    if (sharedDownloadWorkerRunning && sharedDownloadActiveKey === key) {
      return true;
    }
    if (this.downloadRuntimeWorkerRunning && this.downloadRuntimeActiveKey === key) {
      return true;
    }
    if (this.isDownloadRuntimeHeartbeatActiveForKey(key)) {
      return true;
    }
    const sharedItem = this.sharedDownloadItemByKey(key);
    return (this.downloadWorkerRunning || sharedDownloadWorkerRunning || this.downloadRuntimeWorkerRunning) &&
      !!sharedItem &&
      sharedItem.status === DOWNLOAD_STATUS_DOWNLOADING;
  }

  private latestDownloadItem(item: DownloadQueueItem): DownloadQueueItem {
    const key = this.downloadKey(item.gid, item.site);
    return this.findDownloadItemByKey(key) || item;
  }

  private activeDownloadRuntimeKey(): string {
    if (this.downloadActiveKey.length > 0) {
      return this.downloadActiveKey;
    }
    if (sharedDownloadActiveKey.length > 0) {
      return sharedDownloadActiveKey;
    }
    if (this.downloadRuntimeActiveKey.length > 0) {
      return this.downloadRuntimeActiveKey;
    }
    return this.activeDownloadRuntimeKeyFromPreferences();
  }

  private shouldUseSharedDownloadItem(sharedItem: DownloadQueueItem, localItem: DownloadQueueItem | undefined): boolean {
    if (!localItem) {
      return true;
    }
    if (localItem.downloaded > sharedItem.downloaded) {
      return false;
    }
    if (this.downloadKey(sharedItem.gid, sharedItem.site) === this.activeDownloadRuntimeKey()) {
      return true;
    }
    if (sharedItem.status === DOWNLOAD_STATUS_DOWNLOADING &&
      localItem.status !== DOWNLOAD_STATUS_DONE &&
      localItem.status !== DOWNLOAD_STATUS_DELETED) {
      return true;
    }
    return sharedItem.updatedAt.length > 0 && localItem.updatedAt.length > 0 &&
      sharedItem.updatedAt > localItem.updatedAt;
  }

  private downloadItemsSource(): DownloadQueueItem[] {
    const itemsByKey: Map<string, DownloadQueueItem> = new Map<string, DownloadQueueItem>();
    for (const item of this.downloadItems) {
      const key = this.downloadKey(item.gid, item.site);
      if (!this.isDownloadKeyRemoved(key)) {
        itemsByKey.set(key, this.cloneDownloadItem(item));
      }
    }
    for (const item of sharedDownloadItemsSnapshot) {
      const key = this.downloadKey(item.gid, item.site);
      if (this.isDownloadKeyRemoved(key)) {
        continue;
      }
      const existing = itemsByKey.get(key);
      if (this.shouldUseSharedDownloadItem(item, existing)) {
        itemsByKey.set(key, this.cloneDownloadItem(item));
      }
    }
    for (const item of this.runtimeDownloadItemsSnapshot()) {
      const key = this.downloadKey(item.gid, item.site);
      if (this.isDownloadKeyRemoved(key)) {
        continue;
      }
      const existing = itemsByKey.get(key);
      if (this.shouldUseSharedDownloadItem(item, existing)) {
        itemsByKey.set(key, this.cloneDownloadItem(item));
      }
    }
    const items: DownloadQueueItem[] = [];
    itemsByKey.forEach((item: DownloadQueueItem) => {
      items.push(this.downloadDisplayItem(item));
    });
    return items;
  }

  private downloadDisplayItem(item: DownloadQueueItem): DownloadQueueItem {
    if (item.status === DOWNLOAD_STATUS_DOWNLOADING &&
      this.isDownloadItemRunning(item) &&
      item.lastAction.startsWith('下载中断')) {
      const action = item.currentPage > 0 ? `正在下载第 ${item.currentPage} 页` : '正在下载';
      return this.toDownloadItem(
        item,
        item.status,
        item.queuedAt,
        action,
        item.label,
        item.downloaded,
        item.total,
        item.failedCount,
        item.archiveUri,
        item.createdAt,
        item.updatedAt,
        item.currentPage,
        item.currentPageLabel,
        item.speedBytesPerSecond,
        item.remainingSeconds,
        item.downloadDir,
        item.error,
        item.pageErrors
      );
    }
    return item;
  }

  private publishSharedDownloadItems(): void {
    const snapshot: DownloadQueueItem[] = [];
    for (const item of this.downloadItems) {
      snapshot.push(this.cloneDownloadItem(item));
    }
    sharedDownloadItemsSnapshot = snapshot;
    this.publishDownloadRuntimeStorage(snapshot);
    this.bumpDownloadQueueRevision();
  }

  private enqueueSharedDownloadWaitKey(key: string, front: boolean = false): void {
    sharedDownloadWaitKeys = sharedDownloadWaitKeys.filter((entry: string) => entry !== key);
    if (front) {
      sharedDownloadWaitKeys = [key, ...sharedDownloadWaitKeys];
    } else {
      sharedDownloadWaitKeys = [...sharedDownloadWaitKeys, key];
    }
  }

  private removeSharedDownloadWaitKey(key: string): void {
    sharedDownloadWaitKeys = sharedDownloadWaitKeys.filter((entry: string) => entry !== key);
  }

  private isRecordQueued(record: LocalGalleryRecord): boolean {
    return !!this.findDownloadItemByKey(this.downloadKey(record.gid, record.site));
  }

  private toggleGalleryQueue(record: LocalGalleryRecord): void {
    const key = this.downloadKey(record.gid, record.site);
    const existing = this.findDownloadItemByKey(key);
    if (existing) {
      this.removeDownloadItem(existing);
      return;
    }
    this.clearDownloadKeyRemoved(key);
    this.downloadCancelKeys.delete(key);
    sharedDownloadCancelKeys.delete(key);
    this.updateRuntimeStringArray(DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY, key, false);
    const nextItem = this.toDownloadItem(
      record,
      DOWNLOAD_STATUS_QUEUED,
      this.nowLabel(),
      '从详情加入',
      DOWNLOAD_DEFAULT_LABEL,
      0,
      record.pages,
      0,
      '',
      this.nowLabel(),
      this.nowLabel()
    );
    this.downloadItems = [nextItem, ...this.downloadItems].slice(0, 80);
    this.ensureDownloadLabelExists(nextItem.label);
    this.saveDownloadItems();
    this.libraryPanel = LIBRARY_DOWNLOADS;
    this.setDownloadViewMode(DOWNLOAD_VIEW_ACTIVE);
    this.toast('已加入下载队列并开始');
    this.startDownloadItem(nextItem);
  }

  private toggleCurrentGalleryQueue(): void {
    const record = this.createRecordFromDetail();
    if (!record) {
      return;
    }
    this.toggleGalleryQueue(record);
  }

  private toggleSummaryQueue(item: NativeGallerySummary): void {
    this.toggleGalleryQueue(this.createRecordFromSummary(item));
  }

  private updateDownloadStatus(gid: number, site: string, status: string): void {
    const item = this.findDownloadItem(gid, site);
    if (!item) {
      return;
    }
    this.replaceDownloadItem(this.toDownloadItem(
      item,
      status,
      item.queuedAt,
      `状态改为 ${this.downloadStatusLabel(status)}`,
      item.label,
      item.downloaded,
      item.total,
      item.failedCount,
      item.archiveUri,
      item.createdAt,
      this.nowLabel(),
      item.currentPage,
      item.currentPageLabel,
      status === DOWNLOAD_STATUS_DOWNLOADING ? item.speedBytesPerSecond : 0,
      status === DOWNLOAD_STATUS_DOWNLOADING ? item.remainingSeconds : -1,
      item.downloadDir,
      item.error,
      item.pageErrors
    ));
  }

  private toggleDownloadDone(item: DownloadQueueItem): void {
    const current = this.latestDownloadItem(item);
    if (current.status === DOWNLOAD_STATUS_DONE) {
      this.updateDownloadStatus(current.gid, current.site, DOWNLOAD_STATUS_QUEUED);
      return;
    }
    this.clearDownloadTransferProgress(current);
    this.replaceDownloadItem(this.toDownloadItem(
      current,
      DOWNLOAD_STATUS_DONE,
      current.queuedAt,
      '手动标记完成',
      current.label,
      current.total > 0 ? current.total : current.downloaded,
      current.total > 0 ? current.total : current.downloaded,
      0,
      current.archiveUri,
      current.createdAt,
      this.nowLabel(),
      current.currentPage,
      current.currentPageLabel,
      0,
      0,
      current.downloadDir,
      '',
      []
    ));
  }

  private removeDownloadedFilesForItem(item: DownloadQueueItem): void {
    const paths: string[] = [];
    const storedDir = item.downloadDir.trim();
    if (storedDir.length > 0) {
      paths.push(storedDir);
    }
    const defaultDir = this.galleryDownloadDir(item);
    if (defaultDir.length > 0 && paths.indexOf(defaultDir) < 0) {
      paths.push(defaultDir);
    }
    for (const path of paths) {
      this.removePathRecursive(path);
    }
  }

  private removeDownloadItem(item: DownloadQueueItem): void {
    const current = this.latestDownloadItem(item);
    const key = this.downloadKey(current.gid, current.site);
    this.bumpDownloadRunGeneration(key);
    this.invalidateDownloadPersistForKey(key);
    this.clearDownloadTransferProgress(current);
    this.cancelDownloadActiveRequests(key);
    this.markDownloadKeyRemoved(key);
    this.downloadItems = this.downloadItems.filter((entry: DownloadQueueItem) =>
      !(entry.gid === current.gid && entry.site === current.site));
    sharedDownloadItemsSnapshot = sharedDownloadItemsSnapshot.filter((entry: DownloadQueueItem) =>
      this.downloadKey(entry.gid, entry.site) !== key);
    const runtimeSnapshot = this.runtimeDownloadItemsSnapshot().filter((entry: DownloadQueueItem) =>
      this.downloadKey(entry.gid, entry.site) !== key);
    AppStorage.setOrCreate<string>(DOWNLOAD_RUNTIME_ITEMS_KEY, JSON.stringify(runtimeSnapshot));
    this.downloadWaitKeys = this.downloadWaitKeys.filter((entry: string) => entry !== key);
    this.downloadStartRequestedKeys.delete(key);
    this.removeSharedDownloadWaitKey(key);
    sharedDownloadStartRequestedKeys.delete(key);
    this.saveDownloadItems();
    this.scheduleDownloadItemDelete(current);
    this.removeDownloadedFilesForItem(current);
    this.downloadItems = this.downloadItemsSource();
    this.publishSharedDownloadItems();
    this.reconcileDownloadViewMode();
    this.toast('已删除下载任务和本地文件');
    this.refreshDownloadRuntimeState(true);
  }

  private replaceDownloadItem(nextItem: DownloadQueueItem): void {
    this.replaceDownloadItemInternal(nextItem, true);
  }

  private replaceDownloadItemInternal(nextItem: DownloadQueueItem, persist: boolean): void {
    const key = this.downloadKey(nextItem.gid, nextItem.site);
    if (this.isDownloadKeyRemoved(key)) {
      return;
    }
    const nextItems: DownloadQueueItem[] = [];
    let replaced = false;
    for (const item of this.downloadItems) {
      if (this.downloadKey(item.gid, item.site) === key) {
        nextItems.push(nextItem);
        replaced = true;
      } else {
        nextItems.push(item);
      }
    }
    if (!replaced) {
      nextItems.unshift(nextItem);
    }
    this.downloadItems = nextItems;
    if (persist) {
      this.saveDownloadItems();
    } else {
      this.publishSharedDownloadItems();
    }
    this.reconcileDownloadViewMode();
  }

  private updateDownloadProgress(
    item: DownloadQueueItem,
    status: string,
    downloaded: number,
    total: number,
    failedCount: number,
    lastAction: string,
    currentPage: number,
    speedBytesPerSecond: number,
    remainingSeconds: number,
    downloadDir: string,
    error: string,
    pageErrors: DownloadPageError[],
    persist: boolean = true,
    currentPageLabel: string = ''
  ): void {
    if (status !== DOWNLOAD_STATUS_DOWNLOADING) {
      this.clearDownloadTransferProgress(item);
    }
    this.replaceDownloadItemInternal(this.toDownloadItem(
      item,
      status,
      item.queuedAt,
      lastAction,
      item.label,
      downloaded,
      total,
      failedCount,
      item.archiveUri,
      item.createdAt,
      this.nowLabel(),
      currentPage,
      currentPageLabel.length > 0 ? currentPageLabel : (currentPage > 0 ? `${currentPage}/${Math.max(total, currentPage)}` : ''),
      speedBytesPerSecond,
      remainingSeconds,
      downloadDir,
      error,
      pageErrors
    ), persist);
    const key = this.downloadKey(item.gid, item.site);
    const activeKey = this.activeDownloadRuntimeKey();
    if (key === activeKey && lastAction.length > 0) {
      this.downloadManagerStatus = lastAction;
    }
    this.refreshDownloadRuntimeState(status !== DOWNLOAD_STATUS_DOWNLOADING);
  }

  private updateDownloadPageTransferFraction(item: DownloadQueueItem, pageIndex: number, fraction: number): void {
    const key = this.downloadKey(item.gid, item.site);
    let pageFractions = this.downloadPageTransferFractions.get(key);
    if (!pageFractions) {
      pageFractions = new Map<number, number>();
      this.downloadPageTransferFractions.set(key, pageFractions);
    }
    pageFractions.set(pageIndex, clampNumber(fraction, 0, 0.99));
  }

  private clearDownloadPageTransferFraction(item: DownloadQueueItem, pageIndex: number): void {
    const key = this.downloadKey(item.gid, item.site);
    const pageFractions = this.downloadPageTransferFractions.get(key);
    if (!pageFractions) {
      return;
    }
    pageFractions.delete(pageIndex);
    if (pageFractions.size <= 0) {
      this.downloadPageTransferFractions.delete(key);
    }
  }

  private clearDownloadTransferProgress(item: DownloadQueueItem): void {
    this.downloadPageTransferFractions.delete(this.downloadKey(item.gid, item.site));
  }

  private downloadPageTransferFractionSum(item: DownloadQueueItem): number {
    const pageFractions = this.downloadPageTransferFractions.get(this.downloadKey(item.gid, item.site));
    if (!pageFractions) {
      return 0;
    }
    let total = 0;
    pageFractions.forEach((value: number) => {
      total += clampNumber(value, 0, 0.99);
    });
    return total;
  }

  private registerDownloadActiveRequest(key: string, request: http.HttpRequest): void {
    const requests = this.downloadActiveRequests.get(key) || [];
    requests.push(request);
    this.downloadActiveRequests.set(key, requests);
  }

  private unregisterDownloadActiveRequest(key: string, request: http.HttpRequest): void {
    const requests = this.downloadActiveRequests.get(key);
    if (!requests) {
      return;
    }
    const nextRequests = requests.filter((entry: http.HttpRequest) => entry !== request);
    if (nextRequests.length > 0) {
      this.downloadActiveRequests.set(key, nextRequests);
    } else {
      this.downloadActiveRequests.delete(key);
    }
  }

  private cancelDownloadActiveRequests(key: string): void {
    const requests = this.downloadActiveRequests.get(key);
    if (!requests) {
      return;
    }
    this.downloadActiveRequests.delete(key);
    for (const request of requests) {
      try {
        request.destroy();
      } catch (error) {
      }
    }
  }

  private ensureDownloadLabelExists(label: string): void {
    const name = label.trim().length > 0 ? label.trim() : DOWNLOAD_DEFAULT_LABEL;
    if (this.downloadLabels.some((entry: DownloadLabelItem) => entry.label === name)) {
      return;
    }
    this.downloadLabels = [...this.downloadLabels, { label: name, createdAt: this.nowLabel() }];
    this.saveDownloadLabels();
  }

  private addDownloadLabel(): void {
    const label = this.downloadLabelDraft.trim();
    if (label.length === 0) {
      this.toast('请输入标签名称');
      return;
    }
    if (label === DOWNLOAD_LABEL_ALL || this.downloadLabels.some((entry: DownloadLabelItem) => entry.label === label)) {
      this.toast('标签已存在');
      return;
    }
    this.downloadLabels = [...this.downloadLabels, { label, createdAt: this.nowLabel() }];
    this.downloadLabelDraft = '';
    this.saveDownloadLabels();
  }

  private moveDownloadItemToNextLabel(item: DownloadQueueItem): void {
    const current = this.latestDownloadItem(item);
    const labels = ensureDownloadDefaultLabel(this.downloadLabels, this.nowLabel());
    const currentIndex = Math.max(0, labels.findIndex((entry: DownloadLabelItem) => entry.label === current.label));
    const nextLabel = labels[(currentIndex + 1) % labels.length].label;
    this.replaceDownloadItem(this.toDownloadItem(
      current,
      current.status,
      current.queuedAt,
      `移动到 ${nextLabel}`,
      nextLabel,
      current.downloaded,
      current.total,
      current.failedCount,
      current.archiveUri,
      current.createdAt,
      this.nowLabel(),
      current.currentPage,
      current.currentPageLabel,
      current.speedBytesPerSecond,
      current.remainingSeconds,
      current.downloadDir,
      current.error,
      current.pageErrors
    ));
    this.refreshDownloadRuntimeState(true);
  }

  private isDownloadItemRunning(item: DownloadQueueItem): boolean {
    const key = this.downloadKey(item.gid, item.site);
    return item.status !== DOWNLOAD_STATUS_DONE &&
      item.status !== DOWNLOAD_STATUS_DELETED &&
      this.isDownloadKeyRunningInCurrentProcess(key);
  }

  private activeDownloadItem(): DownloadQueueItem | undefined {
    const key = this.activeDownloadRuntimeKey();
    if (key.length <= 0 || this.isDownloadKeyCancelled(key) || this.isDownloadKeyRemoved(key)) {
      return undefined;
    }
    return this.findDownloadItemByKey(key);
  }

  private downloadRuntimeActive(): boolean {
    if (this.downloadNotificationItems().length <= 0) {
      return false;
    }
    const localActive = this.downloadActiveKey.length > 0 && !this.isDownloadKeyRemoved(this.downloadActiveKey);
    const sharedActive = sharedDownloadActiveKey.length > 0 && !this.isDownloadKeyRemoved(sharedDownloadActiveKey);
    const storageActive = this.downloadRuntimeActiveKey.length > 0 && !this.isDownloadKeyRemoved(this.downloadRuntimeActiveKey);
    const heartbeatActiveKey = this.activeDownloadRuntimeKeyFromPreferences();
    const heartbeatActive = heartbeatActiveKey.length > 0 && !this.isDownloadKeyRemoved(heartbeatActiveKey);
    return this.downloadWorkerRunning ||
      localActive ||
      sharedDownloadWorkerRunning ||
      sharedActive ||
      this.downloadRuntimeWorkerRunning ||
      storageActive ||
      heartbeatActive;
  }

  private shortDownloadNotificationText(text: string, limit: number): string {
    if (text.length <= limit) {
      return text;
    }
    return `${text.slice(0, Math.max(0, limit - 3))}...`;
  }

  private async createDownloadWantAgent(requestCode: number = DOWNLOAD_NOTIFICATION_BASE_ID): Promise<object | undefined> {
    const parameters: Record<string, Object> = {};
    parameters[DOWNLOAD_ROUTE_ACTION_KEY] = DOWNLOAD_ROUTE_ACTION_ACTIVE;
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: APP_BUNDLE_NAME,
        abilityName: APP_ABILITY_NAME,
        parameters
      }],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    try {
      return await wantAgent.getWantAgent(wantAgentInfo);
    } catch (error) {
      return undefined;
    }
  }

  private shouldPublishDownloadNotification(item: DownloadQueueItem): boolean {
    if (item.status === DOWNLOAD_STATUS_DONE ||
      item.status === DOWNLOAD_STATUS_DELETED ||
      item.status === DOWNLOAD_STATUS_PAUSED) {
      return false;
    }
    const key = this.downloadKey(item.gid, item.site);
    return this.isDownloadItemRunning(item) || this.activeDownloadRuntimeKey() === key;
  }

  private downloadNotificationItems(): DownloadQueueItem[] {
    const items: DownloadQueueItem[] = [];
    for (const item of this.downloadItemsSource()) {
      if (this.shouldPublishDownloadNotification(item)) {
        items.push(item);
      }
    }
    const active = this.activeDownloadItem();
    if (active && this.shouldPublishDownloadNotification(active)) {
      const activeKey = this.downloadKey(active.gid, active.site);
      const ordered: DownloadQueueItem[] = [];
      for (const item of items) {
        if (this.downloadKey(item.gid, item.site) === activeKey) {
          ordered.push(item);
        }
      }
      for (const item of items) {
        if (this.downloadKey(item.gid, item.site) !== activeKey) {
          ordered.push(item);
        }
      }
      return ordered.length > 0 ? ordered : [active];
    }
    return items;
  }

  private downloadNotificationTitle(item: DownloadQueueItem): string {
    const title = item.title.trim();
    return this.shortDownloadNotificationText(title.length > 0 ? title : `${item.site}-${item.gid}`, 72);
  }

  private downloadNotificationBase(item: DownloadQueueItem): number {
    return Math.max(item.total, item.pages, Math.ceil(item.downloaded), 1);
  }

  private downloadNotificationCurrent(item: DownloadQueueItem): number {
    const base = this.downloadNotificationBase(item);
    return Math.floor(clampNumber(this.downloadProgressRatio(item), 0, 1) * base);
  }

  private downloadNotificationPercent(item: DownloadQueueItem): number {
    return Math.round(clampNumber(this.downloadProgressRatio(item), 0, 1) * 100);
  }

  private downloadNotificationIdForKey(key: string): number {
    const cached = sharedDownloadNotificationIds.get(key);
    if (cached !== undefined) {
      return cached;
    }
    let hash = 0;
    for (let index = 0; index < key.length; index++) {
      hash = (hash * 31 + key.charCodeAt(index)) & 0x7fffffff;
    }
    const id = DOWNLOAD_NOTIFICATION_BASE_ID + (hash % 1000000);
    sharedDownloadNotificationIds.set(key, id);
    return id;
  }

  private downloadNotificationLabelForKey(key: string): string {
    const cached = sharedDownloadNotificationLabels.get(key);
    if (cached !== undefined) {
      return cached;
    }
    const safeKey = key.replace(/[^0-9A-Za-z_]/g, '_');
    const label = `${DOWNLOAD_NOTIFICATION_LABEL_PREFIX}${safeKey}`;
    sharedDownloadNotificationLabels.set(key, label);
    return label;
  }

  private downloadNotificationStateKey(item: DownloadQueueItem): string {
    return [
      item.site,
      item.gid,
      item.status,
      this.downloadNotificationCurrent(item),
      this.downloadNotificationBase(item),
      this.downloadNotificationPercent(item),
      item.downloaded,
      item.total,
      item.failedCount,
      item.currentPage,
      item.currentPageLabel,
      item.speedBytesPerSecond,
      item.remainingSeconds,
      item.lastAction,
      item.error
    ].join('|');
  }

  private async ensureDownloadNotificationPermission(): Promise<boolean> {
    try {
      await notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION);
    } catch (error) {
      hilog.warn(DIAG_DOMAIN, DIAG_TAG, 'Download notification add slot failed: %{public}s', JSON.stringify(error));
    }
    try {
      if (await notificationManager.isNotificationEnabled()) {
        return true;
      }
      if (this.downloadNotificationPermissionAsked) {
        return false;
      }
      const context = this.uiAbilityContext();
      if (!context) {
        return false;
      }
      this.downloadNotificationPermissionAsked = true;
      await notificationManager.requestEnableNotification(context);
      return await notificationManager.isNotificationEnabled();
    } catch (error) {
      hilog.warn(DIAG_DOMAIN, DIAG_TAG, 'Download notification permission failed: %{public}s',
        JSON.stringify(error));
      return false;
    }
  }

  private async publishDownloadNotificationForItem(item: DownloadQueueItem, force: boolean): Promise<void> {
    const key = this.downloadKey(item.gid, item.site);
    const id = this.downloadNotificationIdForKey(key);
    const label = this.downloadNotificationLabelForKey(key);
    const stateKey = this.downloadNotificationStateKey(item);
    const now = Date.now();
    const lastAt = sharedDownloadNotificationLastAt.get(key) || 0;
    if (!force && stateKey === sharedDownloadNotificationStates.get(key)) {
      return;
    }
    if (!force && now - lastAt < DOWNLOAD_NOTIFICATION_INTERVAL_MS) {
      return;
    }
    if (!(await this.ensureDownloadNotificationPermission())) {
      return;
    }
    const agent = await this.createDownloadWantAgent(id);
    const percent = this.downloadNotificationPercent(item);
    const speed = item.speedBytesPerSecond > 0 ? ` · ${formatBytesPerSecond(item.speedBytesPerSecond)}` : '';
    const remaining = item.remainingSeconds >= 0 ? ` · 剩余 ${formatRemainingSeconds(item.remainingSeconds)}` : '';
    const detail = item.error.length > 0 ? item.error : (item.lastAction.length > 0 ? item.lastAction : '正在下载');
    const title = this.downloadNotificationTitle(item);
    const text = `${percent}% · ${this.downloadProgressText(item)}${speed}${remaining}`;
    const request: notificationManager.NotificationRequest = {
      id,
      label,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title,
          text,
          additionalText: this.shortDownloadNotificationText(detail, 96)
        }
      },
      template: {
        name: 'downloadTemplate',
        data: {
          title: 'E-Harmony 下载',
          fileName: this.shortDownloadNotificationText(`${title} · ${text}`, 120),
          progressValue: percent
        }
      },
      notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
      isOngoing: false,
      isUnremovable: false,
      tapDismissed: false,
      isAlertOnce: true,
      groupName: DOWNLOAD_NOTIFICATION_GROUP
    };
    if (agent) {
      request.wantAgent = agent;
    }
    try {
      await notificationManager.publish(request);
      sharedDownloadNotificationStates.set(key, stateKey);
      sharedDownloadNotificationLastAt.set(key, now);
    } catch (error) {
      hilog.warn(DIAG_DOMAIN, DIAG_TAG, 'Download notification publish failed: %{public}s', JSON.stringify(error));
    }
  }

  private async cancelDownloadNotificationByKey(key: string): Promise<void> {
    const id = sharedDownloadNotificationIds.get(key);
    const label = sharedDownloadNotificationLabels.get(key);
    if (id !== undefined && label !== undefined) {
      try {
        await notificationManager.cancel(id, label);
      } catch (error) {
      }
    }
    sharedDownloadNotificationStates.delete(key);
    sharedDownloadNotificationLastAt.delete(key);
    sharedDownloadNotificationIds.delete(key);
    sharedDownloadNotificationLabels.delete(key);
  }

  private async cancelStaleDownloadNotifications(activeKeys: string[]): Promise<void> {
    const knownKeys = Array.from(sharedDownloadNotificationIds.keys());
    for (const key of knownKeys) {
      if (activeKeys.indexOf(key) < 0) {
        await this.cancelDownloadNotificationByKey(key);
      }
    }
  }

  private async publishDownloadNotifications(force: boolean): Promise<void> {
    const items = this.downloadNotificationItems();
    if (items.length <= 0) {
      await this.cancelAllDownloadNotifications();
      return;
    }
    const activeKeys: string[] = [];
    for (const item of items) {
      const key = this.downloadKey(item.gid, item.site);
      activeKeys.push(key);
      await this.publishDownloadNotificationForItem(item, force);
    }
    await this.cancelStaleDownloadNotifications(activeKeys);
  }

  private async cancelAllDownloadNotifications(): Promise<void> {
    const knownKeys = Array.from(sharedDownloadNotificationIds.keys());
    for (const key of knownKeys) {
      await this.cancelDownloadNotificationByKey(key);
    }
  }

  private async startDownloadBackgroundTask(): Promise<void> {
    if (this.downloadBackgroundRunning || this.downloadBackgroundStarting) {
      return;
    }
    this.downloadBackgroundStarting = true;
    try {
      const context = this.uiAbilityContext();
      if (!context) {
        return;
      }
      const agent = await this.createDownloadWantAgent();
      if (!agent) {
        return;
      }
      let taskId = -1;
      try {
        const request = new backgroundTaskManager.ContinuousTaskRequest();
        request.backgroundTaskModes = [backgroundTaskManager.BackgroundTaskMode.MODE_DATA_TRANSFER];
        request.combinedTaskNotification = true;
        request.wantAgent = agent;
        const notification: backgroundTaskManager.ContinuousTaskNotification =
          await backgroundTaskManager.startBackgroundRunning(context, request);
        taskId = notification.continuousTaskId === undefined ? -1 : notification.continuousTaskId;
      } catch (requestError) {
        const notification: backgroundTaskManager.ContinuousTaskNotification = await backgroundTaskManager.startBackgroundRunning(
          context,
          [DOWNLOAD_BACKGROUND_MODE],
          agent
        );
        taskId = notification.continuousTaskId === undefined ? -1 : notification.continuousTaskId;
      }
      this.downloadBackgroundRunning = true;
      this.downloadBackgroundTaskId = taskId;
      sharedDownloadBackgroundStopAttempted = false;
      hilog.info(DIAG_DOMAIN, DIAG_TAG, 'Download background task started: %{public}d', this.downloadBackgroundTaskId);
    } catch (error) {
      const code = `${(error as NativeReadableErrorInfo).code}`;
      if (code === '9800005') {
        this.downloadBackgroundRunning = true;
        this.downloadBackgroundTaskId = -1;
        sharedDownloadBackgroundStopAttempted = false;
        hilog.info(DIAG_DOMAIN, DIAG_TAG, 'Download background task already running');
        return;
      }
      hilog.warn(DIAG_DOMAIN, DIAG_TAG, 'Download background task start failed: %{public}s', JSON.stringify(error));
      this.downloadBackgroundRunning = false;
      this.downloadBackgroundTaskId = -1;
    } finally {
      this.downloadBackgroundStarting = false;
    }
  }

  private async stopDownloadBackgroundTask(): Promise<void> {
    const context = this.uiAbilityContext();
    if (!context) {
      this.downloadBackgroundRunning = false;
      this.downloadBackgroundTaskId = -1;
      return;
    }
    if (!this.downloadBackgroundRunning && sharedDownloadBackgroundStopAttempted) {
      this.downloadBackgroundTaskId = -1;
      return;
    }
    if (this.downloadBackgroundRunning || !sharedDownloadBackgroundStopAttempted) {
      try {
        if (this.downloadBackgroundTaskId > 0) {
          await backgroundTaskManager.stopBackgroundRunning(context, this.downloadBackgroundTaskId);
        } else {
          await backgroundTaskManager.stopBackgroundRunning(context);
        }
      } catch (error) {
        try {
          await backgroundTaskManager.stopBackgroundRunning(context);
        } catch (fallbackError) {
        }
      }
    }
    this.downloadBackgroundRunning = false;
    this.downloadBackgroundTaskId = -1;
    sharedDownloadBackgroundStopAttempted = true;
  }

  private refreshDownloadRuntimeState(force: boolean = false): void {
    this.updateDownloadStatePolling();
    this.queueDownloadRuntimeStateSync(force);
  }

  private queueDownloadRuntimeStateSync(force: boolean): void {
    this.downloadRuntimeSyncPending = true;
    this.downloadRuntimeSyncPendingForce = this.downloadRuntimeSyncPendingForce || force;
    if (this.downloadRuntimeSyncInFlight) {
      return;
    }
    this.downloadRuntimeSyncInFlight = true;
    void this.drainDownloadRuntimeStateSync();
  }

  private async drainDownloadRuntimeStateSync(): Promise<void> {
    try {
      while (this.downloadRuntimeSyncPending) {
        const force = this.downloadRuntimeSyncPendingForce;
        this.downloadRuntimeSyncPending = false;
        this.downloadRuntimeSyncPendingForce = false;
        await this.syncDownloadRuntimeState(force);
      }
    } finally {
      this.downloadRuntimeSyncInFlight = false;
      if (this.downloadRuntimeSyncPending) {
        this.queueDownloadRuntimeStateSync(this.downloadRuntimeSyncPendingForce);
      }
    }
  }

  private async syncDownloadRuntimeState(force: boolean): Promise<void> {
    if (this.downloadRuntimeActive()) {
      await this.publishDownloadNotifications(force);
      await this.startDownloadBackgroundTask();
    } else {
      await this.stopDownloadBackgroundTask();
      await this.cancelAllDownloadNotifications();
    }
  }

  private updateDownloadStatePolling(): void {
    if (this.isReady && !this.downloadWorkerRunning) {
      this.startDownloadStatePolling();
    } else {
      this.stopDownloadStatePolling();
    }
  }

  private startDownloadStatePolling(): void {
    if (this.downloadStatePollTimerId >= 0) {
      return;
    }
    const handle = setInterval(() => {
      if (!this.downloadRuntimeActive() || this.downloadWorkerRunning) {
        this.stopDownloadStatePolling();
        return;
      }
      void this.syncDownloadStateFromDatabase(false);
    }, DOWNLOAD_STATE_POLL_INTERVAL_MS);
    this.downloadStatePollTimerId = Number(handle);
  }

  private stopDownloadStatePolling(): void {
    if (this.downloadStatePollTimerId < 0) {
      return;
    }
    clearInterval(this.downloadStatePollTimerId);
    this.downloadStatePollTimerId = -1;
  }

  private enqueueDownloadWaitKey(key: string, front: boolean = false): void {
    this.downloadWaitKeys = this.downloadWaitKeys.filter((entry: string) => entry !== key);
    if (front) {
      this.downloadWaitKeys = [key, ...this.downloadWaitKeys];
    } else {
      this.downloadWaitKeys = [...this.downloadWaitKeys, key];
    }
    this.enqueueSharedDownloadWaitKey(key, front);
  }

  private currentDownloadRunGeneration(key: string): number {
    const generation = sharedDownloadRunGenerations.get(key);
    return generation === undefined ? 0 : generation;
  }

  private bumpDownloadRunGeneration(key: string): number {
    const nextGeneration = this.currentDownloadRunGeneration(key) + 1;
    this.downloadRunGenerations.set(key, nextGeneration);
    sharedDownloadRunGenerations.set(key, nextGeneration);
    return nextGeneration;
  }

  private startDownloadItem(item: DownloadQueueItem): void {
    const key = this.downloadKey(item.gid, item.site);
    this.bumpDownloadRunGeneration(key);
    this.downloadCancelKeys.delete(key);
    sharedDownloadCancelKeys.delete(key);
    this.updateRuntimeStringArray(DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY, key, false);
    this.downloadStartRequestedKeys.add(key);
    sharedDownloadStartRequestedKeys.add(key);
    this.enqueueDownloadWaitKey(key);
    const current = this.findDownloadItem(item.gid, item.site) || item;
    const runnable = this.toDownloadItem(
      current,
      DOWNLOAD_STATUS_QUEUED,
      current.queuedAt,
      '等待下载',
      current.label,
      current.downloaded,
      current.total,
      current.failedCount,
      current.archiveUri,
      current.createdAt,
      this.nowLabel(),
      current.currentPage,
      current.currentPageLabel,
      0,
      -1,
      current.downloadDir,
      '',
      current.pageErrors
    );
    this.replaceDownloadItem(runnable);
    this.downloadManagerStatus = '下载等待中';
    if (this.libraryPanel === LIBRARY_DOWNLOADS) {
      this.setDownloadViewMode(DOWNLOAD_VIEW_ACTIVE);
    }
    this.ensureDownloadWorker();
    this.refreshDownloadRuntimeState(true);
  }

  private markDownloadItemRunning(item: DownloadQueueItem): DownloadQueueItem {
    const running = this.toDownloadItem(
      item,
      DOWNLOAD_STATUS_DOWNLOADING,
      item.queuedAt,
      '正在开始下载',
      item.label,
      item.downloaded,
      item.total,
      item.failedCount,
      item.archiveUri,
      item.createdAt,
      this.nowLabel(),
      item.currentPage,
      item.currentPageLabel,
      0,
      -1,
      item.downloadDir,
      '',
      item.pageErrors
    );
    this.replaceDownloadItem(running);
    return running;
  }

  private pauseDownloadItem(item: DownloadQueueItem): void {
    const current = this.latestDownloadItem(item);
    const key = this.downloadKey(current.gid, current.site);
    this.bumpDownloadRunGeneration(key);
    this.clearDownloadTransferProgress(current);
    this.cancelDownloadActiveRequests(key);
    this.downloadCancelKeys.add(key);
    sharedDownloadCancelKeys.add(key);
    this.updateRuntimeStringArray(DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY, key, true);
    this.downloadStartRequestedKeys.delete(key);
    sharedDownloadStartRequestedKeys.delete(key);
    this.downloadWaitKeys = this.downloadWaitKeys.filter((entry: string) => entry !== key);
    this.removeSharedDownloadWaitKey(key);
    this.replaceDownloadItem(this.toDownloadItem(
      current,
      DOWNLOAD_STATUS_PAUSED,
      current.queuedAt,
      '已暂停',
      current.label,
      current.downloaded,
      current.total,
      current.failedCount,
      current.archiveUri,
      current.createdAt,
      this.nowLabel(),
      current.currentPage,
      current.currentPageLabel,
      0,
      -1,
      current.downloadDir,
      current.error,
      current.pageErrors
    ));
    this.downloadManagerStatus = `已暂停 ${current.title.length > 0 ? current.title : current.gid}`;
    this.refreshDownloadRuntimeState(true);
  }

  private startAllDownloads(): void {
    const nextItems: DownloadQueueItem[] = [];
    for (const item of this.downloadItemsSource()) {
      if (item.status === DOWNLOAD_STATUS_DONE || this.isDownloadItemRunning(item)) {
        nextItems.push(item);
        continue;
      }
      const key = this.downloadKey(item.gid, item.site);
      this.bumpDownloadRunGeneration(key);
      this.downloadCancelKeys.delete(key);
      sharedDownloadCancelKeys.delete(key);
      this.updateRuntimeStringArray(DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY, key, false);
      this.downloadStartRequestedKeys.add(key);
      sharedDownloadStartRequestedKeys.add(key);
      this.enqueueDownloadWaitKey(key);
      nextItems.push(this.toDownloadItem(
        item,
        DOWNLOAD_STATUS_QUEUED,
        item.queuedAt,
        '由全部开始加入队列',
        item.label,
        item.downloaded,
        item.total,
        item.failedCount,
        item.archiveUri,
        item.createdAt,
        this.nowLabel(),
        item.currentPage,
        item.currentPageLabel,
        0,
        -1,
        item.downloadDir,
        '',
        item.pageErrors
      ));
    }
    this.downloadItems = nextItems;
    this.saveDownloadItems();
    this.ensureDownloadWorker();
    this.refreshDownloadRuntimeState(true);
  }

  private pauseAllDownloads(): void {
    const nextItems: DownloadQueueItem[] = [];
    for (const item of this.downloadItemsSource()) {
      if (item.status === DOWNLOAD_STATUS_DONE) {
        nextItems.push(item);
        continue;
      }
      const key = this.downloadKey(item.gid, item.site);
      this.bumpDownloadRunGeneration(key);
      this.clearDownloadTransferProgress(item);
      this.cancelDownloadActiveRequests(key);
      this.downloadCancelKeys.add(key);
      sharedDownloadCancelKeys.add(key);
      this.updateRuntimeStringArray(DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY, key, true);
      this.downloadStartRequestedKeys.delete(key);
      sharedDownloadStartRequestedKeys.delete(key);
      this.downloadWaitKeys = this.downloadWaitKeys.filter((entry: string) => entry !== key);
      this.removeSharedDownloadWaitKey(key);
      nextItems.push(this.toDownloadItem(
        item,
        DOWNLOAD_STATUS_PAUSED,
        item.queuedAt,
        '由全部暂停',
        item.label,
        item.downloaded,
        item.total,
        item.failedCount,
        item.archiveUri,
        item.createdAt,
        this.nowLabel(),
        item.currentPage,
        item.currentPageLabel,
        0,
        -1,
        item.downloadDir,
        item.error,
        item.pageErrors
      ));
    }
    this.downloadItems = nextItems;
    this.saveDownloadItems();
    this.refreshDownloadRuntimeState(true);
  }

  private clearCompletedDownloads(): void {
    const source = this.downloadItemsSource();
    const removed = source.filter((item: DownloadQueueItem) => item.status === DOWNLOAD_STATUS_DONE);
    const removedKeys: string[] = removed.map((item: DownloadQueueItem) => this.downloadKey(item.gid, item.site));
    for (const item of removed) {
      const key = this.downloadKey(item.gid, item.site);
      this.markDownloadKeyRemoved(key);
      this.scheduleDownloadItemDelete(item);
    }
    this.downloadItems = source.filter((item: DownloadQueueItem) => removedKeys.indexOf(this.downloadKey(item.gid, item.site)) < 0);
    this.saveDownloadItems();
    this.refreshDownloadRuntimeState(true);
  }

  private invalidateDownloadPersistForKey(key: string): void {
    const nextVersion = (this.downloadPersistVersions.get(key) || 0) + 1;
    this.downloadPersistVersions.set(key, nextVersion);
  }

  private clearAllDownloadContent(): void {
    const removed = [...this.downloadItemsSource()];
    if (removed.length === 0) {
      this.toast('没有可清空的下载');
      return;
    }

    const removedKeys: string[] = [];
    for (const item of removed) {
      const key = this.downloadKey(item.gid, item.site);
      removedKeys.push(key);
      this.bumpDownloadRunGeneration(key);
      this.invalidateDownloadPersistForKey(key);
      this.clearDownloadTransferProgress(item);
      this.cancelDownloadActiveRequests(key);
      this.markDownloadKeyRemoved(key);
      this.removeDownloadedFilesForItem(item);
      this.scheduleDownloadItemDelete(item);
    }

    this.downloadWaitKeys = this.downloadWaitKeys.filter((entry: string) => removedKeys.indexOf(entry) < 0);
    sharedDownloadWaitKeys = sharedDownloadWaitKeys.filter((entry: string) => removedKeys.indexOf(entry) < 0);
    if (removedKeys.indexOf(this.downloadActiveKey) >= 0) {
      this.downloadActiveKey = '';
    }
    if (removedKeys.indexOf(sharedDownloadActiveKey) >= 0) {
      sharedDownloadActiveKey = '';
    }
    this.downloadItems = [];
    this.saveDownloadItems();
    this.downloadManagerStatus = '下载器空闲';
    this.refreshDownloadRuntimeState(true);
    this.toast(`已清空 ${removed.length} 个下载`);
  }

  private confirmClearAllDownloadContent(): void {
    const count = this.downloadItemsSource().length;
    if (count === 0) {
      this.toast('没有可清空的下载');
      return;
    }
    const options: promptAction.ShowDialogOptions = {
      title: '清空下载内容',
      message: `确定要删除全部 ${count} 个下载任务和本地文件吗？`,
      buttons: [
        { text: '取消', color: '#6F5964' },
        { text: '清空', color: '#B42318' }
      ]
    };
    try {
      void this.getUIContext().getPromptAction().showDialog(options)
        .then((result: promptAction.ShowDialogSuccessResponse) => {
          if (result.index === 1) {
            this.clearAllDownloadContent();
          }
        })
        .catch(() => {
        });
    } catch (error) {
    }
  }

  private nextRunnableDownload(): DownloadQueueItem | undefined {
    while (sharedDownloadWaitKeys.length > 0) {
      const key = sharedDownloadWaitKeys[0];
      sharedDownloadWaitKeys = sharedDownloadWaitKeys.slice(1);
      this.downloadWaitKeys = this.downloadWaitKeys.filter((entry: string) => entry !== key);
      if (this.downloadCancelKeys.has(key) || sharedDownloadCancelKeys.has(key)) {
        continue;
      }
      const item = this.findDownloadItemByKey(key);
      if (!item || item.status === DOWNLOAD_STATUS_DONE || item.status === DOWNLOAD_STATUS_DELETED) {
        continue;
      }
      if (item.status === DOWNLOAD_STATUS_QUEUED ||
        this.downloadStartRequestedKeys.has(key) ||
        sharedDownloadStartRequestedKeys.has(key)) {
        return item;
      }
    }
    for (const item of this.downloadItemsSource()) {
      if (item.status === DOWNLOAD_STATUS_QUEUED) {
        return item;
      }
    }
    return undefined;
  }

  private hasRunnableDownload(): boolean {
    for (const key of sharedDownloadWaitKeys) {
      if (this.downloadCancelKeys.has(key) || sharedDownloadCancelKeys.has(key)) {
        continue;
      }
      const item = this.findDownloadItemByKey(key);
      if (!item || item.status === DOWNLOAD_STATUS_DONE || item.status === DOWNLOAD_STATUS_DELETED) {
        continue;
      }
      if (item.status === DOWNLOAD_STATUS_QUEUED ||
        this.downloadStartRequestedKeys.has(key) ||
        sharedDownloadStartRequestedKeys.has(key)) {
        return true;
      }
    }
    for (const item of this.downloadItemsSource()) {
      if (item.status === DOWNLOAD_STATUS_QUEUED) {
        return true;
      }
    }
    return false;
  }

  private ensureDownloadWorker(): void {
    if (this.downloadWorkerRunning || sharedDownloadWorkerRunning) {
      this.updateDownloadStatePolling();
      return;
    }
    this.downloadWorkerRunning = true;
    sharedDownloadWorkerRunning = true;
    this.refreshDownloadRuntimeState(true);
    void this.runDownloadWorker();
  }

  private async runDownloadWorker(): Promise<void> {
    try {
      while (true) {
        const item = this.nextRunnableDownload();
        if (!item) {
          this.downloadManagerStatus = '下载器空闲';
          this.downloadActiveKey = '';
          sharedDownloadActiveKey = '';
          this.publishDownloadRuntimeStorage();
          return;
        }
        this.downloadActiveKey = this.downloadKey(item.gid, item.site);
        sharedDownloadActiveKey = this.downloadActiveKey;
        sharedDownloadWorkerRunning = true;
        this.publishDownloadRuntimeStorage();
        this.refreshDownloadRuntimeState(true);
        const runGeneration = this.currentDownloadRunGeneration(this.downloadActiveKey);
        const runningItem = this.markDownloadItemRunning(item);
        await this.runGalleryDownload(runningItem, runGeneration);
      }
    } finally {
      this.downloadWorkerRunning = false;
      sharedDownloadWorkerRunning = false;
      this.publishDownloadRuntimeStorage(sharedDownloadItemsSnapshot, true);
      if (this.hasRunnableDownload()) {
        this.ensureDownloadWorker();
      } else {
        this.refreshDownloadRuntimeState(true);
      }
    }
  }

  private downloadSiteReady(site: string): boolean {
    if (site === GallerySite.EX && !this.hasExCookie) {
      this.toast('EX 下载需要有效 EX Cookie');
      return false;
    }
    return true;
  }

  private async fetchDownloadDetail(item: DownloadQueueItem): Promise<NativeGalleryDetail> {
    const summary = this.toNativeSummary(item);
    return await NativeEhClient.fetchGalleryDetail(item.site, summary);
  }

  private async collectDownloadPageUrls(site: string, detail: NativeGalleryDetail): Promise<string[]> {
    const cacheKey = `${site}-${detail.gid}-${detail.token}`;
    const cached = this.downloadPageUrlCache.get(cacheKey);
    if (cached && cached.length > 0) {
      return cached;
    }
    const positions: Map<number, string> = new Map();
    let previewPages = Math.max(1, detail.previewPageCount);
    for (let pageIndex = 0; pageIndex < previewPages; pageIndex++) {
      const page = await NativeEhClient.fetchGalleryPreviewPage(site, detail.detailUrl, pageIndex);
      previewPages = Math.max(previewPages, page.pageCount);
      for (const item of page.items) {
        if (item.pageUrl.length > 0) {
          positions.set(item.position, item.pageUrl);
        }
      }
    }
    const keys = Array.from(positions.keys()).sort((a: number, b: number) => a - b);
    const urls: string[] = [];
    for (const key of keys) {
      const url = positions.get(key);
      if (url && url.length > 0) {
        urls.push(url);
      }
    }
    this.downloadPageUrlCache.set(cacheKey, urls);
    return urls;
  }

  private downloadRoot(): string {
    const custom = this.downloadDirectoryPath.trim();
    if (custom.length > 0) {
      return custom;
    }
    const filesDir = this.abilityFilesDir();
    return filesDir.length > 0 ? `${filesDir}/${READER_DOWNLOAD_DIR_NAME}` : '';
  }

  private galleryDownloadDir(item: DownloadQueueItem): string {
    const root = this.downloadRoot();
    if (root.length === 0) {
      return '';
    }
    return `${root}/${item.site}-${item.gid}`;
  }

  private existingDownloadPath(item: DownloadQueueItem, pageIndex: number): string {
    const dir = this.galleryDownloadDir(item);
    if (dir.length === 0) {
      return '';
    }
    const oneBased = pageIndex + 1;
    const names: string[] = [];
    for (const extension of READER_IMAGE_EXTENSIONS) {
      names.push(`${oneBased}`.padStart(8, '0') + extension);
      names.push(`${oneBased}`.padStart(5, '0') + extension);
      names.push(`${oneBased}${extension}`);
    }
    for (const name of names) {
      const path = `${dir}/${name}`;
      try {
        if (fileIo.accessSync(path)) {
          return path;
        }
      } catch (error) {
      }
    }
    return '';
  }

  private downloadTargetPath(item: DownloadQueueItem, pageIndex: number, sourceUrl: string): string {
    const dir = this.galleryDownloadDir(item);
    const pageName = `${pageIndex + 1}`.padStart(8, '0');
    return `${dir}/${pageName}${this.readerImageExtensionFromUrl(sourceUrl)}`;
  }

  private appendDownloadCookieSource(url: string, names: string[], values: string[]): void {
    this.appendReaderCookieSource(url, names, values);
  }

  private downloadCookieHeader(url: string, site: string): string {
    const names: string[] = [];
    const values: string[] = [];
    this.appendDownloadCookieSource(EhUrl.DOMAIN_FORUMS, names, values);
    this.appendDownloadCookieSource(EhUrl.DOMAIN_E, names, values);
    if (site === GallerySite.EX) {
      this.appendDownloadCookieSource(EhUrl.DOMAIN_EX, names, values);
    }
    this.appendDownloadCookieSource(url, names, values);
    if (site === GallerySite.E && names.indexOf('nw') < 0) {
      names.push('nw');
      values.push('nw=1');
    }
    return values.join('; ');
  }

  private writeLocalTextFile(path: string, value: string): void {
    let file: fileIo.File | undefined = undefined;
    try {
      file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(file.fd, value);
    } catch (error) {
    } finally {
      if (file) {
        try {
          fileIo.closeSync(file);
        } catch (closeError) {
        }
      }
    }
  }

  private downloadCsvCell(value: string): string {
    return value.replace(/[\r\n,]/g, ' ').trim();
  }

  private downloadCsvLine(item: DownloadQueueItem): string {
    const fields: string[] = [
      `${item.gid}`,
      item.token,
      this.downloadCsvCell(item.title),
      this.downloadCsvCell(item.titleJpn),
      item.cover,
      `${this.categoryBitFromLabel(item.categoryLabel)}`,
      item.posted,
      this.downloadCsvCell(item.uploader),
      `${item.rating}`,
      'false',
      this.downloadCsvCell(item.language),
      '[]',
      '0',
      '0',
      '0',
      '0',
      '0',
      '-2',
      '',
      `${item.total > 0 ? item.total : item.pages}`
    ];
    return fields.join(',');
  }

  private writeDownloadMetadata(item: DownloadQueueItem, dir: string): void {
    if (dir.length === 0 || !this.ensureLocalDirectory(dir)) {
      return;
    }
    this.writeLocalTextFile(`${dir}/${DOWNLOAD_INFO_FILENAME}`, `${DOWNLOAD_INFO_HEADER}\n${this.downloadCsvLine(item)}\n`);
  }

  private async downloadImageFile(
    taskKey: string,
    site: string,
    sourceUrl: string,
    referer: string,
    targetPath: string,
    onProgress?: DownloadProgressCallback
  ): Promise<DownloadPageResult> {
    const dir = targetPath.substring(0, targetPath.lastIndexOf('/'));
    if (sourceUrl.length === 0 || targetPath.length === 0 || !this.ensureLocalDirectory(dir)) {
      throw new Error('下载目录不可用');
    }
    const request = http.createHttp();
    const headers: Record<string, string> = {
      'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'User-Agent': NativeEhClient.USER_AGENT,
      'Referer': referer
    };
    const host = this.readerHostFromUrl(sourceUrl);
    if (host.length > 0) {
      headers['Host'] = host;
    }
    const cookie = this.downloadCookieHeader(sourceUrl, site);
    if (cookie.length > 0) {
      headers['Cookie'] = cookie;
    }
    const progressCallback = (progress: http.DataReceiveProgressInfo): void => {
      if (onProgress) {
        onProgress(progress.receiveSize, progress.totalSize);
      }
    };
    this.registerDownloadActiveRequest(taskKey, request);
    try {
      if (onProgress) {
        request.on('dataReceiveProgress', progressCallback);
      }
      const response = await request.request(sourceUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        usingCache: false,
        usingProxy: AppNetworkProxy.requestProxy(),
        readTimeout: 45000,
        connectTimeout: 15000,
        header: headers
      });
      const code = Number(response.responseCode);
      if (code < 200 || code >= 400) {
        throw new Error(`HTTP ${code}`);
      }
      const result = response.result;
      const data = typeof result === 'string' ? this.stringToArrayBuffer(result) : result as ArrayBuffer;
      if (data.byteLength <= 0) {
        throw new Error('图片响应为空');
      }
      const tempPath = `${targetPath}.tmp`;
      let file: fileIo.File | undefined = undefined;
      try {
        file = fileIo.openSync(tempPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
        fileIo.writeSync(file.fd, data);
      } finally {
        if (file) {
          try {
            fileIo.closeSync(file);
          } catch (closeError) {
          }
        }
      }
      try {
        if (fileIo.accessSync(targetPath)) {
          fileIo.unlinkSync(targetPath);
        }
      } catch (error) {
      }
      try {
        fileIo.renameSync(tempPath, targetPath);
      } catch (renameError) {
        throw new Error(`${renameError}`);
      }
      return {
        path: targetPath,
        bytes: data.byteLength,
        sourceUrl
      };
    } catch (error) {
      const message = `${error}`;
      throw new Error(message.length > 0 ? message : '图片下载失败');
    } finally {
      this.unregisterDownloadActiveRequest(taskKey, request);
      if (onProgress) {
        try {
          request.off('dataReceiveProgress', progressCallback);
        } catch (offError) {
        }
      }
      try {
        request.destroy();
      } catch (destroyError) {
      }
    }
  }

  private async downloadSinglePage(
    item: DownloadQueueItem,
    pageUrl: string,
    pageIndex: number,
    onProgress?: DownloadProgressCallback
  ): Promise<DownloadPageResult> {
    const page = await NativeEhClient.fetchReaderPage(item.site, pageUrl);
    const sourceUrl = this.downloadUseOriginImage && page.originImageUrl.length > 0 ? page.originImageUrl : page.imageUrl;
    const targetPath = this.downloadTargetPath(item, pageIndex, sourceUrl);
    return await this.downloadImageFile(this.downloadKey(item.gid, item.site), item.site, sourceUrl, page.pageUrl, targetPath, onProgress);
  }

  private async downloadPageWithRetry(
    item: DownloadQueueItem,
    pageUrl: string,
    pageIndex: number,
    onProgress?: DownloadProgressCallback
  ): Promise<DownloadPageResult> {
    let lastError = '';
    for (let attempt = 0; attempt <= DOWNLOAD_PAGE_RETRY_LIMIT; attempt++) {
      try {
        return await this.downloadSinglePage(item, pageUrl, pageIndex, onProgress);
      } catch (error) {
        lastError = `${error}`;
      }
    }
    throw new Error(lastError.length > 0 ? lastError : '图片下载失败');
  }

  private shouldStopDownload(item: DownloadQueueItem, runGeneration: number): boolean {
    const key = this.downloadKey(item.gid, item.site);
    if (this.isDownloadKeyRemoved(key)) {
      return true;
    }
    if (this.currentDownloadRunGeneration(key) !== runGeneration) {
      return true;
    }
    if (this.downloadCancelKeys.has(key) || sharedDownloadCancelKeys.has(key)) {
      return true;
    }
    const current = this.findDownloadItem(item.gid, item.site);
    if (!current) {
      return true;
    }
    return current.status === DOWNLOAD_STATUS_PAUSED || current.status === DOWNLOAD_STATUS_DELETED;
  }

  private async runGalleryDownload(seed: DownloadQueueItem, runGeneration: number): Promise<void> {
    if (!this.downloadSiteReady(seed.site)) {
      this.updateDownloadStatus(seed.gid, seed.site, DOWNLOAD_STATUS_FAILED);
      return;
    }
    const key = this.downloadKey(seed.gid, seed.site);
    this.downloadStartRequestedKeys.delete(key);
    sharedDownloadStartRequestedKeys.delete(key);
    this.downloadActiveKey = key;
    sharedDownloadActiveKey = key;
    sharedDownloadWorkerRunning = true;
    this.downloadManagerStatus = `正在下载 ${seed.title.length > 0 ? seed.title : seed.gid}`;
    let item = this.findDownloadItem(seed.gid, seed.site) || seed;
    this.updateDownloadProgress(
      item,
      DOWNLOAD_STATUS_DOWNLOADING,
      item.downloaded,
      item.total,
      item.failedCount,
      '正在获取画廊页面',
      item.currentPage,
      0,
      -1,
      item.downloadDir,
      '',
      item.pageErrors
    );

    try {
      const detail = await this.fetchDownloadDetail(item);
      item = this.findDownloadItem(seed.gid, seed.site) || item;
      if (this.shouldStopDownload(item, runGeneration)) {
        this.downloadManagerStatus = '下载器已暂停';
        return;
      }
      const detailRecord: LocalGalleryRecord = {
        gid: detail.gid,
        token: detail.token,
        title: detail.title,
        titleJpn: detail.titleJpn,
        cover: detail.cover,
        detailUrl: detail.detailUrl,
        site: item.site,
        uploader: detail.uploader,
        categoryLabel: detail.categoryLabel,
        posted: detail.posted,
        pages: detail.pages,
        language: detail.language,
        rating: detail.rating
      };
      item = this.toDownloadItem(
        detailRecord,
        DOWNLOAD_STATUS_DOWNLOADING,
        item.queuedAt,
        '正在获取画廊页面',
        item.label,
        item.downloaded,
        detail.pages > 0 ? detail.pages : item.total,
        item.failedCount,
        item.archiveUri,
        item.createdAt,
        this.nowLabel(),
        item.currentPage,
        item.currentPageLabel,
        0,
        -1,
        item.downloadDir,
        '',
        item.pageErrors
      );
      this.replaceDownloadItem(item);

      const pageUrls = await this.collectDownloadPageUrls(item.site, detail);
      item = this.findDownloadItem(seed.gid, seed.site) || item;
      if (this.shouldStopDownload(item, runGeneration)) {
        this.downloadManagerStatus = '下载器已暂停';
        return;
      }
      const total = Math.max(item.total, detail.pages, pageUrls.length);
      if (pageUrls.length === 0) {
        throw new Error('未解析到下载页');
      }
      const dir = this.galleryDownloadDir(item);
      if (dir.length === 0 || !this.ensureLocalDirectory(dir)) {
        throw new Error('下载目录不可用');
      }
      this.writeDownloadMetadata(item, dir);

      let downloaded = 0;
      const pageErrors: DownloadPageError[] = [];
      let failedCount = Math.max(0, total - pageUrls.length);
      if (failedCount > 0) {
        pageErrors.push({
          page: pageUrls.length + 1,
          message: `缺少 ${failedCount} 个下载页链接`,
          updatedAt: this.nowLabel()
        });
        this.updateDownloadProgress(
          item,
          DOWNLOAD_STATUS_DOWNLOADING,
          downloaded,
          total,
          failedCount,
          '下载页链接不完整',
          item.currentPage,
          0,
          -1,
          dir,
          pageErrors[0].message,
          pageErrors
        );
      }
      let lastSpeed = 0;
      let nextPageIndex = 0;
      const runPageWorker = async (): Promise<void> => {
        while (true) {
          const index = nextPageIndex;
          nextPageIndex++;
          if (index >= pageUrls.length) {
            return;
          }
          item = this.findDownloadItem(seed.gid, seed.site) || item;
          if (this.shouldStopDownload(item, runGeneration)) {
            this.downloadManagerStatus = '下载器已暂停';
            return;
          }
          const existingPath = this.existingDownloadPath(item, index);
          if (existingPath.length > 0) {
            downloaded++;
            this.updateDownloadProgress(
              item,
              DOWNLOAD_STATUS_DOWNLOADING,
              downloaded,
              total,
              failedCount,
              `跳过已存在第 ${index + 1} 页`,
              index + 1,
              lastSpeed,
              -1,
              dir,
              '',
              pageErrors
            );
            continue;
          }
          const startedAt = Date.now();
          let lastProgressAt = 0;
          let lastProgressPersistAt = 0;
          this.updateDownloadPageTransferFraction(item, index, 0);
          this.updateDownloadProgress(
            item,
            DOWNLOAD_STATUS_DOWNLOADING,
            downloaded,
            total,
            failedCount,
            `正在下载第 ${index + 1} 页`,
            index + 1,
            lastSpeed,
            -1,
            dir,
            '',
            pageErrors,
            false,
            `第 ${index + 1} 页 0%`
          );
          const onPageProgress: DownloadProgressCallback = (receivedBytes: number, totalBytes: number): void => {
            const now = Date.now();
            const complete = totalBytes > 0 && receivedBytes >= totalBytes;
            if (!complete && now - lastProgressAt < DOWNLOAD_PROGRESS_UI_INTERVAL_MS) {
              return;
            }
            lastProgressAt = now;
            const current = this.findDownloadItem(seed.gid, seed.site) || item;
            if (this.shouldStopDownload(current, runGeneration)) {
              return;
            }
            const elapsedSeconds = Math.max(1, (now - startedAt) / 1000);
            lastSpeed = Math.round(Math.max(0, receivedBytes) / elapsedSeconds);
            const fraction = totalBytes > 0 ? clampNumber(receivedBytes / totalBytes, 0, 0.99) : 0;
            this.updateDownloadPageTransferFraction(current, index, fraction);
            const activeFraction = this.downloadPageTransferFractionSum(current);
            const remainingPages = Math.max(0, total - downloaded - failedCount - activeFraction);
            const bytesBasis = Math.max(1024, totalBytes > 0 ? totalBytes : receivedBytes);
            const remainingSeconds = lastSpeed > 0 ? Math.round(remainingPages * bytesBasis / lastSpeed) : -1;
            const percent = totalBytes > 0 ? ` ${Math.round(fraction * 100)}%` : '';
            const byteText = totalBytes > 0 ?
              `${formatByteSize(receivedBytes)}/${formatByteSize(totalBytes)}` :
              formatByteSize(receivedBytes);
            const pageLabel = `第 ${index + 1} 页${percent}`;
            const shouldPersist = now - lastProgressPersistAt >= DOWNLOAD_PROGRESS_PERSIST_INTERVAL_MS || complete;
            if (shouldPersist) {
              lastProgressPersistAt = now;
            }
            this.updateDownloadProgress(
              current,
              DOWNLOAD_STATUS_DOWNLOADING,
              downloaded,
              total,
              failedCount,
              `正在下载${pageLabel} · ${byteText}`,
              index + 1,
              lastSpeed,
              remainingSeconds,
              dir,
              '',
              pageErrors,
              shouldPersist,
              pageLabel
            );
          };
          try {
            const result = await this.downloadPageWithRetry(item, pageUrls[index], index, onPageProgress);
            item = this.findDownloadItem(seed.gid, seed.site) || item;
            this.clearDownloadPageTransferFraction(item, index);
            if (this.shouldStopDownload(item, runGeneration)) {
              this.downloadManagerStatus = '下载器已暂停';
              return;
            }
            downloaded++;
            const elapsedSeconds = Math.max(1, (Date.now() - startedAt) / 1000);
            lastSpeed = Math.round(result.bytes / elapsedSeconds);
            const remainingPages = Math.max(0, total - downloaded - failedCount);
            const remainingSeconds = lastSpeed > 0 ? Math.round(remainingPages * Math.max(1024, result.bytes) / lastSpeed) : -1;
            this.updateDownloadProgress(
              item,
              DOWNLOAD_STATUS_DOWNLOADING,
              downloaded,
              total,
              failedCount,
              `已下载第 ${index + 1} 页`,
              index + 1,
              lastSpeed,
              remainingSeconds,
              dir,
              '',
              pageErrors
            );
          } catch (error) {
            item = this.findDownloadItem(seed.gid, seed.site) || item;
            this.clearDownloadPageTransferFraction(item, index);
            if (this.shouldStopDownload(item, runGeneration)) {
              this.downloadManagerStatus = '下载器已暂停';
              return;
            }
            failedCount++;
            const message = `${error}`;
            pageErrors.push({
              page: index + 1,
              message: message.length > 0 ? message : '下载失败',
              updatedAt: this.nowLabel()
            });
            this.updateDownloadProgress(
              item,
              DOWNLOAD_STATUS_DOWNLOADING,
              downloaded,
              total,
              failedCount,
              `第 ${index + 1} 页失败`,
              index + 1,
              0,
              -1,
              dir,
              pageErrors[pageErrors.length - 1].message,
              pageErrors
            );
          }
        }
      };
      const workerCount = clampNumber(this.downloadConcurrency, 1, DOWNLOAD_MAX_CONCURRENCY);
      const workers: Promise<void>[] = [];
      for (let index = 0; index < workerCount; index++) {
        workers.push(runPageWorker());
      }
      await Promise.all(workers);

      item = this.findDownloadItem(seed.gid, seed.site) || item;
      if (this.shouldStopDownload(item, runGeneration)) {
        this.downloadManagerStatus = '下载器已暂停';
        return;
      }

      item = this.findDownloadItem(seed.gid, seed.site) || item;
      const finalFailedCount = Math.max(failedCount, Math.max(0, total - downloaded));
      if (finalFailedCount > 0) {
        this.updateDownloadProgress(
          item,
          DOWNLOAD_STATUS_FAILED,
          downloaded,
          total,
          finalFailedCount,
          '下载完成，但有页面失败',
          item.currentPage,
          0,
          -1,
          dir,
          `${finalFailedCount} 页失败`,
          pageErrors
        );
      } else {
        this.updateDownloadProgress(
          item,
          DOWNLOAD_STATUS_DONE,
          total,
          total,
          0,
          '下载完成',
          total,
          0,
          0,
          dir,
          '',
          []
        );
        this.toast('下载完成');
      }
    } catch (error) {
      item = this.findDownloadItem(seed.gid, seed.site) || item;
      if (this.shouldStopDownload(item, runGeneration)) {
        this.downloadManagerStatus = '下载器已暂停';
        return;
      }
      const message = `${error}`;
      this.updateDownloadProgress(
        item,
        DOWNLOAD_STATUS_FAILED,
        item.downloaded,
        item.total,
        item.failedCount > 0 ? item.failedCount : 1,
        '下载失败',
        item.currentPage,
        0,
        -1,
        item.downloadDir,
        message.length > 0 ? message : '下载失败',
        item.pageErrors
      );
    } finally {
      this.clearDownloadTransferProgress(seed);
      this.downloadCancelKeys.delete(key);
      sharedDownloadCancelKeys.delete(key);
      this.updateRuntimeStringArray(DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY, key, false);
      if (this.downloadActiveKey === key) {
        this.downloadActiveKey = '';
      }
      if (sharedDownloadActiveKey === key) {
        sharedDownloadActiveKey = '';
      }
      this.publishDownloadRuntimeStorage();
      this.refreshDownloadRuntimeState(true);
    }
  }

  private exportDownloadCsv(): void {
    const lines = [DOWNLOAD_INFO_HEADER];
    for (const item of this.downloadItems) {
      lines.push(this.downloadCsvLine(item));
    }
    this.downloadImportExportText = lines.join('\n');
    this.toast('下载 CSV 已导出');
  }

  private importDownloadCsv(): void {
    const raw = this.downloadImportExportText.trim();
    if (raw.length === 0) {
      this.toast('请先粘贴 Android CSV');
      return;
    }
    const imported: DownloadQueueItem[] = [];
    const lines = raw.split(/\r?\n/);
    for (const line of lines) {
      if (line.trim().length === 0 || line.startsWith('gid,')) {
        continue;
      }
      const values = line.split(',');
      if (values.length < 20) {
        continue;
      }
      const gid = Number(values[0]);
      if (!Number.isFinite(gid) || gid <= 0) {
        continue;
      }
      const token = values[1];
      const pages = Number(values[19]);
      const record: LocalGalleryRecord = {
        gid,
        token,
        title: values[2],
        titleJpn: values[3],
        cover: values[4],
        detailUrl: EhUrl.galleryDetail(this.siteMode, gid, token),
        site: this.siteMode,
        uploader: values[7],
        categoryLabel: values[5],
        posted: values[6],
        pages: Number.isFinite(pages) ? pages : 0,
        language: values[10],
        rating: Number(values[8])
      };
      imported.push(this.toDownloadItem(
        record,
        DOWNLOAD_STATUS_QUEUED,
        this.nowLabel(),
        '从 Android CSV 导入',
        DOWNLOAD_DEFAULT_LABEL,
        0,
        record.pages,
        0,
        '',
        this.nowLabel(),
        this.nowLabel()
      ));
    }
    if (imported.length === 0) {
      this.toast('没有可导入的下载记录');
      return;
    }
    const existingKeys = this.downloadItems.map((item: DownloadQueueItem) => this.downloadKey(item.gid, item.site));
    const merged = [...this.downloadItems];
    for (const item of imported) {
      if (existingKeys.indexOf(this.downloadKey(item.gid, item.site)) >= 0) {
        continue;
      }
      this.clearDownloadKeyRemoved(this.downloadKey(item.gid, item.site));
      merged.unshift(item);
    }
    this.downloadItems = merged.slice(0, 120);
    this.saveDownloadItems();
    this.toast(`已导入 ${imported.length} 个下载`);
  }

  private clearHistory(): void {
    this.historyItems = [];
    this.saveHistoryItems();
  }

  private confirmClearHistory(): void {
    if (this.historyItems.length === 0) {
      return;
    }
    const options: promptAction.ShowDialogOptions = {
      title: '清空历史',
      message: '确定要清空全部浏览历史吗？',
      buttons: [
        { text: '取消', color: '#6F5964' },
        { text: '清空', color: '#B42318' }
      ]
    };
    try {
      void this.getUIContext().getPromptAction().showDialog(options)
        .then((result: promptAction.ShowDialogSuccessResponse) => {
          if (result.index === 1) {
            this.clearHistory();
          }
        })
        .catch(() => {
        });
    } catch (error) {
    }
  }

  private removeHistoryItem(item: HistoryItem): void {
    this.historyItems = this.historyItems.filter((entry: HistoryItem) =>
      !(entry.gid === item.gid && entry.site === item.site));
    this.saveHistoryItems();
  }

  private async openStoredGalleryInNative(record: LocalGalleryRecord): Promise<void> {
    this.toggleSite(record.site);
    await this.openNativeDetail(this.toNativeSummary(record));
  }

  private async openStoredGalleryInReader(record: LocalGalleryRecord): Promise<void> {
    this.toggleSite(record.site);
    this.recordHistory(record);
    this.nativeDetail = this.createNativeDetailFromRecord(record);
    this.nativeDetailRevision++;
    this.nativePreviewItems = this.createLocalReaderPreviewItems(record);
    if (this.nativePreviewItems.length > 0) {
      this.nativePreviewPageIndex = 0;
      this.nativePreviewPageCount = 1;
      await this.loadNativeReaderByPageUrl(this.nativePreviewItems[0].pageUrl);
      return;
    }
    const loaded = await this.loadNativeDetail(this.toNativeSummary(record));
    if (loaded) {
      await this.openNativeReaderFromStart();
    }
  }

  private localReaderPageUrl(gid: number, pageIndex: number): string {
    return `local://reader/${gid}/${pageIndex + 1}`;
  }

  private isLocalReaderPageUrl(pageUrl: string): boolean {
    return pageUrl.startsWith('local://reader/');
  }

  private createNativeDetailFromRecord(record: LocalGalleryRecord): NativeGalleryDetail {
    const detail = createEmptyNativeGalleryDetail();
    detail.gid = record.gid;
    detail.token = record.token;
    detail.title = record.title;
    detail.titleJpn = record.titleJpn;
    detail.cover = record.cover;
    detail.categoryLabel = record.categoryLabel;
    detail.posted = record.posted;
    detail.uploader = record.uploader;
    detail.rating = record.rating;
    detail.pages = record.pages;
    detail.language = record.language;
    detail.detailUrl = record.detailUrl;
    detail.previewPageCount = 1;
    return detail;
  }

  private createLocalReaderPreviewItems(record: LocalGalleryRecord): NativeGalleryPreview[] {
    const items: NativeGalleryPreview[] = [];
    const pages = Math.max(0, record.pages);
    for (let pageIndex = 0; pageIndex < pages; pageIndex++) {
      const localUri = this.readerDownloadedImageUri(pageIndex);
      if (localUri.length === 0) {
        continue;
      }
      items.push({
        position: pageIndex,
        pageUrl: this.localReaderPageUrl(record.gid, pageIndex),
        thumbUrl: localUri,
        pageLabel: `${pageIndex + 1}`,
        thumbWidth: 0,
        thumbHeight: 0,
        thumbOffsetX: 0,
        thumbOffsetY: 0
      });
    }
    return items;
  }

  private downloadStatusLabel(status: string): string {
    switch (status) {
      case DOWNLOAD_STATUS_DOWNLOADING:
        return '下载中';
      case DOWNLOAD_STATUS_PAUSED:
        return '已暂停';
      case DOWNLOAD_STATUS_FAILED:
        return '失败';
      case DOWNLOAD_STATUS_READING:
        return '读取中';
      case DOWNLOAD_STATUS_DONE:
        return '完成';
      default:
        return '等待';
    }
  }

  private downloadItemStatusLabel(item: DownloadQueueItem): string {
    if (this.isDownloadItemRunning(item)) {
      return this.downloadStatusLabel(DOWNLOAD_STATUS_DOWNLOADING);
    }
    if (item.status === DOWNLOAD_STATUS_DOWNLOADING && !this.isDownloadItemRunning(item)) {
      return '已中断';
    }
    return this.downloadStatusLabel(item.status);
  }

  private downloadStatusColor(status: string): string {
    switch (status) {
      case DOWNLOAD_STATUS_DOWNLOADING:
        return '#1976D2';
      case DOWNLOAD_STATUS_PAUSED:
        return '#7C6470';
      case DOWNLOAD_STATUS_FAILED:
        return '#D93025';
      case DOWNLOAD_STATUS_READING:
        return '#FF9800';
      case DOWNLOAD_STATUS_DONE:
        return '#4CAF50';
      default:
        return '#C86B8C';
    }
  }

  private downloadItemStatusColor(item: DownloadQueueItem): string {
    if (this.isDownloadItemRunning(item)) {
      return this.downloadStatusColor(DOWNLOAD_STATUS_DOWNLOADING);
    }
    if (item.status === DOWNLOAD_STATUS_DOWNLOADING && !this.isDownloadItemRunning(item)) {
      return '#7C6470';
    }
    return this.downloadStatusColor(item.status);
  }

  private downloadProgressRatio(item: DownloadQueueItem): number {
    if (item.total <= 0) {
      return 0;
    }
    const activeFraction = this.isDownloadItemRunning(item) ? this.downloadPageTransferFractionSum(item) : 0;
    return clampNumber((Math.floor(item.downloaded) + activeFraction) / item.total, 0, 1);
  }

  private downloadProgressText(item: DownloadQueueItem): string {
    const total = item.total > 0 ? item.total : item.pages;
    const downloaded = Math.floor(item.downloaded);
    if (total <= 0) {
      return `${downloaded} 页`;
    }
    const failed = item.failedCount > 0 ? ` · 失败 ${item.failedCount}` : '';
    const current = this.isDownloadItemRunning(item) && item.currentPageLabel.length > 0 ?
      ` · ${item.currentPageLabel}` : '';
    return `${downloaded}/${total}${failed}${current}`;
  }

  private setDownloadViewMode(value: string): void {
    const nextMode = value === DOWNLOAD_VIEW_ACTIVE ? DOWNLOAD_VIEW_ACTIVE : DOWNLOAD_VIEW_DOWNLOADED;
    this.downloadViewMode = nextMode;
    this.downloadViewSelectedIndexes = [nextMode === DOWNLOAD_VIEW_ACTIVE ? 1 : 0];
  }

  private setDownloadViewModeByIndex(index: number): void {
    this.setDownloadViewMode(index === 1 ? DOWNLOAD_VIEW_ACTIVE : DOWNLOAD_VIEW_DOWNLOADED);
  }

  private handleDownloadRouteEventChanged(): void {
    this.applyPendingDownloadRouteEvent();
  }

  private applyPendingDownloadRouteEvent(): boolean {
    if (!this.isReady ||
      this.downloadRouteEventId <= 0 ||
      this.downloadRouteEventId === this.handledDownloadRouteEventId) {
      return false;
    }
    this.handledDownloadRouteEventId = this.downloadRouteEventId;
    if (this.downloadRouteTarget !== DOWNLOAD_ROUTE_ACTION_ACTIVE) {
      return false;
    }
    this.fullScreenWebUrl = '';
    this.fullScreenWebTitle = '';
    this.fullScreenWebMode = '';
    this.routeNativeSummary = undefined;
    this.routeNativeMode = '';
    this.routeReaderPageUrl = '';
    this.prepareMySubPageLocal(MY_PAGE_DOWNLOADS, '下载');
    this.setDownloadViewMode(DOWNLOAD_VIEW_ACTIVE);
    if (!this.downloadWorkerRunning) {
      void this.syncDownloadStateFromDatabase(false);
    }
    return true;
  }

  private preferredDownloadViewMode(): string {
    return this.activeDownloadTaskCount() > 0 ? DOWNLOAD_VIEW_ACTIVE : DOWNLOAD_VIEW_DOWNLOADED;
  }

  private effectiveDownloadViewMode(): string {
    return this.downloadViewMode === DOWNLOAD_VIEW_ACTIVE ? DOWNLOAD_VIEW_ACTIVE : DOWNLOAD_VIEW_DOWNLOADED;
  }

  private hasRunningDownloadTask(): boolean {
    for (const item of this.downloadItemsSource()) {
      if (this.isDownloadItemRunning(item)) {
        return true;
      }
    }
    return false;
  }

  private reconcileDownloadViewMode(selectPreferredView: boolean = false): void {
    if (selectPreferredView) {
      this.setDownloadViewMode(this.preferredDownloadViewMode());
      return;
    }
    this.setDownloadViewMode(this.downloadViewMode);
  }

  private activeDownloadTaskCount(): number {
    let count = 0;
    for (const item of this.downloadItemsSource()) {
      if (item.status !== DOWNLOAD_STATUS_DONE && item.status !== DOWNLOAD_STATUS_DELETED) {
        count++;
      }
    }
    return count;
  }

  private downloadedTaskCount(): number {
    let count = 0;
    for (const item of this.downloadItemsSource()) {
      if (item.status === DOWNLOAD_STATUS_DONE) {
        count++;
      }
    }
    return count;
  }

  private homeMenuSymbol(symbol: Resource): SymbolGlyphModifier {
    return new SymbolGlyphModifier(symbol)
      .fontColor(['#A85474']);
  }

  private homeNavigationMenuContent(): HdsNavigationMenuContentOptions {
    return {
      value: [
        {
          content: {
            label: '默认首页',
            icon: this.homeMenuSymbol($r('sys.symbol.house_fill')),
            action: () => {
              this.openHomePrimaryPage(HOME_PAGE_DEFAULT);
            }
          }
        },
        {
          content: {
            label: '热门',
            icon: this.homeMenuSymbol($r('sys.symbol.flame_fill')),
            action: () => {
              this.openHomePrimaryPage(HOME_PAGE_POPULAR);
            }
          }
        },
        {
          content: {
            label: '关注',
            icon: this.homeMenuSymbol($r('sys.symbol.eye')),
            action: () => {
              this.openHomePrimaryPage(HOME_PAGE_WATCHED);
            }
          }
        },
        {
          content: {
            label: '排行榜',
            icon: this.homeMenuSymbol($r('sys.symbol.star_fill')),
            action: () => {
              this.openHomePrimaryPage(HOME_PAGE_TOP);
            }
          }
        }
      ],
      maxCount: 1
    };
  }

  private libraryNavigationMenuContent(): HdsNavigationMenuContentOptions {
    return {
      value: [
        {
          content: {
            label: '刷新当前',
            icon: this.homeMenuSymbol($r('sys.symbol.arrow_clockwise')),
	            action: () => {
	              if (this.libraryPanel === LIBRARY_FAVORITES) {
	                void this.refreshFavoriteWaterfall();
	              } else if (this.libraryPanel === LIBRARY_HISTORY) {
	                void this.loadLocalSideData();
	              } else if (!this.downloadWorkerRunning) {
                void this.syncDownloadStateFromDatabase(false);
              }
            }
          }
        },
        {
          content: {
            label: '收藏',
            icon: this.homeMenuSymbol($r('sys.symbol.heart_fill')),
            action: () => {
              this.openLibraryPage(LIBRARY_FAVORITES);
            }
          }
        },
        {
          content: {
            label: '历史',
            icon: this.homeMenuSymbol($r('sys.symbol.clock_fill')),
            action: () => {
              this.openLibraryPage(LIBRARY_HISTORY);
            }
          }
        },
        {
          content: {
            label: '下载',
            icon: this.homeMenuSymbol($r('sys.symbol.waveform_folder_fill')),
            action: () => {
              this.openLibraryPage(LIBRARY_DOWNLOADS);
            }
          }
        }
      ],
      maxCount: 1
    };
  }

  private favoriteFilterCount(filter: number): number {
    if (filter === FAVORITE_FILTER_LOCAL) {
      return this.localFavorites.length;
    }
    if (filter === FAVORITE_FILTER_ALL) {
      return this.cloudFavoriteCount() + this.localFavorites.length;
    }
    if (filter >= 0 && filter < this.favoriteCategoryCounts.length) {
      return this.favoriteCategoryCounts[filter];
    }
    return 0;
  }

  private favoriteMenuLabel(filter: number): string {
    const name = this.favoriteFilterLabel(filter);
    const count = this.favoriteFilterCount(filter);
    return count > 0 ? `${name} (${count})` : name;
  }

  private favoriteMenuSymbol(filter: number): SymbolGlyphModifier {
    if (filter === FAVORITE_FILTER_LOCAL) {
      return this.homeMenuSymbol($r('sys.symbol.folder_fill'));
    }
    if (filter === this.favoriteListFilter) {
      return this.homeMenuSymbol($r('sys.symbol.heart_fill'));
    }
    return this.homeMenuSymbol($r('sys.symbol.heart'));
  }

  private favoriteNavigationMenuContent(): HdsNavigationMenuContentOptions {
    return {
      value: [
        {
          content: {
            label: this.favoriteMenuLabel(FAVORITE_FILTER_LOCAL),
            icon: this.favoriteMenuSymbol(FAVORITE_FILTER_LOCAL),
            action: (): void => {
              this.setFavoriteListFilter(FAVORITE_FILTER_LOCAL);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(FAVORITE_FILTER_ALL),
            icon: this.favoriteMenuSymbol(FAVORITE_FILTER_ALL),
            action: (): void => {
              this.setFavoriteListFilter(FAVORITE_FILTER_ALL);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(0),
            icon: this.favoriteMenuSymbol(0),
            action: (): void => {
              this.setFavoriteListFilter(0);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(1),
            icon: this.favoriteMenuSymbol(1),
            action: (): void => {
              this.setFavoriteListFilter(1);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(2),
            icon: this.favoriteMenuSymbol(2),
            action: (): void => {
              this.setFavoriteListFilter(2);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(3),
            icon: this.favoriteMenuSymbol(3),
            action: (): void => {
              this.setFavoriteListFilter(3);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(4),
            icon: this.favoriteMenuSymbol(4),
            action: (): void => {
              this.setFavoriteListFilter(4);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(5),
            icon: this.favoriteMenuSymbol(5),
            action: (): void => {
              this.setFavoriteListFilter(5);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(6),
            icon: this.favoriteMenuSymbol(6),
            action: (): void => {
              this.setFavoriteListFilter(6);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(7),
            icon: this.favoriteMenuSymbol(7),
            action: (): void => {
              this.setFavoriteListFilter(7);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(8),
            icon: this.favoriteMenuSymbol(8),
            action: (): void => {
              this.setFavoriteListFilter(8);
            }
          }
        },
        {
          content: {
            label: this.favoriteMenuLabel(9),
            icon: this.favoriteMenuSymbol(9),
            action: (): void => {
              this.setFavoriteListFilter(9);
            }
          }
        }
      ],
      maxCount: 1
    };
  }

  private emptyNavigationMenuContent(): HdsNavigationMenuContentOptions {
    return {
      value: [],
      maxCount: 0
    };
  }

  private shouldShowFavoriteNavigationMenu(): boolean {
    return this.activeSection === NAV_LIBRARY && this.myPage === MY_PAGE_FAVORITES && !this.hasVisibleNativeSubPage();
  }

  private shouldShowHistoryNavigationMenu(): boolean {
    return this.activeSection === NAV_LIBRARY && this.myPage === MY_PAGE_HISTORY && !this.hasVisibleNativeSubPage();
  }

  private shouldShowDownloadNavigationMenu(): boolean {
    return this.activeSection === NAV_LIBRARY && this.myPage === MY_PAGE_DOWNLOADS && !this.hasVisibleNativeSubPage();
  }

  private shouldShowDownloadTitleSegment(): boolean {
    return this.activeSection === NAV_LIBRARY && this.myPage === MY_PAGE_DOWNLOADS && !this.hasVisibleNativeSubPage();
  }

  private historyNavigationMenuContent(): HdsNavigationMenuContentOptions {
    return {
      value: [
        {
          content: {
            label: '清空',
            icon: this.homeMenuSymbol($r('sys.symbol.trash')),
            isEnabled: this.historyItems.length > 0,
            action: (): void => {
              this.confirmClearHistory();
            }
          }
        }
      ],
      maxCount: 1
    };
  }

  private downloadNavigationMenuContent(): HdsNavigationMenuContentOptions {
    return this.emptyNavigationMenuContent();
  }

  private currentBackTitleBarMenuContent(): HdsNavigationMenuContentOptions {
    if (this.shouldShowDownloadNavigationMenu()) {
      return this.downloadNavigationMenuContent();
    }
    if (this.shouldShowFavoriteNavigationMenu()) {
      return this.favoriteNavigationMenuContent();
    }
    if (this.shouldShowHistoryNavigationMenu()) {
      return this.historyNavigationMenuContent();
    }
    return this.emptyNavigationMenuContent();
  }

  private currentNavigationMenuContent(): HdsNavigationMenuContentOptions {
    if (this.hasVisibleNativeSubPage()) {
      return this.emptyNavigationMenuContent();
    }
    if (this.activeSection === NAV_HOME) {
      return this.homeNavigationMenuContent();
    }
    if (this.shouldShowFavoriteNavigationMenu()) {
      return this.favoriteNavigationMenuContent();
    }
    if (this.shouldShowHistoryNavigationMenu()) {
      return this.historyNavigationMenuContent();
    }
    if (this.shouldShowDownloadNavigationMenu()) {
      return this.downloadNavigationMenuContent();
    }
    return this.emptyNavigationMenuContent();
  }

  private handleNativeTitleBarBack(): void {
    if (this.hasTagSearchReturnDetail()) {
      this.goBackToTagSearchReturnDetail();
      return;
    }
    if (this.nativeViewMode === 'reader') {
      this.persistCurrentReaderProgress();
      if (this.routeNativeMode === ROUTE_NATIVE_READER && this.tryRouterBack()) {
        return;
      }
      this.goBackToNativeDetail();
      return;
    }
    if (this.nativeViewMode === 'previews' || this.nativeViewMode === 'comments') {
      if ((this.routeNativeMode === ROUTE_NATIVE_PREVIEWS || this.routeNativeMode === ROUTE_NATIVE_COMMENTS) &&
        this.tryRouterBack()) {
        return;
      }
      this.goBackToNativeDetail();
      return;
    }
    if (this.nativeViewMode === 'detail') {
      if (this.routeNativeMode === ROUTE_NATIVE_DETAIL && this.tryRouterBack()) {
        return;
      }
      this.goBackToNativeList();
      return;
    }
    if (this.isRouteSearchBackAvailable() && this.tryRouterBack()) {
      return;
    }
    if (this.isMySubPage()) {
      if (this.tryRouterBack()) {
        return;
      }
      this.returnToMyMainPage();
    }
  }

  private hasMyNavigationPath(): boolean {
    return this.isMySubPage();
  }

  private clearMyNavigationPath(): void {
    this.mySubPage = MY_PAGE_MAIN;
    this.mySubPageTitle = '';
  }

  private returnToMyMainPage(): void {
    this.clearMyNavigationPath();
    this.activeSection = NAV_LIBRARY;
    this.myPage = MY_PAGE_MAIN;
    this.myPageTitle = '';
    this.nativeViewMode = 'list';
  }

  private isMySubPage(): boolean {
    return (this.activeSection === NAV_LIBRARY && this.myPage !== MY_PAGE_MAIN) ||
      this.activeSection === NAV_SETTINGS;
  }

  private shouldShowNativeTitleBarBack(): boolean {
    return this.hasTagSearchReturnDetail() || this.isRouteSearchBackAvailable() ||
      this.hasVisibleNativeSubPage() || this.isMySubPage();
  }

  private currentTitleBarOptions(): HdsNavigationTitleBarOptions {
    if (this.activeSection === NAV_SEARCH && this.nativeViewMode === 'list') {
      const searchBackEnabled = this.hasTagSearchReturnDetail() || this.isRouteSearchBackAvailable();
      if (searchBackEnabled) {
        return {
          content: {
            title: {
              mainTitle: ''
            },
            backIcon: {
              label: '返回',
              isEnabled: true,
              action: (): void => {
                this.handleNativeTitleBarBack();
              }
            },
            menu: {
              value: [],
              maxCount: 0
            },
            stackBuilder: (): void => {
              this.SearchTitleBar();
            }
          },
          style: {
            scrollEffectOpts: {
              enableScrollEffect: true,
              scrollEffectType: ScrollEffectType.GRADIENT_BLUR
            },
            systemMaterialEffect: {
              materialType: hdsMaterial.MaterialType.ADAPTIVE,
              materialLevel: this.customMaterialLevel
            }
          },
          avoidLayoutSafeArea: true,
          enableComponentSafeArea: false
        };
      }
      return {
        content: {
          title: {
            mainTitle: ''
          },
          menu: {
            value: [],
            maxCount: 0
          },
          stackBuilder: (): void => {
            this.SearchTitleBar();
          }
        },
        style: {
          scrollEffectOpts: {
            enableScrollEffect: true,
            scrollEffectType: ScrollEffectType.GRADIENT_BLUR
          },
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: this.customMaterialLevel
          }
        },
        avoidLayoutSafeArea: true,
        enableComponentSafeArea: false
      };
    }
    if (this.shouldShowNativeTitleBarBack()) {
      if (this.shouldShowDownloadTitleSegment()) {
        return {
          content: {
            title: {
              mainTitle: this.currentNavigationTitle()
            },
            backIcon: {
              label: '返回',
              isEnabled: true,
              action: (): void => {
                this.handleNativeTitleBarBack();
              }
            },
            menu: this.emptyNavigationMenuContent(),
            bottomBuilder: {
              builder: (): void => {
                this.DownloadTitleBarSegment();
              },
              height: DOWNLOAD_TITLE_BAR_BOTTOM_HEIGHT
            }
          },
          style: {
            scrollEffectOpts: {
              enableScrollEffect: true,
              scrollEffectType: ScrollEffectType.GRADIENT_BLUR
            },
            systemMaterialEffect: {
              materialType: hdsMaterial.MaterialType.ADAPTIVE,
              materialLevel: this.customMaterialLevel
            }
          },
          avoidLayoutSafeArea: true,
          enableComponentSafeArea: false
        };
      }
      return {
        content: {
          title: {
            mainTitle: this.currentNavigationTitle()
          },
          backIcon: {
            label: '返回',
            isEnabled: true,
            action: (): void => {
              this.handleNativeTitleBarBack();
            }
          },
          menu: this.currentBackTitleBarMenuContent()
        },
        style: {
          scrollEffectOpts: {
            enableScrollEffect: true,
            scrollEffectType: ScrollEffectType.GRADIENT_BLUR
          },
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: this.customMaterialLevel
          }
        },
        avoidLayoutSafeArea: true,
        enableComponentSafeArea: false
      };
    }
    return {
      content: {
        title: {
          mainTitle: this.currentNavigationTitle()
        },
        menu: this.currentNavigationMenuContent()
      },
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: this.customMaterialLevel
        }
      },
      avoidLayoutSafeArea: true,
      enableComponentSafeArea: false
    };
  }

  private pageContentTopPadding(): number {
    const titleBarBottomInset = this.shouldShowDownloadTitleSegment() ? DOWNLOAD_TITLE_BAR_BOTTOM_HEIGHT : 0;
    return this.systemSafeTop + HDS_MINI_TITLE_BAR_HEIGHT + titleBarBottomInset;
  }

  private pageContentBottomPadding(): number {
    const floatingTabInset = this.shouldShowBottomTabs() ? FLOATING_BOTTOM_TAB_BAR_HEIGHT : 0;
    return this.systemSafeBottom + floatingTabInset + PAGE_BOTTOM_SPACING;
  }

  private downloadScrollContentMinHeight(): number {
    return Math.max(1, this.pageViewportHeight + DOWNLOAD_SCROLL_EXTRA_HEIGHT);
  }

  private viewportLengthToNumber(value: Length): number {
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      const parsed = Number.parseFloat(value);
      return Number.isFinite(parsed) ? parsed : 0;
    }
    return 0;
  }

  private updatePageViewportSize(value: Area): void {
    const nextWidth = Math.max(1, this.viewportLengthToNumber(value.width));
    const nextHeight = Math.max(1, this.viewportLengthToNumber(value.height));
    if (Math.abs(nextWidth - this.pageViewportWidth) >= 1) {
      this.pageViewportWidth = nextWidth;
    }
    if (Math.abs(nextHeight - this.pageViewportHeight) >= 1) {
      this.pageViewportHeight = nextHeight;
    }
  }

  private waterfallContentWidth(): number {
    return Math.max(1, this.pageViewportWidth - PAGE_SIDE_GUTTER * 2);
  }

  private waterfallCoverHeight(item: NativeGallerySummary): number {
    if (item.pages > 120) {
      return 208;
    }
    if (item.pages > 80) {
      return 188;
    }
    return 154;
  }

  private waterfallCardHeight(item: NativeGallerySummary): number {
    return this.waterfallCoverHeight(item) + WATERFALL_CARD_EXTRA_HEIGHT;
  }

  private waterfallItemWidthForColumns(width: number, columns: number): number {
    if (columns <= 0) {
      return width;
    }
    return (width - WATERFALL_COLUMN_GAP * (columns - 1)) / columns;
  }

  private waterfallColumnCount(): number {
    const width = this.waterfallContentWidth();
    let bestColumns = WATERFALL_MIN_COLUMNS;
    let bestDistance = Math.abs(this.waterfallItemWidthForColumns(width, bestColumns) -
      WATERFALL_PREFERRED_ITEM_WIDTH);
    const widestUsefulColumns = Math.max(
      WATERFALL_MIN_COLUMNS,
      Math.ceil((width + WATERFALL_COLUMN_GAP) /
        (WATERFALL_PREFERRED_ITEM_WIDTH + WATERFALL_COLUMN_GAP)) + 1
    );
    for (let columns = WATERFALL_MIN_COLUMNS + 1; columns <= widestUsefulColumns; columns++) {
      const distance = Math.abs(this.waterfallItemWidthForColumns(width, columns) -
        WATERFALL_PREFERRED_ITEM_WIDTH);
      if (distance < bestDistance) {
        bestColumns = columns;
        bestDistance = distance;
      }
    }
    return bestColumns;
  }

  private waterfallItemsContentHeight(items: NativeGallerySummary[]): number {
    const columns = this.waterfallColumnCount();
    const columnHeights: number[] = [];
    for (let index = 0; index < columns; index++) {
      columnHeights.push(0);
    }
    for (let itemIndex = 0; itemIndex < items.length; itemIndex++) {
      let targetColumn = 0;
      for (let columnIndex = 1; columnIndex < columns; columnIndex++) {
        if (columnHeights[columnIndex] < columnHeights[targetColumn]) {
          targetColumn = columnIndex;
        }
      }
      if (columnHeights[targetColumn] > 0) {
        columnHeights[targetColumn] += WATERFALL_ROW_GAP;
      }
      columnHeights[targetColumn] += this.waterfallCardHeight(items[itemIndex]);
    }
    let total = 0;
    for (let index = 0; index < columnHeights.length; index++) {
      total = Math.max(total, columnHeights[index]);
    }
    return Math.max(WATERFALL_MIN_CONTENT_HEIGHT, total);
  }

  private waterfallEstimatedContentHeight(items: NativeGallerySummary[]): number {
    return this.pageContentTopPadding() + this.waterfallItemsContentHeight(items) + this.pageContentBottomPadding();
  }

  private shouldLoadWaterfallByRemainingContent(
    scroller: Scroller,
    items: NativeGallerySummary[],
    loading: boolean,
    currentUrl: string,
    nextUrl: string,
    autoLoadEnabled: boolean
  ): boolean {
    if (!autoLoadEnabled || loading || items.length === 0 || nextUrl.length === 0 || nextUrl === currentUrl) {
      return false;
    }
    const contentHeight = this.waterfallEstimatedContentHeight(items);
    const visibleBottom = this.currentScrollerOffsetY(scroller) + Math.max(1, this.pageViewportHeight);
    const remaining = Math.max(0, contentHeight - visibleBottom);
    const remainingRatio = remaining / Math.max(1, contentHeight);
    return remainingRatio <= WATERFALL_LOAD_REMAINING_RATIO;
  }

  private normalizeScrollOffset(value: number): number {
    if (!Number.isFinite(value) || value < 0) {
      return 0;
    }
    return value;
  }

  private currentGalleryListScroller(): Scroller | undefined {
    if (this.activeSection === NAV_SEARCH) {
      return this.searchScroller;
    }
    if (this.activeSection === NAV_LIBRARY) {
      return this.libraryScroller;
    }
    if (this.activeSection === NAV_HOME) {
      return this.homeScroller;
    }
    return undefined;
  }

  private currentGalleryListScrollOffsetY(): number {
    if (this.activeSection === NAV_SEARCH) {
      return this.searchScrollOffsetY;
    }
    if (this.activeSection === NAV_LIBRARY) {
      return this.libraryScrollOffsetY;
    }
    return this.homeScrollOffsetY;
  }

  private currentScrollerOffsetY(scroller: Scroller): number {
    try {
      const offset = scroller.currentOffset();
      return this.normalizeScrollOffset(Number(offset.yOffset));
    } catch (error) {
      return 0;
    }
  }

  private saveCurrentGalleryListScrollOffset(): void {
    if (this.nativeViewMode !== 'list') {
      return;
    }
    const scroller = this.currentGalleryListScroller();
    if (!scroller) {
      return;
    }
    const yOffset = this.currentScrollerOffsetY(scroller);
    if (this.activeSection === NAV_SEARCH) {
      this.searchScrollOffsetY = yOffset;
      return;
    }
    if (this.activeSection === NAV_LIBRARY) {
      this.libraryScrollOffsetY = yOffset;
      return;
    }
    if (this.activeSection === NAV_HOME) {
      this.homeScrollOffsetY = yOffset;
    }
  }

  private restoreCurrentGalleryListScrollOffset(): void {
    const scroller = this.currentGalleryListScroller();
    if (!scroller) {
      return;
    }
    const yOffset = this.currentGalleryListScrollOffsetY();
    this.restoringGalleryListScroll = true;
    setTimeout(() => {
      try {
        scroller.scrollTo({
          xOffset: 0,
          yOffset
        });
      } catch (error) {
      } finally {
        setTimeout(() => {
          this.restoringGalleryListScroll = false;
        }, 120);
      }
    }, 0);
  }

  private activeNavigationScrollers(): Scroller[] {
    if (this.activeSection === NAV_SEARCH) {
      return [this.searchScroller];
    }
    if (this.activeSection === NAV_LIBRARY) {
      return this.myPage === MY_PAGE_MAIN ? [this.myScroller] : [this.libraryScroller];
    }
    if (this.activeSection === NAV_SETTINGS) {
      return [this.settingsScroller];
    }
    return [this.homeScroller];
  }

  private shouldAutoLoadHomeWaterfall(): boolean {
    return this.activeSection === NAV_HOME &&
      this.myPage === MY_PAGE_MAIN &&
      this.nativeViewMode === 'list' &&
      !this.shouldShowNativeRouteLoading() &&
      this.canUseNativeSite(this.siteMode);
  }

  private shouldAutoLoadSearchWaterfall(): boolean {
    return this.activeSection === NAV_SEARCH &&
      this.searchResultsActive &&
      this.nativeViewMode === 'list' &&
      !this.shouldShowNativeRouteLoading() &&
      this.canUseNativeSite(this.siteMode);
  }

  private shouldAutoLoadFavoriteWaterfall(): boolean {
    return this.activeSection === NAV_LIBRARY &&
      this.libraryPanel === LIBRARY_FAVORITES &&
      this.nativeViewMode === 'list' &&
      this.favoriteResults.length > 0 &&
      this.favoriteListFilter !== FAVORITE_FILTER_LOCAL &&
      !this.shouldShowNativeRouteLoading() &&
      this.canUseNativeSite(this.siteMode);
  }

  private handleHomeScrollProgress(): void {
    if (this.shouldLoadWaterfallByRemainingContent(
      this.homeScroller,
      this.homeResults,
      this.homeLoading,
      this.homeListUrl,
      this.homeNextUrl,
      this.shouldAutoLoadHomeWaterfall()
    )) {
      void this.loadMoreHomeGalleryList();
    }
  }

  private handleSearchScrollProgress(): void {
    this.hideSearchSuggestionOverlay();
    if (this.shouldLoadWaterfallByRemainingContent(
      this.searchScroller,
      this.searchResults,
      this.searchLoading,
      this.searchListUrl,
      this.searchNextUrl,
      this.shouldAutoLoadSearchWaterfall()
    )) {
      void this.loadMoreSearchGalleryList();
    }
  }

  private handleLibraryFavoritesScrollProgress(): void {
    if (this.shouldLoadWaterfallByRemainingContent(
      this.libraryScroller,
      this.favoriteResults,
      this.favoriteLoading,
      this.favoriteListUrl,
      this.favoriteNextUrl,
      this.shouldAutoLoadFavoriteWaterfall()
    )) {
      void this.loadMoreFavoriteGalleryList();
    }
  }

  private handleHomeScrollEdge(side: Edge): void {
    if (side !== Edge.Bottom || !this.shouldAutoLoadHomeWaterfall() || this.homeResults.length === 0) {
      return;
    }
    void this.loadMoreHomeGalleryList();
  }

  private handleSearchScrollEdge(side: Edge): void {
    if (side !== Edge.Bottom || !this.shouldAutoLoadSearchWaterfall() || this.searchResults.length === 0) {
      return;
    }
    void this.loadMoreSearchGalleryList();
  }

  private queuedStateText(): string {
    const record = this.createRecordFromDetail();
    if (!record) {
      return '加入队列';
    }
    return this.isRecordQueued(record) ? '移出队列' : '加入队列';
  }

  private normalizeFavoriteSlot(value: number, allowInvalid: boolean): number {
    const slot = Math.floor(value);
    if (slot === FAVORITE_LOCAL_SLOT || (slot >= 0 && slot <= 9)) {
      return slot;
    }
    return allowInvalid ? FAVORITE_INVALID_DEFAULT_SLOT : FAVORITE_LOCAL_SLOT;
  }

  private normalizeFavoriteListFilter(value: number): number {
    const filter = Math.floor(value);
    if (filter === FAVORITE_FILTER_LOCAL || filter === FAVORITE_FILTER_ALL || (filter >= 0 && filter <= 9)) {
      return filter;
    }
    return FAVORITE_FILTER_ALL;
  }

  private isLocalFavoriteListFilter(): boolean {
    return this.favoriteListFilter === FAVORITE_FILTER_LOCAL;
  }

  private favoriteCategoryName(slot: number): string {
    if (slot >= 0 && slot < this.favoriteCategoryNames.length) {
      const value = this.favoriteCategoryNames[slot].trim();
      if (value.length > 0) {
        return value;
      }
    }
    return slot >= 0 && slot < FAVORITE_SLOT_NAMES.length ? FAVORITE_SLOT_NAMES[slot] : `收藏 ${slot}`;
  }

  private favoriteSlotName(slot: number): string {
    if (slot === FAVORITE_LOCAL_SLOT) {
      return '本地收藏';
    }
    if (slot >= 0 && slot < FAVORITE_SLOT_NAMES.length) {
      return this.favoriteCategoryName(slot);
    }
    return '未设置';
  }

  private favoriteSlots(): NativeFavoriteSlot[] {
    const slots: NativeFavoriteSlot[] = [{
      slot: FAVORITE_LOCAL_SLOT,
      name: this.favoriteSlotName(FAVORITE_LOCAL_SLOT),
      count: this.localFavorites.length
    }];
    for (let index = 0; index < FAVORITE_SLOT_NAMES.length; index++) {
      slots.push({
        slot: index,
        name: this.favoriteSlotName(index),
        count: index < this.favoriteCategoryCounts.length ? this.favoriteCategoryCounts[index] : 0
      });
    }
    return slots;
  }

  private cloudFavoriteCount(): number {
    return this.favoriteCategoryCounts.reduce((total: number, value: number): number => total + Math.max(0, value), 0);
  }

  private favoriteFilterLabel(filter: number): string {
    if (filter === FAVORITE_FILTER_LOCAL) {
      return '本地收藏';
    }
    if (filter === FAVORITE_FILTER_ALL) {
      return '全部收藏';
    }
    return this.favoriteSlotName(filter);
  }

  private favoriteFilterOptions(): FavoriteFilterOption[] {
    const options: FavoriteFilterOption[] = [{
      filter: FAVORITE_FILTER_LOCAL,
      name: '本地收藏',
      count: this.localFavorites.length
    }, {
      filter: FAVORITE_FILTER_ALL,
      name: '全部收藏',
      count: this.cloudFavoriteCount() + this.localFavorites.length
    }];
    for (let index = 0; index < FAVORITE_SLOT_NAMES.length; index++) {
      options.push({
        filter: index,
        name: this.favoriteSlotName(index),
        count: index < this.favoriteCategoryCounts.length ? this.favoriteCategoryCounts[index] : 0
      });
    }
    return options;
  }

  private favoriteFilterSelectOptions(): SelectOption[] {
    return this.favoriteFilterOptions().map((item: FavoriteFilterOption): SelectOption => {
      return {
        value: item.count > 0 ? `${item.name} (${item.count})` : item.name
      };
    });
  }

  private favoriteFilterSelectedIndex(): number {
    const options = this.favoriteFilterOptions();
    const index = options.findIndex((item: FavoriteFilterOption) => item.filter === this.favoriteListFilter);
    if (index >= 0) {
      return index;
    }
    const allIndex = options.findIndex((item: FavoriteFilterOption) => item.filter === FAVORITE_FILTER_ALL);
    return allIndex >= 0 ? allIndex : 0;
  }

  private favoriteFilterSummary(): string {
    const options = this.favoriteFilterOptions();
    const index = this.favoriteFilterSelectedIndex();
    const item = index >= 0 && index < options.length ? options[index] : options[0];
    return item.count > 0 ? `${item.name} · ${item.count}` : item.name;
  }

  private favoriteFilterUrl(filter: number): string {
    const normalized = this.normalizeFavoriteListFilter(filter);
    const baseUrl = EhUrl.favorites(this.siteMode);
    if (normalized >= 0) {
      return `${baseUrl}?favcat=${normalized}`;
    }
    return baseUrl;
  }

  private localFavoriteListUrl(): string {
    return 'local://favorites';
  }

  private favoriteSlotIndexByName(name: string): number {
    const normalizedName = name.trim();
    if (normalizedName.length === 0) {
      return FAVORITE_INVALID_DEFAULT_SLOT;
    }
    for (let index = 0; index < FAVORITE_SLOT_NAMES.length; index++) {
      if (this.favoriteSlotName(index) === normalizedName) {
        return index;
      }
    }
    return FAVORITE_INVALID_DEFAULT_SLOT;
  }

  private preferredFavoritePanelSlot(): number {
    if (this.nativeDetail.isFavorited) {
      const slot = this.favoriteSlotIndexByName(this.nativeDetail.favoriteName);
      if (slot !== FAVORITE_INVALID_DEFAULT_SLOT) {
        return slot;
      }
    }
    if (this.isCurrentGalleryLocalFavorite()) {
      return FAVORITE_LOCAL_SLOT;
    }
    if (this.defaultFavoriteSlot !== FAVORITE_INVALID_DEFAULT_SLOT) {
      return this.defaultFavoriteSlot;
    }
    return FAVORITE_LOCAL_SLOT;
  }

  private favoritePanelSelectOptions(): SelectOption[] {
    return this.favoriteSlots().map((item: NativeFavoriteSlot): SelectOption => {
      const countText = item.count && item.count > 0 ? ` (${item.count})` : '';
      return { value: `${item.name}${countText}` };
    });
  }

  private favoritePanelSelectedIndex(): number {
    const options = this.favoriteSlots();
    const index = options.findIndex((item: NativeFavoriteSlot) => item.slot === this.favoritePanelSlotDraft);
    return index >= 0 ? index : 0;
  }

  private favoritePanelSlotSummary(): string {
    return this.favoriteSlotName(this.favoritePanelSlotDraft);
  }

  private favoriteQuickSlot(): number {
    if (this.defaultFavoriteSlot !== FAVORITE_INVALID_DEFAULT_SLOT) {
      return this.defaultFavoriteSlot;
    }
    return this.preferredFavoritePanelSlot();
  }

  private favoriteQuickSubtitle(): string {
    return this.favoriteSlotName(this.favoriteQuickSlot());
  }

  private applyFavoriteCategoryMeta(slots: NativeFavoriteSlot[]): void {
    if (slots.length === 0) {
      return;
    }
    const nextNames = FAVORITE_SLOT_NAMES.slice();
    const nextCounts = emptyFavoriteCategoryCounts();
    for (const item of slots) {
      if (item.slot < 0 || item.slot >= FAVORITE_SLOT_NAMES.length) {
        continue;
      }
      if (item.name.trim().length > 0) {
        nextNames[item.slot] = item.name.trim();
      }
      nextCounts[item.slot] = item.count && item.count > 0 ? item.count : 0;
    }
    this.favoriteCategoryNames = nextNames;
    this.favoriteCategoryCounts = nextCounts;
    this.writeValue(FAVORITE_CATEGORY_NAMES_KEY, JSON.stringify(nextNames));
    this.writeValue(FAVORITE_CATEGORY_COUNTS_KEY, JSON.stringify(nextCounts));
  }

  private setFavoriteListFilter(filter: number): void {
    const normalized = this.normalizeFavoriteListFilter(filter);
    if (this.favoriteListFilter === normalized) {
      return;
    }
    this.favoriteListFilter = normalized;
    this.writeValue(FAVORITE_RECENT_FILTER_KEY, normalized);
    if (this.activeSection === NAV_LIBRARY && this.libraryPanel === LIBRARY_FAVORITES) {
      this.loadCurrentLibraryFavoriteList(true);
    }
  }

  private findLocalFavoriteRecordForSummary(item: NativeGallerySummary): LocalGalleryRecord | undefined {
    return this.localFavorites.find((record: LocalGalleryRecord) =>
      record.gid === item.gid && record.detailUrl === item.detailUrl);
  }

  private currentFavoriteActionSummary(): string {
    if (this.nativeDetail.isFavorited) {
      return this.currentSiteFavoriteName();
    }
    if (this.isCurrentGalleryLocalFavorite()) {
      return this.favoriteSlotName(FAVORITE_LOCAL_SLOT);
    }
    return this.defaultFavoriteLabel();
  }

  private isCurrentGalleryFavorited(): boolean {
    return this.nativeDetail.isFavorited || this.isCurrentGalleryLocalFavorite();
  }

  private currentSiteFavoriteName(): string {
    return this.nativeDetail.favoriteName.length > 0 ? this.nativeDetail.favoriteName : '站点收藏';
  }

  private currentFavoriteRemovalName(): string {
    if (this.nativeDetail.isFavorited) {
      return this.currentSiteFavoriteName();
    }
    if (this.isCurrentGalleryLocalFavorite()) {
      return this.favoriteSlotName(FAVORITE_LOCAL_SLOT);
    }
    return '';
  }

  private favoriteSquareSubtitle(): string {
    const removalName = this.currentFavoriteRemovalName();
    return removalName.length > 0 ? removalName : this.favoriteQuickSubtitle();
  }

  private async handleFavoriteSquareClick(): Promise<void> {
    if (this.isCurrentGalleryFavorited()) {
      await this.removeCurrentGalleryFavorite();
    } else {
      await this.applyFavoriteSlot(this.favoritePanelSlotDraft, true);
    }
  }

  private defaultFavoriteLabel(): string {
    return this.defaultFavoriteSlot === FAVORITE_INVALID_DEFAULT_SLOT ?
      '未使用过收藏夹' : `上次 ${this.favoriteSlotName(this.defaultFavoriteSlot)}`;
  }

  private localFavoriteKey(record: LocalGalleryRecord): string {
    return `${record.site}-${record.gid}`;
  }

  private isRecordLocalFavorite(record: LocalGalleryRecord): boolean {
    const key = this.localFavoriteKey(record);
    return this.localFavorites.some((item: LocalGalleryRecord) => this.localFavoriteKey(item) === key);
  }

  private isCurrentGalleryLocalFavorite(): boolean {
    const record = this.createRecordFromDetail();
    return record ? this.isRecordLocalFavorite(record) : false;
  }

  private setDefaultFavoriteSlot(slot: number): void {
    this.defaultFavoriteSlot = this.normalizeFavoriteSlot(slot, true);
    this.writeValue(FAVORITE_DEFAULT_SLOT_KEY, this.defaultFavoriteSlot);
  }

  private torrentMetaLine(item: NativeTorrentItem): string {
    const parts: string[] = [];
    if (item.posted.length > 0) {
      parts.push(item.posted);
    }
    if (item.size.length > 0) {
      parts.push(item.size);
    }
    if (item.seeds.length > 0) {
      parts.push(`${item.seeds} seeds`);
    }
    return parts.length > 0 ? parts.join('  ·  ') : item.url;
  }

  private commentScoreText(comment: NativeGalleryComment): string {
    if (comment.id <= 0) {
      return '';
    }
    if (comment.score > 0) {
      return `+${comment.score}`;
    }
    return `${comment.score}`;
  }

  @Builder
  private HeaderCard(): void {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('E-Harmony')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF');
          Text('原生浏览、搜索、详情、阅读和下载')
            .fontSize(13)
            .fontColor('#FBEAF1')
            .maxLines(2);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);

        Column({ space: 6 }) {
          Text(this.siteLabel())
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#A85474')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor('#FFFFFF')
            .borderRadius(8);
          Text(this.siteMode === GallerySite.EX ? '里站' : '外站')
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FBEAF1');
        }
        .alignItems(HorizontalAlign.End);
      }
      .width('100%');

      Row({ space: 8 }) {
        this.HeaderPill(this.sitePanelTitle());
        this.HeaderPill(this.cookieStatusSummary);
      }
      .width('100%');
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor('#A85474')
    .borderRadius(6)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private HeaderPill(value: string): void {
    Text(value)
      .fontSize(11)
      .fontColor('#FFFFFF')
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('#B76482')
      .borderRadius(8)
      .maxLines(1);
  }

  @Builder
  private WarningCard(): void {
    Column({ space: 10 }) {
      Text('迁移状态')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027');
      Text('当前版本已支持网页登录、原生列表/详情/预览/阅读器、EX 访问检查、本地数据库、快速搜索、历史、书签和下载队列。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#6F5964');
      Button('继续')
        .height(28)
        .fontColor('#FFFFFF')
        .backgroundColor('#C86B8C')
        .borderRadius(8)
        .onClick(() => {
          this.acknowledgeWarning();
        });
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private SiteStatusCard(): void {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 4 }) {
          Text(this.siteAccessHeadline())
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027');
          Text(this.siteAccessDescription())
            .fontSize(13)
            .lineHeight(20)
            .fontColor('#6F5964');
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);

        Text(this.siteMode === GallerySite.EX ? 'EX' : 'E')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(this.siteMode === GallerySite.EX ? '#37474F' : '#C86B8C')
          .borderRadius(8);
      }
      .width('100%');

      Row({ space: 8 }) {
        Button('登录')
          .layoutWeight(1)
          .height(28)
          .fontColor('#FFFFFF')
          .backgroundColor('#C86B8C')
          .borderRadius(8)
          .onClick(() => {
            this.openWebSignIn();
          });
        Button('读取 Cookie')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.exportCookies();
          });
        Button(this.siteMode === GallerySite.EX ? '切到外站' : '切到里站')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.switchSiteAndRestart(this.siteMode === GallerySite.EX ? GallerySite.E : GallerySite.EX);
          });
      }
      .width('100%');
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private BrowseToolbarCard(): void {
    Column({ space: 10 }) {
      TextInput({
        text: this.addressInput,
        placeholder: '打开 EH 页面或粘贴画廊链接'
      })
        .width('100%')
        .height(38)
        .backgroundColor('#F8F8F8')
        .borderRadius(8)
        .fontSize(14)
        .onChange((value: string) => {
          this.addressInput = value;
        });

      Row({ space: 8 }) {
        Button('打开')
          .layoutWeight(1)
          .height(28)
          .fontColor('#FFFFFF')
          .backgroundColor('#C86B8C')
          .borderRadius(8)
          .onClick(() => {
            this.openEhRouteOrInternalWeb(this.addressInput, '内置网页');
          });
        Button('首页')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.openHome();
          });
        Button('书签')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.addCurrentPageToBookmarks();
          });
      }

      Text('EH 链接优先进入原生页面；未覆盖且安卓也是网页流程的入口使用应用内 WebView。')
        .fontSize(12)
        .fontColor('#7C6470')
        .width('100%');
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8);
  }

  @Builder
  private BrowseQuickRouteCard(): void {
    Column({ space: 10 }) {
      Text('快捷入口')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027');

      Row({ space: 8 }) {
        Button('首页')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.openHomePrimaryPage(HOME_PAGE_DEFAULT);
          });
        Button('热门')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.openHomePrimaryPage(HOME_PAGE_POPULAR);
          });
        Button('收藏')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.openLibraryPage(LIBRARY_FAVORITES);
          });
        Button('关注')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.openHomePrimaryPage(HOME_PAGE_WATCHED);
          });
      }

      Row({ space: 8 }) {
        Button('我的标签')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.openMyPage(MY_PAGE_MY_TAGS, '我的标签');
          });
        Button('UConfig')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.openFullScreenWeb(EhUrl.uConfig(this.siteMode), 'UConfig', WEB_MODE_UCONFIG);
          });
        Button('登录')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.openWebSignIn();
          });
        Button('资讯')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.openInternalWeb(EhUrl.news(), '资讯');
          });
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private BrowseSection(): void {
    Column({ space: 12 }) {
      this.SiteStatusCard();
      this.BrowseQuickRouteCard();
      Text('EH 路由会优先在原生列表、详情和阅读器中打开；安卓本身使用网页的入口使用应用内 WebView。')
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#6F5964')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8);
    }
    .width('100%')
    .height('100%')
    .layoutWeight(1);
  }

  @Builder
  private LocalFilterStatusCard(hiddenCount: number): void {
    if (hiddenCount > 0) {
      Text(this.filterStatusText(hiddenCount))
        .width('100%')
        .fontSize(12)
        .fontColor('#6F5964')
        .padding(10)
        .backgroundColor('#FFF8E1')
        .borderRadius(8);
    }
  }

  @Builder
  private HomeGalleryRoute(): void {
    Column({ space: 12 }) {
      this.LocalFilterStatusCard(this.homeFilteredCount);
      HomeGalleryPage({
        items: this.homeResults,
        loading: this.homeLoading,
        loadingMessage: this.homeLoadingMessage,
        error: this.homeError,
        emptyText: this.homeGalleryEmptyText(),
        itemKeyPrefix: this.currentHomeGalleryKeyPrefix(),
        firstEnabled: this.homeFirstUrl.length > 0 && !this.homeLoading,
        prevEnabled: this.homePrevUrl.length > 0 && !this.homeLoading,
        nextEnabled: this.homeNextUrl.length > 0 && !this.homeLoading,
        lastEnabled: this.homeLastUrl.length > 0 && !this.homeLoading,
        imageVersion: this.galleryImageCacheVersion,
        imageUrlForItem: (item: NativeGallerySummary): string => this.galleryImageDisplayUrl(item.thumb),
        categoryColorForItem: (category: string): string => categoryColor(category),
        formatRatingValue: (rating: number): string => formatRating(rating),
        transitionIdForItem: (item: NativeGallerySummary): string => this.galleryCoverTransitionIdForSummary(item),
        onOpenItem: (item: NativeGallerySummary): void => {
          void this.openNativeDetail(item);
        },
        onFirst: (): void => {
          void this.loadHomeGalleryList(this.homeFirstUrl);
        },
        onPrev: (): void => {
          void this.loadHomeGalleryList(this.homePrevUrl);
        },
        onNext: (): void => {
          void this.loadMoreHomeGalleryList();
        },
        onLast: (): void => {
          void this.loadHomeGalleryList(this.homeLastUrl);
        }
      });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private FavoriteGalleryRoute(): void {
    Column({ space: 12 }) {
      this.LocalFilterStatusCard(this.favoriteFilteredCount);
      FavoriteGalleryPage({
        items: this.favoriteResults,
        loading: this.favoriteLoading,
        loadingMessage: this.favoriteLoadingMessage,
        error: this.favoriteError,
        emptyText: this.favoriteGalleryEmptyText(),
        itemKeyPrefix: this.currentFavoriteGalleryKeyPrefix(),
        firstEnabled: this.favoriteFirstUrl.length > 0 && !this.favoriteLoading,
        prevEnabled: this.favoritePrevUrl.length > 0 && !this.favoriteLoading,
        nextEnabled: this.favoriteNextUrl.length > 0 && !this.favoriteLoading,
        lastEnabled: this.favoriteLastUrl.length > 0 && !this.favoriteLoading,
        imageVersion: this.galleryImageCacheVersion,
        imageUrlForItem: (item: NativeGallerySummary): string => this.galleryImageDisplayUrl(item.thumb),
        categoryColorForItem: (category: string): string => categoryColor(category),
        formatRatingValue: (rating: number): string => formatRating(rating),
        transitionIdForItem: (item: NativeGallerySummary): string => this.galleryCoverTransitionIdForSummary(item),
        onOpenItem: (item: NativeGallerySummary): void => {
          if (this.favoriteListFilter === FAVORITE_FILTER_LOCAL) {
            const record = this.findLocalFavoriteRecordForSummary(item);
            if (record) {
              void this.openStoredGalleryInNative(record);
              return;
            }
          }
          void this.openNativeDetail(item);
        },
        onFirst: (): void => {
          void this.loadFavoriteGalleryList(this.favoriteFirstUrl);
        },
        onPrev: (): void => {
          void this.loadFavoriteGalleryList(this.favoritePrevUrl);
        },
        onNext: (): void => {
          void this.loadMoreFavoriteGalleryList();
        },
        onLast: (): void => {
          void this.loadFavoriteGalleryList(this.favoriteLastUrl);
        }
      });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  private homeGalleryEmptyText(): string {
    if (this.homeFilteredCount > 0) {
      return '当前页面的画廊已被本地过滤规则隐藏。';
    }
    return HOME_CONTENT_UNAVAILABLE_MESSAGE;
  }

  private favoriteGalleryEmptyText(): string {
    if (this.favoriteFilteredCount > 0) {
      return '当前收藏页的画廊已被本地过滤规则隐藏。';
    }
    if (this.favoriteListFilter === FAVORITE_FILTER_LOCAL) {
      return '还没有本地收藏。详情页点“本地收藏入口”后会出现在这里。';
    }
    return '暂无收藏数据。下拉刷新当前收藏。';
  }

  @Builder
  private SearchResultsRoute(): void {
    Column({ space: 12 }) {
      this.LocalFilterStatusCard(this.searchFilteredCount);
      SearchResultsPage({
        items: this.searchResults,
        loading: this.searchLoading,
        loadingMessage: this.searchLoadingMessage,
        error: this.searchError,
        resultCount: this.searchResultCount,
        listUrl: this.searchListUrl.length > 0 ? this.searchListUrl : this.buildAdvancedSearchUrl(),
        emptyText: this.searchFilteredCount > 0 ? '搜索结果已被本地过滤规则隐藏。' : '没有搜索结果。换一个关键词再试。',
        firstEnabled: this.searchFirstUrl.length > 0 && !this.searchLoading,
        prevEnabled: this.searchPrevUrl.length > 0 && !this.searchLoading,
        nextEnabled: this.searchNextUrl.length > 0 && !this.searchLoading,
        lastEnabled: this.searchLastUrl.length > 0 && !this.searchLoading,
        imageVersion: this.galleryImageCacheVersion,
        imageUrlForItem: (item: NativeGallerySummary): string => this.galleryImageDisplayUrl(item.thumb),
        categoryColorForItem: (category: string): string => categoryColor(category),
        formatRatingValue: (rating: number): string => formatRating(rating),
        transitionIdForItem: (item: NativeGallerySummary): string => this.galleryCoverTransitionIdForSummary(item),
        onOpenItem: (item: NativeGallerySummary): void => {
          void this.openNativeDetail(item);
        },
        onFirst: (): void => {
          void this.loadSearchGalleryList(this.searchFirstUrl);
        },
        onPrev: (): void => {
          void this.loadSearchGalleryList(this.searchPrevUrl);
        },
        onNext: (): void => {
          void this.loadMoreSearchGalleryList();
        },
        onLast: (): void => {
          void this.loadSearchGalleryList(this.searchLastUrl);
        }
      });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  private hasPendingNativeRoute(): boolean {
    if (this.routeNativeSummary === undefined || this.nativeError.length > 0) {
      return false;
    }
    if (this.routeNativeMode === ROUTE_NATIVE_READER) {
      if (this.routeReaderPageUrl.length === 0 && this.nativeViewMode === 'detail' && this.nativeDetail.gid > 0) {
        return false;
      }
      return !this.hasActiveReaderPage();
    }
    if (this.routeNativeMode === ROUTE_NATIVE_PREVIEWS) {
      return this.nativeViewMode !== 'previews';
    }
    if (this.routeNativeMode === ROUTE_NATIVE_COMMENTS) {
      return this.nativeViewMode !== 'comments';
    }
    if (this.routeNativeMode === ROUTE_NATIVE_DETAIL) {
      return this.nativeDetail.gid <= 0 || this.nativeViewMode === 'list';
    }
    return false;
  }

  private shouldShowNativeRouteLoading(): boolean {
    if (this.hasVisibleNativeSubPage()) {
      return false;
    }
    return this.nativeLoading || this.hasPendingNativeRoute();
  }

  private hasVisibleNativeSubPage(): boolean {
    if (this.nativeViewMode === 'reader') {
      return this.nativeReaderPage.pageUrl.length > 0;
    }
    return (this.nativeViewMode === 'detail' || this.nativeViewMode === 'previews' || this.nativeViewMode === 'comments') &&
      this.nativeDetail.gid > 0;
  }

  @Builder
  private NativeRouteLoadingPage(): void {
    SystemLoadingBlock({
      message: this.nativeLoadingMessage !== '正在加载图库...' ? this.nativeLoadingMessage : '正在加载...',
      minHeight: 260
    });
  }

  @Builder
  private NativeGalleryListHost(): void {
    if (this.activeSection === NAV_LIBRARY && this.libraryPanel === LIBRARY_FAVORITES &&
      this.favoriteListFilter === FAVORITE_FILTER_LOCAL) {
      if (this.shouldShowNativeRouteLoading()) {
        this.NativeRouteLoadingPage();
      } else if (this.nativeViewMode === 'comments' && this.nativeDetail.gid > 0) {
        this.NativeCommentsPage();
      } else if (this.nativeViewMode === 'detail' && this.nativeDetail.gid > 0) {
        this.NativeDetailCard();
      } else if (this.nativeViewMode === 'previews' && this.nativeDetail.gid > 0) {
        this.NativeAllPreviewPage();
      } else {
        this.FavoriteGalleryRoute();
      }
    } else if (!this.canUseNativeSite(this.siteMode)) {
      this.NativeGateCard();
    } else if (this.shouldShowNativeRouteLoading()) {
      this.NativeRouteLoadingPage();
    } else if (this.nativeViewMode === 'comments' && this.nativeDetail.gid > 0) {
      this.NativeCommentsPage();
    } else if (this.nativeViewMode === 'detail' && this.nativeDetail.gid > 0) {
      this.NativeDetailCard();
    } else if (this.nativeViewMode === 'previews' && this.nativeDetail.gid > 0) {
      this.NativeAllPreviewPage();
    } else if (this.activeSection === NAV_LIBRARY && this.libraryPanel === LIBRARY_FAVORITES) {
      this.FavoriteGalleryRoute();
    } else {
      this.HomeGalleryRoute();
    }
  }

  private handleLibraryFavoritesScrollEdge(side: Edge): void {
    if (side !== Edge.Bottom || !this.shouldAutoLoadFavoriteWaterfall()) {
      return;
    }
    void this.loadMoreFavoriteGalleryList();
  }

  @Builder
  private HomeSection(): void {
    if (this.homePage === HOME_PAGE_TOP) {
      Scroll(this.homeScroller) {
        Column({ space: 12 }) {
          if (!this.canUseNativeSite(this.siteMode)) {
            this.NativeGateCard();
          } else if (this.shouldShowNativeRouteLoading()) {
            this.NativeRouteLoadingPage();
          } else if (this.nativeViewMode === 'comments' && this.nativeDetail.gid > 0) {
            this.NativeCommentsPage();
          } else if (this.nativeViewMode === 'detail' && this.nativeDetail.gid > 0) {
            this.NativeDetailCard();
          } else if (this.nativeViewMode === 'previews' && this.nativeDetail.gid > 0) {
            this.NativeAllPreviewPage();
          } else {
            this.TopListSection();
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.pageContentTopPadding(), bottom: this.pageContentBottomPadding() });
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%');
    } else if (this.hasVisibleNativeSubPage()) {
      Scroll(this.homeScroller) {
        Column({ space: 12 }) {
          this.NativeGalleryListHost();
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.pageContentTopPadding(), bottom: this.pageContentBottomPadding() });
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%');
    } else {
      Refresh({ refreshing: $$this.isHomeRefreshing, offset: 64 }) {
        Scroll(this.homeScroller) {
          Column({ space: 12 }) {
            this.NativeGalleryListHost();
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.pageContentTopPadding(), bottom: this.pageContentBottomPadding() });
        }
        .onDidScroll((_xOffset: number, _yOffset: number, _scrollState: ScrollState) => {
          this.handleHomeScrollProgress();
        })
        .onScrollEdge((side: Edge) => {
          this.handleHomeScrollEdge(side);
        })
        .layoutWeight(1)
        .width('100%')
        .height('100%');
      }
      .onRefreshing(() => {
        void this.refreshHomeWaterfall();
      })
      .layoutWeight(1)
      .width('100%')
      .height('100%');
    }
  }

  @Builder
  private SearchModeChip(title: string, mode: string): void {
    Button(title)
      .layoutWeight(1)
      .height(28)
      .fontSize(12)
      .fontColor(this.searchMode === mode ? '#FFFFFF' : '#2B2027')
      .backgroundColor(this.searchMode === mode ? '#C86B8C' : '#F3E3EA')
      .borderRadius(8)
      .onClick(() => {
        this.setSearchMode(mode);
      });
  }

  @Builder
  private CategoryChip(title: string, bit: number, colorKey: string = title): void {
    Button(title)
      .height(28)
      .fontSize(11)
      .fontColor(this.categorySelected(bit) ? '#FFFFFF' : '#2B2027')
      .backgroundColor(this.categorySelected(bit) ? categoryColor(colorKey) : '#F3E3EA')
      .borderRadius(8)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.toggleSearchCategory(bit);
      });
  }

  @Builder
  private SearchToggleChip(title: string, selected: boolean, flag: string): void {
    Button(title)
      .height(28)
      .fontSize(11)
      .fontColor(selected ? '#FFFFFF' : '#2B2027')
      .backgroundColor(selected ? '#C86B8C' : '#F3E3EA')
      .borderRadius(8)
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.toggleSearchFlag(flag);
      });
  }

  @Builder
  private HistorySuggestionRow(query: string): void {
    Row({ space: 10 }) {
      Text(query)
        .layoutWeight(1)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2B2027')
        .maxLines(1);

      Text('历史')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor('#7C6470')
        .padding({ left: 9, right: 9, top: 5, bottom: 5 })
        .backgroundColor('#F3E3EA')
        .borderRadius(6);
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      this.applyHistorySuggestion(query);
    });
  }

  @Builder
  private TagSuggestionRow(item: TagTranslationSuggestion): void {
    Row({ space: 10 }) {
      Column({ space: 3 }) {
        Text(item.key)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2B2027')
          .maxLines(1);
        if (item.translation.length > 0) {
          Text(item.translation)
            .fontSize(11)
            .fontColor('#7C6470')
            .maxLines(1);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Text('标签')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor('#A85474')
        .padding({ left: 9, right: 9, top: 5, bottom: 5 })
        .backgroundColor('#F8E4ED')
        .borderRadius(6);
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      this.applyTagSuggestion(item);
    });
  }

  @Builder
  private FilterTagSuggestionRow(item: TagTranslationSuggestion): void {
    Row({ space: 10 }) {
      Column({ space: 3 }) {
        Text(item.key)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2B2027')
          .maxLines(1);
        if (item.translation.length > 0) {
          Text(item.translation)
            .fontSize(11)
            .fontColor('#7C6470')
            .maxLines(1);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Text('过滤')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor('#A85474')
        .padding({ left: 9, right: 9, top: 5, bottom: 5 })
        .backgroundColor('#F8E4ED')
        .borderRadius(6);
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      this.applyFilterTagSuggestion(item);
    });
  }

  @Builder
  private DownloadTitleBarSegment(): void {
    Column() {
      SegmentButton({
        options: this.downloadViewSegmentOptions,
        selectedIndexes: $downloadViewSelectedIndexes,
        onItemClicked: (index: number): void => {
          this.setDownloadViewModeByIndex(index);
        }
      })
        .width('100%');
    }
    .width('100%')
    .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: 6, bottom: 8 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  private SearchTitleBar(): void {
    Row({ space: 10 }) {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(17)
          .fontColor(['#6B5260']);

        TextInput({
          text: this.nativeQuery,
          placeholder: this.searchInputPlaceholder()
        })
          .layoutWeight(1)
          .height(34)
          .type(InputType.Normal)
          .enterKeyType(EnterKeyType.Search)
          .cancelButton({ style: CancelButtonStyle.INPUT })
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .fontSize(14)
          .fontColor('#2B2027')
          .placeholderColor('#9A7D8A')
          .placeholderFont({ size: 14 })
          .caretColor('#A85474')
          .onFocus(() => {
            this.handleSearchInputFocus();
          })
          .onBlur(() => {
            this.handleSearchInputBlur();
          })
          .onEditChange((isEditing: boolean) => {
            if (isEditing) {
              this.handleSearchInputFocus();
            } else {
              this.handleSearchInputBlur();
            }
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.handleSearchInputUserInteraction();
            }
          })
          .onChange((value: string) => {
            this.setNativeQueryFromSearchInput(value);
          })
          .onSubmit((_enterKey: EnterKeyType, event: SubmitEvent) => {
            this.setNativeQuery(event.text);
            this.hideSearchSuggestionOverlay();
            void this.searchNative();
          });

        Text('搜索')
          .width(48)
          .height(30)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6B5260')
          .backgroundColor('rgba(0,0,0,0.04)')
          .borderRadius(15)
          .textAlign(TextAlign.Center)
          .align(Alignment.Center)
          .onClick(() => {
            this.hideSearchSuggestionOverlay();
            void this.searchNative();
          });
      }
      .layoutWeight(1)
      .height(38)
      .padding({ left: 12, right: 4 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: 'rgba(0,0,0,0.10)' })
      .borderRadius(19)
      .shadow(ShadowStyle.OUTER_DEFAULT_SM)
      .geometryTransition(this.tagSearchTransitionId());

      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.slider_horizontal_2_square'))
          .fontSize(18)
          .fontColor(['#6B5260']);
      }
      .width(40)
      .height(38)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: 'rgba(0,0,0,0.10)' })
      .borderRadius(19)
      .shadow(ShadowStyle.OUTER_DEFAULT_SM)
      .accessibilityText('复杂筛选')
      .accessibilityDescription('打开或关闭复杂筛选')
      .onClick(() => {
        this.toggleSearchFiltersExpanded();
      });
    }
    .width('100%')
    .padding({ left: 4, top: 8, right: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private LaunchLoadingSection(): void {
    Stack({ alignContent: Alignment.Center }) {
      LoadingProgress()
        .width(32)
        .height(32);
    }
    .width('100%')
    .height('100%')
    .layoutWeight(1);
  }

  private shouldShowLoginGate(): boolean {
    return this.isReady &&
      this.loginGateVisible &&
      !this.hasCurrentSiteCredential() &&
      this.fullScreenWebUrl.length === 0 &&
      !this.hasActiveReaderPage();
  }

  private shouldShowAppLockOverlay(): boolean {
    return this.isReady && this.appLockEnabled && this.appLockForegroundRequired;
  }

  private appLockOverlayTransition(): TransitionEffect {
    const appear = TransitionEffect.opacity(0);
    const disappear = TransitionEffect.opacity(0)
      .combine(TransitionEffect.scale({ x: 1.03, y: 1.03, centerX: '50%', centerY: '50%' }));
    return TransitionEffect.asymmetric(appear, disappear)
      .animation({ duration: 260, curve: Curve.EaseOut });
  }

  @Builder
  private AppLockOverlay(): void {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
      }
        .width('100%')
        .height('100%');
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.systemSafeTop, bottom: this.systemSafeBottom })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      if (!this.appLockAuthInProgress) {
        void this.requireAppUnlockIfNeeded();
      }
    })
    .transition(this.appLockOverlayTransition())
    .zIndex(190);
  }

  @Builder
  private LoginGateOverlay(): void {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 18 }) {
        Column({ space: 10 }) {
          Image($r('app.media.eh_logo'))
            .width(96)
            .height(96)
            .objectFit(ImageFit.Cover)
            .borderRadius(20)
            .clip(true);
          Text('E-Hentai for HarmonyOS')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027')
            .textAlign(TextAlign.Center)
            .maxLines(1);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);

        Column({ space: 6 }) {
          Text('需要登录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027')
            .textAlign(TextAlign.Center);
          Text('请选择网页登录或 Cookie 登录，也可以先以游客模式继续。')
            .fontSize(13)
            .lineHeight(20)
            .fontColor('#6F5964')
            .textAlign(TextAlign.Center);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);

        Column({ space: 10 }) {
          Button('网页登录')
            .width('100%')
            .height(40)
            .fontColor('#FFFFFF')
            .backgroundColor('#C86B8C')
            .borderRadius(8)
            .onClick(() => {
              this.openWebSignInFromGate();
            });
          Button('Cookie 登录')
            .width('100%')
            .height(40)
            .backgroundColor('#F8E4ED')
            .fontColor('#2B2027')
            .borderRadius(8)
            .onClick(() => {
              this.openCookieSignInFromGate();
            });
          Column({ space: 4 }) {
            Button('游客模式')
              .width('100%')
              .height(40)
              .backgroundColor('#F3E3EA')
              .fontColor('#2B2027')
              .borderRadius(8)
              .onClick(() => {
                this.enterGuestModeFromGate();
              });
            Text('只能访问外站')
              .width('100%')
              .fontSize(11)
              .fontColor('#7C6470')
              .textAlign(TextAlign.Center);
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center);
        }
        .width('100%');
      }
      .width('88%')
      .constraintSize({ maxWidth: 380 })
      .padding({ left: 22, right: 22, top: 24, bottom: 22 })
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Center);
    }
    .width('100%')
    .height('100%')
    .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.systemSafeTop + 24, bottom: this.systemSafeBottom + 24 })
    .backgroundColor('rgba(43,32,39,0.42)')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  @Builder
  private SearchSectionCardHeader(title: string, secondaryTitle: string = ''): void {
    Row({ space: 8 }) {
      Text(title)
        .layoutWeight(1)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027')
        .maxLines(1);
      if (secondaryTitle.length > 0) {
        Text(secondaryTitle)
          .fontSize(11)
          .fontColor('#7C6470')
          .maxLines(1);
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 6 })
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private SearchHistoryPanelHeader(): void {
    Row({ space: 8 }) {
      Text('历史记录')
        .layoutWeight(1)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027')
        .maxLines(1);
      if (this.shouldShowSearchHistoryExpandButton()) {
        Button(this.searchHistoryExpandButtonLabel())
          .height(28)
          .padding({ left: 12, right: 12 })
          .fontSize(12)
          .fontColor('#6B5260')
          .backgroundColor('#F3E3EA')
          .borderRadius(14)
          .onClick(() => {
            this.toggleSearchHistoryExpanded();
          });
      }
      Button('清空')
        .height(28)
        .padding({ left: 12, right: 12 })
        .fontSize(12)
        .fontColor('#B42318')
        .backgroundColor('#FFF3F2')
        .borderRadius(14)
        .accessibilityText('清空历史记录')
        .accessibilityDescription('清空全部搜索历史记录')
        .onClick(() => {
          this.confirmClearSearchHistoryQueries();
        });
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 6 })
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private SearchHistoryRecordRow(query: string): void {
    Row({ space: 10 }) {
      Text(query)
        .layoutWeight(1)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2B2027')
        .maxLines(1)
        .onClick(() => {
          this.applyHistorySuggestion(query);
        });

      Button() {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize(17)
          .fontColor(['#B42318']);
      }
        .width(32)
        .height(30)
        .backgroundColor('#FFF3F2')
        .borderRadius(15)
        .accessibilityText('删除历史记录')
        .accessibilityDescription('删除这条搜索历史记录')
        .onClick(() => {
          this.removeSearchHistoryQuery(query);
        });
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .transition(this.searchHistoryRecordTransition());
  }

  @Builder
  private SearchFilterCard(): void {
    Column({ space: 10 }) {
      if (this.nativeQuery.trim().length > 0 && this.searchHistorySuggestions.length > 0) {
        List({ space: 0 }) {
          ListItemGroup({
            style: ListItemGroupStyle.CARD,
            header: (): void => {
              this.SearchSectionCardHeader('历史搜索', `${this.searchHistorySuggestions.length} 条`);
            }
          }) {
            ForEach(this.searchHistorySuggestions, (item: string) => {
              ListItem() {
                this.HistorySuggestionRow(item);
              }
            }, (item: string) => item);
          }
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .listDirection(Axis.Vertical);
      }

      if (this.tagSuggestions.length > 0) {
        List({ space: 0 }) {
          ListItemGroup({
            style: ListItemGroupStyle.CARD,
            header: (): void => {
              this.SearchSectionCardHeader('标签联想', `${this.tagSuggestions.length} 条`);
            }
          }) {
            ForEach(this.tagSuggestions, (item: TagTranslationSuggestion) => {
              ListItem() {
                this.TagSuggestionRow(item);
              }
            }, (item: TagTranslationSuggestion) => item.key);
          }
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .listDirection(Axis.Vertical);
      }

    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  private shouldShowSearchHistoryOverlay(): boolean {
    return this.nativeQuery.trim().length === 0 &&
      this.searchHistoryQueries.length > 0;
  }

  private shouldShowSearchAutoCompleteOverlay(): boolean {
    return this.nativeQuery.trim().length > 0 &&
      this.searchSuggestionsVisible &&
      (this.searchHistorySuggestions.length > 0 || this.tagSuggestions.length > 0);
  }

  private shouldShowSearchSuggestionOverlay(): boolean {
    if (!this.isReady ||
      this.fullScreenWebUrl.length > 0 ||
      this.activeSection !== NAV_SEARCH ||
      this.nativeViewMode !== 'list' ||
      !this.searchInputFocused ||
      this.shouldShowLoginGate() ||
      this.searchFilterSheetVisible ||
      this.shouldShowNativeRouteLoading()) {
      return false;
    }
    return this.shouldShowSearchHistoryOverlay() || this.shouldShowSearchAutoCompleteOverlay();
  }

  private searchSuggestionOverlayTop(): number {
    return this.pageContentTopPadding() - 2;
  }

  private searchSuggestionOverlayTransition(): TransitionEffect {
    const appear = TransitionEffect.opacity(0)
      .combine(TransitionEffect.translate({ y: -8 }))
      .combine(TransitionEffect.scale({ x: 0.98, y: 0.82, centerX: '50%', centerY: 0 }));
    const disappear = TransitionEffect.opacity(0)
      .combine(TransitionEffect.translate({ y: -6 }))
      .combine(TransitionEffect.scale({ x: 0.98, y: 0.92, centerX: '50%', centerY: 0 }));
    return TransitionEffect.asymmetric(appear, disappear)
      .animation({ duration: 180, curve: Curve.EaseOut });
  }

  private searchHistoryRecordTransition(): TransitionEffect {
    return TransitionEffect.opacity(0)
      .combine(TransitionEffect.translate({ y: -6 }))
      .animation({ duration: 180, curve: Curve.EaseOut });
  }

  @Builder
  private SearchSuggestionOverlayContent(): void {
    if (this.shouldShowSearchHistoryOverlay()) {
      Column({ space: 8 }) {
        this.SearchHistoryPanelHeader();
        ForEach(this.visibleSearchHistoryQueries(), (item: string) => {
          this.SearchHistoryRecordRow(item);
        }, (item: string) => item);
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);
    } else {
      if (this.searchHistorySuggestions.length > 0) {
        Column({ space: 4 }) {
          this.SearchSectionCardHeader('历史搜索', `${this.searchHistorySuggestions.length} 条`);
          ForEach(this.searchHistorySuggestions, (item: string) => {
            this.HistorySuggestionRow(item);
          }, (item: string) => item);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      }

      if (this.tagSuggestions.length > 0) {
        Column({ space: 4 }) {
          this.SearchSectionCardHeader('标签联想', `${this.tagSuggestions.length} 条`);
          ForEach(this.tagSuggestions, (item: TagTranslationSuggestion) => {
            this.TagSuggestionRow(item);
          }, (item: TagTranslationSuggestion) => item.key);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      }
    }
  }

  private searchSuggestionOverlayMaxHeight(): number {
    if (this.pageViewportHeight <= 1) {
      return 520;
    }
    const availableHeight = this.pageViewportHeight - this.searchSuggestionOverlayTop();
    return Math.max(160, Math.floor(availableHeight));
  }

  private searchSuggestionOverlayBottomSpacerHeight(): number {
    if (this.shouldShowSearchHistoryOverlay() && !this.searchHistoryExpanded) {
      return 0;
    }
    return this.shouldShowBottomTabs() ? this.pageContentBottomPadding() : 0;
  }

  @Builder
  private SearchSuggestionOverlay(): void {
    if (this.shouldShowSearchSuggestionOverlay()) {
      Scroll() {
        Column({ space: 0 }) {
          Column({ space: 8 }) {
            this.SearchSuggestionOverlayContent();
          }
          .width('100%')
          .padding(8)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .border({ width: 1, color: '#E8C8D6' })
          .shadow(ShadowStyle.OUTER_DEFAULT_SM)
          .alignItems(HorizontalAlign.Start);

          if (this.searchSuggestionOverlayBottomSpacerHeight() > 0) {
            Blank()
              .width('100%')
              .height(this.searchSuggestionOverlayBottomSpacerHeight());
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .constraintSize({ maxHeight: this.searchSuggestionOverlayMaxHeight() })
      .scrollBar(BarState.Auto)
      .padding({ left: PAGE_SIDE_GUTTER + 4, right: PAGE_SIDE_GUTTER + 8 })
      .position({ x: 0, y: this.searchSuggestionOverlayTop() })
      .transition(this.searchSuggestionOverlayTransition())
      .zIndex(30);
    }
  }

  @Builder
  private SearchFilterSheetTitle(): void {
    Row({ space: 12 }) {
      Text('高级筛选')
        .layoutWeight(1)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027')
        .maxLines(1);

      Button('应用')
        .height(32)
        .padding({ left: 16, right: 16 })
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.canApplySearchFilters() ? '#FFFFFF' : '#9A7D8A')
        .backgroundColor(this.canApplySearchFilters() ? '#A85474' : '#EEEEEE')
        .borderRadius(16)
        .enabled(this.canApplySearchFilters())
        .onClick(() => {
          this.applySearchFiltersFromSheet();
        });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private SearchFilterCategoryGroups(): void {
    ForEach([`${this.searchCategoryMask}`], (_key: string) => {
      Column({ space: 10 }) {
        Text('分类')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2B2027');

        Column({ space: 6 }) {
          Text('选中分类')
            .fontSize(12)
            .fontColor('#7C6470');
          if (this.selectedSearchCategoryOptions().length > 0) {
            this.SelectedSearchCategoryWrap();
          } else {
            Text('至少选择一个分类')
              .fontSize(12)
              .fontColor('#B42318')
              .padding({ left: 10, right: 10, top: 7, bottom: 7 })
              .backgroundColor('#FFF3F2')
              .borderRadius(8);
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);

        if (this.unselectedSearchCategoryOptions().length > 0) {
          Column({ space: 6 }) {
            Text('未选中分类')
              .fontSize(12)
              .fontColor('#7C6470');
            this.UnselectedSearchCategoryWrap();
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start);
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);
    }, (key: string) => key);
  }

  @Builder
  private SelectedSearchCategoryWrap(): void {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(SEARCH_CATEGORY_OPTIONS, (option: SearchCategoryOption) => {
        if (this.categorySelected(option.bit)) {
          Button(option.label)
            .height(28)
            .padding({ left: 12, right: 12 })
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor('#C86B8C')
            .borderRadius(14)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.animateSearchCategoryChange(() => {
                this.toggleSearchCategoryFromSheet(option.bit);
              });
            });
        }
      }, (option: SearchCategoryOption) => `selected:${option.bit}`);
    }
    .width('100%');
  }

  @Builder
  private UnselectedSearchCategoryWrap(): void {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(SEARCH_CATEGORY_OPTIONS, (option: SearchCategoryOption) => {
        if (!this.categorySelected(option.bit)) {
          Button(option.label)
            .height(28)
            .padding({ left: 12, right: 12 })
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2B2027')
            .backgroundColor('#F3E3EA')
            .borderRadius(14)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.animateSearchCategoryChange(() => {
                this.toggleSearchCategoryFromSheet(option.bit);
              });
            });
        }
      }, (option: SearchCategoryOption) => `unselected:${option.bit}`);
    }
    .width('100%');
  }

  @Builder
  private SearchFilterQuickSearches(): void {
    if (this.quickSearches.length > 0) {
      List({ space: 0 }) {
        ListItemGroup({
          style: ListItemGroupStyle.CARD,
          header: (): void => {
            this.SearchSectionCardHeader('快捷搜索', `${this.quickSearches.length} 个`);
          }
        }) {
          ForEach(this.quickSearches, (item: QuickSearchItem) => {
            ListItem() {
              Row({ space: 10 }) {
                Column({ space: 4 }) {
                  Text(item.label)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#2B2027')
                    .maxLines(1);
                  Text(this.quickSearchSummary(item))
                    .fontSize(11)
                    .fontColor('#7C6470')
                    .maxLines(2);
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start);

                Button('打开')
                  .height(28)
                  .backgroundColor('#F8E4ED')
                  .fontColor('#A85474')
                  .borderRadius(14)
                  .onClick(() => {
                    this.applyQuickSearch(item);
                    this.closeSearchFilterSheet();
                  });

                Button('移除')
                  .height(28)
                  .backgroundColor('#FFF3F2')
                  .fontColor('#B42318')
                  .borderRadius(14)
                  .onClick(() => {
                    this.removeQuickSearch(item.id);
                  });
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(10);
            }
          }, (item: QuickSearchItem) => item.id);
        }
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .listDirection(Axis.Vertical);
    }
  }

  @Builder
  private SearchFilterSheetContent(): void {
    Scroll() {
      Column({ space: 12 }) {
        this.SearchFilterQuickSearches();

        List({ space: 12 }) {
          ListItemGroup({
            style: ListItemGroupStyle.CARD,
            header: (): void => {
              this.SearchSectionCardHeader('当前站点', this.siteDisplayName(this.siteMode));
            }
          }) {
            ListItem() {
              Column({ space: 12 }) {
                Column({ space: 8 }) {
                  Text('搜索模式')
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#2B2027');
                  Select(this.searchModeSelectOptions())
                    .selected(this.searchModeSelectedIndex())
                    .value(this.searchModeLabel(this.searchMode))
                    .width('100%')
                    .height(36)
                    .backgroundColor('#F8F8F8')
                    .font({ size: 13 })
                    .fontColor('#2B2027')
                    .selectedOptionBgColor('#C86B8C')
                    .selectedOptionFont({ size: 13, weight: FontWeight.Medium })
                    .selectedOptionFontColor('#FFFFFF')
                    .optionFont({ size: 13 })
                    .optionBgColor('#FFFFFF')
                    .optionFontColor('#2B2027')
                    .onSelect((index: number, _value: string) => {
                      this.applySearchModeByIndex(index);
                    });
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start);

                this.SearchFilterCategoryGroups();

                Column({ space: 8 }) {
                  Row({ space: 8 }) {
                    Text('高级参数')
                      .layoutWeight(1)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#2B2027');
                    Toggle({ type: ToggleType.Switch, isOn: this.searchAdvancedEnabled })
                      .selectedColor('#C86B8C')
                      .onChange((isOn: boolean) => {
                        this.searchAdvancedEnabled = isOn;
                      });
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center);

                  if (this.searchAdvancedEnabled) {
                    ChipGroup({
                      items: this.searchAdvancedFlagChipItems(),
                      itemStyle: {
                        size: ChipSize.SMALL,
                        backgroundColor: '#F3E3EA',
                        fontColor: '#2B2027',
                        selectedBackgroundColor: '#C86B8C',
                        selectedFontColor: '#FFFFFF'
                      },
                      selectedIndexes: this.selectedSearchAdvancedFlagIndexes(),
                      multiple: true,
                      chipGroupSpace: { itemSpace: 8, startSpace: 0, endSpace: 0 },
                      chipGroupPadding: { top: 2, bottom: 2 },
                      onChange: (indexes: number[]) => {
                        this.applySelectedSearchAdvancedFlagIndexes(indexes);
                      }
                    })
                      .width('100%');

                    Row({ space: 10 }) {
                      Text('分数筛选')
                        .width(64)
                        .fontSize(13)
                        .fontColor('#6F5964');
                      TextInput({ text: this.searchMinRating, placeholder: '最低评分 2-5' })
                        .layoutWeight(1)
                        .height(38)
                        .backgroundColor('#F8F8F8')
                        .borderRadius(10)
                        .fontSize(13)
                        .caretColor('#A85474')
                        .onChange((value: string) => {
                          this.searchMinRating = value;
                        });
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center);

                    Row({ space: 10 }) {
                      Text('页数筛选')
                        .width(64)
                        .fontSize(13)
                        .fontColor('#6F5964');
                      TextInput({ text: this.searchPageFrom, placeholder: '页数从' })
                        .layoutWeight(1)
                        .height(38)
                        .backgroundColor('#F8F8F8')
                        .borderRadius(10)
                        .fontSize(13)
                        .caretColor('#A85474')
                        .onChange((value: string) => {
                          this.searchPageFrom = value;
                        });
                      TextInput({ text: this.searchPageTo, placeholder: '页数到' })
                        .layoutWeight(1)
                        .height(38)
                        .backgroundColor('#F8F8F8')
                        .borderRadius(10)
                        .fontSize(13)
                        .caretColor('#A85474')
                        .onChange((value: string) => {
                          this.searchPageTo = value;
                        });
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center);
                  }
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start);

                Row({ space: 8 }) {
                  Button('保存快捷搜索')
                    .layoutWeight(1)
                    .height(34)
                    .backgroundColor('#F8E4ED')
                    .fontColor('#A85474')
                    .borderRadius(17)
                    .onClick(() => {
                      this.saveCurrentQuickSearch();
                    });
                  Button('重置筛选')
                    .layoutWeight(1)
                    .height(34)
                    .backgroundColor('#F3E3EA')
                    .fontColor('#2B2027')
                    .borderRadius(17)
                    .onClick(() => {
                      this.resetSearchFilters();
                    });
                }
                .width('100%');

                Text(this.buildAdvancedSearchUrl())
                  .fontSize(11)
                  .fontColor('#7C6470')
                  .maxLines(4)
                  .width('100%')
                  .padding(10)
                  .backgroundColor('#FFFFFF')
                  .borderRadius(10);
              }
              .width('100%')
              .padding(12)
              .alignItems(HorizontalAlign.Start);
            }
          }
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .listDirection(Axis.Vertical);
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 24 })
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto);
  }

  @Builder
  private SearchResultsBlock(): void {
    if (this.shouldShowNativeRouteLoading()) {
      this.NativeRouteLoadingPage();
    } else if (this.nativeError.length > 0) {
      Text(this.nativeError)
        .width('100%')
        .fontSize(12)
        .fontColor('#B42318')
        .padding(12)
        .backgroundColor('#FFF3F2')
        .borderRadius(8);
    } else if (this.hasActiveReaderPage()) {
      if (this.readerReadingFullscreen) {
        Text('阅读器全屏模式已开启。')
          .width('100%')
          .fontSize(13)
          .fontColor('#6F5964')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8);
      } else {
        this.NativeReaderCard();
      }
    } else if (this.nativeViewMode === 'comments' && this.nativeDetail.gid > 0) {
      this.NativeCommentsPage();
    } else if (this.nativeViewMode === 'detail' && this.nativeDetail.gid > 0) {
      this.NativeDetailCard();
    } else if (this.nativeViewMode === 'previews' && this.nativeDetail.gid > 0) {
      this.NativeAllPreviewPage();
    } else if (this.searchResultsActive) {
      this.SearchResultsRoute();
    }
  }

  @Builder
  private SearchSection(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll(this.searchScroller) {
        Column({ space: 12 }) {
          if (!this.canUseNativeSite(this.siteMode)) {
            this.NativeGateCard();
          } else if (this.shouldShowNativeRouteLoading()) {
            this.NativeRouteLoadingPage();
          } else {
            this.SearchResultsBlock();
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.pageContentTopPadding(), bottom: this.pageContentBottomPadding() });
      }
      .onDidScroll((_xOffset: number, _yOffset: number, _scrollState: ScrollState) => {
        this.handleSearchScrollProgress();
      })
      .onDisAppear(() => {
        this.searchFilterSheetVisible = false;
      })
      .bindSheet($$this.searchFilterSheetVisible, this.SearchFilterSheetContent(), {
        mode: SheetMode.OVERLAY,
        height: '78%',
        dragBar: true,
        showClose: true,
        preferType: SheetType.BOTTOM,
        title: (): void => {
          this.SearchFilterSheetTitle();
        }
      })
      .onScrollEdge((side: Edge) => {
        this.handleSearchScrollEdge(side);
      })
      .width('100%')
      .height('100%');

      this.SearchSuggestionOverlay();
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private NativeHeaderCard(): void {
    Column({ space: 8 }) {
      Text('原生画廊流程')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027');
      Text('搜索、快捷搜索、列表卡片、详情、预览翻页和阅读入口都在应用内渲染。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#6F5964');
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private NativeGateCard(): void {
    Column({ space: 10 }) {
      Text('EXHentai 需要登录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027');
      Text('当前为里站，但还没有检测到有效登录或 EX Cookie。请先登录或导入 Cookie 后再使用原生页面。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#6F5964');
      Row({ space: 8 }) {
        Button('去登录')
          .layoutWeight(1)
          .height(28)
          .fontColor('#FFFFFF')
          .backgroundColor('#C86B8C')
          .borderRadius(8)
          .onClick(() => {
            this.openWebSignIn();
          });
        Button('使用外站')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            const shouldReloadSearch = this.activeSection === NAV_SEARCH && this.searchResultsActive;
            this.toggleSite(GallerySite.E);
            this.nativeError = '';
            if (shouldReloadSearch) {
              this.searchResultsActive = true;
              void this.loadSearchGalleryList(this.buildAdvancedSearchUrl());
            } else {
              void this.loadHomeGalleryList(EhUrl.galleryFront(this.siteMode));
            }
          });
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private NativeSearchCard(): void {
    Column({ space: 10 }) {
      TextInput({
        text: this.nativeQuery,
        placeholder: this.siteMode === GallerySite.EX ? '搜索 ExHentai' : '搜索 E-Hentai'
      })
        .width('100%')
        .height(38)
        .backgroundColor('#F8F8F8')
        .borderRadius(8)
        .fontSize(14)
        .onChange((value: string) => {
          this.setNativeQuery(value);
        });

      Row({ space: 8 }) {
        Button('搜索')
          .layoutWeight(1)
          .height(28)
          .fontColor('#FFFFFF')
          .backgroundColor('#C86B8C')
          .borderRadius(8)
          .onClick(() => {
            void this.searchNative();
          });
        Button('保存快捷')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.saveCurrentQuickSearch();
          });
        Button('原生链接')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            void this.loadNativeList(EhUrl.search(this.siteMode, this.nativeQuery));
          });
      }

      Row({ space: 8 }) {
        Button('首页')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            void this.loadNativeList(EhUrl.galleryFront(this.siteMode));
          });
        Button('热门')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            void this.loadNativeList(EhUrl.popular(this.siteMode));
          });
        Button('收藏')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            void this.loadNativeList(EhUrl.favorites(this.siteMode));
          });
        Button('关注')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            void this.loadNativeList(EhUrl.watched(this.siteMode));
          });
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8);
  }

  @Builder
  private QuickSearchCard(): void {
    Column({ space: 10 }) {
      Row() {
        Text('快捷搜索')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B2027');
        Text(`${this.quickSearches.length}`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6F5964');
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween);

      if (this.quickSearches.length === 0) {
        Text('还没有保存快捷搜索。搜索一次后点保存快捷。')
          .fontSize(12)
          .fontColor('#7C6470');
      } else {
        ForEach(this.quickSearches, (item: QuickSearchItem) => {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(item.label)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2B2027')
                .maxLines(1);
              Text(this.quickSearchSummary(item))
                .fontSize(11)
                .fontColor('#7C6470')
                .maxLines(1);
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            Button('打开')
              .height(28)
              .backgroundColor('#F8E4ED')
              .borderRadius(8)
              .onClick(() => {
                this.applyQuickSearch(item);
              });

            Button('移除')
              .height(28)
              .backgroundColor('#FFF3F2')
              .fontColor('#B42318')
              .borderRadius(8)
              .onClick(() => {
                this.removeQuickSearch(item.id);
              });
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8);
        }, (item: QuickSearchItem) => item.id);
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private NativePagerCard(): void {
    if (this.nativeViewMode === 'list' && (this.nativeFirstUrl.length > 0 || this.nativePrevUrl.length > 0 ||
      this.nativeNextUrl.length > 0 || this.nativeLastUrl.length > 0)) {
      Row({ space: 8 }) {
        Button('首页')
          .layoutWeight(1)
          .height(28)
          .backgroundColor(this.nativeFirstUrl.length > 0 ? '#FFFFFF' : '#EEEEEE')
          .fontColor(this.nativeFirstUrl.length > 0 ? '#2B2027' : '#9A7D8A')
          .borderRadius(8)
          .enabled(this.nativeFirstUrl.length > 0)
          .onClick(() => {
            void this.loadNativeList(this.nativeFirstUrl);
          });
        Button('上页')
          .layoutWeight(1)
          .height(28)
          .backgroundColor(this.nativePrevUrl.length > 0 ? '#FFFFFF' : '#EEEEEE')
          .fontColor(this.nativePrevUrl.length > 0 ? '#2B2027' : '#9A7D8A')
          .borderRadius(8)
          .enabled(this.nativePrevUrl.length > 0)
          .onClick(() => {
            void this.loadNativeList(this.nativePrevUrl);
          });
        Button('下页')
          .layoutWeight(1)
          .height(28)
          .backgroundColor(this.nativeNextUrl.length > 0 ? '#FFFFFF' : '#EEEEEE')
          .fontColor(this.nativeNextUrl.length > 0 ? '#2B2027' : '#9A7D8A')
          .borderRadius(8)
          .enabled(this.nativeNextUrl.length > 0)
          .onClick(() => {
            void this.loadNativeList(this.nativeNextUrl);
          });
        Button('末页')
          .layoutWeight(1)
          .height(28)
          .backgroundColor(this.nativeLastUrl.length > 0 ? '#FFFFFF' : '#EEEEEE')
          .fontColor(this.nativeLastUrl.length > 0 ? '#2B2027' : '#9A7D8A')
          .borderRadius(8)
          .enabled(this.nativeLastUrl.length > 0)
          .onClick(() => {
            void this.loadNativeList(this.nativeLastUrl);
          });
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8);
    }
  }

  @Builder
  private NativeSummaryCard(item: NativeGallerySummary): void {
    Row({ space: 12 }) {
      if (item.thumb.length > 0) {
        Image(this.galleryImageDisplayUrl(item.thumb))
          .width(88)
          .height(124)
          .borderRadius(6)
          .objectFit(ImageFit.Cover);
      } else {
        Column() {
          Text('无封面')
            .fontSize(12)
            .fontColor('#9A7D8A');
        }
        .width(88)
        .height(124)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#EDEDED')
        .borderRadius(6);
      }

      Column({ space: 6 }) {
        Text(item.title.length > 0 ? item.title : `${item.gid}`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2B2027')
          .maxLines(2);
        if (item.titleJpn.length > 0 && item.titleJpn !== item.title) {
          Text(item.titleJpn)
            .fontSize(12)
            .fontColor('#7C6470')
            .maxLines(1);
        }
        Text(item.uploader.length > 0 ? item.uploader : '未知上传者')
          .fontSize(12)
          .fontColor('#6F5964')
          .maxLines(1);
        Row({ space: 8 }) {
          Text(item.categoryLabel.toUpperCase())
            .fontSize(11)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(categoryColor(item.categoryLabel))
            .borderRadius(6);
          Text(`评分 ${formatRating(item.rating)}`)
            .fontSize(12)
            .fontColor('#6F5964');
        }
        Text(`页数 ${item.pages}  ·  ${item.simpleLanguage.length > 0 ? item.simpleLanguage : '语言未知'}`)
          .fontSize(12)
          .fontColor('#7C6470');
        if (item.simpleTags.length > 0) {
          Text(compactTags(item.simpleTags))
            .fontSize(11)
            .lineHeight(16)
            .fontColor('#7C6470')
            .maxLines(2);
        }
        Text(item.posted.length > 0 ? item.posted : '未知日期')
          .fontSize(11)
          .fontColor('#9A7D8A');
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      void this.openNativeDetail(item);
    });
  }

  @Builder
  private NativePreviewPager(): void {
    if (this.nativePreviewPageCount > 1) {
      Row({ space: 8 }) {
        Button('上一组')
          .layoutWeight(1)
          .height(28)
          .backgroundColor(this.nativePreviewPageIndex > 0 && !this.nativePreviewLoading ? '#F8E4ED' : '#EEEEEE')
          .fontColor(this.nativePreviewPageIndex > 0 && !this.nativePreviewLoading ? '#2B2027' : '#9A7D8A')
          .borderRadius(8)
          .enabled(this.nativePreviewPageIndex > 0 && !this.nativePreviewLoading)
          .onClick(() => {
            void this.changeNativePreviewPage(this.nativePreviewPageIndex - 1);
          });
        Row({ space: 6 }) {
          if (this.nativePreviewLoading) {
            LoadingProgress()
              .width(14)
              .height(14);
          }
          Text(`预览 ${this.nativePreviewPageIndex + 1} / ${this.nativePreviewPageCount}`)
            .textAlign(TextAlign.Center)
            .fontSize(12)
            .fontColor('#6F5964');
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
        Button('下一组')
          .layoutWeight(1)
          .height(28)
          .backgroundColor(this.nativePreviewPageIndex + 1 < this.nativePreviewPageCount && !this.nativePreviewLoading ? '#F8E4ED' : '#EEEEEE')
          .fontColor(this.nativePreviewPageIndex + 1 < this.nativePreviewPageCount && !this.nativePreviewLoading ? '#2B2027' : '#9A7D8A')
          .borderRadius(8)
          .enabled(this.nativePreviewPageIndex + 1 < this.nativePreviewPageCount && !this.nativePreviewLoading)
          .onClick(() => {
            void this.changeNativePreviewPage(this.nativePreviewPageIndex + 1);
          });
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8);
    }
  }

  private activePreviewItemsForLayout(): NativeGalleryPreview[] {
    return this.nativeViewMode === 'previews' ?
      this.nativeAllPreviewItems : this.nativePreviewItems;
  }

  private previewLengthToNumber(value: Length): number {
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      const parsed = Number.parseFloat(value);
      return Number.isFinite(parsed) ? parsed : 0;
    }
    return 0;
  }

  private updateNativePreviewStripWidth(value: Length): void {
    const nextWidth = this.previewLengthToNumber(value);
    if (nextWidth <= 0 || Math.abs(nextWidth - this.nativePreviewStripWidth) < 1) {
      return;
    }
    this.nativePreviewStripWidth = nextWidth;
  }

  private previewStripColumnCount(): number {
    const contentWidth = Math.max(1, this.nativePreviewStripWidth - 20);
    const cardWidth = PREVIEW_THUMB_WIDTH + 12;
    const gap = 10;
    return Math.max(1, Math.floor((contentWidth + gap) / (cardWidth + gap)));
  }

  private previewStripColumnsTemplate(): string {
    const columns: string[] = [];
    const columnCount = this.previewStripColumnCount();
    for (let index = 0; index < columnCount; index++) {
      columns.push('1fr');
    }
    return columns.join(' ');
  }

  private previewSpriteWidth(item: NativeGalleryPreview): number {
    let width = Math.max(item.thumbWidth, item.thumbOffsetX + item.thumbWidth);
    for (const preview of this.activePreviewItemsForLayout()) {
      if (preview.thumbUrl === item.thumbUrl && preview.thumbWidth > 0) {
        width = Math.max(width, preview.thumbOffsetX + preview.thumbWidth);
      }
    }
    return width;
  }

  private previewSpriteHeight(item: NativeGalleryPreview): number {
    let height = Math.max(item.thumbHeight, item.thumbOffsetY + item.thumbHeight);
    for (const preview of this.activePreviewItemsForLayout()) {
      if (preview.thumbUrl === item.thumbUrl && preview.thumbHeight > 0) {
        height = Math.max(height, preview.thumbOffsetY + preview.thumbHeight);
      }
    }
    return height;
  }

  private previewThumbScale(item: NativeGalleryPreview): number {
    if (item.thumbWidth <= 0 || item.thumbHeight <= 0) {
      return 1;
    }
    return Math.min(PREVIEW_THUMB_WIDTH / item.thumbWidth, PREVIEW_THUMB_HEIGHT / item.thumbHeight);
  }

  private previewThumbInsetX(item: NativeGalleryPreview): number {
    return (PREVIEW_THUMB_WIDTH - item.thumbWidth * this.previewThumbScale(item)) / 2;
  }

  private previewThumbInsetY(item: NativeGalleryPreview): number {
    return (PREVIEW_THUMB_HEIGHT - item.thumbHeight * this.previewThumbScale(item)) / 2;
  }

  @Builder
  private NativePreviewThumb(item: NativeGalleryPreview): void {
    if (item.thumbUrl.length > 0) {
      if (item.thumbWidth > 0 && item.thumbHeight > 0) {
        Stack({ alignContent: Alignment.TopStart }) {
          Image(this.galleryImageDisplayUrl(item.thumbUrl))
            .width(this.previewSpriteWidth(item) * this.previewThumbScale(item))
            .height(this.previewSpriteHeight(item) * this.previewThumbScale(item))
            .objectFit(ImageFit.Fill)
            .translate({
              x: this.previewThumbInsetX(item) - item.thumbOffsetX * this.previewThumbScale(item),
              y: this.previewThumbInsetY(item) - item.thumbOffsetY * this.previewThumbScale(item)
            });
        }
        .width(PREVIEW_THUMB_WIDTH)
        .height(PREVIEW_THUMB_HEIGHT)
        .clip(true)
        .borderRadius(6);
      } else {
        Image(this.galleryImageDisplayUrl(item.thumbUrl))
          .width(PREVIEW_THUMB_WIDTH)
          .height(PREVIEW_THUMB_HEIGHT)
          .objectFit(ImageFit.Contain)
          .backgroundColor('#F3E3EA')
          .borderRadius(6);
      }
    } else {
      Column() {
        Text(item.pageLabel)
          .fontSize(12)
          .fontColor('#9A7D8A');
      }
      .width(PREVIEW_THUMB_WIDTH)
      .height(PREVIEW_THUMB_HEIGHT)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#EDEDED')
      .borderRadius(6);
    }
  }

  @Builder
  private NativePreviewStrip(): void {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('预览页')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B2027')
          .layoutWeight(1);
        Button('全部预览')
          .height(28)
          .fontSize(12)
          .backgroundColor('#F8E4ED')
          .fontColor('#2B2027')
          .borderRadius(8)
          .enabled(this.nativePreviewItems.length > 0 || this.nativePreviewPageCount > 0)
          .onClick(() => {
            void this.openNativeAllPreviews();
          });
      }
      .width('100%');
      if (this.nativePreviewItems.length === 0) {
        Text('当前画廊页还没有解析到预览。')
          .fontSize(12)
          .fontColor('#7C6470');
      } else {
        Grid() {
          ForEach(this.nativePreviewItems, (item: NativeGalleryPreview) => {
            GridItem() {
              Column({ space: 6 }) {
                this.NativePreviewThumb(item);
                Text(`第 ${item.pageLabel} 页`)
                  .fontSize(11)
                  .fontColor('#6F5964');
              }
              .width('100%')
              .padding(6)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                void this.openNativeReaderByPageUrl(item.pageUrl);
              });
            }
          }, (item: NativeGalleryPreview) => item.pageUrl);
        }
        .columnsTemplate(this.previewStripColumnsTemplate())
        .columnsGap(10)
        .rowsGap(10)
        .width('100%');
      }
      this.NativePreviewPager();
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.updateNativePreviewStripWidth(newValue.width);
    });
  }

  @Builder
  private NativeAllPreviewPage(): void {
    Column({ space: 12 }) {
      Row({ space: 10 }) {
        Button('返回')
          .height(28)
          .fontSize(12)
          .backgroundColor('#F3E3EA')
          .fontColor('#2B2027')
          .borderRadius(8)
          .onClick(() => {
            this.handleNativeTitleBarBack();
          });
        Column({ space: 4 }) {
          Text('画廊预览')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027');
          Text(this.nativeDetail.title.length > 0 ? this.nativeDetail.title : `${this.nativeDetail.gid}`)
            .fontSize(12)
            .fontColor('#7C6470')
            .maxLines(2);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
        if (this.nativeAllPreviewLoading) {
          LoadingProgress()
            .width(22)
            .height(22);
        } else {
          Button('重载')
            .height(28)
            .fontSize(12)
            .backgroundColor('#F8E4ED')
            .fontColor('#2B2027')
            .borderRadius(8)
            .onClick(() => {
              void this.loadNativeAllPreviewPages();
            });
        }
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FFFFFF')
      .borderRadius(8);

      Row({ space: 8 }) {
        Text(`${this.nativeAllPreviewItems.length} 张预览`)
          .fontSize(13)
          .fontColor('#2B2027')
          .layoutWeight(1);
        Text(this.nativeAllPreviewStatus.length > 0 ? this.nativeAllPreviewStatus :
          `预览页 ${this.nativeAllPreviewLoadedPages}/${Math.max(1, this.nativeAllPreviewPageCount)}`)
          .fontSize(12)
          .fontColor('#7C6470');
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8);

      if (this.nativeAllPreviewItems.length === 0) {
        if (this.nativeAllPreviewLoading) {
          SystemLoadingBlock({
            message: '正在加载全部预览...',
            minHeight: 112
          });
        } else {
          Text('没有已加载的预览。')
            .fontSize(13)
            .fontColor('#6F5964')
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(8);
        }
      } else {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.nativeAllPreviewItems, (item: NativeGalleryPreview) => {
            Column({ space: 6 }) {
              this.NativePreviewThumb(item);
              Text(`第 ${item.pageLabel} 页`)
                .fontSize(11)
                .fontColor('#6F5964');
            }
            .width(PREVIEW_THUMB_WIDTH)
            .margin({ right: 10, bottom: 10 })
            .padding(6)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .onClick(() => {
              void this.openNativeReaderByPageUrl(item.pageUrl);
            });
          }, (item: NativeGalleryPreview) => item.pageUrl);
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFFFFF')
        .borderRadius(8);
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  private detailFavoriteSelectedIndex(): number {
    const options = this.favoriteSlots();
    const slot = this.preferredFavoritePanelSlot();
    const index = options.findIndex((item: NativeFavoriteSlot) => item.slot === slot);
    return index >= 0 ? index : 0;
  }

  @Builder
  private NativeDetailSquareButton(
    title: string,
    subtitle: string,
    symbol: Resource,
    highlighted: boolean,
    action: () => void
  ): void {
    Column({ space: 3 }) {
      SymbolGlyph(symbol)
        .fontSize(19)
        .fontColor([highlighted ? '#FFFFFF' : '#A85474']);
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(highlighted ? '#FFFFFF' : '#2B2027')
        .maxLines(1);
      Text(subtitle)
        .fontSize(9)
        .fontColor(highlighted ? '#FBEAF1' : '#7C6470')
        .maxLines(1);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(0)
    .backgroundColor(highlighted ? '#C86B8C' : '#FFFFFF')
    .borderRadius(8)
    .accessibilityText(title)
    .hitTestBehavior(HitTestMode.Default)
    .onClick(() => {
      action();
    });
  }

  @Builder
  private NativeDetailReadButton(): void {
    Stack({ alignContent: Alignment.Top }) {
      this.NativeDetailSquareButton(
        this.hasCurrentGalleryProgress() ? '继续阅读' : '阅读',
        this.hasCurrentGalleryProgress() ? this.currentGalleryProgressSubtitle() : `${this.nativeDetail.pages} 页`,
        $r('sys.symbol.eye'),
        true,
        (): void => {
          if (this.hasCurrentGalleryProgress()) {
            void this.openNativeReaderFromProgress();
          } else {
            void this.openNativeReaderFromStart();
          }
        }
      );

      if (this.hasCurrentGalleryProgress()) {
        Button('重新阅读')
          .height(22)
          .padding({ left: 8, right: 8 })
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#A85474')
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E8C8D6' })
          .borderRadius(11)
          .shadow(ShadowStyle.OUTER_DEFAULT_XS)
          .translate({ y: -8 })
          .zIndex(2)
          .onClick(() => {
            void this.openNativeReaderFromStart();
          });
      }
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  private NativeFavoriteBar(): void {
    Row({ space: FAVORITE_BAR_GAP }) {
      Button() {
        SymbolGlyph(this.isCurrentGalleryFavorited() ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
          .fontSize(20)
          .fontColor([this.isCurrentGalleryFavorited() ? '#FFFFFF' : '#C86B8C']);
      }
        .width(FAVORITE_BAR_ICON_WIDTH)
        .height(36)
        .padding(0)
        .backgroundColor(this.isCurrentGalleryFavorited() ? '#C86B8C' : '#FFFFFF')
        .borderRadius(8)
        .accessibilityText(this.isCurrentGalleryFavorited() ? '取消收藏' : '收藏')
        .onClick(() => {
          void this.handleFavoriteSquareClick();
        });
      Select(this.favoritePanelSelectOptions())
        .selected(this.favoritePanelSelectedIndex())
        .value(this.favoritePanelSlotSummary())
        .width(FAVORITE_BAR_SELECT_WIDTH)
        .height(36)
        .font({ size: FAVORITE_BAR_FONT_SIZE })
        .fontColor('#2B2027')
        .selectedOptionBgColor('#C86B8C')
        .selectedOptionFont({ size: FAVORITE_BAR_FONT_SIZE, weight: FontWeight.Medium })
        .selectedOptionFontColor('#FFFFFF')
        .optionFont({ size: FAVORITE_BAR_FONT_SIZE })
        .optionBgColor('#FFFFFF')
        .optionFontColor('#2B2027')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .onSelect((index: number, _value: string) => {
          const slots = this.favoriteSlots();
          if (index >= 0 && index < slots.length) {
            this.favoritePanelSlotDraft = slots[index].slot;
          }
        });
    }
    .width(FAVORITE_BAR_WIDTH)
    .padding(FAVORITE_BAR_PADDING)
    .backgroundColor('#F8E4ED')
    .borderRadius(8);
  }

  @Builder
  private NativeDetailActions(): void {
    Column({ space: 8 }) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Column() {
            this.NativeDetailReadButton();
          }
          .layoutWeight(1)
          .height('100%');
          Column() {
            this.NativeDetailSquareButton('书签', this.galleryBookmarkLabel(), $r('sys.symbol.star_fill'), false, (): void => {
              this.toggleCurrentGalleryBookmark();
            });
          }
          .layoutWeight(1)
          .height('100%');
        }
        .width('100%')
        .height(72);

        Row({ space: 8 }) {
          Column() {
            this.NativeDetailSquareButton('下载', this.queuedStateText(), $r('sys.symbol.waveform_folder_fill'), false, (): void => {
              this.toggleCurrentGalleryQueue();
            });
          }
          .layoutWeight(1)
          .height('100%');
          Column() {
            this.NativeDetailSquareButton(
              'Torrent',
              this.nativeDetail.torrentCount > 0 ? `${this.nativeDetail.torrentCount} 个` : '列表',
              $r('sys.symbol.folder_fill'),
              false,
              (): void => {
                void this.openTorrentPanel();
              }
            );
          }
          .layoutWeight(1)
          .height('100%');
        }
        .width('100%')
        .height(72);
      }
      .width(168)
      .height(168)
      .padding(8)
      .backgroundColor('#F8E4ED')
      .borderRadius(8);
      this.NativeFavoriteBar();
    }
    .width(168)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private NativeDetailStatus(): void {
    if (this.detailActionStatus.length > 0 || this.detailActionLoading ||
      (this.nativeLoading && this.nativeLoadingMessage !== '正在加载图库...')) {
      Row({ space: 10 }) {
        if (this.detailActionLoading || this.nativeLoading) {
          LoadingProgress()
            .width(22)
            .height(22);
        }
        Text(this.detailActionStatus.length > 0 ? this.detailActionStatus :
          (this.nativeLoadingMessage !== '正在加载图库...' ? this.nativeLoadingMessage : '正在处理...'))
          .layoutWeight(1)
          .fontSize(12)
          .fontColor('#4E3A45')
          .maxLines(2);
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8);
    }
  }

  @Builder
  private NativeFavoritePanel(): void {
    if (this.favoritePanelVisible) {
      Column({ space: 10 }) {
        Row() {
          Text('收藏到')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027');
          Text(this.defaultFavoriteLabel())
            .fontSize(11)
            .fontColor('#7C6470');
        }
        .width('100%');

        Select(this.favoritePanelSelectOptions())
          .selected(this.favoritePanelSelectedIndex())
          .value(this.favoritePanelSlotSummary())
          .height(36)
          .width('100%')
          .font({ size: 13 })
          .fontColor('#2B2027')
          .selectedOptionBgColor('#C86B8C')
          .selectedOptionFont({ size: 13, weight: FontWeight.Medium })
          .selectedOptionFontColor('#FFFFFF')
          .optionFont({ size: 13 })
          .optionBgColor('#FFFFFF')
          .optionFontColor('#2B2027')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .onSelect((index: number, _value: string) => {
            const slots = this.favoriteSlots();
            if (index >= 0 && index < slots.length) {
              this.favoritePanelSlotDraft = slots[index].slot;
            }
          });

        Text(this.favoritePanelSlotDraft === FAVORITE_LOCAL_SLOT ? '仅保存在本机数据库。' : `当前选择：站点槽 ${this.favoritePanelSlotDraft}`)
          .fontSize(11)
          .fontColor('#6F5964');

        Row({ space: 8 }) {
          Button('收藏到当前槽')
            .layoutWeight(1)
            .height(28)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#C86B8C')
            .borderRadius(8)
            .onClick(() => {
              void this.applyFavoriteSlot(this.favoritePanelSlotDraft, false);
            });
          Button('设为上次')
            .layoutWeight(1)
            .height(28)
            .fontSize(12)
            .backgroundColor('#F8E4ED')
            .borderRadius(8)
            .onClick(() => {
              this.setDefaultFavoriteSlot(this.favoritePanelSlotDraft);
              this.toast(`上次使用已设为 ${this.favoriteSlotName(this.favoritePanelSlotDraft)}`);
            });
          Button('清除上次')
            .layoutWeight(1)
            .height(28)
            .fontSize(12)
            .backgroundColor('#F3E3EA')
            .borderRadius(8)
            .onClick(() => {
              this.setDefaultFavoriteSlot(FAVORITE_INVALID_DEFAULT_SLOT);
            });
        }
        .width('100%');
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Start);
    }
  }

  @Builder
  private NativeRatingPanel(): void {
    if (this.ratingPanelVisible) {
      Column({ space: 10 }) {
        Row() {
          Text('提交评分')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027');
          Text(`${this.selectedRating.toFixed(1)} / 5`)
            .fontSize(13)
            .fontColor('#A85474');
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween);

        Row({ space: 8 }) {
          Button('-0.5')
            .layoutWeight(1)
            .height(28)
            .backgroundColor('#F3E3EA')
            .borderRadius(8)
            .onClick(() => {
              this.adjustSelectedRating(-0.5);
            });
          Button('+0.5')
            .layoutWeight(1)
            .height(28)
            .backgroundColor('#F3E3EA')
            .borderRadius(8)
            .onClick(() => {
              this.adjustSelectedRating(0.5);
            });
          Button('提交')
            .layoutWeight(1)
            .height(28)
            .fontColor('#FFFFFF')
            .backgroundColor('#C86B8C')
            .borderRadius(8)
            .onClick(() => {
              void this.submitSelectedRating();
            });
        }
        .width('100%');
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Start);
    }
  }

  @Builder
  private NativeTorrentPanel(): void {
    if (this.torrentPanelVisible) {
      Column({ space: 10 }) {
        Row() {
          Text('Torrent')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027');
          Button('刷新')
            .height(28)
            .fontSize(12)
            .backgroundColor('#F8E4ED')
            .borderRadius(8)
            .onClick(() => {
              void this.loadTorrentList();
            });
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween);

        if (this.torrentLoading) {
          LoadingProgress()
            .width(28)
            .height(28);
        }
        if (this.torrentStatus.length > 0) {
          Text(this.torrentStatus)
            .width('100%')
            .fontSize(12)
            .fontColor('#6F5964')
            .maxLines(3);
        }

        ForEach(this.torrentItems, (item: NativeTorrentItem) => {
          Column({ space: 6 }) {
            Text(item.name)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2B2027')
              .maxLines(2);
            Text(this.torrentMetaLine(item))
              .fontSize(11)
              .fontColor('#7C6470')
              .maxLines(1);
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .alignItems(HorizontalAlign.Start)
          .onClick(() => {
            void this.downloadTorrentItem(item);
          });
        }, (item: NativeTorrentItem) => item.url);
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Start);
    }
  }

  @Builder
  private NativeArchivePanel(): void {
    if (this.archivePanelVisible) {
      Column({ space: 10 }) {
        Row() {
          Text('Archive / H@H')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027');
          Button('网页')
            .height(28)
            .fontSize(12)
            .backgroundColor('#F8E4ED')
            .borderRadius(8)
            .onClick(() => {
              this.openArchiveWebFallback();
            });
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween);

        if (this.archiveLoading) {
          LoadingProgress()
            .width(28)
            .height(28);
        }
        if (this.archiveStatus.length > 0) {
          Text(this.archiveStatus)
            .width('100%')
            .fontSize(12)
            .fontColor('#6F5964')
            .maxLines(4);
        }

        ForEach(this.archiveList.items, (item: NativeArchiveItem) => {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(item.name)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2B2027')
                .maxLines(2);
              Text(item.res === 'org' ? '原图' : `分辨率 ${item.res}`)
                .fontSize(11)
                .fontColor('#7C6470');
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);
            Text('提交')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('#C86B8C')
              .borderRadius(8);
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => {
            void this.submitArchiveItem(item);
          });
        }, (item: NativeArchiveItem) => `${item.res}-${item.name}`);
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Start);
    }
  }

  @Builder
  private NativeDetailComments(): void {
    Column({ space: 10 }) {
      Row() {
        Text('评论')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B2027');
        if (this.nativeDetail.comments.length > 0 || this.nativeDetail.hasMoreComments) {
          Button('查看全部')
            .height(30)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#C86B8C')
            .borderRadius(8)
            .onClick(() => {
              void this.openNativeComments();
            });
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween);
      if (this.nativeDetail.comments.length === 0) {
        Text('暂无评论')
          .width('100%')
          .fontSize(12)
          .fontColor('#6F5964')
          .padding(10)
          .backgroundColor('#FAF5F8')
          .borderRadius(6);
      } else if (this.visibleNativeComments().length === 0) {
        Text(`已按黑名单隐藏 ${this.hiddenNativeCommentCount()} 条评论`)
          .width('100%')
          .fontSize(12)
          .fontColor('#6F5964')
          .padding(10)
          .backgroundColor('#FAF5F8')
          .borderRadius(6);
      } else {
        ForEach(this.visibleNativeCommentPreview(), (comment: NativeGalleryComment) => {
          Column({ space: 5 }) {
            Row({ space: 8 }) {
              Text(comment.user)
                .layoutWeight(1)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2B2027')
                .maxLines(1);
              Text(comment.posted)
                .fontSize(10)
                .fontColor('#9A7D8A')
                .maxLines(1);
            }
            .width('100%');
            if (comment.id > 0) {
              Text(this.commentScoreText(comment))
                .fontSize(10)
                .fontColor('#A85474');
            }
            Text(comment.body)
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#6F5964')
              .maxLines(5);
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#FAF5F8')
          .borderRadius(6)
          .alignItems(HorizontalAlign.Start);
        }, (comment: NativeGalleryComment) => `${comment.user}-${comment.posted}-${comment.body}`);
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private NativeCommentCard(comment: NativeGalleryComment): void {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Column({ space: 3 }) {
          Text(comment.user)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027')
            .maxLines(1);
          Text(comment.posted)
            .fontSize(11)
            .fontColor('#9A7D8A')
            .maxLines(1);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
        if (comment.id > 0) {
          Text(this.commentScoreText(comment))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#A85474');
        }
      }
      .width('100%');

      Text(comment.body)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#4E3A45');

      Row({ space: 8 }) {
        Button(comment.voteUpEd ? '取消赞同' : '赞同')
          .height(28)
          .fontSize(12)
          .backgroundColor(comment.voteUpEd ? '#C86B8C' : '#F3E3EA')
          .fontColor(comment.voteUpEd ? '#FFFFFF' : '#2B2027')
          .borderRadius(8)
          .enabled(comment.voteUpAble && comment.id > 0)
          .onClick(() => {
            void this.voteGalleryComment(comment, 1);
          });
        Button(comment.voteDownEd ? '取消反对' : '反对')
          .height(28)
          .fontSize(12)
          .backgroundColor(comment.voteDownEd ? '#B42318' : '#F3E3EA')
          .fontColor(comment.voteDownEd ? '#FFFFFF' : '#2B2027')
          .borderRadius(8)
          .enabled(comment.voteDownAble && comment.id > 0)
          .onClick(() => {
            void this.voteGalleryComment(comment, -1);
          });
        if (comment.voteState.length > 0) {
          Text(comment.voteState)
            .layoutWeight(1)
            .fontSize(11)
            .fontColor('#7C6470')
            .maxLines(1);
        }
        Button('拉黑')
          .height(28)
          .fontSize(12)
          .backgroundColor(this.isBlacklistedUser(comment.user) ? '#FFF3F2' : '#F3E3EA')
          .fontColor(this.isBlacklistedUser(comment.user) ? '#B42318' : '#2B2027')
          .borderRadius(8)
          .enabled(!this.isBlacklistedUser(comment.user))
          .onClick(() => {
            void this.addBlacklistUser(comment.user, `来自画廊 ${this.nativeDetail.gid}`);
          });
      }
      .width('100%');
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private NativeCommentsPage(): void {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Button('返回详情')
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(6)
          .onClick(() => {
            this.handleNativeTitleBarBack();
          });
        Button('刷新')
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(6)
          .onClick(() => {
            void this.loadNativeAllComments();
          });
        Button('网页发表/编辑')
          .height(28)
          .fontColor('#FFFFFF')
          .backgroundColor('#C86B8C')
          .borderRadius(6)
          .onClick(() => {
            this.openCommentWebFallback();
          });
      }
      .width('100%');

      Column({ space: 6 }) {
        Text('评论')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B2027');
        Text(this.nativeCommentsStatus.length > 0 ? this.nativeCommentsStatus :
          `${this.visibleNativeComments().length} 条评论${this.hiddenNativeCommentCount() > 0 ? `，已隐藏 ${this.hiddenNativeCommentCount()} 条` : ''}`)
          .fontSize(12)
          .fontColor('#7C6470')
          .maxLines(2);
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Start);

      if (this.nativeCommentsLoading) {
        SystemLoadingBlock({
          message: '正在加载评论...',
          minHeight: 88
        });
      }

      if (this.nativeDetail.comments.length === 0 && !this.nativeCommentsLoading) {
        Text('暂无评论。')
          .width('100%')
          .fontSize(13)
          .fontColor('#6F5964')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8);
      } else if (this.visibleNativeComments().length === 0 && !this.nativeCommentsLoading) {
        Text(`已按黑名单隐藏 ${this.hiddenNativeCommentCount()} 条评论。`)
          .width('100%')
          .fontSize(13)
          .fontColor('#6F5964')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8);
      } else {
        ForEach(this.visibleNativeComments(), (comment: NativeGalleryComment) => {
          this.NativeCommentCard(comment);
        }, (comment: NativeGalleryComment) => `${comment.id}-${comment.user}-${comment.posted}`);
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private NativeDetailCard(): void {
    GalleryDetailPage({
      detail: this.nativeDetailSnapshot(),
      detailRevision: this.nativeDetailRevision + this.downloadQueueRevision,
      metaLanguage: this.nativeDetail.language,
      metaVisible: this.nativeDetail.visible,
      metaFileSize: this.nativeDetail.fileSize,
      metaFavoriteCount: this.nativeDetail.favoriteCount,
      metaTorrentCount: this.nativeDetail.torrentCount,
      tagSearchTransitionQuery: this.tagSearchTransitionQuery,
      imageVersion: this.galleryImageCacheVersion + this.nativeDetailRevision,
      coverTransitionId: this.galleryCoverTransitionIdForDetail(),
      coverUrlFor: (value: string): string => this.galleryImageDisplayUrl(value),
      categoryColorFor: (value: string): string => categoryColor(value),
      formatRatingValue: (rating: number): string => formatRating(rating),
      metaLineFor: (label: string, value: string): string => metaLine(label, value),
      onRead: (): void => {
        void this.openNativeReaderFromStart();
      },
      onOpenUploader: (): void => {
        void this.openNativeUploaderList();
      },
      onOpenParent: (): void => {
        void this.openNativeParentGallery();
      },
      onTagSearch: (namespace: string, tag: string): void => {
        this.openNativeTagSearch(namespace, tag);
      },
      actionsContent: (): void => {
        this.NativeDetailActions();
      },
      statusContent: (): void => {
        this.NativeDetailStatus();
      },
      favoritePanelContent: (): void => {
        this.NativeFavoritePanel();
      },
      ratingPanelContent: (): void => {
        this.NativeRatingPanel();
      },
      torrentPanelContent: (): void => {
        this.NativeTorrentPanel();
      },
      archivePanelContent: (): void => {
        this.NativeArchivePanel();
      },
      commentsContent: (): void => {
        this.NativeDetailComments();
      },
      previewPagerContent: (): void => {
        this.NativePreviewPager();
      },
      previewStripContent: (): void => {
        this.NativePreviewStrip();
      },
      metadataContent: (): void => {
        this.NativeDetailMetadata();
      }
    });
  }

  @Builder
  private ReaderSettingHeader(title: string, value: string, enabled: boolean = true): void {
    Row() {
      Text(title)
        .layoutWeight(1)
        .fontSize(13)
        .fontColor('#E8EAED');
      Text(value)
        .fontSize(12)
        .fontColor(enabled ? '#9A7D8A' : '#6F5964');
    }
    .width('100%');
  }

  @Builder
  private ReaderSelectSetting(
    title: string,
    value: string,
    options: SelectOption[],
    selected: number,
    onSelect: ReaderSelectChangeHandler
  ): void {
    Column({ space: 8 }) {
      this.ReaderSettingHeader(title, value);
      Select(options)
        .selected(selected)
        .value(value)
        .height(36)
        .width('100%')
        .font({ size: 13 })
        .fontColor('#E8EAED')
        .selectedOptionBgColor('#C86B8C')
        .selectedOptionFont({ size: 13, weight: FontWeight.Medium })
        .selectedOptionFontColor('#FFFFFF')
        .optionFont({ size: 13 })
        .optionBgColor('#4E3A45')
        .optionFontColor('#E8EAED')
        .backgroundColor('#4E3A45')
        .borderRadius(8)
        .onSelect((index: number, _value: string) => {
          onSelect(index);
        });
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#3A2A33')
    .borderRadius(6);
  }

  @Builder
  private ReaderSwitchSetting(
    title: string,
    value: boolean,
    enabled: boolean,
    onChange: ReaderToggleChangeHandler
  ): void {
    Row({ space: 12 }) {
      Text(title)
        .layoutWeight(1)
        .fontSize(13)
        .fontColor(enabled ? '#E8EAED' : '#6F5964');
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#C86B8C')
        .switchPointColor('#FFFFFF')
        .enabled(enabled)
        .onChange((isOn: boolean) => {
          onChange(isOn);
        });
    }
    .width('100%')
    .height(34);
  }

  @Builder
  private ReaderSliderSetting(
    title: string,
    valueText: string,
    value: number,
    min: number,
    max: number,
    step: number,
    enabled: boolean,
    onChange: ReaderSliderChangeHandler
  ): void {
    Column({ space: 8 }) {
      this.ReaderSettingHeader(title, valueText, enabled);
      Slider({ value, min, max, step, style: SliderStyle.OutSet })
        .width('100%')
        .enabled(enabled)
        .selectedColor(enabled ? '#C86B8C' : '#4B5563')
        .trackColor('#3A3D42')
        .blockColor(enabled ? '#E8EAED' : '#6F5964')
        .showTips(true, valueText)
        .onChange((nextValue: number, mode: SliderChangeMode) => {
          if (mode !== SliderChangeMode.Begin) {
            onChange(Math.round(nextValue));
          }
        });
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#3A2A33')
    .borderRadius(6);
  }

  @Builder
  private ReaderIconButton(
    symbol: Resource,
    label: string,
    enabled: boolean,
    primary: boolean,
    action: ReaderCommandHandler
  ): void {
    Button() {
      SymbolGlyph(symbol)
        .fontSize(19)
        .fontColor([enabled ? (primary ? '#FFFFFF' : '#E8EAED') : '#7C6470']);
    }
    .width(40)
    .height(40)
    .borderRadius(20)
    .backgroundColor(enabled ? (primary ? '#C86B8C' : '#4E3A45') : '#3A2A33')
    .enabled(enabled)
    .accessibilityText(label)
    .onClick(() => {
      action();
    });
  }

  @Builder
  private ReaderFilledButton(
    symbol: Resource,
    label: string,
    enabled: boolean,
    primary: boolean,
    action: ReaderCommandHandler
  ): void {
    Button() {
      Row({ space: 6 }) {
        SymbolGlyph(symbol)
          .fontSize(17)
          .fontColor([enabled ? (primary ? '#FFFFFF' : '#E8EAED') : '#7C6470']);
        Text(label)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(enabled ? (primary ? '#FFFFFF' : '#E8EAED') : '#7C6470')
          .maxLines(1);
      }
      .justifyContent(FlexAlign.Center);
    }
    .height(40)
    .layoutWeight(1)
    .borderRadius(20)
    .backgroundColor(enabled ? (primary ? '#C86B8C' : '#4E3A45') : '#3A2A33')
    .enabled(enabled)
    .accessibilityText(label)
    .onClick(() => {
      action();
    });
  }

  @Builder
  private ReaderSettingsPanel(): void {
    Scroll() {
      Column({ space: 16 }) {
        this.ReaderSelectSetting(
          '屏幕方向',
          this.readerScreenRotationLabel(),
          this.readerScreenRotationOptions(),
          this.readerSelectIndex(this.readerScreenRotation, READER_ROTATION_VALUES),
          (index: number): void => {
            this.setReaderScreenRotation(this.readerSelectValue(index, READER_ROTATION_VALUES, '0'));
          }
        );

        this.ReaderSelectSetting(
          '阅读方向',
          this.readerDirectionLabel(),
          this.readerDirectionOptions(),
          this.readerSelectIndex(this.readerDirection, READER_DIRECTION_VALUES),
          (index: number): void => {
            this.setReaderDirection(this.readerSelectValue(index, READER_DIRECTION_VALUES, '1'));
          }
        );

        this.ReaderSelectSetting(
          '页面缩放',
          this.readerPageScalingLabel(),
          this.readerPageScalingOptions(),
          this.readerSelectIndex(this.readerPageScaling, READER_SCALING_VALUES),
          (index: number): void => {
            this.setReaderPageScaling(this.readerSelectValue(index, READER_SCALING_VALUES, '3'));
          }
        );

        this.ReaderSelectSetting(
          '起始位置',
          this.readerStartPositionLabel(),
          this.readerStartPositionOptions(),
          this.readerSelectIndex(this.readerStartPosition, READER_START_POSITION_VALUES),
          (index: number): void => {
            this.setReaderStartPosition(this.readerSelectValue(index, READER_START_POSITION_VALUES, '1'));
          }
        );

        Column({ space: 12 }) {
          this.ReaderSwitchSetting('自动翻页', this.readerAutoTransferring, true, (isOn: boolean): void => {
            if (isOn !== this.readerAutoTransferring) {
              this.toggleReaderAutoTransfer();
            }
          });
          this.ReaderSliderSetting(
            '自动翻页间隔',
            `${this.readerAutoTransferSeconds}s`,
            this.readerAutoTransferSeconds,
            1,
            120,
            1,
            true,
            (value: number): void => {
              this.setReaderAutoTransferSeconds(value);
            }
          );
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#3A2A33')
        .borderRadius(6);

        Column({ space: 12 }) {
          this.ReaderSettingHeader('预载缓存', `前后 ${READER_PRELOAD_SIDE_COUNT}`);
          Text(this.readerCacheSummaryText())
            .width('100%')
            .fontSize(11)
            .fontColor('#9A7D8A')
            .maxLines(2);
          this.ReaderSwitchSetting('下载原图', this.readerUseOriginImage, true, (isOn: boolean): void => {
            if (isOn !== this.readerUseOriginImage) {
              this.toggleReaderOriginImage();
            }
          });
          Button('清理阅读缓存')
            .width('100%')
            .height(32)
            .fontSize(12)
            .fontColor('#E8EAED')
            .backgroundColor('#4E3A45')
            .borderRadius(8)
            .onClick(() => {
              this.clearCurrentReaderCache();
            });
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#3A2A33')
        .borderRadius(6);

        Column({ space: 12 }) {
          this.ReaderSwitchSetting('保持亮屏', this.readerKeepScreenOn, true, (isOn: boolean): void => {
            if (isOn !== this.readerKeepScreenOn) {
              this.toggleReaderKeepScreenOn();
            }
          });
          this.ReaderSwitchSetting('显示时钟', this.readerShowClock, true, (isOn: boolean): void => {
            if (isOn !== this.readerShowClock) {
              this.toggleReaderShowClock();
            }
          });
          this.ReaderSwitchSetting('显示进度', this.readerShowProgress, true, (isOn: boolean): void => {
            if (isOn !== this.readerShowProgress) {
              this.toggleReaderShowProgress();
            }
          });
          this.ReaderSwitchSetting('显示电量', this.readerShowBattery, true, (isOn: boolean): void => {
            if (isOn !== this.readerShowBattery) {
              this.toggleReaderShowBattery();
            }
          });
          this.ReaderSwitchSetting('显示页面间距', this.readerShowPageInterval, true, (isOn: boolean): void => {
            if (isOn !== this.readerShowPageInterval) {
              this.toggleReaderShowPageInterval();
            }
          });
          this.ReaderSwitchSetting('音量键翻页', this.readerVolumePage, true, (isOn: boolean): void => {
            if (isOn !== this.readerVolumePage) {
              this.toggleReaderVolumePage();
            }
          });
          this.ReaderSwitchSetting('反转音量键', this.readerReverseVolumePage, this.readerVolumePage, (isOn: boolean): void => {
            if (isOn !== this.readerReverseVolumePage) {
              this.toggleReaderReverseVolumePage();
            }
          });
          this.ReaderSwitchSetting('阅读全屏', this.readerReadingFullscreen, true, (isOn: boolean): void => {
            if (isOn !== this.readerReadingFullscreen) {
              this.toggleReaderFullscreenSetting();
            }
          });
          this.ReaderSwitchSetting('自定义亮度', this.readerCustomScreenLightness, true, (isOn: boolean): void => {
            if (isOn !== this.readerCustomScreenLightness) {
              this.toggleReaderCustomLightness();
            }
          });
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#3A2A33')
        .borderRadius(6);

        this.ReaderSliderSetting(
          '屏幕亮度',
          `${this.readerScreenLightness}%`,
          this.readerScreenLightness,
          0,
          200,
          1,
          this.readerCustomScreenLightness,
          (value: number): void => {
            this.setReaderScreenLightness(value);
          }
        );
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .height(320);
  }

  @Builder
  private ReaderTouchSurface(): void {
    if (this.isReaderVerticalDirection()) {
      Column({ space: 0 }) {
        Column() {
          if (this.readerMenuVisible || !this.readerReadingFullscreen) {
            Text('上一页')
              .fontSize(11)
              .fontColor('#DADCE0');
          }
        }
        .layoutWeight(4)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#01000000');

        Column() {
        }
        .layoutWeight(5)
        .width('100%')
        .backgroundColor('#01000000');

        Column() {
          if (this.readerMenuVisible || !this.readerReadingFullscreen) {
            Text('下一页')
              .fontSize(11)
              .fontColor('#DADCE0');
          }
        }
        .layoutWeight(4)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#01000000');
      }
      .layoutWeight(1)
      .width('100%')
      .gesture(
        PanGesture({ direction: PanDirection.All, distance: 8 })
          .onActionStart(() => {
            this.handleReaderPanStart();
          })
          .onActionUpdate((event: GestureEvent) => {
            this.handleReaderPanUpdate(event);
          })
          .onActionEnd((event: GestureEvent) => {
            this.handleReaderPanEnd(event);
          })
          .onActionCancel(() => {
            this.handleReaderPanCancel();
          })
      )
      .onClick((event: ClickEvent) => {
        this.handleReaderTap(event);
      });
    } else {
      Row({ space: 0 }) {
        Column() {
          if (this.readerMenuVisible || !this.readerReadingFullscreen) {
            Text(this.readerDirection === '1' ? '下一页' : '上一页')
              .fontSize(11)
              .fontColor('#DADCE0');
          }
        }
        .layoutWeight(4)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#01000000');

        Column() {
        }
        .layoutWeight(5)
        .height('100%')
        .backgroundColor('#01000000');

        Column() {
          if (this.readerMenuVisible || !this.readerReadingFullscreen) {
            Text(this.readerDirection === '1' ? '上一页' : '下一页')
              .fontSize(11)
              .fontColor('#DADCE0');
          }
        }
        .layoutWeight(4)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#01000000');
      }
      .layoutWeight(1)
      .width('100%')
      .gesture(
        PanGesture({ direction: PanDirection.All, distance: 8 })
          .onActionStart(() => {
            this.handleReaderPanStart();
          })
          .onActionUpdate((event: GestureEvent) => {
            this.handleReaderPanUpdate(event);
          })
          .onActionEnd((event: GestureEvent) => {
            this.handleReaderPanEnd(event);
          })
          .onActionCancel(() => {
            this.handleReaderPanCancel();
          })
      )
      .onClick((event: ClickEvent) => {
        this.handleReaderTap(event);
      });
    }
  }

  @Builder
  private ReaderSwiperContent(): void {
    Stack({ alignContent: Alignment.Center }) {
      ReaderSwiperView({
        controller: this.readerSwiperController,
        dataSource: this.readerPageDataSource,
        currentIndex: this.readerSwiperIndex,
        cachedCount: READER_PRELOAD_SIDE_COUNT,
        vertical: this.isReaderVerticalDirection(),
        itemSpace: this.readerPagerInterval(),
        fitContain: this.readerFitContain,
        onIndexChange: (index: number): void => {
          this.handleReaderSwiperChange(index);
        },
        onPageAppear: (page: ReaderVirtualPage): void => {
          this.handleReaderVirtualPageAppear(page);
        },
        onPageTap: (event: ClickEvent): void => {
          this.handleReaderTap(event);
        },
        onResolvePage: async (page: ReaderVirtualPage): Promise<ReaderResolvedPage> => {
          return await this.resolveReaderVirtualPage(page);
        },
        onCachePageImage: async (page: ReaderResolvedPage): Promise<string> => {
          return await this.cacheReaderResolvedPageImage(page);
        },
        onPageImageReady: (page: ReaderVirtualPage, _imageUrl: string): void => {
          this.handleReaderVirtualPageImageReady(page);
        },
        onPageImageError: (page: ReaderVirtualPage, _imageUrl: string): void => {
          this.handleReaderVirtualPageImageError(page);
        }
      });
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_: Area, value: Area): void => {
      const nextWidth = Math.max(1, Number(value.width));
      const nextHeight = Math.max(1, Number(value.height));
      if (Math.abs(nextWidth - this.readerViewportWidth) >= 1) {
        this.readerViewportWidth = nextWidth;
      }
      if (Math.abs(nextHeight - this.readerViewportHeight) >= 1) {
        this.readerViewportHeight = nextHeight;
      }
    });
  }

  @Builder
  private ReaderPageLayer(
    pageUrl: string,
    imageUrl: string,
    layer: 'negative' | 'current' | 'positive',
    loading: boolean,
    error: string,
    pageLabel: string
  ): void {
    ForEach([`${layer}:${pageUrl}:${imageUrl}:${pageLabel}:${loading ? '1' : '0'}:${error}`], (_: string) => {
      Stack({ alignContent: Alignment.Center }) {
        Column() {
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#000000');

        if (imageUrl.length > 0) {
          Image(imageUrl)
            .width('100%')
            .height('100%')
            .objectFit(this.readerFitContain ? ImageFit.Contain : ImageFit.Cover)
            .backgroundColor('#000000');
        }

        if (loading || (error.length > 0 && imageUrl.length === 0)) {
          Column({ space: 10 }) {
            if (loading) {
              LoadingProgress()
                .width(40)
                .height(40);
            }
            Text(error.length > 0 ? error : '正在加载阅读页...')
              .fontSize(13)
              .fontColor('#E8EAED')
              .textAlign(TextAlign.Center)
              .maxLines(2);
            if (pageLabel.length > 0) {
              Text(`第 ${pageLabel} 页`)
                .fontSize(11)
                .fontColor('#9A7D8A');
            }
          }
          .width(184)
          .padding({ left: 16, right: 16, top: 18, bottom: 18 })
          .backgroundColor('#C8141517')
          .borderRadius(6)
          .alignItems(HorizontalAlign.Center);
        }
      }
      .width('100%')
      .height('100%')
      .translate({
        x: this.readerLayerTranslateX(layer),
        y: this.readerLayerTranslateY(layer)
      })
      .animation({ duration: this.readerDragActive ? 0 : 180, curve: Curve.EaseOut });
    }, (item: string) => item);
  }

  @Builder
  private ReaderLoadingOverlay(): void {
    if (this.shouldShowReaderGlobalLoading() &&
      Math.abs(this.readerDragOffset) < 1) {
      Column({ space: 10 }) {
        LoadingProgress()
          .width(42)
          .height(42);
        Text(this.readerLoadingText())
          .fontSize(13)
          .fontColor('#E8EAED')
          .textAlign(TextAlign.Center)
          .maxLines(2);
      }
      .width(184)
      .padding({ left: 16, right: 16, top: 18, bottom: 18 })
      .backgroundColor('#C8141517')
      .borderRadius(6)
      .alignItems(HorizontalAlign.Center);
    }
  }

  @Builder
  private ReaderNegativeLayerContent(): void {
    this.ReaderPageLayer(
      this.readerRenderNegativeState().pageUrl,
      this.readerRenderNegativeState().displayUrl,
      'negative',
      this.readerRenderNegativeState().loading,
      this.readerRenderNegativeState().error,
      this.readerRenderNegativeState().pageLabel
    );
  }

  @Builder
  private ReaderCurrentLayerContent(): void {
    this.ReaderPageLayer(
      this.readerRenderCurrentState().pageUrl,
      this.readerRenderCurrentState().displayUrl,
      'current',
      this.readerRenderCurrentState().loading,
      this.readerRenderCurrentState().error,
      this.readerRenderCurrentState().pageLabel
    );
  }

  @Builder
  private ReaderPositiveLayerContent(): void {
    this.ReaderPageLayer(
      this.readerRenderPositiveState().pageUrl,
      this.readerRenderPositiveState().displayUrl,
      'positive',
      this.readerRenderPositiveState().loading,
      this.readerRenderPositiveState().error,
      this.readerRenderPositiveState().pageLabel
    );
  }

  @Builder
  private ReaderFullscreenControlsContent(): void {
    Column({ space: 0 }) {
      if (this.readerShowBattery || this.readerShowProgress || this.readerShowClock) {
        Row({ space: 10 }) {
          if (this.readerShowBattery || this.readerShowClock) {
            Row({ space: 10 }) {
              if (this.readerShowBattery) {
                Text(this.readerBatteryText)
                  .fontSize(12)
                  .fontColor('#E8EAED');
              }
              if (this.readerShowClock) {
                Text(this.readerNowText)
                  .fontSize(12)
                  .fontColor('#E8EAED');
              }
            }
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#7A2D3135')
            .borderRadius(14);
          }

          Blank()
            .layoutWeight(1)
            .hitTestBehavior(HitTestMode.None);

          if (this.readerShowProgress && this.readerProgressText().length > 0) {
            Text(this.readerProgressText())
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#E8EAED')
              .textAlign(TextAlign.End)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#7A2D3135')
              .borderRadius(14);
          } else {
            Text(this.readerPageInfoText())
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#E8EAED')
              .textAlign(TextAlign.End)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#7A2D3135')
              .borderRadius(14);
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 10 })
        .opacity(this.readerTopInfoVisible ? 1 : 0)
        .animation({ duration: 240, curve: Curve.EaseOut });
      }

      Blank()
        .layoutWeight(1)
        .hitTestBehavior(HitTestMode.None);

      if (this.shouldShowReaderGlobalLoading()) {
        Text(this.readerLoadingText())
          .width('100%')
          .fontSize(12)
          .fontColor('#DADCE0')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor('#9416181A');
      }

      if (this.readerCurrentError.length > 0) {
        Row({ space: 8 }) {
          Text(this.readerCurrentError)
            .layoutWeight(1)
            .fontSize(12)
            .fontColor('#FEE4E2')
            .maxLines(2);
          Button('重试')
            .height(28)
            .fontSize(12)
            .fontColor('#E8EAED')
            .backgroundColor('#B54708')
            .borderRadius(6)
            .onClick(() => {
              this.retryCurrentReaderPage();
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#A5331818');
      }

      if (this.readerMenuVisible || !this.readerReadingFullscreen) {
        Column({ space: 10 }) {
          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text('阅读器')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#E8EAED')
                .maxLines(1);
              Text(this.readerBottomHintText())
                .fontSize(11)
                .fontColor('#9A7D8A')
                .maxLines(1);
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            this.ReaderIconButton($r('sys.symbol.eye'), '详情', true, false, (): void => {
                this.handleNativeTitleBarBack();
              });
            this.ReaderIconButton($r('sys.symbol.gearshape_fill'), this.readerSettingsVisible ? '关闭设置' : '设置', true, this.readerSettingsVisible, (): void => {
                this.toggleReaderSettingsPanel();
              });
          }
          .width('100%');

          Text(this.readerCacheSummaryText())
            .width('100%')
            .fontSize(11)
            .fontColor('#9A7D8A')
            .maxLines(1);

          Row({ space: 8 }) {
            TextInput({ text: this.readerJumpInput, placeholder: '页码' })
              .layoutWeight(1)
              .height(34)
              .backgroundColor('#4E3A45')
              .fontColor('#E8EAED')
              .borderRadius(6)
              .fontSize(13)
              .onChange((value: string) => {
                this.readerJumpInput = value;
              });
            this.ReaderIconButton($r('sys.symbol.arrow_clockwise'), '跳转', true, true, (): void => {
                void this.jumpNativeReader();
              });
            this.ReaderFilledButton(
              this.readerAutoTransferring ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'),
              this.readerAutoTransferLabel(),
              true,
              this.readerAutoTransferring,
              (): void => {
                this.toggleReaderAutoTransfer();
              }
            );
          }
          .width('100%');

          Row({ space: 8 }) {
            this.ReaderFilledButton($r('sys.symbol.chevron_left'), '上一页', this.canShiftNativeReaderBackward(), false, (): void => {
                this.goReaderPrevious();
              });
            this.ReaderIconButton($r('sys.symbol.arrow_up_left_and_arrow_down_right'), this.readerFitContain ? '填充' : '适应', true, false, (): void => {
                this.toggleReaderFit();
              });
            this.ReaderFilledButton($r('sys.symbol.chevron_right'), '下一页', this.canShiftNativeReaderForward(), true, (): void => {
                this.goReaderNext();
              });
          }
          .width('100%');

          if (this.readerSettingsVisible) {
            this.ReaderSettingsPanel();
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 14 })
        .backgroundColor('#D9111315')
        .alignItems(HorizontalAlign.Start);
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None);
  }

  @Builder
  private NativeReaderFullscreen(): void {
    ReaderFullscreenPage({
      customLightness: this.readerCustomScreenLightness,
      overlayMaskColor: this.readerOverlayMaskColor(),
      onReaderAreaChange: (_: Area, value: Area): void => {
        const nextWidth = Math.max(1, Number(value.width));
        const nextHeight = Math.max(1, Number(value.height));
        if (Math.abs(nextWidth - this.readerViewportWidth) >= 1) {
          this.readerViewportWidth = nextWidth;
        }
        if (Math.abs(nextHeight - this.readerViewportHeight) >= 1) {
          this.readerViewportHeight = nextHeight;
        }
      },
      currentLayerContent: (): void => {
        this.ReaderSwiperContent();
      },
      loadingOverlayContent: (): void => {
        this.ReaderLoadingOverlay();
      },
      controlsContent: (): void => {
        this.ReaderFullscreenControlsContent();
      }
    });
  }

  @Builder
  private ReaderInlineContent(): void {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Column({ space: 6 }) {
          Text(this.nativeDetail.title.length > 0 ? this.nativeDetail.title : '阅读器')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027')
            .maxLines(2);
          Text(this.readerCacheSummaryText())
            .fontSize(12)
            .fontColor('#6F5964')
            .maxLines(1);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);

        Text(this.readerTopPageText())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#A85474')
          .textAlign(TextAlign.End)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#F8E4ED')
          .borderRadius(14);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);

      Row({ space: 8 }) {
        TextInput({ text: this.readerJumpInput, placeholder: '页码' })
          .layoutWeight(1)
          .height(34)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .fontSize(13)
          .onChange((value: string) => {
            this.readerJumpInput = value;
          });
        Button() {
          SymbolGlyph($r('sys.symbol.arrow_clockwise'))
            .fontSize(18)
            .fontColor(['#FFFFFF']);
        }
        .width(40)
        .height(40)
        .backgroundColor('#C86B8C')
        .borderRadius(20)
        .accessibilityText('跳转')
        .onClick(() => {
            void this.jumpNativeReader();
          });
        Button() {
          SymbolGlyph($r('sys.symbol.arrow_up_left_and_arrow_down_right'))
            .fontSize(18)
            .fontColor(['#A85474']);
        }
        .width(40)
        .height(40)
        .backgroundColor('#F8E4ED')
        .borderRadius(20)
        .accessibilityText(this.readerFitContain ? '填充' : '适应')
        .onClick(() => {
            this.toggleReaderFit();
          });
        Button() {
          SymbolGlyph($r('sys.symbol.gearshape_fill'))
            .fontSize(18)
            .fontColor([this.readerSettingsVisible ? '#FFFFFF' : '#A85474']);
        }
        .width(40)
        .height(40)
        .backgroundColor(this.readerSettingsVisible ? '#C86B8C' : '#F8E4ED')
        .borderRadius(20)
        .accessibilityText(this.readerSettingsVisible ? '隐藏设置' : '设置')
        .onClick(() => {
            this.toggleReaderSettingsPanel();
          });
      }
      .width('100%');

      if (this.readerSettingsVisible) {
        Column({ space: 8 }) {
          this.ReaderSettingsPanel();
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#1E1F20')
        .borderRadius(8);
      }

      Stack({ alignContent: Alignment.Center }) {
        this.ReaderSwiperContent();
      }
      .width('100%')
      .height(500)
      .borderRadius(8)
      .clip(true)
      .backgroundColor('#FFFFFF');

      if (this.readerCurrentError.length > 0) {
        Row({ space: 8 }) {
          Text(this.readerCurrentError)
            .layoutWeight(1)
            .fontSize(12)
            .fontColor('#B42318')
            .maxLines(2);
          Button('重试')
            .height(28)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#B42318')
            .borderRadius(6)
            .onClick(() => {
              this.retryCurrentReaderPage();
            });
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFF3F2')
        .borderRadius(8);
      }

      Row({ space: 8 }) {
        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.chevron_left'))
              .fontSize(17)
              .fontColor([this.canShiftNativeReaderBackward() ? '#2B2027' : '#9A7D8A']);
            Text('上一页')
              .fontSize(12)
              .fontColor(this.canShiftNativeReaderBackward() ? '#2B2027' : '#9A7D8A');
          }
          .justifyContent(FlexAlign.Center);
        }
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.canShiftNativeReaderBackward() ? '#F3E3EA' : '#EEEEEE')
          .borderRadius(20)
          .enabled(this.canShiftNativeReaderBackward())
          .accessibilityText('上一页')
          .onClick(() => {
            this.goReaderPrevious();
          });
        Button() {
          Row({ space: 6 }) {
            Text('下一页')
              .fontSize(12)
              .fontColor(this.canShiftNativeReaderForward() ? '#FFFFFF' : '#9A7D8A');
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(17)
              .fontColor([this.canShiftNativeReaderForward() ? '#FFFFFF' : '#9A7D8A']);
          }
          .justifyContent(FlexAlign.Center);
        }
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.canShiftNativeReaderForward() ? '#C86B8C' : '#EEEEEE')
          .borderRadius(20)
          .enabled(this.canShiftNativeReaderForward())
          .accessibilityText('下一页')
          .onClick(() => {
            this.goReaderNext();
          });
      }

      Button() {
        Row({ space: 6 }) {
          SymbolGlyph($r('sys.symbol.eye'))
            .fontSize(17)
            .fontColor(['#2B2027']);
          Text('返回详情')
            .fontSize(12)
            .fontColor('#2B2027');
        }
        .justifyContent(FlexAlign.Center);
      }
        .width('100%')
        .height(40)
        .backgroundColor('#F3E3EA')
        .borderRadius(20)
        .accessibilityText('返回详情')
        .onClick(() => {
          this.handleNativeTitleBarBack();
        });
    }
    .width('100%');
  }

  @Builder
  private NativeReaderCard(): void {
    ReaderInlinePage({
      content: (): void => {
        this.ReaderInlineContent();
      }
    });
  }

  @Builder
  private NativeSection(): void {
    Scroll(this.nativeScroller) {
      Column({ space: 12 }) {
        this.SiteStatusCard();
        this.NativeHeaderCard();

        if (!this.canUseNativeSite(this.siteMode)) {
          this.NativeGateCard();
        } else {
          this.NativeSearchCard();
          this.QuickSearchCard();

          if (this.shouldShowNativeRouteLoading()) {
            this.NativeRouteLoadingPage();
          } else if (this.nativeError.length > 0) {
            Text(this.nativeError)
              .width('100%')
              .fontSize(12)
              .fontColor('#B42318')
              .padding(12)
              .backgroundColor('#FFF3F2')
              .borderRadius(8);
          } else if (this.hasActiveReaderPage()) {
            this.NativeReaderCard();
          } else if (this.nativeViewMode === 'comments' && this.nativeDetail.gid > 0) {
            this.NativeCommentsPage();
          } else if (this.nativeViewMode === 'detail' && this.nativeDetail.gid > 0) {
            this.NativeDetailCard();
          } else {
            if (this.nativeResults.length > 0 || this.nativeResultCount.length > 0) {
              Column({ space: 4 }) {
                Text(this.nativeResultCount.length > 0 ? `${this.nativeResultCount} 个结果` : `${this.nativeResults.length} 个画廊`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2B2027');
                Text(this.nativeListUrl.length > 0 ? this.nativeListUrl : EhUrl.search(this.siteMode, this.nativeQuery))
                  .fontSize(11)
                  .fontColor('#7C6470')
                  .maxLines(2);
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .alignItems(HorizontalAlign.Start);
            }

            this.LocalFilterStatusCard(this.nativeFilteredCount);
            this.NativePagerCard();

            if (this.nativeResults.length === 0) {
              Text(this.nativeFilteredCount > 0 ? '原生结果已被本地过滤规则隐藏。' : '还没有原生结果。请先搜索，或打开首页、热门、收藏。')
                .width('100%')
                .fontSize(13)
                .fontColor('#6F5964')
                .padding(12)
                .backgroundColor('#FFFFFF')
                .borderRadius(8);
            } else {
              ForEach(this.nativeResults, (item: NativeGallerySummary) => {
                this.NativeSummaryCard(item);
              }, (item: NativeGallerySummary) => `${item.gid}`);
            }
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.pageContentTopPadding(), bottom: this.pageContentBottomPadding() });
    }
    .layoutWeight(1)
    .width('100%')
    .height('100%');
  }

  @Builder
  private DownloadQueueSection(): void {
    DownloadQueueView({
      items: this.downloadItemsSource(),
      viewMode: this.effectiveDownloadViewMode(),
      managerStatus: this.effectiveDownloadManagerStatus(),
      downloadRootText: this.downloadRoot(),
      revision: this.downloadQueueRevision + this.downloadRuntimeRevision,
      imageUrlForCover: (value: string): string => this.galleryImageDisplayUrl(value),
      siteDisplayNameForItem: (item: DownloadQueueItem): string => this.siteDisplayName(item.site),
      statusLabelForItem: (item: DownloadQueueItem): string => this.downloadItemStatusLabel(item),
      statusColorForItem: (item: DownloadQueueItem): string => this.downloadItemStatusColor(item),
      progressRatioForItem: (item: DownloadQueueItem): number => this.downloadProgressRatio(item),
      progressTextForItem: (item: DownloadQueueItem): string => this.downloadProgressText(item),
      speedTextForItem: (item: DownloadQueueItem): string => formatBytesPerSecond(item.speedBytesPerSecond),
      remainingTextForItem: (item: DownloadQueueItem): string => formatRemainingSeconds(item.remainingSeconds),
      isItemRunning: (item: DownloadQueueItem): boolean => this.isDownloadItemRunning(item),
      onViewModeChange: (value: string): void => {
        this.setDownloadViewMode(value);
      },
      onStartAll: (): void => {
        this.startAllDownloads();
      },
      onPauseAll: (): void => {
        this.pauseAllDownloads();
      },
      onStartItem: (item: DownloadQueueItem): void => {
        this.startDownloadItem(item);
      },
      onPauseItem: (item: DownloadQueueItem): void => {
        this.pauseDownloadItem(item);
      },
      onOpenItemDetail: (item: DownloadQueueItem): void => {
        void this.openStoredGalleryInNative(item);
      },
      onRemoveItem: (item: DownloadQueueItem): void => {
        this.removeDownloadItem(item);
      }
    });
  }

  @Builder
  private HistoryDeleteSwipeAction(item: HistoryItem): void {
    Row({ space: 6 }) {
      SymbolGlyph($r('sys.symbol.trash'))
        .fontSize(18)
        .fontColor(['#FFFFFF']);
      Text('删除')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF');
    }
    .width(76)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#B42318')
    .onClick(() => {
      this.removeHistoryItem(item);
    });
  }

  @Builder
  private HistoryRecordRow(item: HistoryItem): void {
    Row({ space: 10 }) {
      if (item.cover.length > 0) {
        Image(this.galleryImageDisplayUrl(item.cover))
          .width(60)
          .height(86)
          .borderRadius(6)
          .clip(true)
          .objectFit(ImageFit.Cover)
          .geometryTransition(this.galleryCoverTransitionIdForRecord(item))
          .transition(TransitionEffect.OPACITY);
      } else {
        Column() {
          Text('无封面')
            .fontSize(11)
            .fontColor('#9A7D8A');
        }
        .width(60)
        .height(86)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F3E3EA')
        .borderRadius(6);
      }

      Column({ space: 6 }) {
        Text(item.title.length > 0 ? item.title : `${item.gid}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2B2027')
          .maxLines(2);
        if (item.titleJpn.length > 0 && item.titleJpn !== item.title) {
          Text(item.titleJpn)
            .fontSize(12)
            .fontColor('#7C6470')
            .maxLines(1);
        }
        Row({ space: 8 }) {
          if (item.categoryLabel.length > 0) {
            Text(item.categoryLabel.toUpperCase())
              .fontSize(10)
              .fontColor('#FFFFFF')
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .backgroundColor(categoryColor(item.categoryLabel))
              .borderRadius(9);
          }
          Text(`${item.pages}P`)
            .fontSize(11)
            .fontColor('#7C6470');
          Text(this.siteDisplayName(item.site))
            .fontSize(10)
            .fontColor('#9A7D8A')
            .maxLines(1);
        }
        .width('100%');
        Row({ space: 6 }) {
          Text(item.uploader.length > 0 ? item.uploader : '未知上传者')
            .fontSize(11)
            .fontColor('#7C6470')
            .maxLines(1);
          Text(item.visitedAt)
            .fontSize(10)
            .fontColor('#9A7D8A')
            .maxLines(1);
        }
        .width('100%');
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      void this.openStoredGalleryInNative(item);
    });
  }

  @Builder
  private HistoryEmptyRow(): void {
    Text('还没有历史记录。打开原生详情页后会自动记录。')
      .width('100%')
      .fontSize(13)
      .fontColor('#6F5964')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8);
  }

  @Builder
  private HistorySection(): void {
    List({ space: 10, scroller: this.libraryScroller }) {
      if (this.historyItems.length === 0) {
        ListItem() {
          this.HistoryEmptyRow();
        }
      } else {
        ForEach(this.historyItems, (item: HistoryItem) => {
          ListItem() {
            this.HistoryRecordRow(item);
          }
          .swipeAction({
            end: {
              builder: (): void => {
                this.HistoryDeleteSwipeAction(item);
              },
              actionAreaDistance: 76,
              onAction: (): void => {
                this.removeHistoryItem(item);
              }
            },
            edgeEffect: SwipeEdgeEffect.Spring
          })
          .selectable(false);
        }, (item: HistoryItem) => this.historyKey(item));
      }
    }
    .layoutWeight(1)
    .width('100%')
    .height('100%')
    .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER })
    .contentStartOffset(this.pageContentTopPadding())
    .contentEndOffset(this.pageContentBottomPadding())
    .backgroundColor('#FFFFFF')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring);
  }

  @Builder
  private BookmarkSection(): void {
    Column({ space: 12 }) {
      Column({ space: 8 }) {
        Text('保存的书签')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B2027');
        if (this.bookmarks.length === 0) {
          Text('还没有保存书签。打开页面后点书签即可保存。')
            .fontSize(13)
            .fontColor('#6F5964');
        } else {
          ForEach(this.bookmarks, (item: BookmarkItem) => {
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text(item.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#2B2027')
                  .maxLines(1);
                Text(item.url)
                  .fontSize(11)
                  .fontColor('#7C6470')
                  .maxLines(1);
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start);
              Button('打开')
                .height(28)
              .backgroundColor('#F8E4ED')
                .borderRadius(8)
                .onClick(() => {
                  if (item.url === EhUrl.signIn()) {
                    this.openWebSignIn();
                  } else {
                    this.openEhRouteOrInternalWeb(item.url, item.title);
                  }
                });
              Button('移除')
                .height(28)
                .backgroundColor('#FFF3F2')
                .fontColor('#B42318')
                .borderRadius(8)
                .onClick(() => {
                  this.removeBookmark(item.url);
                });
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(8);
          }, (item: BookmarkItem) => item.url);
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);

      Column({ space: 8 }) {
        Text('安卓路由映射')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B2027');
        ForEach(this.buildQuickLinks(), (item: QuickLink) => {
          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text(item.title)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2B2027');
              Text(item.description)
                .fontSize(12)
                .lineHeight(18)
                .fontColor('#6F5964');
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);
            Button('打开')
              .height(28)
              .fontColor('#FFFFFF')
              .backgroundColor('#C86B8C')
              .borderRadius(8)
              .onClick(() => {
                if (item.url === EhUrl.signIn()) {
                  this.openWebSignIn();
                } else {
                  this.openEhRouteOrInternalWeb(item.url, item.title);
                }
              });
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8);
        }, (item: QuickLink) => item.url);
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private LibraryFavoriteFilterCard(): void {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 4 }) {
          Text('收藏夹')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027');
          Text(this.favoriteFilterSummary())
            .fontSize(12)
            .fontColor('#6F5964');
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);

        Button('刷新')
          .height(28)
          .fontSize(12)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            if (this.favoriteListFilter === FAVORITE_FILTER_LOCAL) {
              this.loadLocalFavoriteGalleryList();
            } else {
              this.loadCurrentLibraryFavoriteList(true);
            }
          });
      }
      .width('100%');

      Select(this.favoriteFilterSelectOptions())
        .selected(this.favoriteFilterSelectedIndex())
        .value(this.favoriteFilterSummary())
        .height(36)
        .width('100%')
        .font({ size: 13 })
        .fontColor('#2B2027')
        .selectedOptionBgColor('#C86B8C')
        .selectedOptionFont({ size: 13, weight: FontWeight.Medium })
        .selectedOptionFontColor('#FFFFFF')
        .optionFont({ size: 13 })
        .optionBgColor('#FFFFFF')
        .optionFontColor('#2B2027')
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .onSelect((index: number, _value: string) => {
          const options = this.favoriteFilterOptions();
          if (index >= 0 && index < options.length) {
            this.setFavoriteListFilter(options[index].filter);
          }
        });
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private LibrarySection(): void {
    if (this.hasVisibleNativeSubPage()) {
      Scroll(this.libraryScroller) {
        Column({ space: 12 }) {
          this.NativeGalleryListHost();
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.pageContentTopPadding(), bottom: this.pageContentBottomPadding() });
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%');
    } else if (this.libraryPanel === LIBRARY_FAVORITES) {
      Refresh({ refreshing: $$this.isFavoriteRefreshing, offset: 64 }) {
        Scroll(this.libraryScroller) {
          Column({ space: 12 }) {
            this.NativeGalleryListHost();
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.pageContentTopPadding(), bottom: this.pageContentBottomPadding() });
        }
        .onDidScroll((_xOffset: number, _yOffset: number, _scrollState: ScrollState) => {
          this.handleLibraryFavoritesScrollProgress();
        })
        .onScrollEdge((side: Edge) => {
          this.handleLibraryFavoritesScrollEdge(side);
        })
        .layoutWeight(1)
        .width('100%')
        .height('100%');
      }
      .onRefreshing(() => {
        void this.refreshFavoriteWaterfall();
      })
      .layoutWeight(1)
      .width('100%')
      .height('100%');
    } else if (this.libraryPanel === LIBRARY_HISTORY) {
      this.HistorySection();
    } else {
      Scroll(this.libraryScroller) {
        Column({ space: 12 }) {
          this.DownloadQueueSection();
        }
        .width('100%')
        .constraintSize({ minHeight: this.downloadScrollContentMinHeight() })
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.pageContentTopPadding(), bottom: this.pageContentBottomPadding() });
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring);
    }
  }

  @Builder
  private SettingsSection(): void {
    this.SettingsSectionForPage(this.myPage);
  }

  @Builder
  private SettingsSectionForPage(page: string): void {
    Scroll(this.settingsScroller) {
      Column({ space: 10 }) {
        if (page === MY_PAGE_MY_TAGS) {
          this.MyTagsSection();
        } else if (page === MY_PAGE_IMAGE_SEARCH) {
          this.ImageSearchSection();
        } else if (page === MY_PAGE_BOOKMARKS) {
          this.BookmarkSection();
        } else if (page === MY_PAGE_ACCOUNT) {
          this.MyAccountCard();
        } else if (page === MY_PAGE_FILTERS) {
          this.FilterManagementSection();
        } else if (page === MY_PAGE_BLACKLIST) {
          this.BlacklistManagementSection();
        } else {
          this.MyAccountCard();
          PrivacySettingsCard({
            appLockEnabled: this.currentAppLockEnabled(),
            appLockAuthInProgress: this.appLockAuthInProgress,
            appLockStatus: this.appLockStatus,
            backgroundPreviewProtectionEnabled: this.currentBackgroundPreviewProtectionEnabled(),
            onAppLockChange: (isOn: boolean): void => {
              void this.setAppLockEnabled(isOn);
            },
            onBackgroundPreviewProtectionChange: (isOn: boolean): void => {
              this.setBackgroundPreviewProtectionEnabled(isOn);
            }
          });
          this.MyCacheSettingsCard();
          this.MyDownloadSettingsCard();
          this.MyLocalAccountCacheSettingsCard();
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.pageContentTopPadding(), bottom: this.pageContentBottomPadding() });
    }
    .layoutWeight(1)
    .width('100%')
    .height('100%');
  }

  @Builder
  private TopListEntryRow(entry: NativeTopListEntry, index: number): void {
    Row({ space: 10 }) {
      Text(this.topListRankLabel(entry, index))
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#C86B8C')
        .width(42)
        .textAlign(TextAlign.Start);
      if (entry.thumb.length > 0) {
        Image(this.galleryImageDisplayUrl(entry.thumb))
          .width(52)
          .height(72)
          .borderRadius(6)
          .clip(true)
          .objectFit(ImageFit.Cover);
      } else {
        Column() {
          Text('无封面')
            .fontSize(10)
            .fontColor('#9A7D8A');
        }
        .width(52)
        .height(72)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F3E3EA')
        .borderRadius(6);
      }
      Text(entry.title)
        .fontSize(14)
        .lineHeight(20)
        .fontColor('#2B2027')
        .maxLines(2)
        .layoutWeight(1);
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openTopListEntry(entry);
    });
  }

  @Builder
  private TopListSection(): void {
    Column({ space: 12 }) {
      if (this.topListLoading) {
        SystemLoadingBlock({
          message: '正在加载排行榜...',
          minHeight: 88
        });
      } else if (this.topListError.length > 0) {
        Row({ space: 8 }) {
          Text('排行榜')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027')
            .layoutWeight(1);
          Button('刷新')
            .height(28)
            .fontSize(12)
            .fontColor('#2B2027')
            .backgroundColor('#F8E4ED')
            .borderRadius(8)
            .onClick(() => {
              void this.loadTopList();
            });
        }
        .width('100%');
        Text(this.topListError)
          .fontSize(13)
          .lineHeight(20)
          .fontColor('#B42318')
          .width('100%')
          .padding(12)
          .backgroundColor('#FFF3F2')
          .borderRadius(8);
      } else if (this.topListDetail.groups.length === 0) {
        Text('还没有排行榜数据。')
          .fontSize(13)
          .fontColor('#6F5964');
      } else {
        Row({ space: 8 }) {
          Select(this.topListGroupSelectOptions())
            .selected(this.topListGroupSelectedIndex())
            .value(this.topListGroupSummary())
            .height(36)
            .layoutWeight(1)
            .font({ size: 13 })
            .fontColor('#2B2027')
            .selectedOptionBgColor('#C86B8C')
            .selectedOptionFont({ size: 13, weight: FontWeight.Medium })
            .selectedOptionFontColor('#FFFFFF')
            .optionFont({ size: 13 })
            .optionBgColor('#FFFFFF')
            .optionFontColor('#2B2027')
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
            .onSelect((index: number, _value: string) => {
              this.selectTopListGroupByIndex(index);
            });
          Button('刷新')
            .height(36)
            .fontSize(12)
            .fontColor('#2B2027')
            .backgroundColor('#F8E4ED')
            .borderRadius(8)
            .onClick(() => {
              void this.loadTopList();
            });
        }
        .width('100%');

        SegmentButton({
          options: this.topListPeriodSegmentOptions,
          selectedIndexes: $topListPeriodSelectedIndexes
        });

        if (this.currentTopListPeriod().entries.length === 0) {
          Text('当前时间范围没有排行榜条目。')
            .fontSize(13)
            .fontColor('#6F5964')
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(8);
        } else {
          Column({ space: 10 }) {
            ForEach(this.currentTopListPeriod().entries, (entry: NativeTopListEntry, index: number) => {
              this.TopListEntryRow(entry, index);
            }, (entry: NativeTopListEntry) => `${entry.rank}-${entry.url}`);
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start);
        }
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private MyTagsSection(): void {
    Column({ space: 12 }) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Column({ space: 3 }) {
            Text('我的标签')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2B2027');
            Text('读取账号标签状态，点标签直接进入原生标签搜索。')
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#7C6470');
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);
          Button('刷新')
            .height(28)
            .backgroundColor('#F8E4ED')
            .borderRadius(8)
            .onClick(() => {
              void this.loadMyTags();
            });
        }
        .width('100%');

        if (this.myTagsLoading) {
          SystemLoadingBlock({
            message: '正在加载我的标签...',
            minHeight: 88
          });
        } else if (this.myTagsError.length > 0) {
          Text(this.myTagsError)
            .fontSize(13)
            .lineHeight(20)
            .fontColor('#B42318')
            .width('100%')
            .padding(12)
            .backgroundColor('#FFF3F2')
            .borderRadius(8);
        }

        ForEach(this.myTags, (item: NativeUserTag) => {
          Row({ space: 10 }) {
            Column({ space: 5 }) {
              Text(item.tagName)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2B2027')
                .maxLines(1);
              Row({ space: 6 }) {
                Text(item.watched ? '已关注' : '未关注')
                  .fontSize(11)
                  .fontColor(item.watched ? '#FFFFFF' : '#6F5964')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor(item.watched ? '#C86B8C' : '#EEF2F1')
                  .borderRadius(6);
                Text(item.hidden ? '已隐藏' : '可见')
                  .fontSize(11)
                  .fontColor(item.hidden ? '#FFFFFF' : '#6F5964')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor(item.hidden ? '#B42318' : '#EEF2F1')
                  .borderRadius(6);
                Text(`权重 ${item.tagWeight}`)
                  .fontSize(11)
                  .fontColor('#6F5964');
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);
            if (item.color.length > 0) {
              Text(item.color)
                .fontSize(11)
                .fontColor('#6F5964')
                .maxLines(1);
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => {
            this.openUserTagSearch(item);
          });
        }, (item: NativeUserTag) => item.id);
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private ImageSearchSection(): void {
    Column({ space: 12 }) {
      Column({ space: 10 }) {
        Text('图片搜索')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B2027');
        Text('使用系统图片选择器选择本地图片，随后按安卓版 multipart 搜索流程返回原生结果列表。')
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#7C6470');

        if (this.imageSearchPath.length > 0) {
          Text(this.imageSearchPath)
            .fontSize(11)
            .lineHeight(16)
            .fontColor('#6F5964')
            .maxLines(2)
            .width('100%')
            .padding(10)
            .backgroundColor('#FFFFFF')
            .borderRadius(8);
        } else {
          Text('未选择图片')
            .fontSize(13)
            .fontColor('#6F5964');
        }

        Flex({ wrap: FlexWrap.Wrap }) {
          Button(this.imageSearchSimilar ? '相似: 开' : '相似: 关')
            .height(28)
            .margin({ right: 8, bottom: 8 })
            .fontColor(this.imageSearchSimilar ? '#FFFFFF' : '#2B2027')
            .backgroundColor(this.imageSearchSimilar ? '#C86B8C' : '#F8E4ED')
            .borderRadius(8)
            .onClick(() => {
              this.imageSearchSimilar = !this.imageSearchSimilar;
            });
          Button(this.imageSearchCovers ? '封面: 开' : '封面: 关')
            .height(28)
            .margin({ right: 8, bottom: 8 })
            .fontColor(this.imageSearchCovers ? '#FFFFFF' : '#2B2027')
            .backgroundColor(this.imageSearchCovers ? '#C86B8C' : '#F8E4ED')
            .borderRadius(8)
            .onClick(() => {
              this.imageSearchCovers = !this.imageSearchCovers;
            });
          Button(this.imageSearchExpunged ? '隐藏: 开' : '隐藏: 关')
            .height(28)
            .margin({ right: 8, bottom: 8 })
            .fontColor(this.imageSearchExpunged ? '#FFFFFF' : '#2B2027')
            .backgroundColor(this.imageSearchExpunged ? '#37474F' : '#F8E4ED')
            .borderRadius(8)
            .onClick(() => {
              this.imageSearchExpunged = !this.imageSearchExpunged;
            });
        }
        .width('100%');

        Row({ space: 8 }) {
          Button('选择图片')
            .layoutWeight(1)
            .height(28)
            .backgroundColor('#F8E4ED')
            .borderRadius(8)
            .onClick(() => {
              void this.pickImageForSearch();
            });
          Button(this.imageSearchLoading ? '搜索中...' : '搜索')
            .layoutWeight(1)
            .height(28)
            .fontColor('#FFFFFF')
            .backgroundColor('#C86B8C')
            .borderRadius(8)
            .enabled(!this.imageSearchLoading)
            .onClick(() => {
              void this.runImageSearch();
            });
        }
        .width('100%');

        if (this.imageSearchError.length > 0) {
          Text(this.imageSearchError)
            .fontSize(13)
            .lineHeight(20)
            .fontColor('#B42318')
            .width('100%')
            .padding(12)
            .backgroundColor('#FFF3F2')
            .borderRadius(8);
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private MyQuickEntry(title: string, symbol: Resource, action: string): void {
    Column({ space: 8 }) {
      SymbolGlyph(symbol)
        .fontSize(24)
        .fontColor(['#A85474']);
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2B2027')
        .maxLines(1);
    }
    .layoutWeight(1)
    .height(76)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      this.runMyActionWhenSignedIn(action);
    });
  }

  @Builder
  private MyBrandHeader(): void {
    Column({ space: 10 }) {
      Image($r('app.media.eh_logo'))
        .width(132)
        .height(132)
        .objectFit(ImageFit.Cover)
        .borderRadius(26)
        .clip(true);
      Text('E-Harmony')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027')
        .textAlign(TextAlign.Center)
        .maxLines(1);
    }
    .width('100%')
    .padding({ top: 8, bottom: 10 })
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  private MyQuickEntryCard(): void {
    Row({ space: 10 }) {
      this.MyQuickEntry('收藏夹', $r('sys.symbol.heart_fill'), 'favorites');
      this.MyQuickEntry('历史', $r('sys.symbol.clock_fill'), 'history');
      this.MyQuickEntry('下载', $r('sys.symbol.waveform_folder_fill'), 'downloads');
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8);
  }

  @Builder
  private MyControlRow(title: string, symbol: Resource, action: string, destructive: boolean = false): void {
    Row({ space: 12 }) {
      SymbolGlyph(symbol)
        .fontSize(20)
        .fontColor([destructive ? '#B42318' : '#A85474']);
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(destructive ? '#B42318' : '#2B2027')
        .layoutWeight(1);
    }
    .width('100%')
    .height(52)
    .padding({ left: 14, right: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      this.runMyActionWhenSignedIn(action);
    });
  }

  @Builder
  private MyDrawerCard(): void {
    Column({ space: 12 }) {
      this.MyQuickEntryCard();
      Column({ space: 1 }) {
        this.MyControlRow('屏蔽画廊', $r('sys.symbol.eye'), 'filters');
        this.MyControlRow('设置', $r('sys.symbol.gearshape_fill'), 'settings');
        this.MyControlRow('退出登录', $r('sys.symbol.trash'), 'logout', true);
      }
      .width('100%');
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private MyAccountCard(): void {
    Column({ space: 10 }) {
      Row() {
        Text('账户设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B2027')
          .layoutWeight(1);
        Text(this.sitePanelTitle())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.siteMode === GallerySite.EX ? '#37474F' : '#C86B8C')
          .borderRadius(8)
          .maxLines(1);
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);

      Text('目前的 Cookie')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2B2027');
      TextArea({
        text: this.currentCookieHeader(),
        placeholder: '未检测到 Cookie'
      })
        .width('100%')
        .height(104)
        .maxLines(5)
        .fontSize(12)
        .lineHeight(18)
        .fontColor(this.currentCookieHeader().length > 0 ? '#6F5964' : '#9A7D8A')
        .padding(10)
        .backgroundColor('#F8F8F8')
        .borderRadius(8)
        .onChange((value: string) => {
          this.updateSettingsCookieDraft(value);
        });

      Row({ space: 8 }) {
        Button(this.siteMode === GallerySite.EX ? '切换外站' : '切换里站')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.switchSiteAndRestart(this.siteMode === GallerySite.EX ? GallerySite.E : GallerySite.EX);
          });
        Button('我的标签')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.handleMyDrawerAction('mytags');
          });
      }
      .width('100%');
      Row({ space: 8 }) {
        Button('UConfig')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.handleMyDrawerAction('uconfig');
          });
        Button(this.privateBrowsing ? '私密浏览: 开' : '私密浏览: 关')
          .layoutWeight(1)
          .height(28)
          .fontColor(this.privateBrowsing ? '#FFFFFF' : '#2B2027')
          .backgroundColor(this.privateBrowsing ? '#C86B8C' : '#F8E4ED')
          .borderRadius(8)
          .onClick(() => {
            this.togglePrivateBrowsing();
          });
      }
      .width('100%');
      Row({ space: 8 }) {
        Button('复制 Cookie')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.copyCurrentCookie();
          });
        Button('退出登录')
          .layoutWeight(1)
          .height(28)
          .fontColor('#B42318')
          .backgroundColor('#FFF3F2')
          .borderRadius(8)
          .onClick(() => {
            this.confirmClearLocalAccountCache();
          });
      }
      .width('100%');
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private FilterRuleRow(rule: FilterRule): void {
    Row({ space: 8 }) {
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(this.filterModeLabel(rule.mode))
            .fontSize(11)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(rule.enabled ? '#C86B8C' : '#9A7D8A')
            .borderRadius(6);
          Text(rule.enabled ? '启用' : '停用')
            .fontSize(11)
            .fontColor(rule.enabled ? '#A85474' : '#7C6470');
        }
        Text(rule.text)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(rule.enabled ? '#2B2027' : '#9A7D8A')
          .maxLines(2);
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Button(rule.enabled ? '停用' : '启用')
        .height(28)
        .fontSize(12)
        .backgroundColor(rule.enabled ? '#F3E3EA' : '#F8E4ED')
        .fontColor('#2B2027')
        .borderRadius(8)
        .onClick(() => {
          void this.toggleFilterRule(rule);
        });

      Button('删除')
        .height(28)
        .fontSize(12)
        .backgroundColor('#FFF3F2')
        .fontColor('#B42318')
        .borderRadius(8)
        .onClick(() => {
          void this.deleteFilterRule(rule);
        });
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8);
  }

  @Builder
  private FilterManagementSection(): void {
    Column({ space: 12 }) {
      Column({ space: 10 }) {
        Row() {
          Column({ space: 4 }) {
            Text('过滤规则')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2B2027');
            Text('按安卓版 EhFilter 规则隐藏本地列表：标题包含、上传者精确匹配、标签和标签命名空间。')
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#7C6470');
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);
          Text(`${this.activeGalleryFilters().length}/${this.filterRules.length}`)
            .fontSize(12)
            .fontColor('#6F5964');
        }
        .width('100%');

        Select(this.filterModeSelectOptions())
          .selected(this.filterModeSelectedIndex())
          .value(this.filterModeLabel(this.filterModeDraft))
          .height(36)
          .width('100%')
          .font({ size: 13 })
          .fontColor('#2B2027')
          .selectedOptionBgColor('#C86B8C')
          .selectedOptionFont({ size: 13, weight: FontWeight.Medium })
          .selectedOptionFontColor('#FFFFFF')
          .optionFont({ size: 13 })
          .optionBgColor('#FFFFFF')
          .optionFontColor('#2B2027')
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .onSelect((index: number, _value: string) => {
            this.applyFilterModeByIndex(index);
          });

        Row({ space: 8 }) {
          TextInput({ text: this.filterTextDraft, placeholder: this.filterModePlaceholder(this.filterModeDraft) })
            .layoutWeight(1)
            .height(34)
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
            .fontSize(12)
            .onChange((value: string) => {
              this.setFilterTextDraft(value);
            });
          Button('添加')
            .height(34)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#C86B8C')
            .borderRadius(8)
            .onClick(() => {
              void this.addFilterRuleFromDraft();
            });
        }
        .width('100%');

        if (this.filterUsesTagSuggestions() && this.filterTagSuggestions.length > 0) {
          Column({ space: 0 }) {
            this.SearchSectionCardHeader('标签联想', `${this.filterTagSuggestions.length} 条`);
            ForEach(this.filterTagSuggestions, (item: TagTranslationSuggestion) => {
              this.FilterTagSuggestionRow(item);
            }, (item: TagTranslationSuggestion) => item.key);
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E8C8D6' })
          .borderRadius(8);
        }
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Start);

      Column({ space: 8 }) {
        Row() {
          Text('排除语言')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027')
            .layoutWeight(1);
          Text(`${this.excludedLanguageTags.length}`)
            .fontSize(12)
            .fontColor('#6F5964');
        }
        .width('100%');
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(EXCLUDED_LANGUAGE_OPTIONS, (option: LanguageFilterOption) => {
            Button(option.label)
              .height(28)
              .margin({ right: 8, bottom: 8 })
              .fontSize(12)
              .fontColor(this.isExcludedLanguageSelected(option.tag) ? '#FFFFFF' : '#2B2027')
              .backgroundColor(this.isExcludedLanguageSelected(option.tag) ? '#C86B8C' : '#F8E4ED')
              .borderRadius(8)
              .onClick(() => {
                this.toggleExcludedLanguage(option.tag);
              });
          }, (option: LanguageFilterOption) => option.tag);
        }
        .width('100%');
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Start);

      if (this.filterRules.length === 0) {
        Text('还没有过滤规则。添加后会立即作用于首页、搜索、收藏和原生列表。')
          .width('100%')
          .fontSize(13)
          .fontColor('#6F5964')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8);
      } else {
        ForEach(FILTER_MODE_OPTIONS, (option: FilterModeOption) => {
          if (this.filterRulesForMode(option.mode).length > 0) {
            Column({ space: 8 }) {
              Text(option.label)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2B2027');
              ForEach(this.filterRulesForMode(option.mode), (rule: FilterRule) => {
                this.FilterRuleRow(rule);
              }, (rule: FilterRule) => `${rule.id}:${rule.enabled ? '1' : '0'}`);
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .alignItems(HorizontalAlign.Start);
          }
        }, (option: FilterModeOption) => `${option.mode}`);
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private BlacklistRow(item: BlacklistItem): void {
    Row({ space: 8 }) {
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2B2027')
          .maxLines(1);
        Text(item.reason.length > 0 ? item.reason : '无备注')
          .fontSize(11)
          .fontColor('#7C6470')
          .maxLines(1);
        Text(item.addTime.length > 0 ? item.addTime : item.angryWith)
          .fontSize(10)
          .fontColor('#9A7D8A')
          .maxLines(1);
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
      Button('删除')
        .height(28)
        .fontSize(12)
        .backgroundColor('#FFF3F2')
        .fontColor('#B42318')
        .borderRadius(8)
        .onClick(() => {
          void this.deleteBlacklistItem(item);
        });
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8);
  }

  @Builder
  private BlacklistManagementSection(): void {
    Column({ space: 12 }) {
      Column({ space: 10 }) {
        Row() {
          Column({ space: 4 }) {
            Text('评论黑名单')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2B2027');
            Text('与安卓版 BlackList 对齐：命中用户名后详情页和评论页隐藏对应评论。')
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#7C6470');
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start);
          Text(`${this.blacklistItems.length}`)
            .fontSize(12)
            .fontColor('#6F5964');
        }
        .width('100%');

        TextInput({ text: this.blacklistNameDraft, placeholder: '用户名' })
          .width('100%')
          .height(34)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .fontSize(12)
          .onChange((value: string) => {
            this.blacklistNameDraft = value;
          });

        Row({ space: 8 }) {
          TextInput({ text: this.blacklistReasonDraft, placeholder: '备注，可留空' })
            .layoutWeight(1)
            .height(34)
            .backgroundColor('#F8F8F8')
            .borderRadius(8)
            .fontSize(12)
            .onChange((value: string) => {
              this.blacklistReasonDraft = value;
            });
          Button('添加')
            .height(34)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#C86B8C')
            .borderRadius(8)
            .onClick(() => {
              void this.addBlacklistFromDraft();
            });
        }
        .width('100%');
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .alignItems(HorizontalAlign.Start);

      if (this.blacklistItems.length === 0) {
        Text('还没有黑名单用户。也可以在评论页直接点“拉黑”。')
          .width('100%')
          .fontSize(13)
          .fontColor('#6F5964')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8);
      } else {
        Column({ space: 8 }) {
          ForEach(this.blacklistItems, (item: BlacklistItem) => {
            this.BlacklistRow(item);
          }, (item: BlacklistItem) => `${item.id}`);
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start);
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private MyCacheSettingsCard(): void {
    Column({ space: 10 }) {
      Text('缓存清理')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027');
      Text(this.cacheMaintenanceStatus)
        .width('100%')
        .fontSize(12)
        .fontColor('#7C6470')
        .maxLines(2);
      Row({ space: 8 }) {
        TextInput({ text: this.cacheMaxSizeInput, placeholder: '容量上限 MB' })
          .layoutWeight(1)
          .height(34)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .fontSize(12)
          .onChange((value: string) => {
            this.updateCacheMaxSizeInput(value);
          });
        TextInput({ text: this.cacheRetentionDaysInput, placeholder: '保留天数' })
          .layoutWeight(1)
          .height(34)
          .backgroundColor('#F8F8F8')
          .borderRadius(8)
          .fontSize(12)
          .onChange((value: string) => {
            this.updateCacheRetentionDaysInput(value);
          });
      }
      .width('100%');
      Row({ space: 8 }) {
        Button('按策略清理')
          .layoutWeight(1)
          .height(28)
          .fontColor('#FFFFFF')
          .backgroundColor('#C86B8C')
          .borderRadius(8)
          .onClick(() => {
            this.runCachePolicyCleanup(true);
          });
        Button('全部清理')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#FFF3F2')
          .fontColor('#B42318')
          .borderRadius(8)
          .onClick(() => {
            this.clearAllCaches();
          });
      }
      .width('100%');
      Row({ space: 8 }) {
        Button('阅读器')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.clearReaderCaches();
          });
        Button('封面图')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.clearGalleryImageCaches();
          });
        Button('搜图临时')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.clearImageSearchCaches();
          });
      }
      .width('100%');
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private MyDownloadSettingsCard(): void {
    Column({ space: 10 }) {
      Text('下载')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027');
      Text(this.downloadManagerStatus)
        .width('100%')
        .fontSize(12)
        .fontColor('#7C6470')
        .maxLines(2);
      TextInput({
        text: this.downloadDirectoryPath,
        placeholder: `默认应用目录：${this.abilityFilesDir()}/${READER_DOWNLOAD_DIR_NAME}`
      })
        .width('100%')
        .height(34)
        .backgroundColor('#F8F8F8')
        .borderRadius(8)
        .fontSize(12)
        .onChange((value: string) => {
          this.downloadDirectoryPath = value;
          this.writeValue('download_directory_path', value);
        });
      Row({ space: 8 }) {
        Button(`线程 ${this.downloadConcurrency}`)
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            const next = this.downloadConcurrency >= DOWNLOAD_MAX_CONCURRENCY ? 1 : this.downloadConcurrency + 1;
            this.downloadConcurrency = next;
            this.writeValue('download_concurrency', next);
          });
        Button(this.downloadUseOriginImage ? '原图: 开' : '原图: 关')
          .layoutWeight(1)
          .height(28)
          .fontColor(this.downloadUseOriginImage ? '#FFFFFF' : '#2B2027')
          .backgroundColor(this.downloadUseOriginImage ? '#C86B8C' : '#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.downloadUseOriginImage = !this.downloadUseOriginImage;
            this.writeValue('download_origin_image', this.downloadUseOriginImage);
          });
      }
      .width('100%');
      Row({ space: 8 }) {
        Button('导入 CSV')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.importDownloadCsv();
          });
        Button('导出 CSV')
          .layoutWeight(1)
          .height(28)
          .backgroundColor('#F3E3EA')
          .borderRadius(8)
          .onClick(() => {
            this.exportDownloadCsv();
          });
      }
      .width('100%');
      TextArea({
        text: this.downloadImportExportText,
        placeholder: 'Android CSV，可粘贴导入或导出当前下载队列'
      })
        .width('100%')
        .height(86)
        .maxLines(4)
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#6F5964')
        .padding(10)
        .backgroundColor('#F8F8F8')
        .borderRadius(8)
        .onChange((value: string) => {
          this.downloadImportExportText = value;
        });
      Button('清空下载内容')
        .width('100%')
        .height(30)
        .fontColor('#B42318')
        .backgroundColor('#FFF3F2')
        .borderRadius(8)
        .onClick(() => {
          this.confirmClearAllDownloadContent();
        });
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private MyLocalAccountCacheSettingsCard(): void {
    Column({ space: 10 }) {
      Text('本地账号缓存')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027');
      Text(this.cookieStatusSummary)
        .width('100%')
        .fontSize(12)
        .fontColor('#7C6470')
        .maxLines(2);
      Button('删除本地账号缓存')
        .width('100%')
        .height(30)
        .fontColor('#B42318')
        .backgroundColor('#FFF3F2')
        .borderRadius(8)
        .onClick(() => {
          this.confirmClearLocalAccountCache();
        });
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private MySection(): void {
    Scroll(this.myScroller) {
      Column({ space: 12 }) {
        this.MyBrandHeader();
        this.MyDrawerCard();
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: PAGE_SIDE_GUTTER, right: PAGE_SIDE_GUTTER, top: this.pageContentTopPadding(), bottom: this.pageContentBottomPadding() });
    }
    .layoutWeight(1)
    .width('100%')
    .height('100%');
  }

  private BottomTabBar(title: string, symbol: Resource): BottomTabBarStyle {
    return new BottomTabBarStyle({
      normal: new SymbolGlyphModifier(symbol)
        .fontColor(['#9A7D8A']),
      selected: new SymbolGlyphModifier(symbol)
        .fontColor(['#C86B8C'])
    }, title)
      .labelStyle({
        maxLines: 1,
        selectedColor: '#C86B8C',
        unselectedColor: '#7C6470'
      });
  }

  @Builder
  private FullScreenWebSection(): void {
    Column() {
      if (this.fullScreenWebProgress > 0 && this.fullScreenWebProgress < 100) {
        Row() {}
          .width(`${this.fullScreenWebProgress}%`)
          .height(3)
          .backgroundColor('#C86B8C');
      }
      Web({
        src: this.fullScreenWebUrl,
        controller: this.controller,
        incognitoMode: false
      })
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .databaseAccess(true)
        .cacheMode(CacheMode.Default)
        .onControllerAttached(() => {
          this.configureWebControllerForEh();
        })
        .onPageBegin((event: OnPageBeginEvent) => {
          this.addressInput = event.url;
          if (this.fullScreenWebMode !== WEB_MODE_SIGN_IN) {
            this.syncSiteModeFromUrl(event.url);
          }
          this.pageTitle = '';
          this.fullScreenWebProgress = 0;
        })
        .onPageEnd((event: OnPageEndEvent) => {
          this.addressInput = event.url;
          if (this.fullScreenWebMode !== WEB_MODE_SIGN_IN) {
            this.syncSiteModeFromUrl(event.url);
          }
          this.writeValue('last_url', event.url);
          this.syncCookiesFromWeb(event.url, this.fullScreenWebMode === WEB_MODE_SIGN_IN);
        })
        .onProgressChange((event: OnProgressChangeEvent) => {
          this.fullScreenWebProgress = event.newProgress;
        })
        .onTitleReceive((event: OnTitleReceiveEvent) => {
          this.pageTitle = event.title;
          if (this.fullScreenWebTitle.length === 0) {
            this.fullScreenWebTitle = event.title;
          }
        });
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.systemSafeTop, bottom: this.systemSafeBottom })
    .backgroundColor('#FFFFFF')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }

  @Builder
  private CurrentPrimarySection(): void {
    if (this.activeSection === NAV_HOME) {
      this.HomeSection();
    } else if (this.activeSection === NAV_SEARCH) {
      this.SearchSection();
    } else if (this.activeSection === NAV_LIBRARY) {
      this.MyNavigationHost();
    } else {
      this.SettingsSection();
    }
  }

  @Builder
  private MyNavigationHost(): void {
    if (this.myPage === MY_PAGE_MAIN) {
      this.MySection();
    } else if (this.sectionForSubPage(this.myPage) === NAV_LIBRARY) {
      this.LibrarySection();
    } else {
      this.SettingsSectionForPage(this.myPage);
    }
  }

  pageTransition() {
    PageTransitionEnter({ type: RouteType.Push, duration: 260, curve: Curve.EaseOut })
      .slide(SlideEffect.Right)
      .opacity(0);
    PageTransitionExit({ type: RouteType.Push, duration: 220, curve: Curve.EaseIn })
      .slide(SlideEffect.Left)
      .opacity(0.92);
    PageTransitionEnter({ type: RouteType.Pop, duration: 220, curve: Curve.EaseOut })
      .slide(SlideEffect.Left)
      .opacity(0);
    PageTransitionExit({ type: RouteType.Pop, duration: 220, curve: Curve.EaseIn })
      .slide(SlideEffect.Right)
      .opacity(0.92);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.isReady && this.fullScreenWebUrl.length > 0) {
        this.FullScreenWebSection();
      } else if (this.isReady && this.hasActiveReaderPage()) {
        this.NativeReaderFullscreen();
      } else {
        Column({ space: 12 }) {
          if (!this.isReady) {
            this.LaunchLoadingSection();
          } else {
            HdsNavigation() {
              if (this.shouldRenderBottomTabHost()) {
                HdsTabs({ barPosition: BarPosition.End, index: this.bottomTabIndex() }) {
                  TabContent() {
                    this.HomeSection();
                  }
                  .tabBar(this.BottomTabBar('主页', $r('sys.symbol.house_fill')));

                  TabContent() {
                    this.SearchSection();
                  }
                  .tabBar(this.BottomTabBar('搜索', $r('sys.symbol.magnifyingglass')));

                  TabContent() {
                    this.MyNavigationHost();
                  }
                  .tabBar(this.BottomTabBar('我的', $r('sys.symbol.person_crop_circle_fill')));
                }
                .layoutWeight(1)
                .width('100%')
                .vertical(false)
                .barMode(BarMode.Fixed)
                .barHeight(this.bottomTabBarHeight())
                .scrollable(false)
                .barOverlap(true)
                .barFloatingStyle({
                  adaptToHandedness: true,
                  barBottomMargin: this.systemSafeBottom,
                  systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: this.customMaterialLevel
                  }
                })
                .onTabBarClick((index: number) => {
                  this.handleBottomTabClick(index);
                })
                .onChange((index: number) => {
                  this.setActiveSection(this.sectionForBottomTabIndex(index));
                });
              } else {
                this.CurrentPrimarySection();
              }
            }
            .layoutWeight(1)
            .width('100%')
            .mode(NavigationMode.Stack)
            .titleBar(this.currentTitleBarOptions())
            .hideBackButton(!this.shouldShowNativeTitleBarBack())
            .titleMode(HdsNavigationTitleMode.MINI)
            .bindToScrollable(this.activeNavigationScrollers());
          }
        }
        .width('100%')
        .height('100%')
        .padding({ left: 0, right: 0, top: 0, bottom: 0 })
        .backgroundColor('#FFFFFF')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
      }

      if (this.shouldShowLoginGate()) {
        this.LoginGateOverlay();
      }

      if (this.shouldShowAppLockOverlay()) {
        this.AppLockOverlay();
      }
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_oldValue: Area, newValue: Area): void => {
      this.updatePageViewportSize(newValue);
    });
  }
}
