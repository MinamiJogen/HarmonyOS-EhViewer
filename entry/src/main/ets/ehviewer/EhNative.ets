import http from '@ohos.net.http';
import webview from '@ohos.web.webview';
import fileIo from '@ohos.file.fs';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppNetworkProxy } from '../network/AppNetworkProxy';

const DOMAIN = 0x0000;
const LOG_TAG = 'EhNative';

interface NativeRequestErrorInfo {
  code?: number | string;
  message?: string;
  data?: string;
  name?: string;
}

function isMeaningfulErrorMessage(message: string): boolean {
  const value = message.replace('Error: ', '').trim();
  const lower = value.toLowerCase();
  return value.length > 0 &&
    lower !== 'undefined' &&
    lower !== 'null' &&
    lower !== 'object' &&
    lower !== 'object object' &&
    lower !== '[object object]';
}

function nativeRequestErrorMessage(error: Object | string | undefined, fallback: string): string {
  const raw = `${error}`.replace('Error: ', '').trim();
  if (isMeaningfulErrorMessage(raw)) {
    return raw;
  }
  if (error !== undefined && typeof error === 'object') {
    const info = error as NativeRequestErrorInfo;
    const parts: string[] = [];
    const code = `${info.code}`.trim();
    const message = `${info.message}`.replace('Error: ', '').trim();
    const data = `${info.data}`.trim();
    const name = `${info.name}`.trim();
    if (isMeaningfulErrorMessage(code)) {
      parts.push(`code=${code}`);
    }
    if (isMeaningfulErrorMessage(message)) {
      parts.push(message);
    }
    if (isMeaningfulErrorMessage(data)) {
      parts.push(data);
    }
    if (isMeaningfulErrorMessage(name)) {
      parts.push(name);
    }
    if (parts.length > 0) {
      return parts.join(' ');
    }
    try {
      const json = JSON.stringify(error);
      if (isMeaningfulErrorMessage(json)) {
        return json;
      }
    } catch (jsonError) {
    }
  }
  return fallback;
}

export class GallerySite {
  static readonly E: string = 'e';
  static readonly EX: string = 'ex';
}

export interface NativeTagGroup {
  name: string;
  tags: string[];
}

export interface NativeGalleryComment {
  id: number;
  user: string;
  posted: string;
  body: string;
  score: number;
  voteState: string;
  editable: boolean;
  voteUpAble: boolean;
  voteUpEd: boolean;
  voteDownAble: boolean;
  voteDownEd: boolean;
}

export interface TagTranslationSuggestion {
  key: string;
  translation: string;
  display: string;
  namespace: string;
  tag: string;
}

export interface NativeFavoriteSlot {
  slot: number;
  name: string;
  count?: number;
}

export interface NativeRateResult {
  rating: number;
  ratingCount: number;
}

export interface NativeVoteCommentResult {
  id: number;
  score: number;
  vote: number;
  expectVote: number;
}

export interface NativeTorrentItem {
  url: string;
  name: string;
  posted: string;
  size: string;
  seeds: string;
}

export interface NativeArchiveItem {
  res: string;
  name: string;
}

export interface NativeArchiveList {
  formParamOr: string;
  items: NativeArchiveItem[];
}

interface NativeGalleryIdentity {
  gid: number;
  token: string;
  detailUrl: string;
}

export interface NativeGallerySummary {
  gid: number;
  token: string;
  title: string;
  titleJpn: string;
  thumb: string;
  categoryLabel: string;
  posted: string;
  uploader: string;
  rating: number;
  pages: number;
  simpleTags: string[];
  simpleLanguage: string;
  detailUrl: string;
}

export interface NativeGalleryListResult {
  items: NativeGallerySummary[];
  requestUrl: string;
  resultCount: string;
  firstUrl: string;
  prevUrl: string;
  nextUrl: string;
  lastUrl: string;
  favoriteSlots?: NativeFavoriteSlot[];
}

export interface NativeGalleryDetail {
  gid: number;
  token: string;
  title: string;
  titleJpn: string;
  cover: string;
  categoryLabel: string;
  posted: string;
  uploader: string;
  rating: number;
  ratingCount: number;
  pages: number;
  favoriteCount: number;
  isFavorited: boolean;
  favoriteName: string;
  apiUid: number;
  apiKey: string;
  torrentCount: number;
  torrentUrl: string;
  archiveUrl: string;
  visible: string;
  language: string;
  fileSize: string;
  parentUrl: string;
  detailUrl: string;
  previewPageCount: number;
  tagGroups: NativeTagGroup[];
  comments: NativeGalleryComment[];
  hasMoreComments: boolean;
}

export interface NativeGalleryPreview {
  position: number;
  pageUrl: string;
  thumbUrl: string;
  pageLabel: string;
  thumbWidth: number;
  thumbHeight: number;
  thumbOffsetX: number;
  thumbOffsetY: number;
}

export interface NativeGalleryPreviewPage {
  items: NativeGalleryPreview[];
  pageIndex: number;
  pageCount: number;
}

export interface NativeGalleryImagePage {
  pageIndex: number;
  pageLabel: string;
  pageUrl: string;
  imageUrl: string;
  originImageUrl: string;
  skipHathKey?: string;
}

export interface NativeTopListEntry {
  rank: string;
  score: string;
  title: string;
  url: string;
  gid: number;
  token: string;
  thumb: string;
}

export interface NativeTopListEntryPageResult {
  items: NativeTopListEntry[];
  requestUrl: string;
  firstUrl: string;
  prevUrl: string;
  nextUrl: string;
  lastUrl: string;
}

export interface NativeTopListPeriod {
  label: string;
  follow: string;
  url: string;
  entries: NativeTopListEntry[];
}

export interface NativeTopListGroup {
  title: string;
  periods: NativeTopListPeriod[];
}

export interface NativeTopListDetail {
  title: string;
  groups: NativeTopListGroup[];
}

export interface NativeUserTag {
  id: string;
  tagName: string;
  color: string;
  tagWeight: number;
  watched: boolean;
  hidden: boolean;
}

export function createEmptyNativeGalleryDetail(): NativeGalleryDetail {
  return {
    gid: 0,
    token: '',
    title: '',
    titleJpn: '',
    cover: '',
    categoryLabel: '',
    posted: '',
    uploader: '',
    rating: -1,
    ratingCount: 0,
    pages: 0,
    favoriteCount: 0,
    isFavorited: false,
    favoriteName: '',
    apiUid: -1,
    apiKey: '',
    torrentCount: 0,
    torrentUrl: '',
    archiveUrl: '',
    visible: '',
    language: '',
    fileSize: '',
    parentUrl: '',
    detailUrl: '',
    previewPageCount: 0,
    tagGroups: [],
    comments: [],
    hasMoreComments: false
  };
}

type JsonPrimitive = string | number | boolean | null;
type JsonValue = JsonPrimitive | JsonObject | JsonArray;
type JsonObject = Object;
type JsonArray = JsonValue[];

interface NativeFormField {
  name: string;
  value: string;
}

export class EhUrl {
  static readonly DOMAIN_E: string = 'https://e-hentai.org/';
  static readonly DOMAIN_EX: string = 'https://exhentai.org/';
  static readonly DOMAIN_FORUMS: string = 'https://forums.e-hentai.org/';

  static home(site: string): string {
    return site === GallerySite.EX ? `${EhUrl.DOMAIN_EX}home.php` : `${EhUrl.DOMAIN_E}home.php`;
  }

  static galleryFront(site: string): string {
    return EhUrl.host(site);
  }

  static popular(site: string): string {
    return site === GallerySite.EX ? `${EhUrl.DOMAIN_EX}popular` : `${EhUrl.DOMAIN_E}popular`;
  }

  static favorites(site: string): string {
    return site === GallerySite.EX ? `${EhUrl.DOMAIN_EX}favorites.php` : `${EhUrl.DOMAIN_E}favorites.php`;
  }

  static watched(site: string): string {
    return site === GallerySite.EX ? `${EhUrl.DOMAIN_EX}watched` : `${EhUrl.DOMAIN_E}watched`;
  }

  static topList(): string {
    // Android 端固定走 E 站排行榜；EX 不提供 toplist 入口。
    return `${EhUrl.DOMAIN_E}toplist.php`;
  }

  static myTags(site: string): string {
    return site === GallerySite.EX ? `${EhUrl.DOMAIN_EX}mytags` : `${EhUrl.DOMAIN_E}mytags`;
  }

  static uConfig(site: string): string {
    return site === GallerySite.EX ? `${EhUrl.DOMAIN_EX}uconfig.php` : `${EhUrl.DOMAIN_E}uconfig.php`;
  }

  static news(): string {
    return `${EhUrl.DOMAIN_E}news.php`;
  }

  static signIn(): string {
    return 'https://forums.e-hentai.org/index.php?act=Login';
  }

  static api(site: string): string {
    return site === GallerySite.EX ? `${EhUrl.DOMAIN_EX}api.php` : `${EhUrl.DOMAIN_E}api.php`;
  }

  static host(site: string): string {
    return site === GallerySite.EX ? EhUrl.DOMAIN_EX : EhUrl.DOMAIN_E;
  }

  static referer(site: string): string {
    return site === GallerySite.EX ? 'https://exhentai.org' : 'https://e-hentai.org';
  }

  static origin(site: string): string {
    return EhUrl.referer(site);
  }

  static search(site: string, query: string): string {
    const trimmed = query.trim();
    if (trimmed.length === 0) {
      return EhUrl.host(site);
    }
    return `${EhUrl.host(site)}?f_search=${encodeURIComponent(trimmed)}`;
  }

  static galleryDetail(site: string, gid: number, token: string): string {
    return `${EhUrl.host(site)}g/${gid}/${token}/`;
  }

  static galleryComments(site: string, gid: number, token: string): string {
    return `${EhUrl.galleryDetail(site, gid, token)}?hc=1`;
  }

  static addFavorites(site: string, gid: number, token: string): string {
    return `${EhUrl.host(site)}gallerypopups.php?gid=${gid}&t=${token}&act=addfav`;
  }

  static downloadArchive(site: string, gid: number, token: string, formParamOr: string): string {
    const suffix = formParamOr.length > 0 ? `&or=${encodeURIComponent(formParamOr)}` : '';
    return `${EhUrl.host(site)}archiver.php?gid=${gid}&token=${token}${suffix}`;
  }

  static normalize(site: string, raw: string): string {
    const value = decodeHtml(raw).trim();
    if (value.length === 0) {
      return '';
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('//')) {
      return `https:${value}`;
    }
    if (value.startsWith('/')) {
      return `${EhUrl.host(site)}${value.substring(1)}`;
    }
    return `${EhUrl.host(site)}${value}`;
  }

  static cookieTargets(): string[] {
    return [EhUrl.DOMAIN_FORUMS, EhUrl.DOMAIN_E, EhUrl.DOMAIN_EX];
  }

  static siteLabel(site: string): string {
    return site === GallerySite.EX ? 'EXHENTAI' : 'E-HENTAI';
  }
}

interface ParsedListShell {
  identities: NativeGalleryIdentity[];
  resultCount: string;
  firstUrl: string;
  prevUrl: string;
  nextUrl: string;
  lastUrl: string;
  favoriteSlots: NativeFavoriteSlot[];
}

interface ParsedPagerLink {
  label: string;
  url: string;
  selected: boolean;
}

const DETAIL_LINK_PATTERN: RegExp = /href=["']([^"']*\/(?:g|mpv)\/(\d+)\/([0-9a-f]{10})[^"']*)["']/gi;
const GALLERY_QUERY_IDENTITY_PATTERN: RegExp =
  /(?:[?&]|&amp;)gid=(\d+)(?:&amp;|&)t=([0-9a-f]{10})(?=[^0-9a-f]|$)/gi;
const RESULT_COUNT_PATTERN: RegExp = /Found\s+(.+?)\s+results/i;
const PREVIEW_LINK_PATTERN: RegExp =
  /<a[^>]+href=["']([^"']*\/s\/[0-9a-f]{10}\/\d+-\d+[^"']*)["'][^>]*>([\s\S]*?)<\/a>/gi;
const IMAGE_URL_PATTERN: RegExp = /<img[^>]*src="([^"]+)" style/i;
const ORIGIN_IMAGE_URL_PATTERN: RegExp = /<a href="([^"]+)fullimg([^"]+)">/i;
const PAGE_URL_PATTERN: RegExp = /\/s\/([0-9a-f]{10})\/(\d+)-(\d+)/i;
const SKIP_HATH_KEY_PATTERN: RegExp = /return\s+nl\(['"]([^'"]+)['"]\)/i;
const DETAIL_SCRIPT_PATTERN: RegExp =
  /var gid = (\d+);[\s\S]+?var token = "([a-f0-9]+)";[\s\S]+?var apiuid = ([\-\d]+);[\s\S]+?var apikey = "([a-f0-9]+)";/i;
const TORRENT_PATTERN: RegExp =
  /<a[^>]*onclick=["']return\s+popUp\('([^']+)'[\s\S]*?["'][^>]*>\s*Torrent Download\s*\((\d+)\)\s*<\/a>/i;
const ARCHIVE_PATTERN: RegExp =
  /<a[^<>]*onclick="return popUp\('([^']+)'[^)]+\)">Archive Download<\/a>/i;
const COMMENT_PATTERN: RegExp =
  /<div class="c1"[\s\S]*?<div class="c3">Posted on ([^<]+?)(?: by:\s*&nbsp;\s*<a[^>]*>([^<]*)<\/a>)?[\s\S]*?<div class="c6"[^>]*>([\s\S]*?)<\/div>\s*<div class="c[78]"/gi;
const COMMENT_ANCHOR_SPLIT_PATTERN: RegExp = /<a[^>]+name=["']c(\d+)["'][^>]*>\s*<\/a>/gi;
const TORRENT_ROW_PATTERN: RegExp = /<tr[^>]*>([\s\S]*?)<\/tr>/gi;
const TORRENT_LINK_PATTERN: RegExp = /<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/i;
const ARCHIVE_FORM_PATTERN: RegExp = /<form id=["']hathdl_form["'] action=["'][^"']*?or=([^="']*?)["'] method=["']post["']>/i;
const ARCHIVE_ITEM_PATTERN: RegExp = /<a href=["'][^"']*["'] onclick=["']return do_hathdl\(['"]([0-9]+|org)['"]\)["']>([^<]+)<\/a>/gi;
const TAG_TRANSLATION_SOURCE_URL: string =
  'https://raw.githubusercontent.com/xiaojieonly/EhTagTranslation/main/tag-translations/tag-translations-zh-rCN.json';
const TAG_TRANSLATION_SHA1_URL: string =
  'https://raw.githubusercontent.com/xiaojieonly/EhTagTranslation/main/tag-translations/tag-translations-zh-rCN.json.sha1';
const TAG_TRANSLATION_BACKUP_SOURCE_URL: string =
  'https://raw.githubusercontent.com/Mapaler/EhViewer/tag-translations/tag-translations/tag-translations-zh-rCN';
const TAG_TRANSLATION_BACKUP_SHA1_URL: string =
  'https://raw.githubusercontent.com/Mapaler/EhViewer/tag-translations/tag-translations/tag-translations-zh-rCN.sha1';
const TAG_TRANSLATION_BUNDLED_SHA1: string = 'fe57518cec3a79604631a96f742ff0d33c1359c8';
const BASE64_ALPHABET: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

const TAG_NAMESPACE_PREFIXES: Array<Array<string>> = [
  ['rows', 'n:'],
  ['artist', 'a:'],
  ['cosplayer', 'cos:'],
  ['character', 'c:'],
  ['female', 'f:'],
  ['group', 'g:'],
  ['language', 'l:'],
  ['male', 'm:'],
  ['misc', ''],
  ['mixed', 'x:'],
  ['other', 'o:'],
  ['parody', 'p:'],
  ['reclass', 'r:']
];

const FALLBACK_TAG_TRANSLATIONS: Array<Array<string>> = [
  ['n:artist', '艺术家'],
  ['n:cosplayer', '角色扮演者'],
  ['n:character', '角色'],
  ['n:female', '女性'],
  ['n:group', '社团'],
  ['n:language', '语言'],
  ['n:male', '男性'],
  ['n:misc', '杂项'],
  ['n:mixed', '混合'],
  ['n:other', '其他'],
  ['n:parody', '原作'],
  ['n:reclass', '重分类'],
  ['f:sole female', '单女'],
  ['m:sole male', '单男'],
  ['f:big breasts', '巨乳'],
  ['f:large breasts', '大胸'],
  ['f:full color', '全彩'],
  ['m:full color', '全彩'],
  ['l:chinese', '中文'],
  ['l:english', '英语'],
  ['l:japanese', '日语'],
  ['l:korean', '韩语'],
  ['l:translated', '翻译'],
  ['l:rewrite', '改写'],
  ['x:full color', '全彩'],
  ['o:multi-work series', '多作品系列'],
  ['r:compilation', '合集']
];

function decodeHtml(value: string): string {
  let nextValue = value
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, '\'')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&nbsp;/g, ' ');
  nextValue = nextValue.replace(/&#(\d+);/g, (_full: string, code: string): string => {
    const numericCode = Number(code);
    return Number.isFinite(numericCode) ? String.fromCharCode(numericCode) : '';
  });
  return nextValue;
}

function namespaceToPrefix(namespace: string): string | undefined {
  for (const item of TAG_NAMESPACE_PREFIXES) {
    if (item[0] === namespace) {
      return item[1];
    }
  }
  return undefined;
}

function prefixToNamespace(prefix: string): string | undefined {
  for (const item of TAG_NAMESPACE_PREFIXES) {
    if (item[1] === prefix) {
      return item[0];
    }
  }
  return undefined;
}

function splitTagKey(key: string): Array<string> {
  const separatorIndex = key.indexOf(':');
  if (separatorIndex < 0) {
    return ['', key];
  }
  return [key.substring(0, separatorIndex), key.substring(separatorIndex + 1)];
}

function normalizeTranslationKey(key: string): string {
  const parts = splitTagKey(key);
  const prefix = parts[0];
  const tag = parts[1];
  if (prefix === 'n') {
    return key;
  }
  const namespace = prefixToNamespace(`${prefix}:`);
  if (namespace && namespace.length > 0) {
    return `${namespace}:${tag}`;
  }
  return key;
}

function decodeUtf8Bytes(bytes: number[]): string {
  let result = '';
  let index = 0;
  while (index < bytes.length) {
    const first = bytes[index];
    if (first < 0x80) {
      result += String.fromCharCode(first);
      index++;
    } else if ((first & 0xe0) === 0xc0 && index + 1 < bytes.length) {
      const code = ((first & 0x1f) << 6) | (bytes[index + 1] & 0x3f);
      result += String.fromCharCode(code);
      index += 2;
    } else if ((first & 0xf0) === 0xe0 && index + 2 < bytes.length) {
      const code = ((first & 0x0f) << 12) | ((bytes[index + 1] & 0x3f) << 6) | (bytes[index + 2] & 0x3f);
      result += String.fromCharCode(code);
      index += 3;
    } else if ((first & 0xf8) === 0xf0 && index + 3 < bytes.length) {
      const codePoint = ((first & 0x07) << 18) | ((bytes[index + 1] & 0x3f) << 12) |
        ((bytes[index + 2] & 0x3f) << 6) | (bytes[index + 3] & 0x3f);
      const shifted = codePoint - 0x10000;
      result += String.fromCharCode(0xd800 + (shifted >> 10), 0xdc00 + (shifted & 0x3ff));
      index += 4;
    } else {
      index++;
    }
  }
  return result;
}

function decodeBase64Utf8(value: string): string {
  const cleanValue = value.replace(/[^A-Za-z0-9+/=]/g, '');
  const bytes: number[] = [];
  for (let index = 0; index + 3 < cleanValue.length; index += 4) {
    const first = BASE64_ALPHABET.indexOf(cleanValue.charAt(index));
    const second = BASE64_ALPHABET.indexOf(cleanValue.charAt(index + 1));
    const thirdChar = cleanValue.charAt(index + 2);
    const fourthChar = cleanValue.charAt(index + 3);
    const third = thirdChar === '=' ? 0 : BASE64_ALPHABET.indexOf(thirdChar);
    const fourth = fourthChar === '=' ? 0 : BASE64_ALPHABET.indexOf(fourthChar);
    if (first < 0 || second < 0 || third < 0 || fourth < 0) {
      continue;
    }
    bytes.push((first << 2) | (second >> 4));
    if (thirdChar !== '=') {
      bytes.push(((second & 0x0f) << 4) | (third >> 2));
    }
    if (fourthChar !== '=') {
      bytes.push(((third & 0x03) << 6) | fourth);
    }
  }
  return decodeUtf8Bytes(bytes);
}

function stripTags(value: string): string {
  return decodeHtml(value.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ')).trim();
}

function stripQuery(value: string): string {
  const queryIndex = value.indexOf('?');
  return queryIndex >= 0 ? value.substring(0, queryIndex) : value;
}

function fileNameFromPath(value: string): string {
  const cleanValue = stripQuery(value);
  const separator = Math.max(cleanValue.lastIndexOf('/'), cleanValue.lastIndexOf('\\'));
  const rawName = separator >= 0 ? cleanValue.substring(separator + 1) : cleanValue;
  const decodedName = decodeURIComponent(rawName);
  if (decodedName.length === 0) {
    return 'image.jpg';
  }
  return decodedName.indexOf('.') >= 0 ? decodedName : `${decodedName}.jpg`;
}

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function toJsonObject(value: JsonValue | undefined): JsonObject | undefined {
  if (value === null || value === undefined || Array.isArray(value) || typeof value !== 'object') {
    return undefined;
  }
  return value as JsonObject;
}

function getJsonValue(objectValue: JsonObject, key: string): JsonValue | undefined {
  return Reflect.get(objectValue, key) as JsonValue | undefined;
}

function getJsonString(objectValue: JsonObject, key: string, fallback: string = ''): string {
  const value = getJsonValue(objectValue, key);
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number') {
    return `${value}`;
  }
  return fallback;
}

function getJsonNumber(objectValue: JsonObject, key: string, fallback: number = 0): number {
  const value = getJsonValue(objectValue, key);
  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : fallback;
  }
  if (typeof value === 'string') {
    const numericValue = Number(value);
    return Number.isFinite(numericValue) ? numericValue : fallback;
  }
  return fallback;
}

function getJsonArray(objectValue: JsonObject, key: string): JsonArray {
  const value = getJsonValue(objectValue, key);
  return Array.isArray(value) ? value : [];
}

function getJsonStringArray(objectValue: JsonObject, key: string): string[] {
  const arrayValue = getJsonArray(objectValue, key);
  const result: string[] = [];
  for (const item of arrayValue) {
    if (typeof item === 'string') {
      result.push(item);
    }
  }
  return result;
}

function formatUnixSeconds(value: string): string {
  const seconds = Number(value);
  if (!Number.isFinite(seconds) || seconds <= 0) {
    return '';
  }
  const date = new Date(seconds * 1000);
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function normalizeLanguageTag(tag: string): string {
  const rawValue = tag.toLowerCase();
  switch (rawValue) {
    case 'english':
      return 'EN';
    case 'chinese':
      return 'ZH';
    case 'spanish':
      return 'ES';
    case 'korean':
      return 'KO';
    case 'russian':
      return 'RU';
    case 'french':
      return 'FR';
    case 'portuguese':
      return 'PT';
    case 'thai':
      return 'TH';
    case 'german':
      return 'DE';
    case 'italian':
      return 'IT';
    case 'vietnamese':
      return 'VI';
    case 'polish':
      return 'PL';
    case 'hungarian':
      return 'HU';
    case 'dutch':
      return 'NL';
    default:
      return rawValue.toUpperCase();
  }
}

function inferLanguage(tags: string[], title: string): string {
  for (const tag of tags) {
    if (tag.startsWith('language:')) {
      return normalizeLanguageTag(tag.substring('language:'.length));
    }
  }
  if (/\[(chinese|汉化|中文)\]/i.test(title)) {
    return 'ZH';
  }
  if (/\[(english|eng)\]/i.test(title)) {
    return 'EN';
  }
  return '';
}

function groupTags(tags: string[]): NativeTagGroup[] {
  const groups: NativeTagGroup[] = [];
  for (const tag of tags) {
    let groupName = 'misc';
    let nextTag = tag;
    const separatorIndex = tag.indexOf(':');
    if (separatorIndex >= 0) {
      groupName = tag.substring(0, separatorIndex);
      nextTag = tag.substring(separatorIndex + 1);
    }
    let groupIndex = -1;
    for (let index = 0; index < groups.length; index++) {
      if (groups[index].name === groupName) {
        groupIndex = index;
        break;
      }
    }
    if (groupIndex < 0) {
      groups.push({
        name: groupName,
        tags: [nextTag]
      });
    } else {
      groups[groupIndex].tags.push(nextTag);
    }
  }
  return groups;
}

function findAnchorById(html: string, id: string, site: string): string {
  const patterns: RegExp[] = [
    new RegExp(`<a[^>]*id="${id}"[^>]*href="([^"]+)"[^>]*>`, 'i'),
    new RegExp(`<a[^>]*href="([^"]+)"[^>]*id="${id}"[^>]*>`, 'i')
  ];
  for (const pattern of patterns) {
    const match = pattern.exec(html);
    if (match && match[1]) {
      return EhUrl.normalize(site, match[1]);
    }
  }
  return '';
}

function parsePagerLinks(html: string, site: string): ParsedPagerLink[] {
  const tableMatch = /<table[^>]+class=["'][^"']*pt[bt][^"']*["'][^>]*>([\s\S]*?)<\/table>/i.exec(html);
  if (!tableMatch || !tableMatch[1]) {
    return [];
  }
  const links: ParsedPagerLink[] = [];
  const cellPattern: RegExp = /<td([^>]*)>([\s\S]*?)<\/td>/gi;
  let cellMatch: RegExpExecArray | null = cellPattern.exec(tableMatch[1]);
  while (cellMatch !== null) {
    const attributes = cellMatch[1] || '';
    const body = cellMatch[2] || '';
    const hrefMatch = /<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/i.exec(body);
    if (hrefMatch && hrefMatch[1]) {
      links.push({
        label: stripTags(hrefMatch[2] || ''),
        url: EhUrl.normalize(site, hrefMatch[1]),
        selected: attributes.indexOf('ptds') >= 0
      });
    }
    cellMatch = cellPattern.exec(tableMatch[1]);
  }
  return links;
}

function numericPagerLabel(value: string): number {
  const numeric = Number(value.replace(/[^0-9]/g, ''));
  return Number.isFinite(numeric) ? numeric : 0;
}

function findPagerUrl(html: string, site: string, target: string): string {
  const links = parsePagerLinks(html, site);
  if (links.length === 0) {
    return '';
  }
  if (target === 'next' || target === 'prev') {
    const targetLabel = target === 'next' ? '>' : '<';
    for (const link of links) {
      if (link.label === targetLabel) {
        return link.url;
      }
    }
    const selectedIndex = links.findIndex((link: ParsedPagerLink): boolean => link.selected);
    const adjacentIndex = target === 'next' ? selectedIndex + 1 : selectedIndex - 1;
    if (selectedIndex >= 0 && adjacentIndex >= 0 && adjacentIndex < links.length) {
      return links[adjacentIndex].url;
    }
    return '';
  }

  let selectedUrl = '';
  for (const link of links) {
    if (numericPagerLabel(link.label) <= 0) {
      continue;
    }
    selectedUrl = link.url;
    if (target === 'first') {
      return selectedUrl;
    }
  }
  return target === 'last' ? selectedUrl : '';
}

function hasClassToken(classValue: string, token: string): boolean {
  return classValue
    .split(/\s+/)
    .map((item: string) => item.trim())
    .filter((item: string) => item.length > 0)
    .indexOf(token) >= 0;
}

function findMatchingDivEnd(html: string, contentStart: number): number {
  const tagPattern: RegExp = /<\/?div\b[^>]*>/gi;
  tagPattern.lastIndex = contentStart;
  let depth = 1;
  let match: RegExpExecArray | null = tagPattern.exec(html);
  while (match !== null) {
    const tag = match[0] || '';
    if (tag.startsWith('</')) {
      depth--;
      if (depth === 0) {
        return tagPattern.lastIndex;
      }
    } else {
      depth++;
    }
    match = tagPattern.exec(html);
  }
  return -1;
}

function extractDivSegmentsByClass(html: string, classToken: string): Array<Array<string>> {
  const segments: Array<Array<string>> = [];
  const pattern: RegExp = /<div\b[^>]*class=["']([^"']+)["'][^>]*>/gi;
  let match: RegExpExecArray | null = pattern.exec(html);
  while (match !== null) {
    const classValue = match[1] || '';
    if (!hasClassToken(classValue, classToken)) {
      match = pattern.exec(html);
      continue;
    }
    const endIndex = findMatchingDivEnd(html, pattern.lastIndex);
    if (endIndex > match.index) {
      segments.push([classValue, html.substring(match.index, endIndex)]);
      pattern.lastIndex = endIndex;
    }
    match = pattern.exec(html);
  }
  return segments;
}

function extractDirectChildDivTexts(segment: string): string[] {
  const firstTagEnd = segment.indexOf('>');
  const lastClose = segment.lastIndexOf('</div>');
  if (firstTagEnd < 0 || lastClose <= firstTagEnd) {
    return [];
  }
  const inner = segment.substring(firstTagEnd + 1, lastClose);
  const texts: string[] = [];
  const tagPattern: RegExp = /<\/?div\b[^>]*>/gi;
  let depth = 0;
  let childStart = -1;
  let match: RegExpExecArray | null = tagPattern.exec(inner);
  while (match !== null) {
    const tag = match[0] || '';
    if (!tag.startsWith('</')) {
      if (depth === 0) {
        childStart = match.index;
      }
      depth++;
    } else if (depth > 0) {
      depth--;
      if (depth === 0 && childStart >= 0) {
        texts.push(stripTags(inner.substring(childStart, tagPattern.lastIndex)));
        childStart = -1;
      }
    }
    match = tagPattern.exec(inner);
  }
  return texts;
}

function parseFavoriteSlots(html: string): NativeFavoriteSlot[] {
  const slots: NativeFavoriteSlot[] = [];
  const segments = extractDivSegmentsByClass(html, 'fp');
  for (const segment of segments) {
    const classValue = segment[0] || '';
    if (hasClassToken(classValue, 'fps')) {
      continue;
    }
    const childTexts = extractDirectChildDivTexts(segment[1] || '');
    if (childTexts.length < 3) {
      continue;
    }
    const countMatch = /(\d+)/.exec(childTexts[0] || '');
    const slot = slots.length;
    if (slot >= 10) {
      break;
    }
    slots.push({
      slot,
      name: childTexts[2] && childTexts[2].trim().length > 0 ? childTexts[2].trim() : `收藏 ${slot}`,
      count: countMatch && countMatch[1] ? Number(countMatch[1]) : 0
    });
  }
  return slots;
}

function appendGalleryIdentity(
  identities: NativeGalleryIdentity[],
  seenKeys: string[],
  site: string,
  gidValue: string,
  tokenValue: string,
  detailUrl: string = ''
): void {
  const gid = Number(gidValue);
  const token = tokenValue.toLowerCase();
  const key = `${gid}:${token}`;
  if (!Number.isFinite(gid) || gid <= 0 || token.length === 0 || seenKeys.indexOf(key) >= 0) {
    return;
  }
  seenKeys.push(key);
  identities.push({
    gid,
    token,
    detailUrl: detailUrl.length > 0 ? EhUrl.normalize(site, detailUrl) : EhUrl.galleryDetail(site, gid, token)
  });
}

function parseGalleryListShell(html: string, site: string): ParsedListShell {
  const identities: NativeGalleryIdentity[] = [];
  const seenKeys: string[] = [];
  DETAIL_LINK_PATTERN.lastIndex = 0;
  let match: RegExpExecArray | null = DETAIL_LINK_PATTERN.exec(html);
  while (match !== null) {
    appendGalleryIdentity(identities, seenKeys, site, match[2] || '', match[3] || '', match[1] || '');
    match = DETAIL_LINK_PATTERN.exec(html);
  }
  GALLERY_QUERY_IDENTITY_PATTERN.lastIndex = 0;
  let queryMatch: RegExpExecArray | null = GALLERY_QUERY_IDENTITY_PATTERN.exec(html);
  while (queryMatch !== null) {
    appendGalleryIdentity(identities, seenKeys, site, queryMatch[1] || '', queryMatch[2] || '');
    queryMatch = GALLERY_QUERY_IDENTITY_PATTERN.exec(html);
  }

  const resultCountMatch = RESULT_COUNT_PATTERN.exec(html);
  const firstUrl = findAnchorById(html, 'uFirst', site);
  const prevUrl = findAnchorById(html, 'uprev', site);
  const nextUrl = findAnchorById(html, 'unext', site);
  const lastUrl = findAnchorById(html, 'ulast', site);
  return {
    identities,
    resultCount: resultCountMatch && resultCountMatch[1] ? stripTags(resultCountMatch[1]) : '',
    firstUrl: firstUrl.length > 0 ? firstUrl : findPagerUrl(html, site, 'first'),
    prevUrl: prevUrl.length > 0 ? prevUrl : findPagerUrl(html, site, 'prev'),
    nextUrl: nextUrl.length > 0 ? nextUrl : findPagerUrl(html, site, 'next'),
    lastUrl: lastUrl.length > 0 ? lastUrl : findPagerUrl(html, site, 'last'),
    favoriteSlots: html.indexOf('favorites.php') >= 0 ? parseFavoriteSlots(html) : []
  };
}

function parseGDataResponse(body: string, site: string, identities: NativeGalleryIdentity[]): NativeGallerySummary[] {
  const parsed = JSON.parse(body) as JsonObject;
  const metadata = getJsonArray(parsed, 'gmetadata');
  const summaries: NativeGallerySummary[] = [];

  for (let index = 0; index < metadata.length; index++) {
    const item = toJsonObject(metadata[index]);
    if (!item) {
      continue;
    }
    const gid = Number(getJsonString(item, 'gid', '0'));
    const token = getJsonString(item, 'token', identities[index] ? identities[index].token : '');
    const simpleTags = getJsonStringArray(item, 'tags');
    const title = getJsonString(item, 'title', '');
    summaries.push({
      gid,
      token,
      title,
      titleJpn: getJsonString(item, 'title_jpn', ''),
      thumb: getJsonString(item, 'thumb', ''),
      categoryLabel: getJsonString(item, 'category', ''),
      posted: formatUnixSeconds(getJsonString(item, 'posted', '0')),
      uploader: getJsonString(item, 'uploader', ''),
      rating: Number(getJsonString(item, 'rating', '-1')),
      pages: Number(getJsonString(item, 'filecount', '0')),
      simpleTags,
      simpleLanguage: inferLanguage(simpleTags, title),
      detailUrl: identities[index] ? identities[index].detailUrl : EhUrl.galleryDetail(site, gid, token)
    });
  }

  return summaries;
}

function createSummaryFromIdentity(site: string, identity: NativeGalleryIdentity): NativeGallerySummary {
  return {
    gid: identity.gid,
    token: identity.token,
    title: '',
    titleJpn: '',
    thumb: '',
    categoryLabel: '',
    posted: '',
    uploader: '',
    rating: 0,
    pages: 0,
    simpleTags: [],
    simpleLanguage: '',
    detailUrl: identity.detailUrl.length > 0 ? identity.detailUrl : EhUrl.galleryDetail(site, identity.gid, identity.token)
  };
}

function gallerySummaryKey(gid: number, token: string): string {
  return `${gid}:${token.toLowerCase()}`;
}

function findGalleryInlineSegment(html: string, identity: NativeGalleryIdentity): string {
  const marker = `/${identity.gid}/${identity.token}`;
  const lowerHtml = html.toLowerCase();
  const index = lowerHtml.indexOf(marker.toLowerCase());
  if (index < 0) {
    return '';
  }
  const rowStart = html.lastIndexOf('<tr', index);
  const rowEnd = html.indexOf('</tr>', index);
  if (rowStart >= 0 && rowEnd > index) {
    return html.substring(rowStart, rowEnd + 5);
  }
  const itemStart = Math.max(0, html.lastIndexOf('<div', index));
  const itemEnd = Math.min(html.length, index + 5000);
  return html.substring(itemStart, itemEnd);
}

function extractFirstGroup(segment: string, pattern: RegExp): string {
  const match = pattern.exec(segment);
  return match && match[1] ? decodeHtml(match[1]).trim() : '';
}

function extractInlineTitle(segment: string): string {
  const glink = extractFirstGroup(segment, /<div[^>]+class=["'][^"']*\bglink\b[^"']*["'][^>]*>([\s\S]*?)<\/div>/i);
  if (glink.length > 0) {
    return stripTags(glink);
  }
  const glname = extractFirstGroup(segment, /<div[^>]+class=["'][^"']*\bglname\b[^"']*["'][^>]*>([\s\S]*?)<\/div>/i);
  if (glname.length > 0) {
    return stripTags(glname);
  }
  const anchor = extractFirstGroup(segment, /<a[^>]+href=["'][^"']*\/(?:g|mpv)\/\d+\/[0-9a-f]{10}[^"']*["'][^>]*>([\s\S]*?)<\/a>/i);
  return anchor.length > 0 ? stripTags(anchor) : '';
}

function extractInlineThumb(segment: string): string {
  const dataSrc = extractFirstGroup(segment, /<img[^>]+data-src=["']([^"']+)["']/i);
  if (dataSrc.length > 0) {
    return dataSrc;
  }
  const src = extractFirstGroup(segment, /<img[^>]+src=["']([^"']+)["']/i);
  if (src.length > 0 && src.indexOf('blank.gif') < 0) {
    return src;
  }
  return extractFirstGroup(segment, /background(?:-image)?:\s*url\(["']?([^"')]+)["']?\)/i);
}

function extractInlineCategory(segment: string): string {
  const category = extractFirstGroup(segment, /<div[^>]+class=["'][^"']*\bcn\b[^"']*["'][^>]*>([\s\S]*?)<\/div>/i);
  if (category.length > 0) {
    return stripTags(category);
  }
  const knownCategories: string[] = [
    'Doujinshi', 'Manga', 'Artist CG', 'Game CG', 'Western',
    'Non-H', 'Image Set', 'Cosplay', 'Asian Porn', 'Misc'
  ];
  for (const item of knownCategories) {
    if (segment.indexOf(`>${item}<`) >= 0 || segment.indexOf(`\t${item}`) >= 0) {
      return item;
    }
  }
  return '';
}

function extractInlinePosted(segment: string): string {
  const match = /(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2})/.exec(stripTags(segment));
  return match && match[1] ? match[1] : '';
}

function extractInlineUploader(segment: string): string {
  const uploader = extractFirstGroup(segment, /<a[^>]+href=["'][^"']*\/uploader\/[^"']+["'][^>]*>([\s\S]*?)<\/a>/i);
  if (uploader.length > 0) {
    return stripTags(uploader);
  }
  const simple = /<\/a>\s*<\/td>\s*<td[^>]*>([^<]+)<\/td>/i.exec(segment);
  return simple && simple[1] ? decodeHtml(simple[1]).trim() : '';
}

function extractInlinePages(segment: string): number {
  const match = /(\d+)\s+pages?/i.exec(stripTags(segment));
  if (!match || !match[1]) {
    return 0;
  }
  const pages = Number(match[1]);
  return Number.isFinite(pages) ? pages : 0;
}

function extractInlineTags(segment: string): string[] {
  const tags: string[] = [];
  const tagPattern: RegExp = /<div[^>]+class=["'][^"']*\bgt\w*\b[^"']*["'][^>]*title=["']([^"']+)["'][^>]*>/gi;
  let match: RegExpExecArray | null = tagPattern.exec(segment);
  while (match !== null) {
    const tag = match[1] ? decodeHtml(match[1]).trim() : '';
    if (tag.length > 0 && tags.indexOf(tag) < 0) {
      tags.push(tag);
    }
    match = tagPattern.exec(segment);
  }
  if (tags.length > 0) {
    return tags;
  }
  const text = stripTags(segment);
  const textTagPattern: RegExp = /\b(?:f|m|a|c|g|p|l|o|r|x):[a-z0-9][a-z0-9 _-]*/gi;
  let textMatch: RegExpExecArray | null = textTagPattern.exec(text);
  while (textMatch !== null) {
    const tag = textMatch[0] ? textMatch[0].trim() : '';
    if (tag.length > 0 && tags.indexOf(tag) < 0) {
      tags.push(tag);
    }
    textMatch = textTagPattern.exec(text);
  }
  return tags;
}

function createInlineSummary(site: string, identity: NativeGalleryIdentity, html: string): NativeGallerySummary {
  const segment = findGalleryInlineSegment(html, identity);
  if (segment.length === 0) {
    return createSummaryFromIdentity(site, identity);
  }
  const tags = extractInlineTags(segment);
  const title = extractInlineTitle(segment);
  return {
    gid: identity.gid,
    token: identity.token,
    title,
    titleJpn: '',
    thumb: extractInlineThumb(segment),
    categoryLabel: extractInlineCategory(segment),
    posted: extractInlinePosted(segment),
    uploader: extractInlineUploader(segment),
    rating: 0,
    pages: extractInlinePages(segment),
    simpleTags: tags,
    simpleLanguage: inferLanguage(tags, title),
    detailUrl: identity.detailUrl.length > 0 ? identity.detailUrl : EhUrl.galleryDetail(site, identity.gid, identity.token)
  };
}

function mergeSummaryWithInline(summary: NativeGallerySummary, fallback: NativeGallerySummary): NativeGallerySummary {
  return {
    gid: summary.gid > 0 ? summary.gid : fallback.gid,
    token: summary.token.length > 0 ? summary.token : fallback.token,
    title: summary.title.length > 0 ? summary.title : fallback.title,
    titleJpn: summary.titleJpn.length > 0 ? summary.titleJpn : fallback.titleJpn,
    thumb: summary.thumb.length > 0 ? summary.thumb : fallback.thumb,
    categoryLabel: summary.categoryLabel.length > 0 ? summary.categoryLabel : fallback.categoryLabel,
    posted: summary.posted.length > 0 ? summary.posted : fallback.posted,
    uploader: summary.uploader.length > 0 ? summary.uploader : fallback.uploader,
    rating: summary.rating > 0 ? summary.rating : fallback.rating,
    pages: summary.pages > 0 ? summary.pages : fallback.pages,
    simpleTags: summary.simpleTags.length > 0 ? summary.simpleTags : fallback.simpleTags,
    simpleLanguage: summary.simpleLanguage.length > 0 ? summary.simpleLanguage : fallback.simpleLanguage,
    detailUrl: summary.detailUrl.length > 0 ? summary.detailUrl : fallback.detailUrl
  };
}

function findSummaryByIdentity(items: NativeGallerySummary[], identity: NativeGalleryIdentity): NativeGallerySummary | undefined {
  const key = gallerySummaryKey(identity.gid, identity.token);
  for (const item of items) {
    if (gallerySummaryKey(item.gid, item.token) === key) {
      return item;
    }
  }
  return undefined;
}

function mergeGalleryListSummaries(
  site: string,
  html: string,
  identities: NativeGalleryIdentity[],
  apiItems: NativeGallerySummary[]
): NativeGallerySummary[] {
  const merged: NativeGallerySummary[] = [];
  for (const identity of identities) {
    const inline = createInlineSummary(site, identity, html);
    const apiItem = findSummaryByIdentity(apiItems, identity);
    merged.push(apiItem ? mergeSummaryWithInline(apiItem, inline) : inline);
  }
  return merged;
}

function createDetailFromSummary(summary: NativeGallerySummary): NativeGalleryDetail {
  return {
    gid: summary.gid,
    token: summary.token,
    title: summary.title,
    titleJpn: summary.titleJpn,
    cover: summary.thumb,
    categoryLabel: summary.categoryLabel,
    posted: summary.posted,
    uploader: summary.uploader,
    rating: summary.rating,
    ratingCount: 0,
    pages: summary.pages,
    favoriteCount: 0,
    isFavorited: false,
    favoriteName: '',
    apiUid: -1,
    apiKey: '',
    torrentCount: 0,
    torrentUrl: '',
    archiveUrl: '',
    visible: '',
    language: summary.simpleLanguage,
    fileSize: '',
    parentUrl: '',
    detailUrl: summary.detailUrl,
    previewPageCount: 0,
    tagGroups: groupTags(summary.simpleTags),
    comments: [],
    hasMoreComments: false
  };
}

function extractInnerText(html: string, pattern: RegExp): string {
  const match = pattern.exec(html);
  return match && match[1] ? stripTags(match[1]) : '';
}

function extractDetailCell(html: string, label: string): string {
  const rows = parseGalleryDetailRows(html);
  for (const row of rows) {
    const key = row[0];
    if (key.startsWith(label)) {
      return row[1];
    }
  }
  return '';
}

function extractDetailHref(html: string, label: string, site: string): string {
  const rows = parseGalleryDetailRows(html);
  for (const row of rows) {
    const key = row[0];
    if (!key.startsWith(label)) {
      continue;
    }
    const hrefMatch = /<a[^>]+href=["']([^"']+)["'][^>]*>/i.exec(row[2]);
    return hrefMatch && hrefMatch[1] ? EhUrl.normalize(site, hrefMatch[1]) : '';
  }
  return '';
}

function findMatchingElementEnd(html: string, tagName: string, contentStart: number): number {
  const tagPattern = new RegExp(`</?${tagName}\\b[^>]*>`, 'gi');
  tagPattern.lastIndex = contentStart;
  let depth = 1;
  let match: RegExpExecArray | null = tagPattern.exec(html);
  while (match !== null) {
    const tag = match[0] || '';
    if (tag.startsWith('</')) {
      depth--;
      if (depth === 0) {
        return tagPattern.lastIndex;
      }
    } else {
      depth++;
    }
    match = tagPattern.exec(html);
  }
  return -1;
}

function extractElementSegmentById(html: string, id: string): string {
  const pattern = new RegExp(`<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*id=["']${escapeRegex(id)}["'][^>]*>`, 'i');
  const match = pattern.exec(html);
  if (!match || !match[1]) {
    return '';
  }
  const contentStart = match.index + (match[0] || '').length;
  const endIndex = findMatchingElementEnd(html, match[1].toLowerCase(), contentStart);
  return endIndex > match.index ? html.substring(match.index, endIndex) : '';
}

function stripNestedText(value: string): string {
  return stripTags(value
    .replace(/<a\b[\s\S]*?<\/a>/gi, ' ')
    .replace(/<span\b[\s\S]*?<\/span>/gi, ' ')
    .replace(/<div\b[\s\S]*?<\/div>/gi, ' '));
}

function parseGalleryDetailRows(html: string): Array<Array<string>> {
  const gdd = extractElementSegmentById(html, 'gdd');
  const source = gdd.length > 0 ? gdd : html;
  const rows: Array<Array<string>> = [];
  const rowPattern: RegExp =
    /<tr[^>]*>\s*<td[^>]*>([\s\S]*?)<\/td>\s*<td[^>]*>([\s\S]*?)<\/td>\s*<\/tr>/gi;
  let match: RegExpExecArray | null = rowPattern.exec(source);
  while (match !== null) {
    const rawKey = match[1] || '';
    const rawValue = match[2] || '';
    const key = stripTags(rawKey).replace(/:$/, '').trim();
    const value = stripNestedText(rawValue);
    if (key.length > 0) {
      rows.push([key, value, rawValue]);
    }
    match = rowPattern.exec(source);
  }
  return rows;
}

function parseFavoriteCount(value: string): number {
  switch (value) {
    case 'Never':
      return 0;
    case 'Once':
      return 1;
    default: {
      const match = /([\d,]+)/.exec(value);
      return match && match[1] ? Number(match[1].replace(/,/g, '')) : 0;
    }
  }
}

function parseGalleryTagGroups(html: string): NativeTagGroup[] {
  const tagList = extractElementSegmentById(html, 'taglist');
  if (tagList.length === 0) {
    return [];
  }
  const groups: NativeTagGroup[] = [];
  const rowPattern: RegExp =
    /<tr[^>]*>\s*<td[^>]*>([\s\S]*?)<\/td>\s*<td[^>]*>([\s\S]*?)<\/td>\s*<\/tr>/gi;
  let rowMatch: RegExpExecArray | null = rowPattern.exec(tagList);
  while (rowMatch !== null) {
    const rawNamespace = rowMatch[1] || '';
    const rawTags = rowMatch[2] || '';
    const namespace = stripTags(rawNamespace).replace(/:$/, '').trim();
    const tags: string[] = [];
    const seenTags: Record<string, boolean> = {};
    const appendTag = (rawValue: string): void => {
      const rawTag = stripTags(rawValue);
      const separatorIndex = rawTag.indexOf('|');
      const tag = (separatorIndex >= 0 ? rawTag.substring(0, separatorIndex) : rawTag).trim();
      if (tag.length > 0 && !seenTags[tag]) {
        seenTags[tag] = true;
        tags.push(tag);
      }
    };
    const tagPattern: RegExp = /<a\b[^>]*>([\s\S]*?)<\/a>/gi;
    let tagMatch: RegExpExecArray | null = tagPattern.exec(rawTags);
    while (tagMatch !== null) {
      appendTag(tagMatch[1] || '');
      tagMatch = tagPattern.exec(rawTags);
    }
    const divPattern: RegExp = /<div\b[^>]*>([\s\S]*?)<\/div>/gi;
    let divMatch: RegExpExecArray | null = divPattern.exec(rawTags);
    while (divMatch !== null) {
      appendTag(divMatch[1] || '');
      divMatch = divPattern.exec(rawTags);
    }
    if (tags.length === 0) {
      const plainTags = stripTags(rawTags).split(/\s{2,}|\n|\t/g);
      for (const plainTag of plainTags) {
        appendTag(plainTag);
      }
    }
    if (namespace.length > 0 && tags.length > 0) {
      groups.push({
        name: namespace,
        tags
      });
    }
    rowMatch = rowPattern.exec(tagList);
  }
  return groups;
}

function extractDivByClass(segment: string, className: string): string {
  const pattern = new RegExp(`<div[^>]*class=["'][^"']*${escapeRegex(className)}[^"']*["'][^>]*>([\\s\\S]*?)<\\/div>`, 'i');
  const match = pattern.exec(segment);
  return match && match[1] ? match[1] : '';
}

function extractCommentActionLink(segment: string, label: string): string {
  const pattern = new RegExp(`<a[^>]*>[\\s\\S]*?${escapeRegex(label)}[\\s\\S]*?<\\/a>`, 'i');
  const match = pattern.exec(segment);
  return match && match[0] ? match[0] : '';
}

function parseCommentScore(segment: string): number {
  const value = stripTags(extractDivByClass(segment, 'c5'));
  const match = /[-+]?\d+/.exec(value);
  return match && match[0] ? Number(match[0]) : 0;
}

function parseGalleryCommentSegment(id: number, segment: string): NativeGalleryComment | undefined {
  const c3 = extractDivByClass(segment, 'c3');
  const c4 = extractDivByClass(segment, 'c4');
  const c6 = extractDivByClass(segment, 'c6');
  const body = stripTags(c6);
  const rawPosted = stripTags(c3);
  let posted = rawPosted.replace(/^Posted on\s*/i, '').trim();
  const byIndex = posted.indexOf(' by:');
  if (byIndex >= 0) {
    posted = posted.substring(0, byIndex).trim();
  }
  const userMatch = /by:\s*&nbsp;\s*<a[^>]*>([\s\S]*?)<\/a>/i.exec(c3) ||
    /by:\s*<a[^>]*>([\s\S]*?)<\/a>/i.exec(c3);
  const user = userMatch && userMatch[1] ? stripTags(userMatch[1]) : stripTags(c4);
  const voteUpLink = extractCommentActionLink(c4, 'Vote+');
  const voteDownLink = extractCommentActionLink(c4, 'Vote-');
  if (body.length === 0 && user.length === 0) {
    return undefined;
  }
  return {
    id,
    user: user.length > 0 ? user : 'Uploader',
    posted,
    body,
    score: parseCommentScore(segment),
    voteState: stripTags(extractDivByClass(segment, 'c7')),
    editable: />\s*Edit\s*</i.test(c4),
    voteUpAble: voteUpLink.length > 0,
    voteUpEd: voteUpLink.length > 0 && /style=["'][^"']+["']/i.test(voteUpLink),
    voteDownAble: voteDownLink.length > 0,
    voteDownEd: voteDownLink.length > 0 && /style=["'][^"']+["']/i.test(voteDownLink)
  };
}

function parseGalleryComments(html: string, limit: number = 8): NativeGalleryComment[] {
  const comments: NativeGalleryComment[] = [];
  COMMENT_ANCHOR_SPLIT_PATTERN.lastIndex = 0;
  const pieces = html.split(COMMENT_ANCHOR_SPLIT_PATTERN);
  if (pieces.length > 1) {
    for (let index = 1; index + 1 < pieces.length; index += 2) {
      const id = Number(pieces[index]);
      const segment = pieces[index + 1];
      const comment = parseGalleryCommentSegment(Number.isFinite(id) ? id : 0, segment);
      if (comment) {
        comments.push(comment);
      }
    }
  }

  if (comments.length === 0) {
    COMMENT_PATTERN.lastIndex = 0;
    let match: RegExpExecArray | null = COMMENT_PATTERN.exec(html);
    while (match !== null) {
      const body = stripTags(match[3] || '');
      const user = stripTags(match[2] || '');
      const posted = stripTags(match[1] || '');
      if (body.length > 0 || user.length > 0) {
        comments.push({
          id: 0,
          user: user.length > 0 ? user : 'Uploader',
          posted,
          body,
          score: 0,
          voteState: '',
          editable: false,
          voteUpAble: false,
          voteUpEd: false,
          voteDownAble: false,
          voteDownEd: false
        });
      }
      match = COMMENT_PATTERN.exec(html);
    }
  }
  return limit > 0 ? comments.slice(0, limit) : comments;
}

function parsePreviewPageCount(html: string): number {
  const paginatorMatch = /class="ptt"[\s\S]*?<\/table>/i.exec(html);
  if (!paginatorMatch || !paginatorMatch[0]) {
    return 1;
  }
  const numberPattern = />(\d+)</g;
  let match: RegExpExecArray | null = numberPattern.exec(paginatorMatch[0]);
  let maximum = 1;
  while (match !== null) {
    const current = Number(match[1]);
    if (Number.isFinite(current) && current > maximum) {
      maximum = current;
    }
    match = numberPattern.exec(paginatorMatch[0]);
  }
  return maximum;
}

function parsePreviewPositionFromPageUrl(pageUrl: string): number {
  PAGE_URL_PATTERN.lastIndex = 0;
  const match = PAGE_URL_PATTERN.exec(pageUrl);
  if (!match || !match[3]) {
    return -1;
  }
  const position = Number(match[3]);
  return Number.isFinite(position) && position > 0 ? position - 1 : -1;
}

function parsePreviewNumber(value: string | undefined): number {
  if (!value) {
    return 0;
  }
  const parsed = Number(value.replace(/,/g, ''));
  return Number.isFinite(parsed) ? parsed : 0;
}

function extractImageAttribute(fragment: string, name: string): string {
  const pattern = new RegExp(`<img[^>]+${name}=["']([^"']+)["']`, 'i');
  const match = pattern.exec(fragment);
  return match && match[1] ? match[1] : '';
}

function extractPreviewThumbUrl(fragment: string, site: string): string {
  const dataSrc = extractImageAttribute(fragment, 'data-src');
  if (dataSrc.length > 0 && dataSrc.indexOf('data:') !== 0) {
    return EhUrl.normalize(site, dataSrc);
  }
  const src = extractImageAttribute(fragment, 'src');
  if (src.length > 0 && src.indexOf('data:') !== 0) {
    return EhUrl.normalize(site, src);
  }
  const cssUrlMatch = /url\(([^)]+)\)/i.exec(fragment);
  if (cssUrlMatch && cssUrlMatch[1]) {
    return EhUrl.normalize(site, cssUrlMatch[1].replace(/['"]/g, ''));
  }
  const titleUrlMatch = /\((https?:\/\/[^)]+)\)/i.exec(fragment) || /\((\/\/[^)]+)\)/i.exec(fragment);
  if (titleUrlMatch && titleUrlMatch[1]) {
    return EhUrl.normalize(site, titleUrlMatch[1]);
  }
  return '';
}

function extractPreviewNumber(fragment: string): number {
  const imageAltMatch = /<img[^>]+alt=["']([\d,]+)["']/i.exec(fragment);
  if (imageAltMatch && imageAltMatch[1]) {
    return parsePreviewNumber(imageAltMatch[1]);
  }
  const titleMatch = /title=["']Page\s+([\d,]+):/i.exec(fragment);
  if (titleMatch && titleMatch[1]) {
    return parsePreviewNumber(titleMatch[1]);
  }
  return 0;
}

function extractPreviewDimension(fragment: string, name: string): number {
  const pattern = new RegExp(`${name}\\s*:\\s*(\\d+)px|${name}\\s*:\\s*(\\d+)`, 'i');
  const match = pattern.exec(fragment);
  if (!match) {
    return 0;
  }
  return parsePreviewNumber(match[1] || match[2]);
}

function extractPreviewOffset(fragment: string, axis: 'x' | 'y'): number {
  const backgroundPosition = /background(?:-position)?[^;"]*:\s*(-?\d+)px\s+(-?\d+)px/i.exec(fragment);
  if (backgroundPosition) {
    return Math.abs(parsePreviewNumber(axis === 'x' ? backgroundPosition[1] : backgroundPosition[2]));
  }
  if (axis === 'x') {
    const xMatch = /\)[^"'<>]*\s+(-?\d+)px/i.exec(fragment);
    if (xMatch && xMatch[1]) {
      return Math.abs(parsePreviewNumber(xMatch[1]));
    }
  }
  return 0;
}

function addPreviewItem(
  items: NativeGalleryPreview[],
  seenUrls: string[],
  site: string,
  rawPageUrl: string,
  position: number,
  rawThumbUrl: string,
  thumbWidth: number = 0,
  thumbHeight: number = 0,
  thumbOffsetX: number = 0,
  thumbOffsetY: number = 0
): void {
  const pageUrl = EhUrl.normalize(site, rawPageUrl);
  if (pageUrl.length === 0 || seenUrls.indexOf(pageUrl) >= 0) {
    return;
  }
  const inferredPosition = position >= 0 ? position : parsePreviewPositionFromPageUrl(pageUrl);
  if (inferredPosition < 0) {
    return;
  }
  seenUrls.push(pageUrl);
  items.push({
    position: inferredPosition,
    pageUrl,
    thumbUrl: rawThumbUrl.length > 0 ? EhUrl.normalize(site, rawThumbUrl) : '',
    pageLabel: `${inferredPosition + 1}`,
    thumbWidth,
    thumbHeight,
    thumbOffsetX,
    thumbOffsetY
  });
}

function parsePreviewItems(html: string, site: string): NativeGalleryPreview[] {
  const items: NativeGalleryPreview[] = [];
  const seenUrls: string[] = [];

  PREVIEW_LINK_PATTERN.lastIndex = 0;
  let match: RegExpExecArray | null = PREVIEW_LINK_PATTERN.exec(html);
  while (match !== null) {
    const fragment = match[2] || '';
    const previewNumber = extractPreviewNumber(fragment);
    addPreviewItem(
      items,
      seenUrls,
      site,
      match[1],
      previewNumber > 0 ? previewNumber - 1 : -1,
      extractPreviewThumbUrl(fragment, site),
      extractPreviewDimension(fragment, 'width'),
      extractPreviewDimension(fragment, 'height'),
      extractPreviewOffset(fragment, 'x'),
      extractPreviewOffset(fragment, 'y')
    );
    match = PREVIEW_LINK_PATTERN.exec(html);
  }

  items.sort((left: NativeGalleryPreview, right: NativeGalleryPreview): number => left.position - right.position);
  return items;
}

function buildPreviewPageUrl(detailUrl: string, pageIndex: number): string {
  if (pageIndex <= 0) {
    return detailUrl;
  }
  return detailUrl.indexOf('?') >= 0 ? `${detailUrl}&p=${pageIndex}` : `${detailUrl}?p=${pageIndex}`;
}

function parseFirstReaderPageUrl(html: string, site: string): string {
  const items = parsePreviewItems(html, site);
  return items.length > 0 ? items[0].pageUrl : '';
}

function parseTopList(html: string, site: string): NativeTopListDetail {
  const title = extractInnerText(html, /<h1[^>]*>([\s\S]*?)<\/h1>/i) || 'EHG Toplists';
  const groups: NativeTopListGroup[] = [];
  const groupPattern: RegExp = /<h2[^>]*>([\s\S]*?)<\/h2>([\s\S]*?)(?=<h2[^>]*>|<p id=["']nf["']|<div id=["']dc["']|$)/gi;
  let groupMatch: RegExpExecArray | null = groupPattern.exec(html);
  while (groupMatch !== null) {
    const groupTitle = stripTags(groupMatch[1] || '');
    const groupBody = groupMatch[2] || '';
    const periods: NativeTopListPeriod[] = [];
    const periodPattern: RegExp =
      /<p>[\s\S]*?<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>\s*<\/p>\s*<table[^>]*>([\s\S]*?)<\/table>/gi;
    let periodMatch: RegExpExecArray | null = periodPattern.exec(groupBody);
    while (periodMatch !== null) {
      const periodUrl = EhUrl.normalize(site, periodMatch[1] || '');
      const label = stripTags(periodMatch[2] || '');
      const tableHtml = periodMatch[3] || '';
      const followMatch = /[?&](tl=\d+)/i.exec(periodUrl);
      const entries: NativeTopListEntry[] = [];
      const rowPattern: RegExp =
        /<tr[^>]*>\s*<td[^>]*class=["']pso["'][^>]*>([\s\S]*?)<\/td>\s*<td[^>]*>[\s\S]*?<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>[\s\S]*?<\/td>\s*<\/tr>/gi;
      let rowMatch: RegExpExecArray | null = rowPattern.exec(tableHtml);
      while (rowMatch !== null) {
        const entryUrl = EhUrl.normalize(site, rowMatch[2] || '');
        const detailMatch = /\/g\/(\d+)\/([0-9a-f]{10})/i.exec(entryUrl);
        entries.push({
          rank: stripTags(rowMatch[1] || ''),
          score: '',
          title: stripTags(rowMatch[3] || ''),
          url: entryUrl,
          gid: detailMatch && detailMatch[1] ? Number(detailMatch[1]) : 0,
          token: detailMatch && detailMatch[2] ? detailMatch[2] : '',
          thumb: ''
        });
        rowMatch = rowPattern.exec(tableHtml);
      }
      periods.push({
        label,
        follow: followMatch && followMatch[1] ? followMatch[1] : '',
        url: periodUrl,
        entries
      });
      periodMatch = periodPattern.exec(groupBody);
    }
    if (groupTitle.length > 0 && periods.length > 0) {
      groups.push({
        title: groupTitle,
        periods
      });
    }
    groupMatch = groupPattern.exec(html);
  }
  return {
    title,
    groups
  };
}

function topListRankNumber(value: string): number {
  const numeric = Number(value.replace(/[^0-9]/g, ''));
  return Number.isFinite(numeric) ? numeric : 0;
}

function parseTopListEntryPage(html: string, site: string, requestUrl: string): NativeTopListEntryPageResult {
  const items: NativeTopListEntry[] = [];
  const tablePattern: RegExp = /<table([^>]*)>([\s\S]*?)<\/table>/gi;
  let tableMatch: RegExpExecArray | null = tablePattern.exec(html);
  while (tableMatch !== null) {
    const attributes = tableMatch[1] || '';
    const classMatch = /class=["']([^"']+)["']/i.exec(attributes);
    const classValue = classMatch && classMatch[1] ? classMatch[1] : '';
    if (hasClassToken(classValue, 'itg') && !hasClassToken(classValue, 'gltc')) {
      const tableHtml = tableMatch[2] || '';
      const entryPattern: RegExp =
        /<td[^>]+class=["'][^"']*\bdr\b[^"']*["'][^>]*>([\s\S]*?)<\/td>\s*<td[^>]+class=["'][^"']*\bds\b[^"']*["'][^>]*>([\s\S]*?)<\/td>\s*<td[^>]+class=["'][^"']*\bdu\b[^"']*["'][^>]*>([\s\S]*?)<\/td>/gi;
      let entryMatch: RegExpExecArray | null = entryPattern.exec(tableHtml);
      while (entryMatch !== null) {
        const nameHtml = entryMatch[3] || '';
        const hrefMatch = /<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/i.exec(nameHtml);
        const entryUrl = hrefMatch && hrefMatch[1] ? EhUrl.normalize(site, hrefMatch[1]) : '';
        const title = hrefMatch && hrefMatch[2] ? stripTags(hrefMatch[2]) : stripTags(nameHtml);
        const detailMatch = /\/g\/(\d+)\/([0-9a-f]{10})/i.exec(entryUrl);
        if (title.length > 0) {
          items.push({
            rank: stripTags(entryMatch[1] || ''),
            score: stripTags(entryMatch[2] || ''),
            title,
            url: entryUrl,
            gid: detailMatch && detailMatch[1] ? Number(detailMatch[1]) : 0,
            token: detailMatch && detailMatch[2] ? detailMatch[2] : '',
            thumb: ''
          });
        }
        entryMatch = entryPattern.exec(tableHtml);
      }
      break;
    }
    tableMatch = tablePattern.exec(html);
  }
  items.sort((left: NativeTopListEntry, right: NativeTopListEntry): number =>
    topListRankNumber(left.rank) - topListRankNumber(right.rank));
  return {
    items,
    requestUrl,
    firstUrl: findPagerUrl(html, site, 'first'),
    prevUrl: findPagerUrl(html, site, 'prev'),
    nextUrl: findPagerUrl(html, site, 'next'),
    lastUrl: findPagerUrl(html, site, 'last')
  };
}

function extractElementStartTagById(segment: string, id: string): string {
  const pattern = new RegExp(`<[^>]+id\\s*=\\s*["']${escapeRegex(id)}["'][^>]*>`, 'i');
  const match = pattern.exec(segment);
  return match && match[0] ? match[0] : '';
}

function extractTagAttribute(tag: string, attribute: string): string {
  if (tag.length === 0) {
    return '';
  }
  const pattern = new RegExp(`${escapeRegex(attribute)}\\s*=\\s*(["'])([\\s\\S]*?)\\1`, 'i');
  const match = pattern.exec(tag);
  return match && match[2] ? decodeHtml(match[2]) : '';
}

function extractInputTag(segment: string, id: string): string {
  const tag = extractElementStartTagById(segment, id);
  return tag.toLowerCase().startsWith('<input') ? tag : '';
}

function extractInputAttribute(segment: string, id: string, attribute: string): string {
  return extractTagAttribute(extractInputTag(segment, id), attribute);
}

function decodeTagHrefName(value: string): string {
  const normalized = value.replace(/\+/g, ' ');
  try {
    return decodeURIComponent(normalized);
  } catch (error) {
    return normalized;
  }
}

function extractUserTagName(segment: string, id: string): string {
  const previewTag = extractElementStartTagById(segment, `tagpreview${id}`);
  const title = extractTagAttribute(previewTag, 'title').trim();
  if (title.length > 0) {
    return title;
  }
  const hrefMatch = /href\s*=\s*["'][^"']*\/tag\/([^"'?#]+)[^"']*["']/i.exec(segment);
  return hrefMatch && hrefMatch[1] ? decodeTagHrefName(hrefMatch[1]).trim() : '';
}

function parseUserTags(html: string): NativeUserTag[] {
  const lowerHtml = html.toLowerCase();
  if (lowerHtml.indexOf('bounce_login.php') >= 0 ||
    lowerHtml.indexOf('name="username"') >= 0 ||
    lowerHtml.indexOf("name='username'") >= 0 ||
    lowerHtml.indexOf('name="password"') >= 0 ||
    lowerHtml.indexOf("name='password'") >= 0 ||
    lowerHtml.indexOf('ipb_login_form') >= 0 ||
    lowerHtml.indexOf('ipb_login_submit') >= 0) {
    throw new Error('登录状态失效，请重新登录或导入 Cookie。');
  }
  const errorMatch = /<div\s+class=["']d["'][^>]*>\s*<p>([^<]+)<\/p>/i.exec(html);
  if (errorMatch && errorMatch[1]) {
    throw new Error(decodeHtml(errorMatch[1]).trim());
  }
  const list: NativeUserTag[] = [];
  const outerMatch = /<div[^>]+id\s*=\s*["']usertags_outer["'][^>]*>([\s\S]*?)(?:<\/form>|<div\s+id\s*=\s*["']footer["']|$)/i.exec(html);
  if (!outerMatch || !outerMatch[1]) {
    hilog.warn(DOMAIN, LOG_TAG,
      'MyTags parse failed. Bytes=%{public}d Login=%{public}s UserTagsOuter=%{public}s',
      html.length,
      lowerHtml.indexOf('bounce_login.php') >= 0 || lowerHtml.indexOf('name="username"') >= 0 ? 'yes' : 'no',
      lowerHtml.indexOf('usertags_outer') >= 0 ? 'yes' : 'no');
    throw new Error('我的标签页面不可用，请确认已经登录。');
  }
  const body = outerMatch && outerMatch[1] ? outerMatch[1] : html;
  const idPattern: RegExp = /id\s*=\s*["']usertag(_?\d+)["']/gi;
  const starts: Array<Array<number | string>> = [];
  let idMatch: RegExpExecArray | null = idPattern.exec(body);
  while (idMatch !== null) {
    if (idMatch[1]) {
      starts.push([idMatch.index, idMatch[1]]);
    }
    idMatch = idPattern.exec(body);
  }
  for (let index = 0; index < starts.length; index++) {
    const start = Number(starts[index][0]);
    const id = `${starts[index][1]}`;
    const numericId = id.replace(/^_/, '');
    if (numericId === '0') {
      continue;
    }
    const end = index + 1 < starts.length ? Number(starts[index + 1][0]) : body.length;
    const segment = body.substring(start, end);
    const tagName = extractUserTagName(segment, id);
    if (tagName.length === 0) {
      continue;
    }
    const weightValue = Number(extractInputAttribute(segment, `tagweight${id}`, 'value'));
    list.push({
      id: `usertag${id}`,
      tagName,
      color: extractInputAttribute(segment, `tagcolor${id}`, 'placeholder'),
      tagWeight: Number.isFinite(weightValue) ? weightValue : 0,
      watched: extractInputTag(segment, `tagwatch${id}`).toLowerCase().indexOf('checked') >= 0,
      hidden: extractInputTag(segment, `taghide${id}`).toLowerCase().indexOf('checked') >= 0
    });
  }
  const result = list.filter((item: NativeUserTag) => item.tagName.length > 0);
  return result;
}

function parsePageIndexFromUrl(pageUrl: string): number {
  const match = PAGE_URL_PATTERN.exec(pageUrl);
  if (!match || !match[3]) {
    return 0;
  }
  return Math.max(0, Number(match[3]) - 1);
}

function readerPageUrlWithSkipHathKey(pageUrl: string, skipHathKey: string): string {
  if (skipHathKey.length === 0) {
    return pageUrl;
  }
  const hashIndex = pageUrl.indexOf('#');
  const hash = hashIndex >= 0 ? pageUrl.substring(hashIndex) : '';
  const base = hashIndex >= 0 ? pageUrl.substring(0, hashIndex) : pageUrl;
  const queryIndex = base.indexOf('?');
  const path = queryIndex >= 0 ? base.substring(0, queryIndex) : base;
  const query = queryIndex >= 0 ? base.substring(queryIndex + 1) : '';
  const params = query.length > 0 ?
    query.split('&').filter((item: string): boolean => item.length > 0 && !item.startsWith('nl=')) :
    [];
  params.push(`nl=${encodeURIComponent(skipHathKey)}`);
  return `${path}?${params.join('&')}${hash}`;
}

function parseReaderPage(html: string, pageUrl: string): NativeGalleryImagePage {
  const imageMatch = IMAGE_URL_PATTERN.exec(html);
  const originMatch = ORIGIN_IMAGE_URL_PATTERN.exec(html);
  const skipHathMatch = SKIP_HATH_KEY_PATTERN.exec(html);
  const imageUrl = imageMatch && imageMatch[1] ? decodeHtml(imageMatch[1]) : '';
  const originImageUrl = originMatch && originMatch[1] && originMatch[2]
    ? `${decodeHtml(originMatch[1])}fullimg${decodeHtml(originMatch[2])}`
    : '';
  const skipHathKey = skipHathMatch && skipHathMatch[1] ? decodeHtml(skipHathMatch[1]) : '';
  const pageIndex = parsePageIndexFromUrl(pageUrl);

  if (imageUrl.length === 0) {
    throw new Error('Reader image parse failed');
  }

  const page: NativeGalleryImagePage = {
    pageIndex,
    pageLabel: `${pageIndex + 1}`,
    pageUrl,
    imageUrl,
    originImageUrl,
    skipHathKey
  };
  return page;
}

function mergeDetailHtml(base: NativeGalleryDetail, html: string, site: string): NativeGalleryDetail {
  const detail: NativeGalleryDetail = {
    gid: base.gid,
    token: base.token,
    title: base.title,
    titleJpn: base.titleJpn,
    cover: base.cover,
    categoryLabel: base.categoryLabel,
    posted: base.posted,
    uploader: base.uploader,
    rating: base.rating,
    ratingCount: base.ratingCount,
    pages: base.pages,
    favoriteCount: base.favoriteCount,
    isFavorited: base.isFavorited,
    favoriteName: base.favoriteName,
    apiUid: base.apiUid,
    apiKey: base.apiKey,
    torrentCount: base.torrentCount,
    torrentUrl: base.torrentUrl,
    archiveUrl: base.archiveUrl,
    visible: base.visible,
    language: base.language,
    fileSize: base.fileSize,
    parentUrl: base.parentUrl,
    detailUrl: base.detailUrl,
    previewPageCount: base.previewPageCount,
    tagGroups: base.tagGroups,
    comments: base.comments,
    hasMoreComments: base.hasMoreComments
  };
  const detailMatch = DETAIL_SCRIPT_PATTERN.exec(html);
  const torrentMatch = TORRENT_PATTERN.exec(html);
  const archiveMatch = ARCHIVE_PATTERN.exec(html);
  const title = extractInnerText(html, /id="gn"[^>]*>([\s\S]*?)<\/h1>/i);
  const titleJpn = extractInnerText(html, /id="gj"[^>]*>([\s\S]*?)<\/h1>/i);
  const coverMatch = /id="gd1"[\s\S]*?url\(([^)]+)\)/i.exec(html);
  const categoryLabel = extractInnerText(html, /id="gdc"[\s\S]*?<div[^>]*class="(?:cn|cs)"[^>]*>([\s\S]*?)<\/div>/i);
  const uploader = extractInnerText(html, /id="gdn"[^>]*>([\s\S]*?)<\/div>/i);
  const ratingLabel = extractInnerText(html, /id="rating_label"[^>]*>([\s\S]*?)<\/td>/i);
  const ratingCount = extractInnerText(html, /id="rating_count"[^>]*>([\s\S]*?)<\/span>/i) ||
    extractInnerText(html, /id="rating_count"[^>]*>([\s\S]*?)<\/div>/i);
  const favoriteLabel = extractInnerText(html, /id="gdf"[^>]*>([\s\S]*?)<\/div>/i);

  if (detailMatch && detailMatch[1] && detailMatch[2]) {
    const parsedGid = Number(detailMatch[1]);
    if (Number.isFinite(parsedGid) && parsedGid > 0) {
      detail.gid = parsedGid;
    }
    detail.token = detailMatch[2];
    detail.apiUid = detailMatch[3] ? Number(detailMatch[3]) : -1;
    detail.apiKey = detailMatch[4] || '';
  }
  if (torrentMatch && torrentMatch[1]) {
    detail.torrentUrl = EhUrl.normalize(site, torrentMatch[1]);
    detail.torrentCount = torrentMatch[2] ? Number(torrentMatch[2]) : 0;
  }
  if (archiveMatch && archiveMatch[1]) {
    detail.archiveUrl = EhUrl.normalize(site, archiveMatch[1]);
  }
  if (title.length > 0) {
    detail.title = title;
  }
  if (titleJpn.length > 0) {
    detail.titleJpn = titleJpn;
  }
  if (coverMatch && coverMatch[1]) {
    detail.cover = EhUrl.normalize(site, coverMatch[1].replace(/['"]/g, ''));
  }
  if (categoryLabel.length > 0) {
    detail.categoryLabel = categoryLabel;
  }
  if (uploader.length > 0) {
    detail.uploader = uploader;
  }

  const numericRating = /([\d.]+)/.exec(ratingLabel);
  if (numericRating && numericRating[1]) {
    detail.rating = Number(numericRating[1]);
  }
  if (ratingCount.length > 0) {
    detail.ratingCount = Number(ratingCount.replace(/,/g, ''));
  }

  detail.posted = extractDetailCell(html, 'Posted') || detail.posted;
  detail.visible = extractDetailCell(html, 'Visible') || detail.visible;
  detail.language = extractDetailCell(html, 'Language') || detail.language;
  detail.fileSize = extractDetailCell(html, 'File Size') || detail.fileSize;
  const favoritedValue = extractDetailCell(html, 'Favorited');
  if (favoritedValue.length > 0) {
    detail.favoriteCount = parseFavoriteCount(favoritedValue);
  }
  if (favoriteLabel.length > 0) {
    detail.isFavorited = favoriteLabel !== 'Add to Favorites';
    detail.favoriteName = detail.isFavorited ? favoriteLabel : '';
  }

  const lengthValue = extractDetailCell(html, 'Length');
  if (lengthValue.length > 0) {
    const pagesMatch = /([\d,]+)/.exec(lengthValue);
    if (pagesMatch && pagesMatch[1]) {
      detail.pages = Number(pagesMatch[1].replace(/,/g, ''));
    }
  }

  const parentUrl = extractDetailHref(html, 'Parent', site);
  if (parentUrl.length > 0) {
    detail.parentUrl = parentUrl;
  }

  const tagGroups = parseGalleryTagGroups(html);
  if (tagGroups.length > 0) {
    detail.tagGroups = tagGroups;
  }

  detail.previewPageCount = parsePreviewPageCount(html);
  detail.comments = parseGalleryComments(html);
  detail.hasMoreComments = html.indexOf('click to show all') >= 0;

  return detail;
}

function parseRateResult(body: string): NativeRateResult {
  const parsed = JSON.parse(body) as JsonObject;
  return {
    rating: getJsonNumber(parsed, 'rating_avg', -1),
    ratingCount: getJsonNumber(parsed, 'rating_cnt', 0)
  };
}

function parseVoteCommentResult(body: string, expectVote: number): NativeVoteCommentResult {
  const parsed = JSON.parse(body) as JsonObject;
  return {
    id: getJsonNumber(parsed, 'comment_id', 0),
    score: getJsonNumber(parsed, 'comment_score', 0),
    vote: getJsonNumber(parsed, 'comment_vote', 0),
    expectVote
  };
}

function extractTableCells(row: string): string[] {
  const cells: string[] = [];
  const pattern: RegExp = /<t[dh][^>]*>([\s\S]*?)<\/t[dh]>/gi;
  let match: RegExpExecArray | null = pattern.exec(row);
  while (match !== null) {
    const cell = stripTags(match[1] || '');
    if (cell.length > 0) {
      cells.push(cell);
    }
    match = pattern.exec(row);
  }
  return cells;
}

function parseTorrentItems(body: string, site: string): NativeTorrentItem[] {
  const items: NativeTorrentItem[] = [];
  const seenUrls: string[] = [];
  TORRENT_ROW_PATTERN.lastIndex = 0;
  let rowMatch: RegExpExecArray | null = TORRENT_ROW_PATTERN.exec(body);
  while (rowMatch !== null) {
    const row = rowMatch[1] || '';
    const linkMatch = TORRENT_LINK_PATTERN.exec(row);
    if (linkMatch && linkMatch[1]) {
      let url = EhUrl.normalize(site, linkMatch[1]);
      const privateIndex = url.indexOf('?p=');
      if (privateIndex >= 0) {
        url = url.substring(0, privateIndex);
      }
      if (url.length > 0 && seenUrls.indexOf(url) < 0) {
        const name = stripTags(linkMatch[2] || '');
        const cells = extractTableCells(row).filter((cell: string) => cell !== name);
        let size = '';
        let seeds = '';
        for (const cell of cells) {
          if (size.length === 0 && /\d+(?:\.\d+)?\s*(?:B|KB|KiB|MB|MiB|GB|GiB)/i.test(cell)) {
            size = cell;
          }
          if (/^\d+$/.test(cell)) {
            seeds = cell;
          }
        }
        seenUrls.push(url);
        items.push({
          url,
          name: name.length > 0 ? name : `Torrent ${items.length + 1}`,
          posted: cells.length > 0 ? cells[0] : '',
          size,
          seeds
        });
      }
    }
    rowMatch = TORRENT_ROW_PATTERN.exec(body);
  }

  if (items.length === 0) {
    const fallbackPattern: RegExp = /<td colspan=["']5["']>\s*&nbsp;\s*<a href=["']([^"']+)["'][^<]+>([^<]+)<\/a><\/td>/gi;
    let match: RegExpExecArray | null = fallbackPattern.exec(body);
    while (match !== null) {
      let url = EhUrl.normalize(site, match[1] || '');
      const privateIndex = url.indexOf('?p=');
      if (privateIndex >= 0) {
        url = url.substring(0, privateIndex);
      }
      if (url.length > 0 && seenUrls.indexOf(url) < 0) {
        seenUrls.push(url);
        items.push({
          url,
          name: stripTags(match[2] || `Torrent ${items.length + 1}`),
          posted: '',
          size: '',
          seeds: ''
        });
      }
      match = fallbackPattern.exec(body);
    }
  }
  return items;
}

function parseArchiveList(body: string): NativeArchiveList {
  const formMatch = ARCHIVE_FORM_PATTERN.exec(body);
  const items: NativeArchiveItem[] = [];
  ARCHIVE_ITEM_PATTERN.lastIndex = 0;
  let match: RegExpExecArray | null = ARCHIVE_ITEM_PATTERN.exec(body);
  while (match !== null) {
    if (match[1] && match[2]) {
      items.push({
        res: stripTags(match[1]),
        name: stripTags(match[2])
      });
    }
    match = ARCHIVE_ITEM_PATTERN.exec(body);
  }
  return {
    formParamOr: formMatch && formMatch[1] ? decodeHtml(formMatch[1]) : '',
    items
  };
}

function formUrlEncode(values: NativeFormField[]): string {
  const parts: string[] = [];
  for (const item of values) {
    parts.push(`${encodeURIComponent(item.name)}=${encodeURIComponent(item.value)}`);
  }
  return parts.join('&');
}

export class EhTagTranslator {
  private static translations: Record<string, string> = {};
  private static entryKeys: Record<string, boolean> = {};
  private static entries: TagTranslationSuggestion[] = [];
  private static fallbackReady: boolean = false;
  private static loaded: boolean = false;
  private static loading?: Promise<boolean> = undefined;
  private static lastError: string = '';
  private static cacheDir: string = '';
  private static cacheSha1: string = '';
  private static bundledRaw: string = '';
  private static bundledSha1: string = TAG_TRANSLATION_BUNDLED_SHA1;
  private static loadedFromCache: boolean = false;
  private static loadedFromBundled: boolean = false;
  private static checkedRemote: boolean = false;
  private static updatedFromRemote: boolean = false;
  private static selectedSourceUrl: string = TAG_TRANSLATION_SOURCE_URL;
  private static selectedSourceLabel: string = 'primary';

  private static ensureFallback(): void {
    if (EhTagTranslator.fallbackReady) {
      return;
    }
    EhTagTranslator.fallbackReady = true;
    for (const row of FALLBACK_TAG_TRANSLATIONS) {
      EhTagTranslator.addTranslation(row[0], row[1]);
    }
  }

  private static resetTranslations(): void {
    EhTagTranslator.translations = {};
    EhTagTranslator.entryKeys = {};
    EhTagTranslator.entries = [];
    EhTagTranslator.fallbackReady = false;
    EhTagTranslator.ensureFallback();
  }

  private static cacheRoot(): string {
    return EhTagTranslator.cacheDir.length > 0 ? `${EhTagTranslator.cacheDir}/tag-translations` : '';
  }

  private static cacheDataPath(): string {
    const root = EhTagTranslator.cacheRoot();
    return root.length > 0 ? `${root}/tag-translations-zh-rCN` : '';
  }

  private static cacheSha1Path(): string {
    const root = EhTagTranslator.cacheRoot();
    return root.length > 0 ? `${root}/tag-translations-zh-rCN.sha1` : '';
  }

  private static ensureCacheRoot(): boolean {
    const root = EhTagTranslator.cacheRoot();
    if (root.length === 0) {
      return false;
    }
    try {
      if (!fileIo.accessSync(root)) {
        fileIo.mkdirSync(root, true);
      }
      return true;
    } catch (error) {
      try {
        fileIo.mkdirSync(root, true);
        return true;
      } catch (innerError) {
        return false;
      }
    }
  }

  private static readTextFile(path: string): string {
    if (path.length === 0) {
      return '';
    }
    try {
      if (!fileIo.accessSync(path)) {
        return '';
      }
      return fileIo.readTextSync(path);
    } catch (error) {
      return '';
    }
  }

  private static writeTextFile(path: string, value: string): boolean {
    if (path.length === 0 || !EhTagTranslator.ensureCacheRoot()) {
      return false;
    }
    let file: fileIo.File | undefined = undefined;
    try {
      file = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(file.fd, value);
      return true;
    } catch (error) {
      return false;
    } finally {
      if (file) {
        try {
          fileIo.closeSync(file);
        } catch (closeError) {
        }
      }
    }
  }

  private static normalizeSha1(value: string): string {
    const match = /[0-9a-fA-F]{40}/.exec(value);
    return match && match[0] ? match[0].toLowerCase() : value.trim().toLowerCase();
  }

  private static loadCachedRaw(): string {
    if (!EhTagTranslator.ensureCacheRoot()) {
      return '';
    }
    EhTagTranslator.cacheSha1 = EhTagTranslator.normalizeSha1(EhTagTranslator.readTextFile(EhTagTranslator.cacheSha1Path()));
    return EhTagTranslator.readTextFile(EhTagTranslator.cacheDataPath());
  }

  private static saveCache(raw: string, sha1: string): void {
    if (raw.length === 0) {
      return;
    }
    EhTagTranslator.writeTextFile(EhTagTranslator.cacheDataPath(), raw);
    const normalizedSha1 = EhTagTranslator.normalizeSha1(sha1);
    if (normalizedSha1.length > 0) {
      EhTagTranslator.cacheSha1 = normalizedSha1;
      EhTagTranslator.writeTextFile(EhTagTranslator.cacheSha1Path(), normalizedSha1);
    }
  }

  private static loadRaw(raw: string, fromCache: boolean, fromBundled: boolean = false): boolean {
    if (raw.length === 0) {
      return false;
    }
    EhTagTranslator.resetTranslations();
    const count = EhTagTranslator.parseLegacyData(raw);
    if (count <= 0) {
      EhTagTranslator.resetTranslations();
      EhTagTranslator.loaded = false;
      EhTagTranslator.loadedFromCache = false;
      EhTagTranslator.loadedFromBundled = false;
      return false;
    }
    EhTagTranslator.loaded = true;
    EhTagTranslator.loadedFromCache = fromCache;
    EhTagTranslator.loadedFromBundled = fromBundled;
    EhTagTranslator.updatedFromRemote = false;
    EhTagTranslator.lastError = '';
    return true;
  }

  private static addTranslation(rawKey: string, translation: string): void {
    const key = rawKey.trim();
    const readable = translation.trim();
    if (key.length === 0 || readable.length === 0) {
      return;
    }
    EhTagTranslator.translations[key] = readable;
    const normalizedKey = normalizeTranslationKey(key);
    EhTagTranslator.translations[normalizedKey] = readable;
    if (key.startsWith('n:')) {
      return;
    }
    if (EhTagTranslator.entryKeys[normalizedKey]) {
      return;
    }
    const parts = splitTagKey(normalizedKey);
    const namespace = parts[0].length > 0 ? parts[0] : 'misc';
    const tag = parts[1];
    EhTagTranslator.entryKeys[normalizedKey] = true;
    EhTagTranslator.entries.push({
      key: normalizedKey,
      translation: readable,
      display: readable.length > 0 ? `${readable}  ·  ${normalizedKey}` : normalizedKey,
      namespace,
      tag
    });
  }

  private static findTranslationStart(raw: string): number {
    const candidates: string[] = ['a:', 'c:', 'cos:', 'f:', 'g:', 'l:', 'm:', 'n:', 'o:', 'p:', 'r:', 'x:'];
    let startIndex = -1;
    for (const candidate of candidates) {
      const index = raw.indexOf(candidate);
      if (index >= 0 && (startIndex < 0 || index < startIndex)) {
        const endIndex = raw.indexOf('\n', index);
        const delimiterIndex = raw.indexOf('\r', index);
        if (delimiterIndex > index && (endIndex < 0 || delimiterIndex < endIndex)) {
          startIndex = index;
        }
      }
    }
    return startIndex >= 0 ? startIndex : 0;
  }

  private static parseLegacyData(raw: string): number {
    const startIndex = EhTagTranslator.findTranslationStart(raw);
    const lines = raw.substring(startIndex).split('\n');
    let count = 0;
    for (const line of lines) {
      const delimiterIndex = line.indexOf('\r');
      if (delimiterIndex <= 0) {
        continue;
      }
      const key = line.substring(0, delimiterIndex).trim();
      const encoded = line.substring(delimiterIndex + 1).trim();
      if (key.length === 0 || encoded.length === 0) {
        continue;
      }
      const translation = decodeBase64Utf8(encoded);
      if (translation.length === 0) {
        continue;
      }
      EhTagTranslator.addTranslation(key, translation);
      count++;
    }
    return count;
  }

  private static async requestTextFromUrl(url: string, usingCache: boolean): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        usingCache,
        usingProxy: AppNetworkProxy.requestProxy(),
        readTimeout: 30000,
        connectTimeout: 15000,
        header: {
          'Accept': '*/*',
          'User-Agent': NativeEhClient.USER_AGENT
        }
      });
      const code = Number(response.responseCode);
      if (code < 200 || code >= 400) {
        throw new Error(`HTTP ${code}`);
      }
      return typeof response.result === 'string' ? response.result : '';
    } catch (error) {
      const message = nativeRequestErrorMessage(error, 'Tag translation network request failed');
      hilog.error(DOMAIN, LOG_TAG, 'Tag translation request failed. Url=%{public}s Cause=%{public}s', url, message);
      throw new Error(message);
    } finally {
      request.destroy();
    }
  }

  private static async requestSource(): Promise<string> {
    return EhTagTranslator.requestTextFromUrl(EhTagTranslator.selectedSourceUrl, false);
  }

  private static async requestRemoteSha1(): Promise<string> {
    try {
      const sha1 = EhTagTranslator.normalizeSha1(await EhTagTranslator.requestTextFromUrl(TAG_TRANSLATION_SHA1_URL, false));
      EhTagTranslator.selectedSourceUrl = TAG_TRANSLATION_SOURCE_URL;
      EhTagTranslator.selectedSourceLabel = 'primary';
      return sha1;
    } catch (primaryError) {
      const sha1 = EhTagTranslator.normalizeSha1(
        await EhTagTranslator.requestTextFromUrl(TAG_TRANSLATION_BACKUP_SHA1_URL, false)
      );
      EhTagTranslator.selectedSourceUrl = TAG_TRANSLATION_BACKUP_SOURCE_URL;
      EhTagTranslator.selectedSourceLabel = 'backup';
      return sha1;
    }
  }

  static async update(): Promise<boolean> {
    EhTagTranslator.ensureFallback();
    if (EhTagTranslator.loading) {
      return EhTagTranslator.loading;
    }
    EhTagTranslator.loading = new Promise<boolean>(async (resolve) => {
      let cachedRaw = '';
      let localRaw = '';
      let localFromCache = false;
      let localFromBundled = false;
      let cacheAvailable = false;
      try {
        cachedRaw = EhTagTranslator.loadCachedRaw();
        cacheAvailable = EhTagTranslator.loadRaw(cachedRaw, true, false);
        if (cacheAvailable) {
          localRaw = cachedRaw;
          localFromCache = true;
        }
        if (!cacheAvailable) {
          const bundledRaw = EhTagTranslator.bundledRaw;
          cacheAvailable = EhTagTranslator.loadRaw(bundledRaw, false, true);
          if (cacheAvailable) {
            localRaw = bundledRaw;
            localFromBundled = true;
            EhTagTranslator.cacheSha1 = EhTagTranslator.bundledSha1;
            EhTagTranslator.saveCache(bundledRaw, EhTagTranslator.bundledSha1);
          }
        }
        let remoteSha1 = '';
        try {
          remoteSha1 = await EhTagTranslator.requestRemoteSha1();
          EhTagTranslator.checkedRemote = true;
        } catch (sha1Error) {
          EhTagTranslator.checkedRemote = false;
          if (cacheAvailable) {
            EhTagTranslator.updatedFromRemote = false;
            const localLabel = localFromBundled ? '随包内置' : '本地缓存';
            EhTagTranslator.lastError = `远端版本检查失败，已使用${localLabel}：${`${sha1Error}`.replace('Error: ', '')}`;
            resolve(true);
            return;
          }
        }
        if (cacheAvailable && remoteSha1.length > 0 && remoteSha1 === EhTagTranslator.cacheSha1) {
          EhTagTranslator.updatedFromRemote = false;
          EhTagTranslator.lastError = '';
          resolve(true);
          return;
        }

        const raw = await EhTagTranslator.requestSource();
        if (!EhTagTranslator.loadRaw(raw, false, false)) {
          if (cacheAvailable) {
            EhTagTranslator.loadRaw(localRaw, localFromCache, localFromBundled);
            const localLabel = localFromBundled ? '随包内置' : '本地缓存';
            EhTagTranslator.lastError = `远端翻译库解析失败，已使用${localLabel}`;
            resolve(true);
            return;
          }
          EhTagTranslator.lastError = 'No translation rows parsed';
          resolve(false);
          return;
        }

        EhTagTranslator.saveCache(raw, remoteSha1);
        EhTagTranslator.updatedFromRemote = true;
        resolve(EhTagTranslator.loaded);
      } catch (error) {
        if (!cacheAvailable && cachedRaw.length > 0) {
          cacheAvailable = EhTagTranslator.loadRaw(cachedRaw, true, false);
        }
        if (!cacheAvailable && EhTagTranslator.bundledRaw.length > 0) {
          cacheAvailable = EhTagTranslator.loadRaw(EhTagTranslator.bundledRaw, false, true);
        }
        EhTagTranslator.lastError = `${error}`.replace('Error: ', '');
        if (cacheAvailable) {
          resolve(true);
        } else {
          resolve(false);
        }
      } finally {
        EhTagTranslator.loading = undefined;
      }
    });
    return EhTagTranslator.loading;
  }

  static isLoaded(): boolean {
    return EhTagTranslator.loaded;
  }

  static configureCacheDir(filesDir: string): void {
    EhTagTranslator.cacheDir = filesDir;
  }

  static configureBundledRaw(raw: string, sha1: string = TAG_TRANSLATION_BUNDLED_SHA1): void {
    if (raw.length === 0) {
      return;
    }
    EhTagTranslator.bundledRaw = raw;
    EhTagTranslator.bundledSha1 = EhTagTranslator.normalizeSha1(sha1);
  }

  static count(): number {
    EhTagTranslator.ensureFallback();
    return EhTagTranslator.entries.length;
  }

  static statusLabel(): string {
    EhTagTranslator.ensureFallback();
    if (EhTagTranslator.loaded) {
      if (EhTagTranslator.updatedFromRemote) {
        return `标签翻译已更新 ${EhTagTranslator.entries.length} 条（${EhTagTranslator.selectedSourceLabel}）`;
      }
      if (EhTagTranslator.loadedFromCache) {
        if (EhTagTranslator.lastError.length > 0) {
          return `使用本地缓存标签翻译 ${EhTagTranslator.entries.length} 条；${EhTagTranslator.lastError}`;
        }
        return EhTagTranslator.checkedRemote ?
          `标签翻译缓存已是最新 ${EhTagTranslator.entries.length} 条` :
          `使用本地缓存标签翻译 ${EhTagTranslator.entries.length} 条`;
      }
      if (EhTagTranslator.loadedFromBundled) {
        if (EhTagTranslator.lastError.length > 0) {
          return `使用随包内置标签翻译 ${EhTagTranslator.entries.length} 条；${EhTagTranslator.lastError}`;
        }
        return EhTagTranslator.checkedRemote ?
          `随包内置标签翻译已是最新 ${EhTagTranslator.entries.length} 条` :
          `使用随包内置标签翻译 ${EhTagTranslator.entries.length} 条`;
      }
      return `标签翻译已加载 ${EhTagTranslator.entries.length} 条`;
    }
    if (EhTagTranslator.lastError.length > 0) {
      return `使用内置翻译，完整库未加载：${EhTagTranslator.lastError}`;
    }
    return `使用内置翻译，可更新完整标签库`;
  }

  static namespaceToPrefix(namespace: string): string | undefined {
    return namespaceToPrefix(namespace);
  }

  static translateNamespace(namespace: string): string {
    EhTagTranslator.ensureFallback();
    const translated = EhTagTranslator.translations[`n:${namespace}`];
    return translated && translated.length > 0 ? translated : namespace;
  }

  static translateTag(namespace: string, tag: string): string {
    EhTagTranslator.ensureFallback();
    const prefix = namespaceToPrefix(namespace);
    const lookupKey = prefix !== undefined ? `${prefix}${tag}` : `${namespace}:${tag}`;
    const translated = EhTagTranslator.translations[lookupKey] || EhTagTranslator.translations[`${namespace}:${tag}`];
    return translated && translated.length > 0 ? translated : tag;
  }

  static translateFullTag(tag: string): string {
    const separatorIndex = tag.indexOf(':');
    if (separatorIndex < 0) {
      return EhTagTranslator.translateTag('misc', tag);
    }
    const namespace = tag.substring(0, separatorIndex);
    const body = tag.substring(separatorIndex + 1);
    const translatedNamespace = EhTagTranslator.translateNamespace(namespace);
    const translatedBody = EhTagTranslator.translateTag(namespace, body);
    return `${translatedNamespace}:${translatedBody}`;
  }

  static suggest(keyword: string, limit: number): TagTranslationSuggestion[] {
    EhTagTranslator.ensureFallback();
    const query = keyword.trim();
    if (query.length === 0 || limit <= 0) {
      return [];
    }
    const result: TagTranslationSuggestion[] = [];
    for (const item of EhTagTranslator.entries) {
      if (result.length >= limit) {
        break;
      }
      if (item.key.indexOf(query) >= 0 || item.translation.indexOf(query) >= 0) {
        result.push(item);
      }
    }
    return result;
  }
}

export class NativeEhClient {
  static readonly USER_AGENT: string =
    'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Mobile Safari/537.36';
  private static readonly REQUEST_USER_AGENT: string =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36';
  private static readonly REQUEST_ACCEPT: string =
    'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8';
  private static readonly REQUEST_ACCEPT_LANGUAGE: string = 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7';
  private static stableCookieHeader: string = '';

  private static hostFromUrl(url: string): string {
    const match = /^https?:\/\/([^/?#:]+)(?::\d+)?/i.exec(url);
    return match && match[1] ? match[1] : '';
  }

  private static shouldSendCookieName(name: string): boolean {
    const lowerName = name.toLowerCase();
    return lowerName !== 'cf_clearance' && lowerName !== '_cfuvid' && lowerName !== '__cf_bm' &&
      !lowerName.startsWith('__cf') && !lowerName.startsWith('cf_chl');
  }

  private static isCookieAttributeName(name: string): boolean {
    return name === 'domain' || name === 'path' || name === 'expires' || name === 'max-age' ||
      name === 'samesite' || name === 'secure' || name === 'httponly';
  }

  private static cookiePieceValue(piece: string): string {
    const splitIndex = piece.indexOf('=');
    return splitIndex >= 0 ? piece.substring(splitIndex + 1).trim() : '';
  }

  private static isUsableIgneousValue(value: string): boolean {
    const normalized = value.trim().toLowerCase();
    return normalized.length > 0 && normalized !== 'mystery' && normalized !== 'deleted' &&
      normalized !== 'delete' && normalized !== 'null' && normalized !== 'undefined' &&
      normalized !== 'none' && normalized !== '0';
  }

  private static appendCookieHeader(cookie: string, names: string[], values: string[]): void {
    const parts = cookie
      .split(';')
      .map((item: string) => item.trim())
      .filter((item: string) => item.includes('='));
    for (const part of parts) {
      const splitIndex = part.indexOf('=');
      const name = splitIndex > 0 ? part.substring(0, splitIndex).trim() : '';
      const value = splitIndex >= 0 ? part.substring(splitIndex + 1).trim() : '';
      if (name.length === 0) {
        continue;
      }
      const lowerName = name.toLowerCase();
      if (value.length === 0 || NativeEhClient.isCookieAttributeName(lowerName) ||
        !NativeEhClient.shouldSendCookieName(name)) {
        continue;
      }
      if (name === 'igneous' && !NativeEhClient.isUsableIgneousValue(value)) {
        continue;
      }
      const existingIndex = names.indexOf(name);
      if (existingIndex >= 0) {
        const existingValue = NativeEhClient.cookiePieceValue(values[existingIndex]);
        if (name === 'igneous' && NativeEhClient.isUsableIgneousValue(existingValue) &&
          !NativeEhClient.isUsableIgneousValue(value)) {
          continue;
        }
        values[existingIndex] = `${name}=${value}`;
      } else {
        names.push(name);
        values.push(`${name}=${value}`);
      }
    }
  }

  private static splitSetCookieHeaders(cookieHeader: string): string[] {
    return cookieHeader
      .split(/\n|,(?=\s*[^=;,\s]+=)/)
      .map((item: string) => item.trim())
      .filter((item: string) => item.length > 0);
  }

  private static captureResponseCookies(url: string, response: http.HttpResponse): void {
    const cookieHeader = response.cookies;
    if (cookieHeader.length === 0) {
      return;
    }
    const names: string[] = [];
    const values: string[] = [];
    NativeEhClient.appendCookieHeader(NativeEhClient.stableCookieHeader, names, values);
    for (const setCookie of NativeEhClient.splitSetCookieHeaders(cookieHeader)) {
      NativeEhClient.appendCookieHeader(setCookie, names, values);
      try {
        webview.WebCookieManager.configCookieSync(url, setCookie, false, true);
      } catch (httpOnlyError) {
        try {
          webview.WebCookieManager.configCookieSync(url, setCookie, false);
        } catch (error) {
        }
      }
    }
    NativeEhClient.stableCookieHeader = values.join('; ');
    try {
      webview.WebCookieManager.saveCookieSync();
    } catch (error) {
    }
  }

  private static appendCookieSource(url: string, names: string[], values: string[]): void {
    try {
      const cookie = webview.WebCookieManager.fetchCookieSync(url, false);
      NativeEhClient.appendCookieHeader(cookie, names, values);
    } catch (error) {
    }
  }

  static configureCookieHeader(cookieHeader: string): void {
    NativeEhClient.stableCookieHeader = cookieHeader;
  }

  private static readCookie(url: string, site: string): string {
    const names: string[] = [];
    const values: string[] = [];
    NativeEhClient.appendCookieSource(EhUrl.DOMAIN_FORUMS, names, values);
    NativeEhClient.appendCookieSource(EhUrl.DOMAIN_E, names, values);
    if (site === GallerySite.EX) {
      NativeEhClient.appendCookieSource(EhUrl.DOMAIN_EX, names, values);
    }
    NativeEhClient.appendCookieSource(url, names, values);
    NativeEhClient.appendCookieHeader(NativeEhClient.stableCookieHeader, names, values);
    if (site === GallerySite.E) {
      NativeEhClient.appendCookieHeader('nw=1', names, values);
    }
    return values.join('; ');
  }

  private static async requestText(
    url: string,
    site: string,
    method: http.RequestMethod,
    referer: string,
    body?: string
  ): Promise<string> {
    const request = http.createHttp();
    const headers: Record<string, string> = {
      'Accept': NativeEhClient.REQUEST_ACCEPT,
      'Accept-Language': NativeEhClient.REQUEST_ACCEPT_LANGUAGE,
      'User-Agent': NativeEhClient.REQUEST_USER_AGENT
    };
    const host = NativeEhClient.hostFromUrl(url);
    if (host.length > 0) {
      headers['Host'] = host;
    }
    const cookie = NativeEhClient.readCookie(url, site);
    if (cookie.length > 0) {
      headers['Cookie'] = cookie;
    }
    if (referer.length > 0) {
      headers['Referer'] = referer;
    }
    if (method === http.RequestMethod.POST) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
      headers['Origin'] = EhUrl.origin(site);
    }

    const options: http.HttpRequestOptions = {
      method,
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      usingProxy: AppNetworkProxy.requestProxy(),
      readTimeout: 20000,
      connectTimeout: 12000,
      header: headers
    };
    if (body !== undefined) {
      options.extraData = body;
    }

    try {
      const response = await request.request(url, options);
      NativeEhClient.captureResponseCookies(url, response);
      const code = Number(response.responseCode);
      const text = typeof response.result === 'string' ? response.result : '';
      if (code < 200 || code >= 400) {
        throw new Error(`HTTP ${code}`);
      }
      return text;
    } catch (error) {
      const message = nativeRequestErrorMessage(error, 'Network request failed');
      hilog.error(DOMAIN, LOG_TAG, 'Native text request failed. Url=%{public}s Cause=%{public}s', url, message);
      throw new Error(message);
    } finally {
      request.destroy();
    }
  }

  private static async requestFormUrlEncoded(
    url: string,
    site: string,
    referer: string,
    values: NativeFormField[]
  ): Promise<string> {
    return NativeEhClient.requestRawFormUrlEncoded(url, site, referer, formUrlEncode(values));
  }

  private static async requestRawFormUrlEncoded(
    url: string,
    site: string,
    referer: string,
    body: string
  ): Promise<string> {
    const request = http.createHttp();
    const headers: Record<string, string> = {
      'Accept': NativeEhClient.REQUEST_ACCEPT,
      'Accept-Language': NativeEhClient.REQUEST_ACCEPT_LANGUAGE,
      'Content-Type': 'application/x-www-form-urlencoded',
      'Origin': EhUrl.origin(site),
      'Referer': referer,
      'User-Agent': NativeEhClient.REQUEST_USER_AGENT
    };
    const host = NativeEhClient.hostFromUrl(url);
    if (host.length > 0) {
      headers['Host'] = host;
    }
    const cookie = NativeEhClient.readCookie(url, site);
    if (cookie.length > 0) {
      headers['Cookie'] = cookie;
    }
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.POST,
        expectDataType: http.HttpDataType.STRING,
        usingCache: false,
        usingProxy: AppNetworkProxy.requestProxy(),
        readTimeout: 30000,
        connectTimeout: 12000,
        header: headers,
        extraData: body
      });
      NativeEhClient.captureResponseCookies(url, response);
      const code = Number(response.responseCode);
      if (code < 200 || code >= 400) {
        throw new Error(`HTTP ${code}`);
      }
      return typeof response.result === 'string' ? response.result : '';
    } catch (error) {
      const message = nativeRequestErrorMessage(error, 'Form request failed');
      hilog.error(DOMAIN, LOG_TAG, 'Native form request failed. Url=%{public}s Cause=%{public}s', url, message);
      throw new Error(message);
    } finally {
      request.destroy();
    }
  }

  private static async requestBinary(url: string, site: string, referer: string): Promise<ArrayBuffer> {
    const request = http.createHttp();
    const headers: Record<string, string> = {
      'Accept': '*/*',
      'Accept-Language': NativeEhClient.REQUEST_ACCEPT_LANGUAGE,
      'Referer': referer,
      'User-Agent': NativeEhClient.REQUEST_USER_AGENT
    };
    const host = NativeEhClient.hostFromUrl(url);
    if (host.length > 0) {
      headers['Host'] = host;
    }
    const cookie = NativeEhClient.readCookie(url, site);
    if (cookie.length > 0) {
      headers['Cookie'] = cookie;
    }
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        usingCache: false,
        usingProxy: AppNetworkProxy.requestProxy(),
        readTimeout: 60000,
        connectTimeout: 15000,
        header: headers
      });
      NativeEhClient.captureResponseCookies(url, response);
      const code = Number(response.responseCode);
      if (code < 200 || code >= 400) {
        throw new Error(`HTTP ${code}`);
      }
      const result = response.result;
      if (typeof result === 'string') {
        const buffer = new ArrayBuffer(result.length);
        const bytes = new Uint8Array(buffer);
        for (let index = 0; index < result.length; index++) {
          bytes[index] = result.charCodeAt(index) & 0xff;
        }
        return buffer;
      }
      return result as ArrayBuffer;
    } catch (error) {
      const message = nativeRequestErrorMessage(error, 'Binary request failed');
      hilog.error(DOMAIN, LOG_TAG, 'Native binary request failed. Url=%{public}s Cause=%{public}s', url, message);
      throw new Error(message);
    } finally {
      request.destroy();
    }
  }

  private static async requestApiBatch(
    site: string,
    identities: NativeGalleryIdentity[],
    referer: string
  ): Promise<NativeGallerySummary[]> {
    const gidList: Array<Array<number | string>> = [];
    for (const item of identities) {
      gidList.push([item.gid, item.token]);
    }

    const payload = JSON.stringify({
      method: 'gdata',
      gidlist: gidList,
      namespace: 1
    });

    const body = await NativeEhClient.requestText(
      EhUrl.api(site),
      site,
      http.RequestMethod.POST,
      referer,
      payload
    );

    return parseGDataResponse(body, site, identities);
  }

  private static topListEntryKey(gid: number, token: string): string {
    return `${gid}:${token}`;
  }

  private static collectTopListIdentities(detail: NativeTopListDetail): NativeGalleryIdentity[] {
    const identities: NativeGalleryIdentity[] = [];
    const seenKeys: string[] = [];
    for (const group of detail.groups) {
      for (const period of group.periods) {
        for (const entry of period.entries) {
          if (entry.gid <= 0 || entry.token.length === 0) {
            continue;
          }
          const key = NativeEhClient.topListEntryKey(entry.gid, entry.token);
          if (seenKeys.indexOf(key) >= 0) {
            continue;
          }
          seenKeys.push(key);
          identities.push({
            gid: entry.gid,
            token: entry.token,
            detailUrl: entry.url
          });
        }
      }
    }
    return identities;
  }

  private static applyTopListSummaries(detail: NativeTopListDetail, summaries: NativeGallerySummary[]): void {
    const thumbMap: Record<string, string> = {};
    for (const summary of summaries) {
      if (summary.gid <= 0 || summary.token.length === 0 || summary.thumb.length === 0) {
        continue;
      }
      thumbMap[NativeEhClient.topListEntryKey(summary.gid, summary.token)] = summary.thumb;
    }
    for (const group of detail.groups) {
      for (const period of group.periods) {
        for (const entry of period.entries) {
          const thumb = thumbMap[NativeEhClient.topListEntryKey(entry.gid, entry.token)];
          if (thumb && thumb.length > 0) {
            entry.thumb = thumb;
          }
        }
      }
    }
  }

  private static async enrichTopListThumbnails(detail: NativeTopListDetail, referer: string): Promise<void> {
    const identities = NativeEhClient.collectTopListIdentities(detail);
    const summaries: NativeGallerySummary[] = [];
    const chunkSize = 25;
    for (let index = 0; index < identities.length; index += chunkSize) {
      const chunk = identities.slice(index, index + chunkSize);
      const partial = await NativeEhClient.requestApiBatch(GallerySite.E, chunk, referer);
      summaries.push(...partial);
    }
    NativeEhClient.applyTopListSummaries(detail, summaries);
  }

  private static async requestMultipart(
    url: string,
    site: string,
    referer: string,
    formData: http.MultiFormData[]
  ): Promise<string> {
    const request = http.createHttp();
    const headers: Record<string, string> = {
      'Accept': NativeEhClient.REQUEST_ACCEPT,
      'Accept-Language': NativeEhClient.REQUEST_ACCEPT_LANGUAGE,
      'Origin': EhUrl.origin(site),
      'Referer': referer,
      'User-Agent': NativeEhClient.REQUEST_USER_AGENT
    };
    const host = NativeEhClient.hostFromUrl(url);
    if (host.length > 0) {
      headers['Host'] = host;
    }
    const cookie = NativeEhClient.readCookie(url, site);
    if (cookie.length > 0) {
      headers['Cookie'] = cookie;
    }
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      usingProxy: AppNetworkProxy.requestProxy(),
      readTimeout: 60000,
      connectTimeout: 20000,
      maxLimit: 100 * 1024 * 1024,
      header: headers,
      multiFormDataList: formData
    };
    try {
      const response = await request.request(url, options);
      NativeEhClient.captureResponseCookies(url, response);
      const code = Number(response.responseCode);
      if (code < 200 || code >= 400) {
        throw new Error(`HTTP ${code}`);
      }
      return typeof response.result === 'string' ? response.result : '';
    } catch (error) {
      const message = nativeRequestErrorMessage(error, 'Multipart request failed');
      hilog.error(DOMAIN, LOG_TAG, 'Native multipart request failed. Url=%{public}s Cause=%{public}s', url, message);
      throw new Error(message);
    } finally {
      request.destroy();
    }
  }

  private static async createGalleryListResultFromHtml(
    site: string,
    requestUrl: string,
    html: string
  ): Promise<NativeGalleryListResult> {
    if (html.trim().length === 0) {
      throw new Error('Empty response. Sign in first or import the cookie from the web view.');
    }
    const shell = parseGalleryListShell(html, site);
    if (shell.identities.length === 0) {
      const lowerHtml = html.toLowerCase();
      if (lowerHtml.indexOf('no hits found') >= 0 ||
        lowerHtml.indexOf('no unfiltered results') >= 0 ||
        lowerHtml.indexOf('you do not have any watched tags') >= 0) {
        return {
          items: [],
          requestUrl,
          resultCount: shell.resultCount,
          firstUrl: shell.firstUrl,
          prevUrl: shell.prevUrl,
          nextUrl: shell.nextUrl,
          lastUrl: shell.lastUrl,
          favoriteSlots: shell.favoriteSlots
        };
      }
      if (requestUrl.indexOf('home.php') >= 0) {
        throw new Error('Account home is not a gallery list. Use the gallery front page for waterfall loading.');
      }
      if (lowerHtml.indexOf('login') >= 0 || lowerHtml.indexOf('sign in') >= 0) {
        throw new Error('Gallery list was not found. Sign in or import valid cookies first.');
      }
      throw new Error('No gallery entries were parsed from this page.');
    }
    const items: NativeGallerySummary[] = [];
    const chunkSize = 25;
    for (let index = 0; index < shell.identities.length; index += chunkSize) {
      const chunk = shell.identities.slice(index, index + chunkSize);
      try {
        const partial = await NativeEhClient.requestApiBatch(site, chunk, requestUrl);
        items.push(...mergeGalleryListSummaries(site, html, chunk, partial));
      } catch (error) {
        items.push(...mergeGalleryListSummaries(site, html, chunk, []));
      }
    }
    return {
      items,
      requestUrl,
      resultCount: shell.resultCount,
      firstUrl: shell.firstUrl,
      prevUrl: shell.prevUrl,
      nextUrl: shell.nextUrl,
      lastUrl: shell.lastUrl,
      favoriteSlots: shell.favoriteSlots
    };
  }

  public static async fetchGalleryList(site: string, requestUrl: string): Promise<NativeGalleryListResult> {
    const html = await NativeEhClient.requestText(
      requestUrl,
      site,
      http.RequestMethod.GET,
      EhUrl.referer(site)
    );
    return NativeEhClient.createGalleryListResultFromHtml(site, requestUrl, html);
  }

  public static async fetchTopList(site: string): Promise<NativeTopListDetail> {
    const requestUrl = EhUrl.topList();
    const html = await NativeEhClient.requestText(
      requestUrl,
      GallerySite.E,
      http.RequestMethod.GET,
      requestUrl
    );
    const detail = parseTopList(html, GallerySite.E);
    if (detail.groups.length === 0) {
      throw new Error('No toplist entries were parsed.');
    }
    try {
      await NativeEhClient.enrichTopListThumbnails(detail, requestUrl);
    } catch (error) {
    }
    return detail;
  }

  public static async fetchTopListEntryPage(requestUrl: string): Promise<NativeTopListEntryPageResult> {
    const html = await NativeEhClient.requestText(
      requestUrl,
      GallerySite.E,
      http.RequestMethod.GET,
      EhUrl.topList()
    );
    const result = parseTopListEntryPage(html, GallerySite.E, requestUrl);
    if (result.items.length === 0) {
      throw new Error('No plain toplist entries were parsed from this page.');
    }
    return result;
  }

  public static async fetchUserTags(site: string): Promise<NativeUserTag[]> {
    const requestUrl = EhUrl.myTags(site);
    const html = await NativeEhClient.requestText(
      requestUrl,
      site,
      http.RequestMethod.GET,
      EhUrl.referer(site)
    );
    const tags = parseUserTags(html);
    return tags;
  }

  private static userTagNumericId(item: NativeUserTag): string {
    const match = /(\d+)$/.exec(item.id);
    return match && match[1] ? match[1] : '';
  }

  public static async addWatchedTag(site: string, tagName: string): Promise<NativeUserTag[]> {
    const requestUrl = EhUrl.myTags(site);
    const body = `usertag_action=add&tagname_new=${tagName}` +
      '&tagwatch_new=on&tagcolor_new=&tagweight_new=10&usertag_target=0';
    const html = await NativeEhClient.requestRawFormUrlEncoded(
      requestUrl,
      site,
      requestUrl,
      body
    );
    return parseUserTags(html);
  }

  public static async deleteWatchedTag(site: string, item: NativeUserTag): Promise<NativeUserTag[]> {
    const targetId = NativeEhClient.userTagNumericId(item);
    if (targetId.length === 0) {
      throw new Error('无法识别要删除的关注标签。');
    }
    const requestUrl = EhUrl.myTags(site);
    const body = 'usertag_action=mass&tagname_new=&tagcolor_new=' +
      `&tagweight_new=${item.tagWeight}&modify_usertags%5B%5D=${targetId}&usertag_target=0`;
    const html = await NativeEhClient.requestRawFormUrlEncoded(
      requestUrl,
      site,
      requestUrl,
      body
    );
    return parseUserTags(html);
  }

  public static async submitWatchedTagChanges(
    site: string,
    addTagNames: string[],
    deleteTags: NativeUserTag[]
  ): Promise<NativeUserTag[]> {
    const addedKeys: string[] = [];
    for (const rawName of addTagNames) {
      const tagName = rawName.trim();
      const key = tagName.toLowerCase();
      if (tagName.length === 0 || addedKeys.indexOf(key) >= 0) {
        continue;
      }
      addedKeys.push(key);
      await NativeEhClient.addWatchedTag(site, tagName);
    }
    const deletedKeys: string[] = [];
    for (const item of deleteTags) {
      const key = item.tagName.trim().toLowerCase();
      if (key.length === 0 || deletedKeys.indexOf(key) >= 0) {
        continue;
      }
      deletedKeys.push(key);
      await NativeEhClient.deleteWatchedTag(site, item);
    }
    return NativeEhClient.fetchUserTags(site);
  }

  public static async searchByImage(
    site: string,
    filePath: string,
    similar: boolean,
    covers: boolean,
    expunged: boolean
  ): Promise<NativeGalleryListResult> {
    const requestUrl = site === GallerySite.EX ?
      'https://upld.exhentai.org/upld/image_lookup.php' : 'https://upld.e-hentai.org/image_lookup.php';
    const formData: http.MultiFormData[] = [
      {
        name: 'sfile',
        contentType: 'image/jpeg',
        remoteFileName: fileNameFromPath(filePath),
        filePath
      }
    ];
    if (similar) {
      formData.push({
        name: 'fs_similar',
        contentType: 'text/plain',
        data: 'on'
      });
    }
    if (covers) {
      formData.push({
        name: 'fs_covers',
        contentType: 'text/plain',
        data: 'on'
      });
    }
    if (expunged) {
      formData.push({
        name: 'fs_exp',
        contentType: 'text/plain',
        data: 'on'
      });
    }
    formData.push({
      name: 'f_sfile',
      contentType: 'text/plain',
      data: 'File Search'
    });
    const html = await NativeEhClient.requestMultipart(requestUrl, site, EhUrl.referer(site), formData);
    return NativeEhClient.createGalleryListResultFromHtml(site, requestUrl, html);
  }

  public static async fetchGalleryDetail(site: string, summary: NativeGallerySummary): Promise<NativeGalleryDetail> {
    const html = await NativeEhClient.requestText(
      summary.detailUrl,
      site,
      http.RequestMethod.GET,
      EhUrl.referer(site)
    );
    return mergeDetailHtml(createDetailFromSummary(summary), html, site);
  }

  public static async fetchGalleryDetailComments(
    site: string,
    detail: NativeGalleryDetail
  ): Promise<NativeGalleryDetail> {
    const requestUrl = EhUrl.galleryComments(site, detail.gid, detail.token);
    const html = await NativeEhClient.requestText(
      requestUrl,
      site,
      http.RequestMethod.GET,
      detail.detailUrl
    );
    const nextDetail = mergeDetailHtml(detail, html, site);
    nextDetail.comments = parseGalleryComments(html, 0);
    nextDetail.hasMoreComments = false;
    return nextDetail;
  }

  public static async modifyFavorite(
    site: string,
    gid: number,
    token: string,
    slot: number,
    note: string = ''
  ): Promise<void> {
    const favcat = slot < 0 ? 'favdel' : `${slot}`;
    const formValues: NativeFormField[] = [
      { name: 'favcat', value: favcat },
      { name: 'favnote', value: note },
      { name: 'submit', value: 'Apply Changes' },
      { name: 'update', value: '1' }
    ];
    await NativeEhClient.requestFormUrlEncoded(
      EhUrl.addFavorites(site, gid, token),
      site,
      EhUrl.galleryDetail(site, gid, token),
      formValues
    );
  }

  public static async rateGallery(
    site: string,
    apiUid: number,
    apiKey: string,
    gid: number,
    token: string,
    rating: number
  ): Promise<NativeRateResult> {
    const payload = JSON.stringify({
      method: 'rategallery',
      apiuid: apiUid,
      apikey: apiKey,
      gid,
      token,
      rating: Math.ceil(rating * 2)
    });
    const body = await NativeEhClient.requestText(
      EhUrl.api(site),
      site,
      http.RequestMethod.POST,
      EhUrl.galleryDetail(site, gid, token),
      payload
    );
    return parseRateResult(body);
  }

  public static async voteComment(
    site: string,
    apiUid: number,
    apiKey: string,
    gid: number,
    token: string,
    commentId: number,
    vote: number
  ): Promise<NativeVoteCommentResult> {
    const payload = JSON.stringify({
      method: 'votecomment',
      apiuid: apiUid,
      apikey: apiKey,
      gid,
      token,
      comment_id: commentId,
      comment_vote: vote
    });
    const body = await NativeEhClient.requestText(
      EhUrl.api(site),
      site,
      http.RequestMethod.POST,
      EhUrl.referer(site),
      payload
    );
    return parseVoteCommentResult(body, vote);
  }

  public static async fetchTorrentList(
    site: string,
    torrentUrl: string,
    gid: number,
    token: string
  ): Promise<NativeTorrentItem[]> {
    const html = await NativeEhClient.requestText(
      torrentUrl,
      site,
      http.RequestMethod.GET,
      EhUrl.galleryDetail(site, gid, token)
    );
    return parseTorrentItems(html, site);
  }

  public static async downloadBinary(
    site: string,
    url: string,
    referer: string
  ): Promise<ArrayBuffer> {
    return NativeEhClient.requestBinary(url, site, referer);
  }

  public static async fetchArchiveList(
    site: string,
    archiveUrl: string,
    gid: number,
    token: string
  ): Promise<NativeArchiveList> {
    const html = await NativeEhClient.requestText(
      archiveUrl,
      site,
      http.RequestMethod.GET,
      EhUrl.galleryDetail(site, gid, token)
    );
    return parseArchiveList(html);
  }

  public static async submitArchiveDownload(
    site: string,
    gid: number,
    token: string,
    formParamOr: string,
    res: string
  ): Promise<void> {
    const formValues: NativeFormField[] = [
      { name: 'hathdl_xres', value: res }
    ];
    const body = await NativeEhClient.requestFormUrlEncoded(
      EhUrl.downloadArchive(site, gid, token, formParamOr),
      site,
      EhUrl.galleryDetail(site, gid, token),
      formValues
    );
    if (/No H@H client|No H.?H client|no client/i.test(body)) {
      throw new Error('No H@H client is available for this archive request');
    }
  }

  public static async fetchGalleryPreviewPage(
    site: string,
    detailUrl: string,
    pageIndex: number
  ): Promise<NativeGalleryPreviewPage> {
    const requestUrl = buildPreviewPageUrl(detailUrl, pageIndex);
    const html = await NativeEhClient.requestText(
      requestUrl,
      site,
      http.RequestMethod.GET,
      detailUrl
    );
    const page: NativeGalleryPreviewPage = {
      items: parsePreviewItems(html, site),
      pageIndex,
      pageCount: parsePreviewPageCount(html)
    };
    return page;
  }

  public static async fetchFirstReaderPageUrl(site: string, detailUrl: string): Promise<string> {
    const html = await NativeEhClient.requestText(
      detailUrl,
      site,
      http.RequestMethod.GET,
      detailUrl
    );
    return parseFirstReaderPageUrl(html, site);
  }

  public static async fetchReaderPage(
    site: string,
    pageUrl: string,
    skipHathKey: string = ''
  ): Promise<NativeGalleryImagePage> {
    const requestUrl = readerPageUrlWithSkipHathKey(pageUrl, skipHathKey);
    const html = await NativeEhClient.requestText(
      requestUrl,
      site,
      http.RequestMethod.GET,
      pageUrl
    );
    return parseReaderPage(html, pageUrl);
  }
}
