import {
  FilterModeOption,
  LanguageFilterOption,
  SearchAdvancedFlagOption,
  SearchCategoryOption,
  SearchModeOption
} from '../models/AppModels';

export const NAV_HOME: number = 0;
export const NAV_SEARCH: number = 1;
export const NAV_LIBRARY: number = 2;
export const NAV_SETTINGS: number = 3;
export const NAV_MY: number = NAV_LIBRARY;

export const LIBRARY_FAVORITES: number = 0;
export const LIBRARY_HISTORY: number = 1;
export const LIBRARY_DOWNLOADS: number = 2;

export const HOME_PAGE_DEFAULT: string = 'default';
export const HOME_PAGE_POPULAR: string = 'popular';
export const HOME_PAGE_WATCHED: string = 'watched';
export const HOME_PAGE_TOP: string = 'top';

export const QUICK_SEARCH_TABLE: string = 'quick_search';
export const SEARCH_HISTORY_TABLE: string = 'search_history';
export const HISTORY_TABLE: string = 'history';
export const BOOKMARKS_TABLE: string = 'bookmarks';
export const LOCAL_FAVORITES_TABLE: string = 'local_favorites';
export const FILTER_TABLE: string = 'filter';
export const BLACKLIST_TABLE: string = 'blacklist';
export const GALLERY_TAGS_TABLE: string = 'gallery_tags';
export const LOCAL_DATA_MIGRATION_KEY: string = 'local_data_migrated_to_rdb_v1';
export const LOCAL_DATA_MIGRATION_TIME_KEY: string = 'local_data_migrated_to_rdb_v1_at';
export const LOCAL_LIST_LOAD_LIMIT: number = 240;
export const APP_BUNDLE_NAME: string = 'com.shuyuan.ehentai';
export const APP_ABILITY_NAME: string = 'EntryAbility';
export const APP_LOCK_AUTH_ACTIVE_STORAGE_KEY: string = 'app_lock_auth_active';
export const APP_LOCK_ENABLED_KEY: string = 'app_lock_enabled';
export const APP_LOCK_FOREGROUND_REQUIRED_STORAGE_KEY: string = 'app_lock_foreground_required';
export const BACKGROUND_PREVIEW_PROTECTION_KEY: string = 'background_preview_protection_enabled';
export const DOWNLOAD_ROUTE_ACTION_KEY: string = 'downloadRouteAction';
export const DOWNLOAD_ROUTE_ACTION_ACTIVE: string = 'active';
export const DOWNLOAD_ROUTE_EVENT_STORAGE_KEY: string = 'download_route_event_id';
export const DOWNLOAD_ROUTE_TARGET_STORAGE_KEY: string = 'download_route_target';

export const MY_PAGE_MAIN: string = 'main';
export const MY_PAGE_FAVORITES: string = 'favorites';
export const MY_PAGE_DOWNLOADS: string = 'downloads';
export const MY_PAGE_HISTORY: string = 'history';
export const MY_PAGE_BOOKMARKS: string = 'bookmarks';
export const MY_PAGE_ACCOUNT: string = 'account';
export const MY_PAGE_SETTINGS: string = 'settings';
export const MY_PAGE_MY_TAGS: string = 'mytags';
export const MY_PAGE_IMAGE_SEARCH: string = 'imagesearch';
export const MY_PAGE_FILTERS: string = 'filters';
export const MY_PAGE_BLACKLIST: string = 'blacklist';

export const SEARCH_MODE_NORMAL: string = 'normal';
export const SEARCH_MODE_WATCHED: string = 'watched';
export const SEARCH_MODE_UPLOADER: string = 'uploader';
export const SEARCH_MODE_TAG: string = 'tag';
export const SEARCH_ADV_FLAG_NAME: number = 1 << 0;
export const SEARCH_ADV_FLAG_TAGS: number = 1 << 1;
export const SEARCH_ADV_FLAG_DESCRIPTION: number = 1 << 2;
export const SEARCH_ADV_FLAG_TORRENT: number = 1 << 3;
export const SEARCH_ADV_FLAG_LOW_POWER_TAGS: number = 1 << 4;
export const SEARCH_ADV_FLAG_EXPUNGED: number = 1 << 5;
export const SEARCH_ADV_FLAG_DOWNVOTED: number = 1 << 6;
export const SEARCH_ADV_FLAG_FILE_NAME: number = 1 << 7;
export const SEARCH_ADV_FLAG_UPLOADER: number = 1 << 8;
export const SEARCH_ADV_FLAG_TORRENT_FILE: number = 1 << 9;

export const FILTER_MODE_TITLE: number = 0;
export const FILTER_MODE_UPLOADER: number = 1;
export const FILTER_MODE_TAG: number = 2;
export const FILTER_MODE_TAG_NAMESPACE: number = 3;
export const FILTER_MODE_OPTIONS: FilterModeOption[] = [
  { label: '标题', mode: FILTER_MODE_TITLE, placeholder: '标题包含的关键词' },
  { label: '上传者', mode: FILTER_MODE_UPLOADER, placeholder: '完整上传者名称' },
  { label: '标签', mode: FILTER_MODE_TAG, placeholder: 'tag 或 namespace:tag' },
  { label: '标签命名空间', mode: FILTER_MODE_TAG_NAMESPACE, placeholder: 'artist / language / female 等' }
];

export const EXCLUDED_LANGUAGE_KEY: string = 'excluded_language_tags';
export const EXCLUDED_LANGUAGE_OPTIONS: LanguageFilterOption[] = [
  { label: '日文', tag: 'japanese', code: 'JAPANESE' },
  { label: '英文', tag: 'english', code: 'EN' },
  { label: '中文', tag: 'chinese', code: 'ZH' },
  { label: '荷兰文', tag: 'dutch', code: 'NL' },
  { label: '法文', tag: 'french', code: 'FR' },
  { label: '德文', tag: 'german', code: 'DE' },
  { label: '匈牙利文', tag: 'hungarian', code: 'HU' },
  { label: '意大利文', tag: 'italian', code: 'IT' },
  { label: '韩文', tag: 'korean', code: 'KO' },
  { label: '波兰文', tag: 'polish', code: 'PL' },
  { label: '葡萄牙文', tag: 'portuguese', code: 'PT' },
  { label: '俄文', tag: 'russian', code: 'RU' },
  { label: '西班牙文', tag: 'spanish', code: 'ES' },
  { label: '泰文', tag: 'thai', code: 'TH' },
  { label: '越南文', tag: 'vietnamese', code: 'VI' },
  { label: '无语言', tag: 'n/a', code: 'N/A' },
  { label: '其他', tag: 'other', code: 'OTHER' }
];

export const SEARCH_MODE_OPTIONS: SearchModeOption[] = [
  { label: '普通', mode: SEARCH_MODE_NORMAL },
  { label: '关注', mode: SEARCH_MODE_WATCHED },
  { label: '上传者', mode: SEARCH_MODE_UPLOADER },
  { label: '标签', mode: SEARCH_MODE_TAG }
];

export const WEB_MODE_SIGN_IN: string = 'sign_in';
export const WEB_MODE_UCONFIG: string = 'uconfig';
export const COOKIE_PERSIST_MAX_AGE_SECONDS: number = 60 * 60 * 24 * 365 * 10;
export const SIGN_IN_COOKIE_RETRY_DELAYS: number[] = [300, 900, 1800, 3200, 5000];
export const WEB_SIGN_IN_RESET_COOKIE_NAMES: string[] = ['ipb_member_id', 'ipb_pass_hash', 'igneous'];
export const WEB_SIGN_IN_CLOUDFLARE_HOSTS: string[] = ['e-hentai.org', 'repo.e-hentai.org', 'forums.e-hentai.org'];
export const SEARCH_HISTORY_MAX_COUNT: number = 100;
export const SEARCH_HISTORY_SUGGEST_LIMIT: number = 128;
export const TAG_SUGGEST_LIMIT: number = 40;
export const GALLERY_LIST_TIMEOUT_MS: number = 20000;
export const HOME_CONTENT_UNAVAILABLE_MESSAGE: string = '无法获取内容，请检查网络连接。';

export const FAVORITE_LOCAL_SLOT: number = -1;
export const FAVORITE_INVALID_DEFAULT_SLOT: number = 99;
export const FAVORITE_DEFAULT_SLOT_KEY: string = 'default_favorite_slot';
export const FAVORITE_CATEGORY_NAMES_KEY: string = 'favorite_category_names';
export const FAVORITE_CATEGORY_COUNTS_KEY: string = 'favorite_category_counts';
export const FAVORITE_RECENT_FILTER_KEY: string = 'recent_favorite_filter';
export const FAVORITE_FILTER_ALL: number = -1;
export const FAVORITE_FILTER_LOCAL: number = -2;
export const FAVORITE_BAR_WIDTH: number = 168;
export const FAVORITE_BAR_PADDING: number = 8;
export const FAVORITE_BAR_GAP: number = 8;
export const FAVORITE_BAR_ICON_WIDTH: number = 36;
export const FAVORITE_BAR_SELECT_WIDTH: number =
  FAVORITE_BAR_WIDTH - FAVORITE_BAR_PADDING * 2 - FAVORITE_BAR_GAP - FAVORITE_BAR_ICON_WIDTH;
export const FAVORITE_BAR_FONT_SIZE: number = 10;
export const FAVORITE_SLOT_NAMES: string[] = [
  '收藏 0',
  '收藏 1',
  '收藏 2',
  '收藏 3',
  '收藏 4',
  '收藏 5',
  '收藏 6',
  '收藏 7',
  '收藏 8',
  '收藏 9'
];
export const EMPTY_FAVORITE_CATEGORY_COUNTS: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
export const DETAIL_TORRENT_DIR_NAME: string = 'torrents';

export const READER_KEY_SCREEN_ROTATION: string = 'screen_rotation';
export const READER_KEY_READING_DIRECTION: string = 'reading_direction';
export const READER_KEY_PAGE_SCALING: string = 'page_scaling';
export const READER_KEY_START_POSITION: string = 'start_position';
export const READER_KEY_START_TRANSFER_TIME: string = 'start_transfer_time';
export const READER_KEY_KEEP_SCREEN_ON: string = 'keep_screen_on';
export const READER_KEY_SHOW_CLOCK: string = 'gallery_show_clock';
export const READER_KEY_SHOW_PROGRESS: string = 'gallery_show_progress';
export const READER_KEY_SHOW_BATTERY: string = 'gallery_show_battery';
export const READER_KEY_SHOW_PAGE_INTERVAL: string = 'gallery_show_page_interval';
export const READER_KEY_VOLUME_PAGE: string = 'volume_page';
export const READER_KEY_REVERSE_VOLUME_PAGE: string = 'reverse_volume_page';
export const READER_KEY_FULLSCREEN: string = 'reading_fullscreen';
export const READER_KEY_CUSTOM_LIGHTNESS: string = 'custom_screen_lightness';
export const READER_KEY_SCREEN_LIGHTNESS: string = 'screen_lightness';
export const READER_KEY_PRELOAD_IMAGE: string = 'preload_image';
export const READER_KEY_DOWNLOAD_ORIGIN_IMAGE: string = 'download_origin_image';
export const READER_PROGRESS_KEY: string = 'reader_progress_by_gallery';
export const READER_DEFAULT_PRELOAD_IMAGE: number = 5;
export const READER_MAX_PRELOAD_IMAGE: number = 20;
export const READER_PRELOAD_SIDE_COUNT: number = 5;
export const READER_HTML_PREFETCH_CONCURRENCY: number = 2;
export const READER_IMAGE_PREFETCH_CONCURRENCY: number = 2;
export const READER_CACHE_DIR_NAME: string = 'reader-cache';
export const GALLERY_IMAGE_CACHE_DIR_NAME: string = 'gallery-image-cache';
export const READER_DOWNLOAD_DIR_NAME: string = 'downloads';
export const READER_IMAGE_EXTENSIONS: string[] = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];

export const CACHE_KEY_MAX_SIZE_MB: string = 'cache_max_size_mb';
export const CACHE_KEY_RETENTION_DAYS: string = 'cache_retention_days';
export const CACHE_DEFAULT_MAX_SIZE_MB: number = 512;
export const CACHE_DEFAULT_RETENTION_DAYS: number = 30;
export const CACHE_MIN_MAX_SIZE_MB: number = 64;
export const CACHE_MAX_MAX_SIZE_MB: number = 4096;
export const CACHE_MIN_RETENTION_DAYS: number = 1;
export const CACHE_MAX_RETENTION_DAYS: number = 365;
export const CACHE_CATEGORY_READER: string = 'reader';
export const CACHE_CATEGORY_GALLERY: string = 'gallery';
export const CACHE_CATEGORY_IMAGE_SEARCH: string = 'image-search';

export const PREVIEW_THUMB_WIDTH: number = 80;
export const PREVIEW_THUMB_HEIGHT: number = 112;
export const BOTTOM_NAV_SAFE_FALLBACK: number = 0;
export const HDS_MINI_TITLE_BAR_HEIGHT: number = 56;
export const FLOATING_BOTTOM_TAB_BAR_HEIGHT: number = 64;
export const PAGE_SIDE_GUTTER: number = 10;
export const PAGE_BOTTOM_SPACING: number = 12;

export const READER_ROTATION_VALUES: string[] = ['0', '1', '2', '3'];
export const READER_DIRECTION_VALUES: string[] = ['0', '1', '2'];
export const READER_SCALING_VALUES: string[] = ['0', '1', '2', '3', '4'];
export const READER_START_POSITION_VALUES: string[] = ['0', '1', '2', '3', '4'];

export const CATEGORY_MISC: number = 0x1;
export const CATEGORY_DOUJINSHI: number = 0x2;
export const CATEGORY_MANGA: number = 0x4;
export const CATEGORY_ARTIST_CG: number = 0x8;
export const CATEGORY_GAME_CG: number = 0x10;
export const CATEGORY_IMAGE_SET: number = 0x20;
export const CATEGORY_COSPLAY: number = 0x40;
export const CATEGORY_ASIAN_PORN: number = 0x80;
export const CATEGORY_NON_H: number = 0x100;
export const CATEGORY_WESTERN: number = 0x200;
export const CATEGORY_ALL: number = 0x3ff;
export const SEARCH_CATEGORY_OPTIONS: SearchCategoryOption[] = [
  { label: '同人志', bit: CATEGORY_DOUJINSHI },
  { label: '漫画', bit: CATEGORY_MANGA },
  { label: '画师 CG', bit: CATEGORY_ARTIST_CG },
  { label: '游戏 CG', bit: CATEGORY_GAME_CG },
  { label: '西方', bit: CATEGORY_WESTERN },
  { label: '非 H', bit: CATEGORY_NON_H },
  { label: '图集', bit: CATEGORY_IMAGE_SET },
  { label: 'Cosplay', bit: CATEGORY_COSPLAY },
  { label: '亚洲成人', bit: CATEGORY_ASIAN_PORN },
  { label: '其他', bit: CATEGORY_MISC }
];
export const SEARCH_ADVANCED_FLAG_OPTIONS: SearchAdvancedFlagOption[] = [
  { label: '标题', flag: 'name' },
  { label: '标签', flag: 'tags' },
  { label: '描述', flag: 'desc' },
  { label: '种子', flag: 'torrent' },
  { label: '低权重标签', flag: 'low' },
  { label: '已删除图库', flag: 'expunged' },
  { label: '低评分图库', flag: 'downvoted' },
  { label: '文件名', flag: 'filename' },
  { label: '上传者', flag: 'uploader' },
  { label: '种子文件', flag: 'torrentfile' }
];
