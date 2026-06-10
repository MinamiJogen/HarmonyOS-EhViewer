import { LocalGalleryRecord } from '../models/LocalModels';

export interface DownloadQueueItem extends LocalGalleryRecord {
  status: string;
  label: string;
  queuedAt: string;
  lastAction: string;
  downloaded: number;
  total: number;
  failedCount: number;
  archiveUri: string;
  createdAt: string;
  updatedAt: string;
  currentPage: number;
  currentPageLabel: string;
  speedBytesPerSecond: number;
  remainingSeconds: number;
  downloadDir: string;
  error: string;
  pageErrors: DownloadPageError[];
}

export interface DownloadPageError {
  page: number;
  message: string;
  updatedAt: string;
}

export interface DownloadLabelItem {
  label: string;
  createdAt: string;
}

export interface DownloadPageResult {
  path: string;
  bytes: number;
  sourceUrl: string;
}

export type DownloadProgressCallback = (receivedBytes: number, totalBytes: number) => void;

export const DOWNLOAD_STATUS_QUEUED: string = 'waiting';
export const DOWNLOAD_STATUS_READING: string = 'reading';
export const DOWNLOAD_STATUS_DOWNLOADING: string = 'downloading';
export const DOWNLOAD_STATUS_PAUSED: string = 'paused';
export const DOWNLOAD_STATUS_FAILED: string = 'failed';
export const DOWNLOAD_STATUS_DONE: string = 'complete';
export const DOWNLOAD_STATUS_DELETED: string = 'deleted';
export const DOWNLOAD_LABEL_ALL: string = '__all__';
export const DOWNLOAD_DEFAULT_LABEL: string = '默认';
export const DOWNLOAD_DATABASE_NAME: string = 'ehviewer_harmony_downloads.db';
export const DOWNLOAD_TABLE: string = 'downloads';
export const DOWNLOAD_LABEL_TABLE: string = 'download_label';
export const DOWNLOAD_INFO_FILENAME: string = '.ehviewer';
export const DOWNLOAD_INFO_HEADER: string =
  'gid,token,title,title_jpn,thumb,category,posted,uploader,rating,rated,simple_lang,simple_tags,thumb_width,thumb_height,span_size,span_index,span_group_index,favorite_slot,favorite_name,pages';
export const DOWNLOAD_PAGE_RETRY_LIMIT: number = 2;
export const DOWNLOAD_DEFAULT_CONCURRENCY: number = 1;
export const DOWNLOAD_MAX_CONCURRENCY: number = 3;
export const DOWNLOAD_NOTIFICATION_ID: number = 2401;
export const DOWNLOAD_NOTIFICATION_LABEL: string = 'ehviewer_download_queue';
export const DOWNLOAD_NOTIFICATION_INTERVAL_MS: number = 1500;
export const DOWNLOAD_BACKGROUND_MODE: string = 'dataTransfer';
export const DOWNLOAD_STATE_POLL_INTERVAL_MS: number = 400;
export const DOWNLOAD_PROGRESS_UI_INTERVAL_MS: number = 260;
export const DOWNLOAD_PROGRESS_PERSIST_INTERVAL_MS: number = 2000;
