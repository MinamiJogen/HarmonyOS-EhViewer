import { NativeGallerySummary } from '../ehviewer/EhNative';

export const APP_INDEX_PAGE_URL: string = 'pages/Index';

export const ROUTE_NATIVE_DETAIL: string = 'detail';
export const ROUTE_NATIVE_PREVIEWS: string = 'previews';
export const ROUTE_NATIVE_READER: string = 'reader';
export const ROUTE_NATIVE_COMMENTS: string = 'comments';
export const ROUTE_SEARCH_ACTIVE: string = '1';

export interface PageRouteParams {
  activeSection: string;
  myPage: string;
  myPageTitle: string;
  webUrl?: string;
  webTitle?: string;
  webMode?: string;
  nativeRoute?: string;
  siteMode?: string;
  gid?: string;
  token?: string;
  title?: string;
  titleJpn?: string;
  thumb?: string;
  categoryLabel?: string;
  posted?: string;
  uploader?: string;
  rating?: string;
  pages?: string;
  simpleLanguage?: string;
  detailUrl?: string;
  readerPageUrl?: string;
  searchRoute?: string;
  searchMode?: string;
  searchQuery?: string;
  searchCategoryMask?: string;
  searchAdvancedEnabled?: string;
  searchAdvancedFlags?: string;
  searchMinRating?: string;
  searchPageFrom?: string;
  searchPageTo?: string;
  searchUrl?: string;
  searchTransitionQuery?: string;
}

export function readRouteString(params: Record<string, Object>, key: string): string {
  const value = params[key];
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number') {
    return `${value}`;
  }
  return '';
}

export function createBaseRouteParams(activeSection: number, myPage: string, myPageTitle: string): PageRouteParams {
  return {
    activeSection: `${activeSection}`,
    myPage,
    myPageTitle
  };
}

export function createWebRouteParams(
  activeSection: number,
  myPage: string,
  myPageTitle: string,
  webUrl: string,
  webTitle: string,
  webMode: string
): PageRouteParams {
  const params = createBaseRouteParams(activeSection, myPage, myPageTitle);
  params.webUrl = webUrl;
  params.webTitle = webTitle;
  params.webMode = webMode;
  return params;
}

export function createNativeRouteParams(
  activeSection: number,
  myPage: string,
  myPageTitle: string,
  siteMode: string,
  item: NativeGallerySummary,
  nativeRoute: string,
  readerPageUrl: string = ''
): PageRouteParams {
  const params = createBaseRouteParams(activeSection, myPage, myPageTitle);
  params.nativeRoute = nativeRoute;
  params.siteMode = siteMode;
  params.gid = `${item.gid}`;
  params.token = item.token;
  params.title = item.title;
  params.titleJpn = item.titleJpn;
  params.thumb = item.thumb;
  params.categoryLabel = item.categoryLabel;
  params.posted = item.posted;
  params.uploader = item.uploader;
  params.rating = `${item.rating}`;
  params.pages = `${item.pages}`;
  params.simpleLanguage = item.simpleLanguage;
  params.detailUrl = item.detailUrl;
  params.readerPageUrl = readerPageUrl;
  return params;
}

export function createMyPageRouteParams(
  activeSection: number,
  page: string,
  title: string,
  siteMode: string = ''
): PageRouteParams {
  const params = createBaseRouteParams(activeSection, page, title);
  if (siteMode.length > 0) {
    params.siteMode = siteMode;
  }
  return params;
}

export function createSearchRouteParams(
  activeSection: number,
  myPage: string,
  myPageTitle: string,
  siteMode: string,
  searchMode: string,
  searchQuery: string,
  searchCategoryMask: number,
  searchAdvancedFlags: number,
  searchUrl: string,
  searchTransitionQuery: string = '',
  searchAdvancedEnabled: boolean = true,
  searchMinRating: string = '',
  searchPageFrom: string = '',
  searchPageTo: string = ''
): PageRouteParams {
  const params = createBaseRouteParams(activeSection, myPage, myPageTitle);
  params.searchRoute = ROUTE_SEARCH_ACTIVE;
  params.siteMode = siteMode;
  params.searchMode = searchMode;
  params.searchQuery = searchQuery;
  params.searchCategoryMask = `${searchCategoryMask}`;
  params.searchAdvancedEnabled = searchAdvancedEnabled ? '1' : '0';
  params.searchAdvancedFlags = `${searchAdvancedFlags}`;
  params.searchMinRating = searchMinRating;
  params.searchPageFrom = searchPageFrom;
  params.searchPageTo = searchPageTo;
  params.searchUrl = searchUrl;
  params.searchTransitionQuery = searchTransitionQuery;
  return params;
}
